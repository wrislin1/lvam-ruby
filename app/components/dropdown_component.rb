# frozen_string_literal: true

class DropdownComponent < ViewComponent::Base
  renders_one :trigger

  def initialize(items = [], id:, init: true, disabled: false, menu_class: "w-52", placement: "bottom")
    @items = items
    @id = id
    @init = init
    @disabled = disabled
    @menu_class = menu_class
    @placement = placement
    super
  end

  def action_groups?
    @items.any? { |item| item[:actions].present? }
  end
end
