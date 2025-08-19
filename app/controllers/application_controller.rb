class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :authenticate_user!, except: [ :index, :contact ]
  before_action :set_paper_trail_whodunnit
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :track_action, unless: :devise_controller?

  def contact; end

  def index
    return redirect_to reports_path if user_signed_in?

    flash.now[:notice] = "Thank you for subscribing!" if params[:checkout_session] == "complete"
    flash.now[:alert] = "Checkout canceled!" if params[:checkout_session] == "canceled"
  end

  def breadcrumbs
    @breadcrumbs ||= []
  end
  helper_method :breadcrumbs

  def add_breadcrumb(name, path: nil, icon: nil)
    breadcrumbs << Breadcrumb.new(name, path:, icon:)
  end

  def stream_alert(type: "info", data: {})
    turbo_stream.update(
      :alerts,
      partial: "partials/alert",
      locals: { type:, data: }
    )
  end

  def stream_success_alert(message, title: "Success!", duration: 6000)
    data = { title:, message:, duration: }
    stream_alert type: "success", data:
  end

  def stream_error_alert(message, title: "Error!", duration: 6000)
    data = { title:, message:, duration: }
    stream_alert type: "error", data:
  end

  def close_modal(id: nil)
    turbo_stream.close_modals id:
  end

  def close_confirmation_modal
    close_modal id: "confirmation-modal"
  end

  def render_confirmation_modal(action, message: nil, header: "Are you sure?", method: :delete, turbo: true, params: {})
    turbo_stream.update(
      :modal,
      partial: "partials/confirmation_modal",
      locals: { action:, header:, message:, method:, turbo:, params: }
    )
  end

  protected

  def configure_permitted_parameters
    attributes = %i[
      first_name
      last_name
    ]
    devise_parameter_sanitizer.permit(:sign_up, keys: attributes)
    devise_parameter_sanitizer.permit(:account_update, keys: attributes)
    devise_parameter_sanitizer.permit(:accept_invitation, keys: attributes)
  end

  private

  def track_action
    return if %w[/].include? request.fullpath

    ahoy.track "#{controller_name}:#{action_name}", {
      **request.path_parameters,
      **helpers.sanitized_params
    }
  end
end
