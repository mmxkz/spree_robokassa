module Spree
  class RobokassaController < BaseController
    before_action :set_order
    before_action :validate_request, :except => :failure
    skip_before_action :verify_authenticity_token

    def result
      payment.complete
      render text: notification.success_response
    end

    def success
      payment.complete
      redirect_to @order, notice: t('robokassa.payment_succeed')
    end

    def failure
      payment.failure
      redirect_to :root, flash: { error: t('robokassa.payment_failed') }
    end

    private

    def set_order
      @order = Order.find params['InvId']
    end

    def validate_request
      unless notification.acknowledge
        payment.failure
        head :bad_request and return false
      end
    end

    def payment
      @payment ||= @order.payments.detect do |p|
        p.payment_method.is_a? BillingIntegration::Robokassa
      end
    end

    def notification
      req_str = request.query_string
      req_str = request.raw_post if req_str.empty?
      secret  = action_name == 'result' ?
        payment.payment_method.preferred_password2 :
        payment.payment_method.preferred_password1
      @notification ||= ActiveMerchant::Billing::Integrations::Robokassa.notification(
        req_str,
        secret: secret)
      @notification
    end
  end
end
