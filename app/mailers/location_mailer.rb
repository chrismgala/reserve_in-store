class LocationMailer < ApplicationMailer
  ##
  # Generate email to tell the store owner that a new reservation request has been submitted and provide all the details of the request.
  # @param [object] store - The store object that got a new reservation
  # @param [object] reservation - The reservation object that just been created
  # @param [object] product - The product object being reserved
  # @param [object] variant - The variant object being reserved
  # @returns [Mail::Message]
  def new_reservation(store, reservation, product_title, variant_title)
    @store = store
    @reservation = reservation
    @product_title = product_title
    @variant_title = variant_title
    staged_mail(to: to_location, subject: "A new reservation request has been submitted", from: from_system)
  end

  def staged_mail(params = {})
    Rails.logger.info("Email being sent with params: #{params.inspect}") unless Rails.env.test?
    mail(params)
  end

  def to_location
    "#{@reservation.location.name} <#{@reservation.location.email}>"
  end

end

