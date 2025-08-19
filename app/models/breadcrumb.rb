# frozen_string_literal: true

class Breadcrumb
  attr_reader :name, :path, :icon

  def initialize(name, path: nil, icon: nil)
    @name = name
    @path = path
    @icon = icon
  end

  def link?
    @path.present?
  end
end
