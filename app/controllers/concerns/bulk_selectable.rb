# frozen_string_literal: true

module BulkSelectable
  attr_accessor :resource

  include SessionKeyable
  extend ActiveSupport::Concern

  included do
    attr_accessor :selected_records, :selected_ids
  end

  def select!(resource, load: true)
    @resource = resource
    store_selected!
    load_selected! if load
  end

  def load_selected!(resource: nil)
    @resource = resource if resource
    @selected_ids = session_ids
    @selected_records = @selected_ids.any? ? @resource.where(id: @selected_ids) : []
  end

  def session_ids
    return [] unless session.key?(selected_key)

    session[selected_key] || []
  end

  def clear_selected!(resource: nil)
    @resource = resource if resource
    session.delete(selected_key)
  end

  private

  def selected_key
    session_key(@resource, suffix: "selected")
  end

  def store_selected!
    param_ids = params[:ids]
    session[selected_key] = param_ids.present? ? (session_ids + param_ids).uniq : []
  end
end
