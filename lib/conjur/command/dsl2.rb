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
  subcommand_option_handling :normal

  def self.load filename, syntax
    script = script_from_filename filename
    loader(filename, syntax).load script, filename
  end
  
  def self.script_from_filename filename
    if filename
      if File.exists?(filename)
        File.read(filename)
      else
        require 'open-uri'
        uri = URI.parse(filename)
        raise "Unable to read this kind of URL : #{filename}" unless uri.respond_to?(:read)
        begin
          uri.read
        rescue OpenURI::HTTPError
          raise "Unable to read URI #{filename} : #{$!.message}"
        end
      end
    else
      STDIN.read
    end
  end
  
  def self.loader filename, syntax
    if syntax.nil? && filename
      filename =~ /\.([^.]+)$/
      suffix = $1
      syntax = case suffix
      when 'yaml', 'yml'
        'YAML'
      when 'rb'
        'Ruby'
      end
    end
    raise "No syntax provided or detected" unless syntax
    mod = Conjur::DSL2.const_get syntax
    mod.const_get "Loader"
  end
  
  def self.execute api, actions, options
    executor = Conjur::DSL2::Executor.new api, actions
    executor.owner = options[:ownerid] if options[:ownerid]
    executor.execute
  end
  
  desc "Load a DSL2 policy"
  command :policy do |policy|
    policy.desc "Load a policy from Conjur YAML DSL"
    policy.arg_name "(policy-file | STDIN)"
    policy.command :load do |c|
      acting_as_option(c)

      c.desc "Policy namespace, blank by default"
      c.arg_name "namespace"
      c.flag [:namespace]

      c.desc "Syntax (ruby or YAML, will be auto-detected from file extension)"
      c.switch [:"syntax"]
      
      c.desc "Print the actions that would be performed"
      c.switch [:"dry-run"]

      c.action do |global_options,options,args|
        Conjur.log = "stderr"
  
        filename = args.pop
        records = load filename, options[:syntax]
        plan = Conjur::DSL2::Planner.plan(records, api, options[:namespace])
          
        if options[:"dry-run"]
          puts plan.actions.to_yaml
        else
          execute api, plan.actions, options
        end
      end
    end
    
    policy.desc "Import policy statements from a policy plan (aka --dry-run)"
    policy.arg_name "(statements-file | STDIN)"
    policy.command :import do |c|
      acting_as_option(c)
      
      c.action do |global_options,options,args|
        Conjur.log = "stderr"
  
        filename = args.pop
        script = script_from_filename filename
        actions = YAML.load(script, filename)
        execute api, actions, options
      end
    end
  end
end
