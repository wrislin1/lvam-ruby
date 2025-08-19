# frozen_string_literal: true

module TurboStreamActionsHelper
  # Close a modal, or all modals if id is omitted
  def close_modals(id: nil)
    turbo_stream_action_tag :close_modals, id:
  end

  def change_value(target:, value:)
    turbo_stream_action_tag :change_value, target:, value:
  end

  def redirect_to(path)
    turbo_stream_action_tag :redirect_to, path:
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
