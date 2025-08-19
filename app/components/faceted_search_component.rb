# frozen_string_literal: true

class FacetedSearchComponent < ViewComponent::Base
  BTN_CLASSES = %w[
    focus:outline-none
    focus:border-gray-300
    border-dashed
    border
    border-gray-300
    hover:bg-gray-100
    rounded-lg
    px-3
    text-center
    inline-flex
    items-center
    dark:bg-blue-600
    dark:hover:bg-blue-700
    dark:focus:ring-blue-800
    py-2
    focus:ring-2
    active:ring-2
    ring-gray-300
    ring-offset-2
    ring-opacity-50
  ]

  # @param options [Array<Hash>] An array of option hashes, each with the following keys:
  #   - `:value` [String] The value of the option
  #   - `:label` [String] The display label for the option
  #   - `:count` [Integer] The count associated with the option (optional)
  #   - `:selected` [Boolean] Whether the option is selected
  def initialize(id, name, options = [], btn_label, menu_class: "w-48", search: true, single: false)
    @id = id
    @name = name
    @options = options
    @btn_label = btn_label
    @menu_class = menu_class
    @search = search
    @single = single
    super
  end

  def toggle_id
    "#{@id}-toggle"
  end

  def selected_options
    @options.select { |option| option[:selected] }
  end
end
