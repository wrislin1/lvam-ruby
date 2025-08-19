# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(pagy:, frame: nil, length: true)
    @pagy = pagy
    @frame = frame
    @length = length
    super
  end

  attr_reader :pagy
end
