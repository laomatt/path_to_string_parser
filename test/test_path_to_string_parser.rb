# frozen_string_literal: true

require "test_helper"

class TestPathToStringParser < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PathToStringParser::VERSION
  end

  def test_it_parses_a_replaces_a_intorpolated_string
    translation_hash = {
      "named_path" => "corrected/path",
      "named_path(@object)" => "corrected/path/:id"
    }

    assert_equal PathToStringParser.parse_line("this is a sentence with an intorpolated \#{named_path\} in it",translation_hash), "this is a sentence with an intorpolated corrected/path in it"

    assert_equal PathToStringParser.parse_line("this is a sentence with an intorpolated \#{invalid_named_path\} in it",translation_hash), "this is a sentence with an intorpolated \#{invalid_named_path\} in it"

  end

  def test_it_parses_a_replaces_a_path_with_argument
    translation_hash = {
      "named_path" => "corrected/path",
      "named_path_with_id" => "corrected/path/:id"
    }

    test_line = "
      this is a sentence with an intorpolated \#{named_path_with_id(@some_obj)\} in it \n
    "

    assert_equal PathToStringParser.parse_line(test_line, translation_hash), "
      this is a sentence with an intorpolated corrected/path/\#{@some_obj.id\} in it \n
    "
  end

end
