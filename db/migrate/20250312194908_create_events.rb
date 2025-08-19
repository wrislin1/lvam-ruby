class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_enum :event_status, %w[pending processing processed failed]
    create_table :events do |t|
      t.json :data, null: false
      t.string :source, null: false
      t.text :processing_errors
      t.enum(:status, enum_type: 'event_status', default: 'pending', null: false)
      t.timestamps
    end
  end
end
