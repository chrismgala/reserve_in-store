ReserveInStore.CheckoutSuccessMessage = function (opts) {
    opts = opts || {};

    var init = function () {
        var reservationId = opts.storage.getItem('reservationId');
        var checkoutSuccessMessageTpl = opts.storage.getItem('checkoutSuccessMessageTpl');
        if (reservationId) {
            showMessage(reservationId, checkoutSuccessMessageTpl);
        }
    };

    var showMessage = function(reservationId, checkoutSuccessMessageTpl) {
        if (window.location.toString().indexOf('/thank_you') !== -1 && reservationId)  {
            Shopify.Checkout.OrderStatus.addContentBox(
                checkoutSuccessMessageTpl.replace(/reservation_id/g, reservationId)
            );
            window.localStorage.removeItem('reservationCustomId');
        }
    };

    init();
};
