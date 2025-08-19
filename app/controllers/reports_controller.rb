class ReportsController < ApplicationController
  include Filterable
  include ColumnCustomizable
  include RequiresSubscription
  include DestroyConfirmable
  before_action :set_report, only: [ :destroy, :download, :show, :edit, :update, :download_excel, :edit_intersection_caption,
                                    :intersection_captions, :create_intersection_caption, :destroy_intersection_caption]
  before_action :set_index_crumb
  skip_before_action :redirect_unless_subscribed, :authenticate_user!, only: :render_download
  before_action :validate_ferrum_key, only: :render_download

  def column_defs
    [
      Column.new(:id, label: "ID", icon: "fa-hashtag", toggleable: false),
      Column.new(:title, icon: "fa-file-signature"),
      Column.new(:subtitle1, icon: "fa-pencil"),
      Column.new(:subtitle2, icon: "fa-pencil"),
      *TableHelper.updated_created_cols,
      Column.new(:actions, label: "", template: "actions", toggleable: false, sortable: false),
    ].freeze
  end

  def index
    params[:sort] = [ "created_at:desc" ] if params[:sort].blank?
    paginate_reports
    filters_and_sort
  end

  def new
    @report = Report.new
    add_breadcrumb "New Report"
  end

  def create
    @report = current_user.reports.new(report_params)
    if @report.save
      redirect_to edit_report_path(@report, wizard: "true"), notice: "Report created successfully."
    else
      Rails.logger.error("ERROR: Report failed to save - #{@report.errors.full_messages.inspect}")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    add_breadcrumb @report.title
  end

  def download
    format = case params[:type]
             when "png"
               :png
             when "jpg"
               :jpg
             else
               :pdf
             end

    hidden_intersections = []
    if params[:hidden_intersections].present?
      begin
        hidden_intersections = JSON.parse(params[:hidden_intersections])
      rescue JSON::ParserError => e
        Rails.logger.warn("Failed to parse hidden_intersections: #{e.message}")
      end
    end

    @user_download = current_user.user_downloads.create(
      downloadable: @report,
      description: "#{@report.title} #{format.to_s.upcase}"
    )

    ExportReportJob.perform_later(
      @user_download.id,
      @report.id,
      format: format,
      hidden_intersections: hidden_intersections
    )

    redirect_to user_downloads_path,
                notice: "Your download is being processed!"
  end

  def render_download
    @report = Report.find params[:id]

    @hidden_intersections = []
    if params[:hidden_intersections].present?
      begin
        @hidden_intersections = JSON.parse(params[:hidden_intersections])
      rescue JSON::ParserError => e
        Rails.logger.warn("Failed to parse hidden_intersections in render_download: #{e.message}")
        @hidden_intersections = []
      end
    end

    render :download, layout: "download"
  end

  def edit
    @wizard = params[:wizard] == "true"
    @report_column = @report.report_columns.new unless @report.report_columns.any?
    add_breadcrumb "Edit #{@report.title}"
  end

  def update
    if @report.update(report_params)
      redirect_to report_path(@report), notice: "Report updated successfully."
    else
      @wizard = @report.wizard&.to_s == "true" || params[:wizard] == "true" || false
      respond_to do |format|
        format.html do
          render :edit, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              helpers.dom_id(@report, :form),
              partial: "reports/edit"
            )
          ], status: :unprocessable_entity
        end
      end
    end
  end

  def download_excel
    @user_download = current_user.user_downloads.create(
      downloadable: @report,
      description: "#{@report.title} Excel File"
    )
    ExportReportExcelJob.perform_later(@user_download.id, @report.id)
    redirect_to user_downloads_path,
                notice: "Your Excel file is being processed!"
  end

  def destroy
    confirm_or_destroy(
      @report,
      report_path(@report),
      method: :delete,
      message: "Are you sure you want to delete <strong>#{@report.title}</strong>? This action cannot be undone.",
    )
  end

  def intersection_captions
    captions = @report.intersection_captions.as_hash_for_report(@report.id)
    render json: captions
  end


  def create_intersection_caption
    @intersection_id = params[:intersection_id]
    @caption = @report.intersection_captions.find_or_initialize_for(@report.id, @intersection_id)

    @caption.caption = params[:caption].to_s.strip[0, 50]

    if @caption.save
      @captions = @report.intersection_captions.as_hash_for_report(@report.id)
      respond_to do |format|
        format.turbo_stream
        format.json {
          render json: {
            success: true,
            intersection_id: @caption.intersection_id,
            caption: @caption.caption
          }
        }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "caption-form-errors",
            partial: "reports/caption_form_errors",
            locals: { errors: @caption.errors.full_messages }
          )
        end
        format.json do
          render json: {
            success: false,
            errors: @caption.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def edit_intersection_caption
    @intersection_id = params[:intersection_id]
    @caption = @report.intersection_captions.find_by(intersection_id: @intersection_id)
    @current_caption = @caption&.caption || params[:current_caption] || ''

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy_intersection_caption
    @caption = @report.intersection_captions.find_by(intersection_id: params[:intersection_id])

    if @caption&.destroy
      render json: { success: true }
    else
      render json: { success: false }, status: :not_found
    end
  end

  private

  def validate_ferrum_key
    unless params[:api_key].present? && params[:api_key] == Rails.application.credentials.ferrum_api_key
      redirect_to reports_path, alert: "Invalid API key."
    end
  end

  def set_index_crumb
    add_breadcrumb "Reports", path: reports_path
  end

  def paginate_reports
    @pagy, @reports = pagy(filter!(Report, scope: current_user.reports))
  end

  def set_report
    @report = current_user.reports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("ERROR: Report not found for ID: #{params[:id]}")
    redirect_to reports_path, alert: "Report not found."
  end

  def report_params
    params.require(:report).permit(
      :title,
      :subtitle1,
      :subtitle2,
      :image,
      :wizard,
      report_columns_attributes: [
        :id,
        :title,
        :subtitle,
        :_destroy,
        :am_file,
        :pm_file,
        :position,
        :col_type,
        position: []
      ]
    )
  end

  def intersection_caption_params
    params.permit(:intersection_id, :caption)
  end
end