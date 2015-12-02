module DSLWorld
  
  def specify_cli_environment
    set_environment_variable "GLI_DEBUG", "true"
  end
  
  def load_policy text
    specify_cli_environment
    step "I run `conjur policy load --namespace #{namespace} --syntax ruby` interactively"
    last_command_started.write(text)
    last_command_started.stdin.close
    step "the exit status should be 0"
  end
  
  def last_json
    # Hack to get Aruba to populate stdout
    step "the output should contain \"\""
    YAML.load(all_commands.map(&:stdout).join).to_json
  end
  
  def normalize_stdout
    all_commands.each do |cmd|
      if cmd.instance_variable_get("@context").nil?
        cmd.instance_variable_set("@context", self)
        class << cmd
          def stdout(options={})
            @context.strip_namespace super(options)
          end
        end
      end
    end
  end
  
  def namespace
    @namespace ||= [ 'cucumber', 'dsl2', $timestamp, (0..3).inject([]){|memo,entry| memo.push rand(255).to_s(16); memo}.join ].join('/')
  end
  
  def inject_namespace text
    text.gsub "@namespace@", namespace
  end
  
  def strip_namespace text
    return "" if text.nil?
    text.gsub "#{namespace}/", ""
  end  
end

require 'rspec/mocks'
require 'cucumber/rspec/doubles'

World(RSpec::Expectations, RSpec::Mocks, DSLWorld)
