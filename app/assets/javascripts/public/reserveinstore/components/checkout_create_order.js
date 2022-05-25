ReserveInStore.CheckoutCreateOrder = function (opts) {
    opts = opts || {};
    var customReservationId, discountCode;

    var init = function () {
        config = opts.config || {};
        customReservationId = opts.customReservationId;
        discountCode = config.discount_code;
        // Save for 10 minutes I think 10 minutes should be enough to complete checkout.
        opts.storage.setItem('reservationCustomId', customReservationId, opts.debugMode ? 1 : 1000*60*10);

        window.location = '/checkout?discount=' + discountCode +
            '&note=In-store reservation id: ' + customReservationId + "" +
            "&checkout[email]=" + opts.email;
    };

    init();
};
