class CreateReportColumns < ActiveRecord::Migration[8.0]
  def change
    create_table :report_columns do |t|
      t.references :report, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false, limit: 255
      t.integer :sort, default: 0
      t.string :subtitle, default: "", limit: 255
      t.timestamps
    end
  end
end