ReserveInStore.CheckoutSuccessMessage = function (opts) {
    opts = opts || {};

    var init = function () {
        var reservation_id = opts.storage.getItem('reservationCustomId');

        if (window.location.toString().indexOf('/thank_you') !== -1 && reservation_id)  {
            Shopify.Checkout.OrderStatus.addContentBox(
                '<h2>Your In-store reservation #' + reservation_id + ' has been received please check email for further instructions</h2>',
            );
            window.localStorage.removeItem('reservationCustomId');
        }
    };

    init();
};
