# frozen_string_literal: true

class PrimaryButtonComponent < ButtonComponent
  CLASSES = %w[
    text-primary-600
    bg-transparent
    border-2
    border-primary-600
    hover:bg-primary-600
    hover:text-white
    hover:shadow
    focus:ring-2
    focus:ring-offset-2
    focus:ring-primary-100
    disabled:hover:bg-transparent
    disabled:hover:text-primary-600
    disabled:focus:ring-0
    disabled:opacity-50
    hover:shadow-md
    transition-all
    uppercase
  ].freeze
end
