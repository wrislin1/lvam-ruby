class Report < ApplicationRecord
  include PgSearch::Model
  attr_accessor :wizard

  belongs_to :user
  has_many :report_columns, -> { order :position }, dependent: :destroy
  has_many :intersection_captions, dependent: :destroy
  has_one_attached :image
  has_many :user_downloads, as: :downloadable, dependent: :restrict_with_exception
  validates :title, presence: true, length: { maximum: 255 }
  validates :subtitle1, length: { maximum: 255 }, allow_blank: true
  validates :subtitle2, length: { maximum: 255 }, allow_blank: true
  validates :image, content_type: { in: %w[image/png image/jpeg image/webp], message: "must be PNG, JPG, or WEBP" }
  validate :uniq_col_types

  accepts_nested_attributes_for :report_columns, allow_destroy: true
  pg_search_scope :by_term,
                  against: %i[title subtitle1 subtitle2],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.1 }
                  }
  FILTER_PARAMS = %w[].freeze
  SORTABLE_COLS = %w[id title subtitle1 subtitle2 created_at updated_at].freeze

  def self.filter(params, scope: nil)
    q, sort = params.values_at "q", "sort"
    query = scope || Report
    query = query.merge(Report.by_term(q)) if q.present?
    query = query.order Arel.sql(TableHelper.sort_str(sort, SORTABLE_COLS)) if sort.present?
    query
  end

  private

  def uniq_col_types
    counts = report_columns.select { |x| x.col_type.present? }.group_by(&:col_type).transform_values(&:count)
    counts.each do |col_type, count|
      if count > 1
        report_columns.select { |x| x.col_type == col_type }.each { |x| x.errors.add(:col_type, "must be unique") }
        errors.add(:base, "Can only have 1 #{col_type.titleize} column")
      end
    end
  end
end
