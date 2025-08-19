# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  renders_one :actions

  def initialize(header:, id:, controller: nil, size: "lg", static: false, action: "", closable: true, content_action: "keydown->modal#keydown", open: true)
    @header = header
    @id = id
    @controller = controller
    @size = size
    @static = static
    @action = action
    @content_action = content_action
    @open = open
    @closable = closable
    super
  end

  def size_class
    case @size
    when "sm"
      "max-w-md"
    when "md"
      "max-w-lg"
    else
      "max-w-4xl"
    end
  end
end
