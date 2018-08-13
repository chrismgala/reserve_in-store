Raven.configure do |config|
  config.dsn = 'https://d4efe5f067be4951a85b51efd193e8f6:5d7a7da2a91b43f0a1982f857c2138c6@sentry.io/1261651'
  config.environments = ['staging', 'production']
  config.async = lambda { |event|
    Thread.new { Raven.send_event(event) }
  }
  config.processors -= [Raven::Processor::PostData] # Do this to send POST data
  config.processors -= [Raven::Processor::Cookies] # Do this to send cookies by default
  config.silence_ready = true
end
