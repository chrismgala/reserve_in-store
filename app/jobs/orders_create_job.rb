class OrdersCreateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    @webhook = webhook
    @platform_order_id = webhook[:id]
    @store = Store.find_by(shopify_domain: shop_domain, checkout_without_clearing_cart: true)

    return if @store.blank?

    note = webhook[:note]

    if note.to_s.include? "id:"
      index= note.index('id:')
      note.from(index + 4)

      @reservation = @store.reservations.find_by(id: note.from(index + 4))

      if @reservation
        @reservation.update(platform_order_id: @platform_order_id)
        @reservation.send_notification_emails!
      end
    end
  end
end
