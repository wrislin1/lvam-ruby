# frozen_string_literal: true

class StickyBannerComponent < ViewComponent::Base
  def initialize(id, dismissable: true)
    @id = id
    @dismissable = dismissable
    super
  end
end
