class AlterReportsAddPosition < ActiveRecord::Migration[8.0]
  def change
    remove_column :report_columns, :sort, :integer, default: 0
    add_column :report_columns, :position, :integer, null: false

    add_index :report_columns, [ :report_id, :position ], unique: true
  end
end
