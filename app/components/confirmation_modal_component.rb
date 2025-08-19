# frozen_string_literal: true

class ConfirmationModalComponent < ViewComponent::Base
  def initialize(action, message: nil, header: "Are you sure?", method: :delete, turbo: true, params: {})
    @action = action
    @message = message
    @header = header.presence || "Are you sure?"
    @method = method
    @turbo = turbo
    @params = params
    super
  end

  def id
    "confirmation-modal"
  end
end
