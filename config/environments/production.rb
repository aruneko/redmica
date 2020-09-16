# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Disable delivery errors
  config.action_mailer.raise_delivery_errors = false

  # No email in production log
  config.action_mailer.logger = nil

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Logging by JSON
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_payload do |controller|
    current_user = controller.find_current_user
    user_name = current_user&.logged? ? "#{current_user.login}" : "anonymous"
    user_id = current_user&.logged? ? "#{current_user.id}" : "0"
    {
      remote_ip: controller.request.remote_ip,
      user_name: user_name,
      user_id: user_id
    }
  end
end
