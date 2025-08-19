module Auth
  class RegistrationsController < Devise::RegistrationsController
    prepend_before_action :require_not_subscribed, only: :destroy

    private

    def require_not_subscribed
      alert = "Please cancel your active subscription before deleting your account."
      redirect_to subscription_path, alert: alert if current_user&.subscribed?
    end
  end
end
