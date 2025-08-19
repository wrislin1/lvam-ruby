# frozen_string_literal: true

module TableHelper
  def self.sort_str(sorts, sortable_cols)
    sorts.reject do |x|
      col = x.split(":").first
      col.exclude?("COUNT(") && col.exclude?("AVG(") && sortable_cols.exclude?(col)
    end.map do |x|
      col, dir = x.split ":"
      "#{col} #{dir == 'asc' ? 'ASC' : 'DESC'} NULLS LAST"
    end.join(", ")
  end

  def self.updated_created_cols(updated_sort_key: "updated_at", created_sort_key: "created_at")
    [
      Column.new(
        :updated_at,
        label: "Updated",
        icon: "fa-clock",
        sort_key: updated_sort_key,
        func: ->(x) { x.updated_at.to_fs(:us_datetime) },
        classes: "text-xs text-gray-600"
      ),
      Column.new(
        :created_at,
        label: "Created",
        icon: "fa-calendar",
        sort_key: created_sort_key,
        func: ->(x) { x.created_at.to_fs(:us_date) },
        classes: "text-xs text-gray-600"
      ),
    ]
  end
end
