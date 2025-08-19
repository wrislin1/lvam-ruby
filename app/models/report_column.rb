class ReportColumn < ApplicationRecord
  belongs_to :report
  positioned on: :report
  has_one_attached :am_file
  has_one_attached :pm_file
  enum :col_type, {
    no_build: "no_build",
    build: "build",
    build_mitigated: "build_mitigated"
  }, prefix: true
  validates :am_file, :pm_file, attached: true, content_type: { in: %w[text/plain], message: "must be .txt" }
  validates :title, presence: true, length: { maximum: 255 }
  validates :subtitle, length: { maximum: 255 }, allow_blank: true

  # Check if both Synchro files are attached
  def synchro_files_attached?
    am_file.attached? && pm_file.attached?
  end

  def am_content
    @am_content ||= am_file.download if am_file.attached?
  end

  def pm_content
    @pm_content ||= pm_file.download if pm_file.attached?
  end

  # Get the parsed synchro report
  def synchro_report
    return nil unless synchro_files_attached?

    begin
      SynchroParser::Report.new(am_content, pm_content)
    rescue => e
      Rails.logger.error("Error parsing synchro files for column #{id}: #{e.message}")
      nil
    end
  end

  # Get a count of intersections
  def intersection_count
    return 0 unless synchro_report

    synchro_report.am_intersections.size
  end
end
