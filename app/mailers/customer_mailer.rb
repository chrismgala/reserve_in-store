class CustomerMailer < ApplicationMailer
  ##
  # Generate reservation confirmation email to be sent to the customer
  # @param [object] store - The store object that got a new reservation
  # @param [object] reservation - The reservation object that just been created
  # @param [object] product - The product object being reserved
  # @param [object] variant - The variant object being reserved
  # @returns [Mail::Message]
  def reserve_confirmation(store, reservation, product, variant)
    @store = store
    @reservation = reservation
    @product = product
    @variant = variant
    subject = @product.present? ? "Your reservation of #{@product.title}" : "Your reservation at #{@store.name}"
    staged_mail(to: to_customer, subject: subject, from: from_system)
  end

  def staged_mail(params = {})
    Rails.logger.info("Email being sent with params: #{params.inspect}") unless Rails.env.test?
    mail(params)
  end

  def to_customer
    "#{@reservation.customer_name} <#{@reservation.customer_email}>"
  end

end

