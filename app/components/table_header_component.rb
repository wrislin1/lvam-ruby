# frozen_string_literal: true

class TableHeaderComponent < ViewComponent::Base
  include ActionView::Helpers::TagHelper

  def initialize(column, column_defs: [], sort: [], idx: nil)
    @column = column
    @column_defs = column_defs
    @sort = sort
    @idx = idx
    super
  end

  def selectable?
    @column_defs.any? { |col| col.id == :select }
  end

  def select?
    @column.id == :select
  end

  def sortable?
    @column.sortable
  end

  def col_class
    return "" if @idx.blank?

    if selectable?
      @idx.zero? || @idx > 1 ? "" : ""
    else
      @idx.zero? ? "" : ""
    end
  end

  def sorting
    @sort&.any? { |s| s.start_with?(@column.sort_key) }
  end

  def ascending?
    @sort.find { |s| s.start_with?(@column.sort_key) }&.end_with?("asc")
  end

  def container_tag(&block)
    if sortable?
      content_tag :a, { class: "group flex items-center", href: link_path } do
        block.call
      end
    else
      content_tag :div, { class: "flex items-center" } do
        block.call
      end
    end
  end

  def link_path
    _params = params.to_unsafe_h.except("action", "controller", "sort", "format", "length", "page", "clear")
    if sorting
      new_sort = [ "#{@column.sort_key}:#{ascending? ? 'desc' : 'asc'}" ]
      url_for(only_path: true, sort: new_sort, **_params)
    else
      url_for(only_path: true, sort: [ "#{@column.sort_key}:asc" ], **_params)
    end
  end

  def indicator_class
    if sorting
      "bg-primary-500/10 text-primary-600 group-hover:bg-primary-500/20 #{ascending? ? 'rotate-180' : ''}"
    else
      "invisible text-primary-600/50 group-hover:visible group-focus:visible"
    end
  end
end
