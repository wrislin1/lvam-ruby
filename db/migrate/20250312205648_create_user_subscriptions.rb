class CreateUserSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_subscriptions do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.string :stripe_id, null: false
      t.string :payment_method_id
      t.string :product_id
      t.string :price_id
      t.integer :amount
      t.timestamp :current_period_start
      t.timestamp :current_period_end
      t.timestamps
    end
    add_index :user_subscriptions, :status
    add_index :user_subscriptions, %i[user_id stripe_id], unique: true
  end
end
