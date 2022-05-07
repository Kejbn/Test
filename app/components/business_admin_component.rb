class BusinessAdminComponent < ApplicationComponent
  attr_reader :business, :user

  def initialize(business, user:)
    @business = business
    @user = user
  end

  def render?
    user&.admin?
  end

  def stripe_customer?
    customer&.stripe?
  end

  def stripe_url
    if live?
      "https://dashboard.stripe.com/customers/#{customer.processor_id}"
    else
      "https://dashboard.stripe.com/test/customers/#{customer.processor_id}"
    end
  end

  private

  def customer
    business.user.payment_processor
  end

  def live?
    customer.processor_id.starts_with?("cus_")
  end
end
