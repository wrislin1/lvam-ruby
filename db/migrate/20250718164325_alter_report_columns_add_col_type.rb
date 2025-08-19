class AlterReportColumnsAddColType < ActiveRecord::Migration[8.0]
  def change
    add_column :report_columns, :col_type, :string
  end
end
