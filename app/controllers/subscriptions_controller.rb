class SubscriptionsController < ApplicationController
  def create
    price_id = params.require :price_id
    checkout_session = StripeAdmin.create_checkout_session(
      current_user,
      price_id,
      root_url(checkout_session: "complete"),
      root_url(checkout_session: "canceled")
    )
    redirect_to checkout_session.url, allow_other_host: true
  end
end
