Before do
  @namespace ||= [ 'cucumber', 'dsl2', $timestamp, (0..3).inject([]){|memo,entry| memo.push rand(255).to_s(16); memo}.join ].join('/')
  step %Q(I set the environment variable "NAMESPACE" to "#{@namespace}")
end
