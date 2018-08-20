class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :location

  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location
  validates :customer_email, format: /\A[^@\s]+@[^@\s]+\z/

  PERMITTED_PARAMS = [:customer_name, :customer_email, :customer_phone, :location_id,
                      :platform_product_id, :platform_variant_id, :instructions_from_customer, :fulfilled]

  def customer_first_name
    customer_name.to_s.split(' ').first
  end

  def customer_last_name
    customer_name.to_s.split(' ').last
  end

  ##
  # Save the reservation, hit ShopifyAPI to get product and variant information
  # and send notification emails to the customer and the store owner
  #
  # @return [Boolean] save result
  def save_and_email
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

  private

  ##
  # Creates and utilizes a shopifyAPI instance to return a link for the reservation's product
  # @return [String] HTML link to the shopify product OR a raw "unknown product" string
  def shopify_product_link!
    if shopify_product!.present?
      "<a href='https://#{store.shopify_domain}/product/#{shopify_product!.handle}'>#{shopify_product_variant_title!}</a>"
    else
      "Unknown Product"
    end
  end

  ##
  # Creates and utilizes a shopifyAPI instance to return the product variant title
  # @return [String] title of the product variant
  def shopify_product_variant_title!
    if shopify_product!.present?
      if shopify_variant!.present? && shopify_variant!.title != 'Default Title'
        "#{shopify_product!.title} (#{shopify_variant!.title})"
      else
        shopify_product!.title
      end
    else
      "Unknown Product"
    end
  end

  ##
  # ! Dangerous method since if we do not check .present? we will query the API way too much !
  # @return [ShopifyAPI::Product|NilClass] nil if not product available, otherwise the shopify product model
  def shopify_product!
    @shopify_product ||= ShopifyAPI::Product.find(platform_product_id)
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # ! Dangerous method since if we do not check .present? we will query the API way too much !
  # @return [ShopifyAPI::Variant|NilClass] nil if not variant available, otherwise the shopify variant model
  def shopify_variant!
    @shopify_variant ||= ShopifyAPI::Variant.find(platform_variant_id)
  rescue => e
    Rails.logger.error(e)
    nil
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
end
