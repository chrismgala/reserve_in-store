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
    @rendered_location_email_template = @reservation.rendered_location_email_template
    staged_mail(to: store_location_contact,
                subject: store.location_notification_subject.presence || "New In-store Reservation",
                from: location_notification_sender,
                reply_to: customer_contact)
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
    @rendered_customer_email_template = @reservation.rendered_customer_email_template
    staged_mail(to: customer_contact,
                subject: store.customer_confirmation_subject.presence || "In-Store Reservation Confirmation",
                from: customer_confirmation_sender,
                reply_to: store_location_contact)
  end

  def unfulfilled_reservation(store:, reservation:)
    @store = store
    @reservation = reservation
    if reservation.unfulfilled_reservation_custom_email_tpl_enabled?
      @rendered_unfulfilled_reservation_notification_email_template = @reservation.rendered_unfulfilled_reservation_custom_notification_email_template
    else
      @rendered_unfulfilled_reservation_notification_email_template = @reservation.rendered_unfulfilled_reservation_notification_email_template
    end

    staged_mail(to: customer_contact,
                subject: store.unfulfilled_reservation_subject.presence || "In-store Reservation Unfulfilled",
                from: unfulfilled_reservation_sender,
                reply_to: store_location_contact)
  end

  def fulfilled_reservation(store:, reservation:)
    @store = store
    @reservation = reservation
    @rendered_fulfilled_reservation_notification_email_template = @reservation.rendered_fulfilled_reservation_notification_email_template

    staged_mail(to: customer_contact,
                subject: store.fulfilled_reservation_subject.presence || "In-store Reservation Fulfilled",
                from: fulfilled_reservation_sender,
                reply_to: store_location_contact)
  end

  private

  def store_location_contact
    @reservation.location.email.split(",").map{|email_address| "\"#{store_name}\" <#{email_address}>"}.join(",")
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

  def unfulfilled_reservation_sender_name
    if @store.unfulfilled_reservation_sender_name?
      @store.unfulfilled_reservation_sender_name
    else
      system_name
    end
  end

  def unfulfilled_reservation_sender
    "\"#{unfulfilled_reservation_sender_name}\" <#{system_email}>"
  end

  def fulfilled_reservation_sender_name
    if @store.fulfilled_reservation_sender_name?
      @store.fulfilled_reservation_sender_name
    else
      system_name
    end
  end

  def fulfilled_reservation_sender
    "\"#{fulfilled_reservation_sender_name}\" <#{system_email}>"
  end

  def customer_confirmation_sender_name
    if @store.customer_confirmation_sender_name.present?
      @store.customer_confirmation_sender_name
    else
      system_name  
    end
  end

  def customer_confirmation_sender
    "\"#{customer_confirmation_sender_name}\" <#{system_email}>"
  end

  def location_notification_sender_name
    from_name = system_name
    if @store.location_notification_sender_name.present?
      from_name = "#{@store.location_notification_sender_name} #{@reservation.customer_name}"
    end
    return from_name
  end

  def location_notification_sender
    "\"#{location_notification_sender_name}\" <#{system_email}>"
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
