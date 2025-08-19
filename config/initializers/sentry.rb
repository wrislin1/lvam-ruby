# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger, :sentry_logger]
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
  config.traces_sampler = lambda do |sampling_context|
    # if this is the continuation of a trace, just use that decision (rate controlled by the caller)
    unless sampling_context[:parent_sampled].nil?
      next sampling_context[:parent_sampled]
    end

    # the sampling context also has the full rack environment if you want to check the path directly
    rack_env = sampling_context[:env]
    return 0.0 if rack_env && rack_env['PATH_INFO'] =~ /health_check/

    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]
    transaction_name = transaction_context[:name] # request path

    case op
    when /http/
      case transaction_name
      when '/', /sign_in/, /health_check/, /up/, /sign_out/, /users\/password/
        0.0
      when /cable/
        0.05
      else
        0.25
      end
    when /queue/
      0.1 # Sidekiq
    when /websocket/
      0.05 # ActionCable
    else
      0.0
    end
  end
end
