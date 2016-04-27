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
require 'conjur-asset-policy'

class Conjur::Command::Policy < Conjur::DSLCommand
  def self.load filename
    script = script_from_filename filename
    loader.load script, filename
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

  def self.loader
    mod = Conjur::Policy.const_get 'YAML'
    mod.const_get "Loader"
  end

  def self.execute api, records, options = {}
    actions = []
    records.each do |record|
      executor_class = Conjur::Policy::Executor.class_for(record)
      executor = executor_class.new(record, actions)
      executor.execute
    end
    Conjur::Policy::HTTPExecutor.new(api).execute actions
  end


  def self.save_context_to_file context, path

    existing = if File.file?(path)
      JSON.load(File.read(path))
    else
      {}
    end

    File.write(path, existing.merge(context).to_json)
  rescue => ex
    # It would suck to lose all your API keys by fat-fingering the filename -- write it to the stdout if
    # anything goes wrong.
    $stderr.puts "Error saving context to #{path}: #{ex}.  Context will be written to the stdout"
    $stderr.puts ex.backtrace.join("\n\t") if ENV['DEBUG']
    puts context.to_json
  end

  desc "Manage policies"
  command :policy do |policy|

    policy.desc "Load a policy from Conjur YAML"
    policy.long_desc <<-DESC
Using this command, Conjur data can be specified as Ruby or YAML statements and
loaded into the server.

Each statement performs one of the following functions:

* Find or create a record, for example a group

* Give a permission on a resource, e.g. permission to 'execute' a variable

* Grant a role, e.g. add a member to a group.

When finding or creating a record, the "namespace" option can be used to prepend
a common prefix to each record.

If the statements are enclosed by a "policy", the id of the policy is also prepended
to the id of each record, after the namespace.

This command can load the policy directly into Conjur, and it can also operate
in "dry run" mode. In dry run mode, an execution plan will be computed and printed,
but the actions will not be performed. The execution plan includes only the minimal
set of commands which are required to apply the policy to Conjur. In effect, it's
a "diff" between the policy and the current state of the Conjur database.

The execution plan can be printed in machine-readable YAML format, or in a more
human-friendly text format.

The YAML output of dry run mode can be used as input for the "conjur policy import"
command. Therefore, a policy can be loaded in three steps, if desired:

1) Load the policy in dry run mode to print the execution plan.

2) Review the execution plan, manually or programatically.

3) Import the execution plan.
    DESC
    policy.arg_name "(policy-file | STDIN)"
    policy.command :load do |c|
      acting_as_option(c)

      c.desc "Policy namespace (optional)"
      c.flag [:namespace]

      c.desc "Print the actions that would be performed"
      c.switch [:"dry-run"]

      c.desc "Output format of --dry-run mode (text, yaml)"
      c.default_value "yaml"
      c.flag [:format]

      c.desc "File to store API keys for created roles (defaults to stdout)"
      c.flag [:context]

      c.desc "Don't save the context anywhere (including the stdout)"
      c.switch [:'no-context']

      c.action do |global_options,options,args|
        Conjur.log = "stderr"

        filename = args.pop
        records = load filename

        ownerid = options[:ownerid]
        unless ownerid
          user_kind, user_id = api.username.split('/', 2)
          unless user_id
            user_id = user_kind
            user_kind = 'user'
          end
          ownerid = [ Conjur.configuration.account, user_kind, user_id ].join(":")
        end

        records = Conjur::Policy::Resolver.resolve(records, Conjur.configuration.account, ownerid, options[:namespace])
        naked_api = api.dup
        naked_api.privilege = nil
        plan_api = if api.privilege == "elevate" && naked_api.global_privilege_permitted?("reveal")
          api.with_privilege("reveal")
        else
          api
        end
        plan = Conjur::Policy::Planner.plan(records, plan_api)

        if options[:"dry-run"]
          case options[:"format"]
          when 'text'
            puts plan.actions.map(&:to_s)
          else
            puts plan.actions.to_yaml
          end
        else
          $stderr.puts plan.actions.map(&:to_s)
          context = execute api, plan.actions

          if options[:context]
            save_context_to_file context, options[:context]
          else
            puts context.to_json unless options[:'no-context']
          end
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
        actions = Conjur::Policy::YAML::Loader.load(script, filename)
        context = execute api, actions, options

        if options[:context]
          save_context_to_file context, options[:context]
        else
          puts context.to_json unless options[:'no-context']
        end
      end
    end

    policy.desc 'Decommision a policy'
    policy.arg_name 'POLICY'
    policy.command :retire do |c|
      retire_options c

      c.action do |global_options, options, args |
        id = "policy:#{require_arg(args, 'POLICY')}"

        # policy isn't a rolsource (yet), but we can pretend
        Policy = Struct.new(:role, :resource)
        pol = Policy.new(api.role(id), api.resource(id))

        validate_retire_privileges(pol, options)

        retire_resource(pol)

        # The policy resource is owned by the policy role. Having the
        # policy role is what allows us to administer it. So, we have
        # to give the resource away before we can revoke the role.
        give_away_resource(pol, options)

        retire_role(pol)

        puts 'Policy retired'
      end
    end
  end
end
