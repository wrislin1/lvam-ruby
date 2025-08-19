class ExportReportExcelJob < ApplicationJob
  require "axlsx"

  queue_as :default

  rescue_from(StandardError) do |e|
    error_message = e.respond_to?(:message) ? e.message : e
    @user_download.update(status: :failed, error_message:) if @user_download
    raise e
  end

  def perform(user_download_id, report_id)
    @user_download = UserDownload.find(user_download_id)
    @report = Report.find(report_id)
    @user_download.update(status: :processing, progress_message: "Processing download...")
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: "Intersections") do |sheet|
      header_style = workbook.styles.add_style(
        bg_color: "2980a0",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center }
      )

      los_a_style = workbook.styles.add_style(fg_color: "4CAF50")
      los_b_style = workbook.styles.add_style(fg_color: "8BC34A")
      los_c_style = workbook.styles.add_style(fg_color: "CDDC39")
      los_d_style = workbook.styles.add_style(fg_color: "FFC107")
      los_e_style = workbook.styles.add_style(fg_color: "FF9800")
      los_f_style = workbook.styles.add_style(fg_color: "F44336")

      sheet.add_row [ @report.title ], style: header_style
      sheet.add_row [ @report.subtitle1 ] if @report.subtitle1.present?
      sheet.add_row [ @report.subtitle2 ] if @report.subtitle2.present?
      sheet.add_row [] # Empty row

      sheet.add_row [
                      "Intersection Name",
                      "AM LOS",
                      "PM LOS",
                      "AM Delay",
                      "PM Delay"
                    ], style: header_style

      @report.report_columns.each do |column|
        next unless column.synchro_files_attached? && column.synchro_report

        row_index = sheet.rows.count
        sheet.add_row [ column.title ], style: header_style
        sheet.merge_cells "A#{row_index+1}:E#{row_index+1}"

        column.synchro_report.am_intersections.each do |name, intersection|
          pm_intersection = column.synchro_report.pm_intersections[name]

          am_los = intersection&.los || "N/A"
          pm_los = pm_intersection&.los || "N/A"

          am_style = case am_los
                     when "A" then los_a_style
                     when "B" then los_b_style
                     when "C" then los_c_style
                     when "D" then los_d_style
                     when "E" then los_e_style
                     when "F" then los_f_style
                     else nil
                     end

          pm_style = case pm_los
                     when "A" then los_a_style
                     when "B" then los_b_style
                     when "C" then los_c_style
                     when "D" then los_d_style
                     when "E" then los_e_style
                     when "F" then los_f_style
                     else nil
                     end

          row_data = [
            name,
            am_los,
            pm_los,
            intersection&.control_delay || "N/A",
            pm_intersection&.control_delay || "N/A"
          ]

          styles = [ nil, am_style, pm_style, nil, nil ]
          sheet.add_row row_data, style: styles
        end

        sheet.add_row []
      end

      sheet.column_widths 40, 10, 10, 10, 10
    end
    @user_download.update progress_message: "Preparing file for download"
    @user_download.file.attach(
      io: StringIO.new(package.to_stream.read),
      filename: "#{@report.title.parameterize}_intersection_report.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      identify: false
    )
    @user_download.file.analyze
    @user_download.update(status: :complete, progress_message: "Download complete!")
  end
end
