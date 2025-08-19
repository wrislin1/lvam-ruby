class HandleEventJob < ApplicationJob
  queue_as :default
  rescue_from(StandardError) do |e|
    event = arguments.first
    event.processing_errors = e.message
    event.status_failed!
    raise e
  end

  def perform(event)
    event.status_processing!
    case event.source
    when "stripe"
      handle_stripe_event(event)
    end
    event.status_processed!
  end

  def handle_stripe_event(event)
    stripe_event = Stripe::Event.construct_from(event.data)
    case stripe_event.type
    when "checkout.session.completed"
      checkout_session_completed(stripe_event)
    when "customer.subscription.deleted"
      subscription_deleted(stripe_event)
    when "customer.subscription.paused"
      subscription_paused(stripe_event)
    when "customer.subscription.resumed"
      subscription_resumed(stripe_event)
    when "customer.subscription.updated"
      subscription_updated(stripe_event)
    when "checkout.session.async_payment_failed"
      nil
    when "checkout.session.async_payment_succeeded"
      nil
    when "radar.early_fraud_warning.created"
      early_fraud_warning(stripe_event)
    end
  end

  private

  def subscription_deleted(stripe_event)
    obj = stripe_event.data.object
    user_subscription = UserSubscription.find_by(stripe_id: obj.id)
    raise "UserSubscription not found for stripe_id: #{obj.id}" if user_subscription.blank?

    user_subscription.canceled!
  end

  def early_fraud_warning(stripe_event)
    obj = stripe_event.data.object
    charge = Stripe::Charge.retrieve(obj.charge)
    return if charge.blank?

    Stripe::Refund.create({ charge: obj.charge, reason: "fraudulent" })
    return unless (user = User.find_by(stripe_id: charge.customer))

    user.blocked!
    active_subscriptions = user.user_subscriptions.active
    active_subscriptions.each do |sub|
      Stripe::Subscription.cancel(sub.stripe_id)
    end
  end

  def subscription_updated(stripe_event)
    obj = stripe_event.data.object
    user_subscription = UserSubscription.find_by(stripe_id: obj.id)
    raise "UserSubscription not found for stripe_id: #{obj.id}" if user_subscription.blank?

    plan = obj.plan
    amount = plan&.amount
    product = plan&.product
    price_id = plan&.id
    user_subscription.update!(
      status: obj.status,
      current_period_start: obj.current_period_start,
      current_period_end: obj.current_period_end,
      payment_method_id: obj.default_payment_method,
      amount:,
      product_id: product,
      price_id:
    )
  end

  def subscription_paused(stripe_event)
    obj = stripe_event.data.object
    user_subscription = UserSubscription.find_by(stripe_id: obj.id)
    raise "UserSubscription not found for stripe_id: #{obj.id}" if user_subscription.blank?

    user_subscription.paused!
  end

  def subscription_resumed(stripe_event)
    obj = stripe_event.data.object
    user_subscription = UserSubscription.find_by(stripe_id: obj.id)
    raise "UserSubscription not found for stripe_id: #{obj.id}" if user_subscription.blank?

    user_subscription.update!(status: obj.status)
  end

  def checkout_session_completed(stripe_event)
    obj = stripe_event.data.object
    user = User.find_by stripe_id: obj.customer
    raise "User not found for stripe_id: #{obj.customer}" if user.blank?

    stripe_subscription = StripeAdmin.get_subscription(obj.subscription)
    user_subscription = UserSubscription.find_or_create_by!(user:, stripe_id: stripe_subscription.id)
    status = stripe_subscription.status
    current_period_start = Time.at(stripe_subscription.current_period_start)
    current_period_end = Time.at(stripe_subscription.current_period_end)
    default_payment_method = stripe_subscription.default_payment_method
    plan = stripe_subscription.plan
    amount = plan.amount
    product = plan.product
    price_id = plan.id
    user_subscription.update!(
      status:,
      current_period_start:,
      current_period_end:,
      payment_method_id: default_payment_method,
      amount:,
      product_id: product,
      price_id:
    )
  end
end
