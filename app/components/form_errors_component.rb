# frozen_string_literal: true

class FormErrorsComponent < ViewComponent::Base
  def initialize(model:, skip: [])
    @model = model
    @skip = skip
    super
  end

  def un_skipped_errors
    @model.errors.map(&:attribute) - @skip
  end
end
