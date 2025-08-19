class Event < ApplicationRecord
  validates :source, :data, presence: true
  enum :status, {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, default: "pending", prefix: true
end
