ReserveInStore.CheckoutSuccessMessage = function (opts) {
    opts = opts || {};

    var init = function () {
        var reservationId = opts.storage.getItem('reservationCustomId');
        var checkoutSuccessMessageTpl = opts.storage.getItem('checkoutSuccessMessageTpl');
        if (reservationId) {
            successMessage(reservationId, checkoutSuccessMessageTpl);
        }
    };

    var successMessage = function(reservationId, checkoutSuccessMessageTpl) {
        if (window.location.toString().indexOf('/thank_you') !== -1 && reservationId)  {
            Shopify.Checkout.OrderStatus.addContentBox(
                checkoutSuccessMessageTpl.replace(/reservation_id/g, reservationId)
            );
            window.localStorage.removeItem('reservationCustomId');
        }
    };

    init();
};
