class UserDownload < ApplicationRecord
  include PgSearch::Model
  has_one_attached :file
  belongs_to :user
  belongs_to :downloadable, polymorphic: true, optional: true
  validates :status, presence: true
  pg_search_scope :by_term,
                  against: %i[description],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.1 }
                  }
  after_update_commit do
    broadcast_replace_to :"user_#{self.user_id}_downloads",
                         target: self,
                         partial: "user_downloads/user_download",
                         locals: {
                           user_download: self,
                           stream_enter_class: "animate-flash-green",
                           active_columns: nil,
                           i: 0,
                           collection: [],
                           collection_size: 0,
                           template_path: "user_downloads/column_templates",
                           column_defs: UserDownloadHelper.column_defs
                         }
  end
  enum :status, {
    pending: "pending",
    processing: "processing",
    complete: "complete",
    failed: "failed"
  }
  FILTER_PARAMS = %w[].freeze
  SORTABLE_COLS = %w[id created_at updated_at].freeze

  def self.filter(params, scope: nil)
    q, sort = params.values_at "q", "sort"
    query = scope || UserDownload
    query = query.joins(
      "LEFT JOIN reports ON reports.id = user_downloads.downloadable_id AND user_downloads.downloadable_type = 'Report'"
    ).select(
      [
        "user_downloads.*",
        "reports.title AS report_title"
      ].join(", ")
    )
    query = query.merge(UserDownload.by_term(q)) if q.present?
    query = query.order Arel.sql(TableHelper.sort_str(sort, SORTABLE_COLS)) if sort.present?
    query
  end
end
