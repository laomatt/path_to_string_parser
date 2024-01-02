# frozen_string_literal: true

require_relative "path_to_string_parser/version"

module PathToStringParser
  class Error < StandardError; end

  def self.parse_and_convert_file(file)
    paths = []
    File.open( file ).each { |line| 
      paths += line.scan(/\S*_path/).map { |e| e.delete_prefix("\#{") }
    }

    puts "Building a temporary routes file"
    out_file = File.new("tmp/routes.txt", "w")
    out_file.puts(`rails routes`)
    out_file.close

    translation = {}

    File.open( "tmp/routes.txt" ).each { |ln|
      sub_line = ln.split(/\s/).reject{|e| e == ""}
      if paths.include? "#{sub_line[0]}_path"
        translation["#{sub_line[0]}_path"] = sub_line[2].sub("(.:format)","")
      end
    }

    replace_path = lambda do |arg|
      translation_replace = translation[arg.sub(/\(.*?\)/,'')].clone
      obj = arg.scan(/\(.*?\)/).first.delete_prefix("(").chomp(')') if arg.scan(/\(.*?\)/).first

      if translation_replace && translation_replace.include?(":") && obj
        translation_replace.clone.scan(/:\w*?\/|:.*/) { |a| 
          att_name = a.delete_prefix(":").chomp('/')
          raw_att_name = a.chomp('/')
          translation_replace.sub!(raw_att_name, '#{'+"#{obj}.#{att_name}"+'}')
        }
      end

      translation_replace
    end

    File.open( file ).each do |line| 
      line.clone.scan(/\#{.*?\}/).reject { |e| e.include? "if " }.to_a.uniq.each do |r|
        nr = r.chomp("}").delete_prefix('#{')
        to_replace = replace_path.call(nr)
        line.sub!(r,to_replace) if to_replace
      end

      line.clone.scan(/\S*_path\(.*?\)|\S*_path/).to_a.uniq.each do |r|
        to_replace = replace_path.call(r)
        line.sub!(r,"\"#{to_replace}\"") if to_replace
      end

    end

    File.delete("tmp/routes.txt")
  end
end
