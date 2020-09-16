Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins *ENV.fetch('CORS_ALLOWED_ORIGINS', '*').split(',').map { |origin| origin.strip }

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end

