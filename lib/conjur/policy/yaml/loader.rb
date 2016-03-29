require 'conjur-asset-policy'

module Conjur
  module Policy
    module YAML
      class Loader
        class << self
          def load yaml, filename = nil
            parser = Psych::Parser.new(handler = Handler.new)
            handler.filename = filename
            handler.parser = parser
            begin
              parser.parse(yaml)
            rescue
              handler.log { $!.message }
              handler.log { $!.backtrace.join("  \n") }
              raise Invalid.new($!.message || "(no message)", filename, parser.mark)
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
end
