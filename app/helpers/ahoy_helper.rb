# frozen_string_literal: true

module AhoyHelper
  def sanitized_params
    p = begin
      param_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      param_filter.filter(params.to_unsafe_h)
    rescue StandardError => e
      Rails.logger.error e
      {}
    end
    p[:fullpath] = request.fullpath
    p
  end
end
