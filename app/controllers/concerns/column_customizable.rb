# frozen_string_literal: true

module ColumnCustomizable
  extend ActiveSupport::Concern

  included do
    helper_method :active_columns
    helper_method :column_defs
  end

  def column_defs
    raise NotImplementedError
  end

  def active_columns
    return @active_columns if @active_columns.present?

    session_var = "#{controller_name}_#{action_name}_active_columns"
    col_params = params[:columns]&.map(&:to_sym)
    session[session_var] = col_params if col_params.present?

    @active_columns ||= session[session_var]&.map(&:to_sym)
  end
end
