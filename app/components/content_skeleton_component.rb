# frozen_string_literal: true

class ContentSkeletonComponent < ViewComponent::Base
  def initialize(lines:)
    @lines = lines
    super
  end
end
