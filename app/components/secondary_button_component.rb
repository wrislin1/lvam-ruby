# frozen_string_literal: true

class SecondaryButtonComponent < ButtonComponent
  CLASSES = %w[
    text-primary-700
    bg-primary-200
    hover:bg-primary-300
    focus:ring-2
    focus:ring-offset-2
    focus:ring-primary-700
    disabled:hover:bg-primary-300
    disabled:focus:ring-0
    disabled:opacity-50
    hover:shadow-md
    transition-all
    uppercase
  ].freeze
end
