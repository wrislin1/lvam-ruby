module RequiresSubscription
  extend ActiveSupport::Concern

  included do
    before_action :redirect_unless_subscribed
  end

  private

  def redirect_unless_subscribed
    redirect_to root_path, alert: "You must be subscribed to access this feature." unless current_user&.subscribed?
  end
end
