# frozen_string_literal: true

class BadgeComponent < ViewComponent::Base
  renders_one :icon_left
  renders_one :icon_right

  # @param variant [String] - info, default, success, warning, danger
  def initialize(label:, id: nil, variant: "info", classes: "", dismissible: false, large: false, path: nil, turbo: false, root_tag: :div)
    @label = label
    @id = id
    @variant = variant
    @classes = classes
    @dismissible = dismissible
    @large = large
    @path = path
    @turbo = turbo
    @root_tag = root_tag
    super
  end

  def root_tag(&block)
    tag = if @path
            :a
    else
            @root_tag
    end
    attrs = { id: @id }
    attrs[:href] = @path if @path
    attrs[:data] = { turbo_frame: "_top" }
    attrs[:data][:turbo_stream] = true if @turbo
    content_tag tag, { **attrs, class: "badge #{'lg' if @large} #{@variant} #{@classes}" } do
      block.call
    end
  end
end
