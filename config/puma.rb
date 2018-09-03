workers ENV.fetch('PUMA_WORKERS', 1).to_i
threads ENV.fetch('PUMA_MIN_THREADS', 0).to_i, ENV.fetch('PUMA_MAX_THREADS', 5).to_i

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
