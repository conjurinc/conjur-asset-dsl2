module Conjur::DSL2::Executor
  class Update < Base
    def execute
      record.custom_attribute_names.each do |attr|
        value = record.send(attr)
        next unless value
        action({ 
          'action' => 'put',
          'path' => update_path,
          'parameters' => { attr.to_s => value || "" }
        })
      end
    end
  end
end
