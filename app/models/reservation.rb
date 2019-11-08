class Reservation < ActiveRecord::Base
  serialize :line_item
  belongs_to :store
  belongs_to :location

  before_validation :populate_cart_attribute
  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location
  validates :customer_email, format: /\A[^@\s]+@[^@\s]+\z/

  after_create :trigger_create_webhook!
  after_update :trigger_fulfilled_webhook!, :trigger_update_webhook!
  after_destroy :trigger_destroy_webhook!

  PERMITTED_PARAMS = [:customer_name, :customer_email, :customer_phone, :location_id, :platform_product_id,
                      :platform_variant_id, :instructions_from_customer, :fulfilled, :line_item, :cart => {}]

  def customer_first_name
    customer_name.to_s.split(' ').first
  end

  def customer_last_name
    customer_name.to_s.split(' ').last
  end

  ##
  # Save the reservation, and send notification emails to the customer and the store owner
  # @return [Boolean] save result
  def save_and_email
    return false unless save
    send_notification_emails!
    true
  end

  ##
  # @param [String] shopify_product_link - the link to put in our liquid params
  # @return [Text] - rendered email template
  def rendered_customer_email_template
    tpl = store.customer_confirm_email_tpl_in_use
    Liquid::Template.parse(tpl).render(email_liquid_params.deep_stringify_keys).html_safe
  end

  ##
  # @return [ActiveSupport::SafeBuffer] - the rendered email template is a String object
  # which is then wrapped in a SafeBuffer
  def rendered_location_email_template
    tpl = store.location_notification_email_tpl_in_use
    Liquid::Template.parse(tpl).render(email_liquid_params.deep_stringify_keys).html_safe
  end

  def cart
    (super.presence || build_legacy_cart).to_h.with_indifferent_access
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
      cart: cart,
      fulfilled: fulfilled?,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  ##
  # @deprecated Temporary method. Can be removed by May 20, 2019
  def populate_cart_attribute
    return false if attributes['cart'].present? || platform_product_id.blank?

    legacy_cart = self.cart = build_legacy_cart
    legacy_cart[:items].map do |item|
      product = store.cached_api.product(item[:product_id])
      variant = product.variants.find{ |v| "#{v.id}" == "#{item[:variant_id]}" }
      item.merge!(product_title: product.title)
      item.merge!(variant_title: variant.title, total: variant.price)
      item
    end
    self.cart = legacy_cart
  end

  ##
  # Send emails to confirm with the customer and notify the store owner
  def send_notification_emails!
    ReservationMailer.location_notification(store: store, reservation: self).deliver_later
    ReservationMailer.customer_confirmation(store: store, reservation: self).deliver_later
  end

  ##
  # @return [Hash] - render the email liquid with this hash
  def email_liquid_params
    attributes.merge({
                       customer: {
                         first_name: customer_first_name,
                         last_name: customer_last_name,
                         email: customer_email,
                         phone: customer_phone
                       },
                       location: location.to_liquid,
                       store: {
                         name: store.name,
                         website_url: store.website_url
                       }
                     }.deep_stringify_keys)
  end

  ##
  # @return [Hash] - liquid params used by JS email previewer
  def preview_email_liquid_params
    {
      customer: {
        first_name: "John",
        last_name: "Doe",
        email: "john.doe@example.com",
        phone: "+1-123-456-7890"
      },
      location: {
        name: "Store 3",
        address: "1234 Test St.",
        city: "City",
        state: "State",
        country: "Country",
        email: "location@example.com",
        phone: "+1-800-123-1234"
      },
      store: {
        name: store.name,
        website_url: store.website_url
      },
      instructions_from_customer: "Monday at 5:30pm",
      cart: {
        items: [
                 {
                   product_title: "Sample Product Name",
                   variant_title: "Variant Name",
                   total: 1234,
                   total_formatted: store.currency(12.34),
                   price: 1234,
                   vendor: "Sample Product Brand/Vendor",
                   handle: "Sample Product Name",
                   product_description: "This is the description for a sample product",
                   taxable: true,
                   sku: "SKU1234ABCD"
                 }
               ]
      }
    }.deep_stringify_keys
  end

  private

  def build_legacy_cart
    return {} unless platform_product_id.present?

    {
      items: [ {
                 product_id: platform_product_id,
                 variant_id: platform_variant_id
               }]
    }
  end

  ##
  # Creates a link for the reservation's product
  # @deprecated Uses old data. remove by May 31, 2019
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
  # @deprecated Uses old data. remove by May 31, 2019
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

