class UsersController < ApplicationController
  before_action :set_subscription, only: %i[edit_subscription cancel_subscription]

  def subscription
    authorize current_user
    @subscriptions = StripeAdmin.get_user_subscriptions(current_user, status: "all", expand: %w[data.latest_invoice]).data
    @products = StripeAdmin.get_products.data
  end

  def edit_subscription
    config = StripeAdmin.create_payment_update_billing_portal_config
    session = StripeAdmin.create_billing_portal_session(current_user, config.id, subscription_url)
    redirect_to session.url, allow_other_host: true
  end

  def cancel_subscription
    return if request.get?

    cancellation_details = { feedback: params[:feedback], comment: params[:comment] }
    @subscription = StripeAdmin.cancel_subscription(params[:id], cancellation_details:)
    if @subscription.status == "canceled"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            stream_success_alert("Your subscription has been cancelled."),
            close_modal(id: "cancel-subscription"),
            turbo_stream.redirect_to(subscription_path)
          ]
        end
        format.html do
          redirect_to subscription_path, notice: "Your subscription has been cancelled."
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to subscription_path, alert: "A problem occurred! Please contact an administrator."
        end
        format.turbo_stream do
          render turbo_stream: [
            close_modal(id: "cancel-subscription"),
            stream_error_alert("A problem occurred! Please contact an administrator.")
          ], status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_subscription
    @subscription = StripeAdmin.get_subscription(params[:id])

    return redirect_to subscription_path, alert: "Subscription not found." unless @subscription.present?

    redirect_to subscription_path, alert: "You are not authorized to perform this action." unless @subscription.customer == current_user.stripe_id
  end
end
