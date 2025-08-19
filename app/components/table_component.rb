# frozen_string_literal: true

class TableComponent < ViewComponent::Base
  def initialize(collection = [], column_defs = [], active_columns: [], sort: [], select_path: nil, partial: "", as_symbol: nil, table_class: "")
    @collection = collection
    @column_defs = column_defs
    @active_columns = active_columns
    @sort = sort
    @select_path = select_path
    @partial = partial
    @as_symbol = as_symbol
    @table_class = table_class
    super
  end

  def visible_columns
    @column_defs.select { |col| @active_columns.nil? || @active_columns.include?(col.id) }
  end
end
