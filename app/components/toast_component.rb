# frozen_string_literal: true

class ToastComponent < ViewComponent::Base
  def initialize(type:, data:)
    @type = type
    @data = data
    super
  end

  def linked_notification?
    @data[:id].present?
  end

  def action_path
    @data[:action_path]
  end

  def action_label
    @data[:action_label]
  end

  def message
    @data[:message]
  end

  def normalized_type
    case @type.to_sym
    when :notice, :success
      :success
    when :alert, :error
      :error
    else
      @type.to_sym
    end
  end

  def icon_class
    case normalized_type
    when :success
      "far fa-check-circle"
    when :error
      "far fa-exclamation-triangle"
    when :info
      "far fa-info-circle"
    else
      "far fa-exclamation-circle"
    end
  end

  def icon_container_class
    case normalized_type
    when :success
      "text-green-500 bg-green-100"
    when :error
      "text-red-500 bg-red-100"
    when :info
      "text-blue-500 bg-blue-100"
    else
      "text-gray-500 bg-gray-100"
    end
  end
end
