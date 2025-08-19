class UserSubscription < ApplicationRecord
  belongs_to :user
  validates :status, :stripe_id, presence: true
  validates :stripe_id, uniqueness: { scope: :user_id }
  enum :status, {
    incomplete: "incomplete",
    incomplete_expired: "incomplete_expired",
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid",
    paused: "paused",
  }
end
