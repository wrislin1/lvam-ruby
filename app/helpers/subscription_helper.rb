module SubscriptionHelper
  def subscription_actions(subscription)
    ret = []
    if subscription.latest_invoice.try(:hosted_invoice_url)
      ret << {
        name: "Latest Invoice",
        path: subscription.latest_invoice.hosted_invoice_url,
        target: "_blank",
        icon: "fa-receipt"
      }
    end
    if subscription.status == "active"
      if subscription.customer == current_user&.stripe_id
        ret << {
          name: "Change Payment Method",
          path: edit_subscription_path(subscription.id),
          turbo: false,
          icon: "fa-credit-card",
          turbo_action: "click->app#showLoadingOverlay"
        }
      end
      ret << {
        name: "Cancel",
        path: cancel_subscription_path(subscription.id),
        icon: "fa-ban",
        turbo: true
      }
    end
    ret
  end

  def subscription_price_str(subscription)
    amount = subscription.plan.amount
    interval = subscription.plan.interval
    "#{number_to_currency(amount.to_f / 100)} / #{interval}"
  end

  def cancellation_feedback_options
    [
      [
        "Customer service wasn't up to par",
        "customer_service"
      ],
      [
        "Low quality service",
        "low_quality"
      ],
      [
        "Doesn't offer the features I need",
        "missing_features"
      ],
      [
        "I'm switching to a different service",
        "switched_service"
      ],
      [
        "Too complicated for my needs",
        "too_complex"
      ],
      [
        "Too expensive",
        "too_expensive"
      ],
      [
        "I don't use it enough",
        "unused"
      ],
      [
        "Other",
        "other"
      ],
    ].freeze
  end
end
