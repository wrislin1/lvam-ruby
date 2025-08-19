class AlterUsersAddStatus < ActiveRecord::Migration[8.0]
  def change
    create_enum :user_status, %w[active archived blocked]

    add_column :users, :status, :enum, null: false, enum_type: :user_status, default: :active
  end
end
