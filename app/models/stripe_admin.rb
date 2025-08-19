# frozen_string_literal: true

class StripeAdmin
  def self.create_customer(user)
    Stripe::Customer.create({ email: user.email, name: user.name })
  end

  def self.get_customer(user)
    return Stripe::Customer.retrieve(user.stripe_id) if user.stripe_id.present?

    customer = StripeAdmin.create_customer(user)
    user.update!(stripe_id: customer.id)
    customer
  end

  def self.get_products(active: true)
    Stripe::Product.list({ active: })
  end

  def self.get_subscription(subscription_id)
    Stripe::Subscription.retrieve(subscription_id)
  end

  def self.get_user_subscriptions(user, status: "all", expand: [])
    Stripe::Subscription.list({ expand:, customer: StripeAdmin.get_customer(user).id, status: })
  end

  def self.get_payment_method(payment_method_id)
    Stripe::PaymentMethod.retrieve(payment_method_id)
  end

  def self.cancel_subscription(subscription_id, cancellation_details: {})
    Stripe::Subscription.cancel(subscription_id, { cancellation_details: })
  end

  def self.create_payment_update_billing_portal_config
    Stripe::BillingPortal::Configuration.create(
      {
        features: {
          invoice_history: { enabled: true },
          payment_method_update: { enabled: true }
        }
      }
    )
  end

  def self.create_billing_portal_session(user, configuration, return_url)
    Stripe::BillingPortal::Session.create(
      {
        configuration:,
        customer: StripeAdmin.get_customer(user).id,
        return_url:,
      }
    )
  end

  def self.create_checkout_session(user, price_id, success_url, cancel_url)
    Stripe::Checkout::Session.create(
      {
        mode: "subscription",
        payment_method_types: [ "card" ],
        customer: StripeAdmin.get_customer(user).id,
        success_url:,
        cancel_url:,
        line_items: [
          { quantity: 1, price: price_id }
        ]
      }
    )
  end
end
