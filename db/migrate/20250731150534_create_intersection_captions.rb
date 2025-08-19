class CreateIntersectionCaptions < ActiveRecord::Migration[8.0]
  def change
    create_table :intersection_captions do |t|
      t.references :report, null: false, foreign_key: { on_delete: :cascade }
      t.string :intersection_id, null: false, limit: 50
      t.string :caption, null: false, limit: 50

      t.timestamps
    end

    add_index :intersection_captions, [:report_id, :intersection_id], unique: true, name: 'index_intersection_captions_on_report_and_intersection'
  end
end