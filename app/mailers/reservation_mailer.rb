class ReservationMailer < ApplicationMailer

  ##
  # Generate email to tell the store owner that a new reservation request has been submitted and provide all the details of the request.
  # @param [Store] store - The store object that got a new reservation
  # @param [Reservation] reservation - The reservation object that just been created
  # @param [String] shopify_product_link A link for the reservation's product
  # @returns [Mail::Message]
  def location_notification(store:, reservation:)
    @store = store
    @reservation = reservation
    staged_mail(to: store_location_contact,
                subject: store.location_notification_subject.presence || "New In-store Reservation",
                from: system_contact)
  end

  ##
  # Generate reservation confirmation email to be sent to the customer
  # @param [Store] store - The store object that got a new reservation
  # @param [Reservation] reservation - The reservation object that just been created
  # @param [String] rendered_liquid - The rendered liquid to be placed in our view
  # @param [String] product_title - The product title
  # @returns [Mail::Message]
  def customer_confirmation(store:, reservation:)
    @store = store
    @reservation = reservation
    @rendered_email_template = @reservation.rendered_email_template
    staged_mail(to: customer_contact,
                subject: store.customer_confirmation_subject.presence || "In-Store Reservation Confirmation",
                from: system_contact,
                reply_to: store_location_contact)
  end

  private

  def store_location_contact
    "\"#{store_name}\" <#{@reservation.location.email}>"
  end


  def staged_mail(params = {})
    Rails.logger.info("Email being sent with params: #{params.inspect}") unless Rails.env.test?
    mail(params)
  end

  def store_name
    if @store.name.present?
      @store.name
    else
      store_email.split('@').first
    end
  end

  def store_email
    @store.email
  end

  def store_support_contact
    "\"#{store_name}\" <#{store.support_email}>"
  end

  def store_contact
    "\"#{store_name}\" <#{store_email}>"
  end

  def customer_contact
    "\"#{@reservation.customer_name}\" <#{@reservation.customer_email}>"
  end
end
