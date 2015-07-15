require 'conjur-asset-dsl2'

module Conjur
  module DSL2
    class Loader
      class << self
        def load yaml, filename = nil
          parser = Psych::Parser.new(handler = Handler.new)
          handler.filename = filename
          handler.parser = parser
          begin
            parser.parse(yaml)
          rescue
            $stderr.puts $!.message
            $stderr.puts $!.backtrace.join("  \n")
            raise Invalid.new($!.message, filename, parser.mark)
          end
          handler.result
        end
        
        def load_file filename
          load File.read(filename), filename
        end
      end
    end
  end
end
