class Reservation < ActiveRecord::Base
  serialize :line_item
  belongs_to :store
  belongs_to :location

  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location
  validates :customer_email, format: /\A[^@\s]+@[^@\s]+\z/

  after_create :trigger_create_webhook!
  after_update :trigger_fulfilled_webhook!, :trigger_update_webhook!
  after_destroy :trigger_destroy_webhook!

  PERMITTED_PARAMS = [:customer_name, :customer_email, :customer_phone, :location_id, :platform_product_id,
                      :platform_variant_id, :instructions_from_customer, :fulfilled, :line_item]

  def customer_first_name
    customer_name.to_s.split(' ').first
  end

  def customer_last_name
    customer_name.to_s.split(' ').last
  end

  ##
  # Save the reservation, and send notification emails to the customer and the store owner
  # @return [Boolean] save result
  def save_and_email(product_info)
    @product_info = product_info
    return false unless save
    send_notification_emails
    true
  end

  ##
  # @param [String] shopify_product_link - the link to put in our liquid params
  # @return [Text] - rendered email template
  def rendered_email_template(shopify_product_link)
    email_template = store.email_template || Store::default_email_template
    Liquid::Template.parse(email_template).render(email_liquid_params(shopify_product_link)).html_safe
  end


  def to_api_h
    {
      id: id,
      location_id: location_id,
      customer: {
        name: customer_name,
        email: customer_email,
        phone: customer_phone,
        instructions: instructions_from_customer
      },
      cart: {
        items: [ {
                   product_id: platform_product_id,
                   variant_id: platform_variant_id
                 }]
      },
      fulfilled: fulfilled?,
      created_at: created_at,
      updated_at: updated_at

    }
  end


  private

  ##
  # Creates a link for the reservation's product
  # @return [String] HTML link to the shopify product OR a raw "unknown product" string
  def shopify_product_link!
    if @product_info.present?
      "<a href='https://#{store.shopify_domain}/product/#{@product_info[:product_handle]}'>#{shopify_product_variant_title!}</a>"
    else
      "Unknown Product"
    end
  end

  ##
  # Creates the product variant title
  # @return [String] title of the product variant
  def shopify_product_variant_title!
    if @product_info[:product_title].present?
      if @product_info[:variant_title].present? && @product_info[:variant_title] != 'Default Title'
        "#{@product_info[:product_title]} (#{@product_info[:variant_title]})"
      else
        @product_info[:product_title]
      end
    else
      "Unknown Product"
    end
  end

  ##
  # Send emails to confirm with the customer and notify the store owner
  def send_notification_emails
    CustomerMailer.reserve_confirmation({store: store, reservation: self, shopify_product_link: shopify_product_link!}).deliver_later
    LocationMailer.new_reservation({store: store, reservation: self, shopify_product_link: shopify_product_link!}).deliver_later
  end

  ##
  # @param [String] shopify_product_link - the link to put in our liquid params
  # @return [Hash] - render the email liquid with this hash
  def email_liquid_params(shopify_product_link)
    {'customer_first_name' => customer_first_name,
     'customer_last_name' => customer_last_name,
     'product_link' => shopify_product_link,
     'location_name' => location.name,
     'location_address' => location.address,
     'location_city' => location.city,
     'location_state' => location.state,
     'location_country' => location.country,
     'store_link' => store.shopify_link,
     'reservation_time' => instructions_from_customer}
  end

  def trigger_create_webhook!
    TriggerWebhookJob.perform_later(store_id: store_id, topic: 'reservations/create', object_id: id, object_klass: self.class.to_s)
    true
  end

  def trigger_fulfilled_webhook!
    if previous_changes['fulfilled'].present? && !previous_changes['fulfilled'][0] && previous_changes['fulfilled'][1]
      TriggerWebhookJob.perform_later(store_id: store_id, topic: 'reservations/fulfilled', object_id: id, object_klass: self.class.to_s)
    end
    true
  end

  def trigger_destroy_webhook!
    TriggerWebhookJob.perform_later(store_id: store_id, topic: 'reservations/delete', object_id: id, object_klass: self.class.to_s)
    true
  end

  def trigger_update_webhook!
    TriggerWebhookJob.perform_later(store_id: store_id, topic: 'reservations/update', object_id: id, object_klass: self.class.to_s)
    true
  end
end

