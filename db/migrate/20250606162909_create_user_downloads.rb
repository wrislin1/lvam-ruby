class CreateUserDownloads < ActiveRecord::Migration[8.0]
  def change
    create_enum :user_download_status, %w[pending processing complete failed]

    create_table :user_downloads do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :downloadable, polymorphic: true
      t.enum :status, default: 'pending', null: false, enum_type: :user_download_status
      t.string :description
      t.string :error_message
      t.string :progress_message
      t.timestamps
    end
  end
end
