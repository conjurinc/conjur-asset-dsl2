#
# Copyright (C) 2014 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur-asset-dsl2'

class Conjur::Command::DSL2 < Conjur::DSLCommand
  def self.loader filename, options
    result = options[:syntax]
    if result.nil? && filename
      filename =~ /\.([^.]+)$/
      suffix = $1
      result = case suffix
      when 'yaml', 'yml'
        'yaml'
      when 'rb'
        'ruby'
      end
    end
    raise "No syntax provided or detected" unless result
    mod = Conjur::DSL2.const_get result.capitalize
    mod.const_get "Loader"
  end
  
  desc "Load a DSL2 policy"
  command :policy do |policy|
    policy.desc "Load a policy from Conjur YAML DSL"
    policy.arg_name "(policy-file | STDIN)"
    policy.command :load do |c|
      acting_as_option(c)

      c.desc "Syntax (ruby or YAML, will be auto-detected from file extension)"
      c.switch [:"syntax"]
      
      c.desc "Print the actions that would be performed"
      c.switch [:"dry-run"]

      c.action do |global_options,options,args|
        Conjur.log = "stderr"
  
        filename = nil
        records = if script = args.pop
          filename = script
          script = if File.exists?(script)
            File.read(script)
          else
            require 'open-uri'
            uri = URI.parse(script)
            raise "Unable to read this kind of URL : #{script}" unless uri.respond_to?(:read)
            begin
              uri.read
            rescue OpenURI::HTTPError
              raise "Unable to read URI #{script} : #{$!.message}"
            end
          end
          
          loader(filename, options).load_file filename
        else
          loader(filename, options).load STDIN.read
        end

        plan = Conjur::DSL2::Planner.plan(records, api)
          
        if options[:"dry-run"]
          puts plan.to_yaml
        else
          executor = Conjur::DSL2::Executor.new(plan)
          executor.owner = options[:ownerid] if options[:ownerid]
          executor.execute
        end
      end
    end
  end
end
