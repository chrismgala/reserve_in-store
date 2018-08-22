class LocationMailer < ApplicationMailer
  ##
  # Generate email to tell the store owner that a new reservation request has been submitted and provide all the details of the request.
  # @param [Store] store - The store object that got a new reservation
  # @param [Reservation] reservation - The reservation object that just been created
  # @param [String] shopify_product_link A link for the reservation's product
  # @returns [Mail::Message]
  def new_reservation(store:, reservation:, shopify_product_link:)
    @store = store
    @reservation = reservation
    @shopify_product_link = shopify_product_link
    staged_mail(to: to_location, subject: "A new reservation request has been submitted", from: from_system)
  end

  def staged_mail(params = {})
    Rails.logger.info("Email being sent with params: #{params.inspect}") unless Rails.env.test?
    mail(params)
  end

  def to_location
    @reservation.location.email.split(',').map{|email| "#{@reservation.location.name} <#{email}>"}
  end

end

