class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false, limit: 255, index: true
      t.string :subtitle1, default: "", limit: 255
      t.string :subtitle2, default: "", limit: 255
      t.timestamps
    end
  end
end