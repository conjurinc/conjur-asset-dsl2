module Conjur::Policy::Logger
  def self.included base
    base.module_eval do
      # Override the logger with this method.
      cattr_accessor :logger
      
      require 'logger'
      self.logger = Logger.new(STDERR)
      self.logger.level = Logger::INFO
    end
  end
end
