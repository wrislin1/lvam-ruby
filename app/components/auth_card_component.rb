# frozen_string_literal: true

class AuthCardComponent < ViewComponent::Base
  def initialize(header: nil)
    @header = header
    super
  end
end
