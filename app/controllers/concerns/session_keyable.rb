# frozen_string_literal: true

module SessionKeyable
  extend ActiveSupport::Concern

  included do
    attr_accessor :custom_key
  end

  def session_key(resource, suffix:)
    @custom_key || resource_key(resource, suffix:)
  end

  protected

  def resource_key(resource, suffix:)
    "#{'admin_' if admin_route?}#{resource.to_s.underscore}_#{suffix}"
  end

  private

  def admin_route?
    controller_path.include? "admin/"
  end
end
