# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  include ActionView::Helpers::TagHelper
  renders_one :icon
  renders_one :icon_right

  DEFAULT_CLASSES = %w[
    inline-flex
    items-center
    justify-center
    gap-x-2
    font-semibold
    rounded-xl
    disabled:opacity-60
    disabled:cursor-not-allowed
  ].freeze

  def initialize(text, tag: :button, type: :button, attrs: {}, icon: nil, classes: [], size: "md", loading_icon: false, loading: false, icon_position: "left")
    @type = type
    @tag = tag
    @text = text
    @attrs = attrs
    @icon = icon
    @size = size
    @classes = classes
    @loading_icon = loading_icon
    @loading = loading
    @attrs[:disabled] = true if @loading
    @icon_position = icon_position
    super
  end

  def icon_only?
    @icon.present? && @text.blank?
  end

  def size_class
    case @size
    when "xs"
      icon_only? ? "p-1.5" : "px-3 py-2 text-xs"
    when "sm"
      icon_only? ? "p-2" : "px-3 py-2 text-sm"
    when "md"
      icon_only? ? "p-3" : "px-6 py-2.5 text-sm"
    else
      icon_only? ? "p-4" : "px-6 py-3 text-base"
    end
  end

  def loading_class
    "#{'disabled:cursor-wait' if @loading} #{'loadingIcon' if @loading_icon}"
  end

  def all_classes
    DEFAULT_CLASSES + self.class::CLASSES + @classes + [ size_class ] + [ loading_class ]
  end

  def root_tag(&block)
    if @tag == :button_to
      button_to @attrs[:path], { method: @attrs[:method], class: all_classes, **@attrs.except(:path, :method) }, &block
    else
      content_tag @tag, { type: @type, class: all_classes, **@attrs } do
        block.call
      end
    end
  end
end
