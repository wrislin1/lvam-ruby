class IntersectionCaption < ApplicationRecord
  belongs_to :report

  validates :intersection_id, presence: true, length: { maximum: 50 }
  validates :caption, presence: true, length: { maximum: 50 }, allow_blank: true
  validates :intersection_id, uniqueness: { scope: :report_id }

  scope :for_report, ->(report_id) { where(report_id: report_id) }

  def self.as_hash_for_report(report_id)
    for_report(report_id).pluck(:intersection_id, :caption).to_h
  end

  def self.find_or_initialize_for(report_id, intersection_id)
    find_or_initialize_by(report_id: report_id, intersection_id: intersection_id)
  end
end