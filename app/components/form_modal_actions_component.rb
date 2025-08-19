# frozen_string_literal: true

class FormModalActionsComponent < ViewComponent::Base
  def initialize(submit_text: "Save", submit_icon: "fa-floppy-disk fa-lg", submit_target: "modal.submit", submit_disabled: false, submit_action: "modal#submit", cancel_action: nil)
    @submit_text = submit_text
    @submit_icon = submit_icon
    @submit_target = submit_target
    @submit_disabled = submit_disabled
    @submit_action = submit_action
    @cancel_action = cancel_action
    super
  end
end
