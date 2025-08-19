class ExportReportJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |e|
    pp e
    error_message = e.respond_to?(:message) ? e.message : e
    @user_download.update(status: :failed, error_message:) if @user_download
    raise e
  end

  def perform(user_download_id, report_id, format: :pdf, debug: false, hidden_intersections: [])
    @user_download = UserDownload.find(user_download_id)
    @report = Report.find(report_id)
    @user_download.update(status: :processing, progress_message: "Processing download...")
    tmp_files = []
    begin
      browser_opts = {
        headless: true,
        process_timeout: 30,
        timeout: 200,
        pending_connection_errors: true
      }
      browser_opts[:logger] = $stdout if debug
      unless Rails.env.development?
        browser_opts[:browser_path] = "/usr/bin/chromium"
        browser_opts[:browser_options] = { 'no-sandbox': nil }
      end
      browser = Ferrum::Browser.new(browser_opts)
      tmp = Tempfile.new
      filename = "#{@report.title.parameterize}-#{Time.current.strftime('%Y-%m-%d-%H-%M')}.#{format}"
      content_type = Mime::Type.lookup_by_extension(format.to_s)&.to_s
      base_path = "#{Rails.application.credentials[:host]}/reports/#{@report.id}/render_download?api_key=#{Rails.application.credentials[:ferrum_api_key]}"

      if hidden_intersections.any?
        encoded_hidden = CGI.escape(hidden_intersections.to_json)
        path = "#{base_path}&hidden_intersections=#{encoded_hidden}"
      else
        path = base_path
      end

      browser.goto(path)
      output_path = tmp.path
      browser.network.wait_for_idle
      sleep 0.5
      browser.pdf(
        path: tmp.path,
        landscape: true,
        format: :A4,
        preferCSSPageSize: false,
        printBackground: false,
        pageRanges: "1-1",
        )
      if format == :png
        png_base_path = Rails.root.join("tmp", SecureRandom.uuid).to_s
        raise "Missing input file!" unless File.exist?(tmp.path)
        success = system("pdftoppm -singlefile -png -r 150 #{tmp.path} #{png_base_path}")
        raise "pdftoppm failed!" unless success
        output_path = Dir["#{png_base_path}*.png"].first
        raise "Output PNG not found" unless output_path && File.exist?(output_path)
        tmp_files << output_path
      elsif format == :jpg
        jpg_path = Rails.root.join("tmp", SecureRandom.uuid)
        system("pdftoppm -singlefile -jpeg -r 150 #{tmp.path} #{jpg_path}")
        output_path = jpg_path.to_s + ".jpg"
        tmp_files << output_path
      elsif format != :pdf
        raise ArgumentError, "Unsupported format: #{format}. Supported formats are :pdf, :png, :jpg."
      end
      @user_download.update progress_message: "Preparing file for download"
      @user_download.file.attach(
        io: File.open(output_path),
        filename:,
        content_type:,
        identify: false
      )
      @user_download.file.analyze
      @user_download.update(status: :complete, progress_message: "Download complete!")
    ensure
      if tmp
        tmp.close
        tmp.unlink
      end
      tmp_files.each do |file|
        File.delete(file) if File.exist?(file)
      end
      browser.quit if browser
    end
  end
end
