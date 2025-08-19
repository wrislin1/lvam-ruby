# frozen_string_literal: true

class DropdownItemComponent < ViewComponent::Base
  CLASSES = %w[
    block
    px-4
    py-2
    text-gray-600
    hover:text-gray-800
    hover:bg-gray-100
  ].freeze

  def initialize(data:)
    @data = data
    super
  end

  def turbo_frame
    @data[:turbo_frame]
  end

  def turbo_action
    @data[:turbo_action]
  end

  def turbo_method
    @data[:turbo_method]
  end

  def form_data
    ret = {}
    ret[:turbo_confirm] = @data[:confirm] if @data[:confirm].present?
    ret[:turbo_frame] = turbo_frame if turbo_frame.present?
    ret[:action] = @data[:form_action] if @data[:form_action].present?
    ret
  end

  def params
    @data[:params]
  end

  def name
    @data[:name]
  end

  def icon
    @data[:icon]
  end

  def path
    @data[:path]
  end

  def method
    @data[:method]
  end

  def target
    @data[:target]
  end

  def attrs
    ret = {}
    ret[:data] = { turbo_stream: true } if @data[:turbo]
    ret[:data] = { turbo_stream: false } if @data[:turbo] == false
    ret[:data] ||= {}
    ret[:data][:turbo_frame] = @data[:turbo_frame] if @data[:turbo_frame].present?
    ret[:data][:action] = turbo_action if turbo_action.present?
    ret[:data][:turbo_method] = turbo_method if turbo_method.present?
    ret[:target] = target if target.present?
    ret
  end
end
