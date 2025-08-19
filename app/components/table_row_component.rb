# frozen_string_literal: true

class TableRowComponent < ViewComponent::Base
  def initialize(
    record,
    column_defs,
    collection_size: 0,
    idx: nil,
    template_path: "",
    stream_enter_class: "",
    stream_exit_class: "",
    resource_key: nil,
    selected_ids: [],
    active_columns: [],
    url: nil
  )
    @record = record
    @column_defs = column_defs
    @collection_size = collection_size
    @idx = idx
    @template_path = template_path
    @stream_enter_class = stream_enter_class
    @stream_exit_class = stream_exit_class
    @resource_key = resource_key
    @selected_ids = selected_ids
    @active_columns = active_columns
    @url = url
    super
  end

  def selected?
    (@selected_ids || []).map(&:to_i).include?(@record.id)
  end

  def select?(col)
    col.id == :select
  end

  def col_locals(col)
    ret = { value: col.value_for(@record), collection_size: @collection_size, idx: @idx, dropdown_top: dropdown_top?, template_path: @template_path }
    ret[@resource_key&.to_sym || @record.model_name.param_key.to_sym] = @record
    ret
  end

  def visible_columns
    @column_defs.select { |col| @active_columns.nil? || @active_columns.include?(col.id) }
  end

  def dropdown_top?
    (@idx >= @collection_size - 2) && @collection_size > 5 if @collection_size.positive? && !@idx.nil?
  end

  def last_row?
    @idx == @collection_size - 1
  end

  def col_template(col)
    return if col.template.blank?

    [ @template_path, col.template ].compact_blank.join("/")
  end

  def selectable?
    @column_defs.any? { |col| col.id == :select }
  end

  def visibility(col_idx)
    if selectable?
      "" if col_idx > 1 || col_idx.zero?
    else
      "" unless col_idx.zero?
    end
  end
end
