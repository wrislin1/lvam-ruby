# frozen_string_literal: true

require "stripe"

class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  ENDPOINT_SECRET = ENV.fetch(
    "ENDPOINT_SECRET",
    Rails.application.credentials.dig(:stripe, :endpoint_secret)
  )

  def create
    @event = Event.create!(data: params, source: params[:source])
    if params[:source] == "stripe"
      verify_stripe_and_process
    else
      render json: { status: :ok }
    end
  end

  private

  def verify_stripe_and_process
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    begin
      Stripe::Webhook.construct_event(payload, sig_header, ENDPOINT_SECRET)
      HandleEventJob.perform_later(@event)
      render json: { status: :ok }
    rescue JSON::ParserError => e
      Rails.logger.error "Error parsing payload: #{e.message}"
      render json: { status: :bad_request }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Error verifying webhook signature: #{e.message}"
      render json: { status: :bad_request }, status: :bad_request
    end
  end
end
