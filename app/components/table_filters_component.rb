# frozen_string_literal: true

class TableFiltersComponent < ViewComponent::Base
  renders_one :actions

  def initialize(turbo_frame: nil, placeholder: "Search...", turbo_action: "advance", filters: {}, reset: false)
    @turbo_frame = turbo_frame
    @turbo_action = turbo_action
    @filters = filters
    @reset = reset
    @placeholder = placeholder
    super
  end
end
