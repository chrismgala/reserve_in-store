class CustomerMailer < ApplicationMailer
  ##
  # Generate reservation confirmation email to be sent to the customer
  # @param [Store] store - The store object that got a new reservation
  # @param [Reservation] reservation - The reservation object that just been created
  # @param [String] rendered_liquid - The rendered liquid to be placed in our view
  # @param [String] product_title - The product title
  # @returns [Mail::Message]
  def reserve_confirmation(store:, reservation:, rendered_liquid:, product_title:)
    @store = store
    @reservation = reservation
    @rendered_email_template = rendered_liquid
    subject = (product_title != "Unknown Product" ? "Your reservation of #{product_title}" : "Your reservation at #{@store.name}")
    staged_mail(to: to_customer, subject: subject, from: from_system, reply_to: reply_to_location)
  end

  def staged_mail(params = {})
    Rails.logger.info("Email being sent with params: #{params.inspect}") unless Rails.env.test?
    mail(params)
  end

  def reply_to_location
    @store.name.present? ? "#{@store.name} <#{@reservation.location.email}>" : @reservation.location.email
  end

  def to_customer
    "#{@reservation.customer_name} <#{@reservation.customer_email}>"
  end

end

