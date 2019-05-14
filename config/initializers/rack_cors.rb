Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do

    # Rack CORs seems to malfunction if we define specific resources with specific origins... so this is our only bet.
    # If you really want to restrict CORs you can respond with headers.
    origins '*'

    resource '/assets/*',
             headers: :any,
             methods: [:get]

    resource '*.js',
             headers: :any,
             methods: [:get]

    resource '*.css',
             headers: :any,
             methods: [:get]

    resource '/api/v1/*',
             headers: :any,
             methods: :any
  end
end
