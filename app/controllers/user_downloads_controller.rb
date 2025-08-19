class UserDownloadsController < ApplicationController
  include Filterable
  include ColumnCustomizable
  include RequiresSubscription

  def column_defs
    UserDownloadHelper.column_defs
  end

  def index
    params[:sort] = [ "created_at:desc" ] if params[:sort].blank?
    paginate_user_downloads
    filters_and_sort
  end

  private

  def paginate_user_downloads
    @pagy, @user_downloads = pagy(
      filter!(UserDownload, scope: current_user.user_downloads),
      limit: 10
    )
  end
end
