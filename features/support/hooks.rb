Before do
  @namespace ||= [ 'cucumber', 'dsl2', $timestamp, (0..3).inject([]){|memo,entry| memo.push rand(255).to_s(16); memo}.join ].join('/')
  step %Q(I set the environment variable "NAMESPACE" to "#{@namespace}")
  step %Q(I set the environment variable "DEBUG" to "true") if ENV['DEBUG']
  step %Q(I set the environment variable "CONJURAPI_LOG" to "stderr") if ENV['DEBUG']
  step %Q(I set the environment variable "RESTCLIENT_LOG" to "stderr") if ENV['DEBUG']
end

Before "@debug-policy" do
  step %Q(I set the environment variable "GLI_DEBUG" to "true")
  step %Q(I set the environment variable "RESTCLIENT_LOG" to "stderr")
  step %Q(I set the environment variable "DEBUG" to "true")
end
