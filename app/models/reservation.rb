class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :location

  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location
  validates :customer_email, format: /\A[^@\s]+@[^@\s]+\z/

  PERMITTED_PARAMS = [:customer_name, :customer_email, :customer_phone, :location_id,
                      :platform_product_id, :platform_variant_id, :instructions_from_customer, :fulfilled]

  def shopify_product_title
    shopify_product.present? ? shopify_product.title : nil
  end

  def shopify_variant_title
    shopify_variant.present? ? shopify_variant.title : nil
  end

  def shopify_product_link
    if shopify_product_title
      if shopify_variant_title && shopify_variant_title != 'Default Title'
        "<a href='https://#{store.shopify_domain}/product/#{shopify_product.handle}'>#{shopify_product_title} (#{shopify_variant_title})</a>"
      else
        "<a href='https://#{store.shopify_domain}/product/#{shopify_product.handle}'>#{shopify_product_title}</a>"
      end
    else
      "Unknown Product"
    end
  end

  def shopify_product_variant_combined_title
    if shopify_product_title
      if shopify_variant_title && shopify_variant_title != 'Default Title'
        "#{shopify_product_title} (#{shopify_variant_title})"
      else
        shopify_product_title
      end
    else
      "Unknown Product"
    end
  end

  ##
  # @return [ShopifyAPI::Product|NilClass] nil if not product available, otherwise the shopify product model
  def shopify_product
    if @shopify_product_checked
      @shopify_product
    else
      @shopify_product_checked = true
      begin
        @shopify_product = ShopifyAPI::Product.find(platform_product_id)
      rescue => e
        Rails.logger.error(e)
        nil
      end
    end
  end

  ##
  # @return [ShopifyAPI::Variant|NilClass] nil if not variant available, otherwise the shopify variant model
  def shopify_variant
    if @shopify_variant_checked
      @shopify_variant
    else
      @shopify_variant_checked = true
      begin
        @shopify_variant = ShopifyAPI::Variant.find(platform_variant_id)
      rescue => e
        Rails.logger.error(e)
        nil
      end
    end
  end

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
  # Send emails to confirm with the customer and notify the store owner
  def send_notification_emails
    CustomerMailer.reserve_confirmation({store: store, reservation: self, rendered_liquid: rendered_email_template, product_title: shopify_product_variant_combined_title}).deliver_later
    LocationMailer.new_reservation({store: store, reservation: self, product_title: shopify_product_title, variant_title: shopify_variant_title}).deliver_later
  end

  ##
  # @param [Customer] customer - the customer needed for some of the liquid params
  # @return [Text] - rendered email template
  def rendered_email_template
    email_template = store.email_template || Store::default_email_template
    Liquid::Template.parse(email_template).render(email_liquid_params).html_safe
  end

  ##
  # @param [Customer] customer - the customer needed for some of the liquid params
  # @return [Hash] - render the email liquid with this hash
  def email_liquid_params
    {'customer_first_name' => customer_first_name,
     'customer_last_name' => customer_last_name,
     'product_link' => shopify_product_link,
     'location_name' => location.name,
     'location_address' => location.address,
     'location_city' => location.city,
     'location_state' => location.state,
     'location_country' => location.country,
     'store_link' => "<a href='https://#{store.shopify_domain}'>#{store.name}</a>",
     'reservation_time' => instructions_from_customer}
  end
end
