ReserveInStore.Cart = function (opts) {
    var self = this;
    opts = opts || {};
    var storage = opts.storage;
    var data;
 
    var init = function () {
    };

    self.setData = function(cartData) {
        data = cartData;
        return self;
    };

    self.getData = function() { return data; };

    self.getAjaxData = function(callback) {
        $.getJSON('/cart.js', function(cartData) {
            opts.app.setCart(cartData);
            callback(cartData);
        });
    };

    /**
     * after reservation if reserved from product then first clear any previous cart items and then add new reserved items to checkout
     * if reserved from cart then no need to clear redirect it to checkout page
     * {object} reservationData
     * {int} reservationId - reservation id
     * {string} discountCode
     * {string}  email
     * {object} cart - if reserved from cart page
     */
    self.checkout = function(reservationData, reservationId, discountCode, email, cart) {
        if (cart) {
            checkoutPath(reservationId, discountCode, email);
        } else {
            $.getJSON( "/cart/clear", function() {
                data = { quantity: reservationData.cart.items[0].quantity || 1,
                    id: reservationData.cart.items[0].variant_id
                }
                $.post('/cart/add.js', data, function() {
                    checkoutPath(reservationId, discountCode, email);
                }, 'json');
            });
        }
    };

    var checkoutPath = function (reservationId, discountCode, email) {
        window.location = '/checkout?discount=' + discountCode +
            '&note=In-store reservation id: ' + reservationId + "" +
            "&checkout[email]=" +  email;
    };

    self.getProductTags = function(callback) {
        var tags = [];
                
        if (!data) return callback(tags);

        var itemCount = data.items.length;
        if (itemCount < 1) return callback(tags);

        var fetchedItemCount = 0;       
        for (var i = 0; i < data.items.length; i++) {
            var item = data.items[i];
            if (storage.getItem('ProductTags.' + item.product_id)) {
                fetchedItemCount += 1;
                tags = tags.concat(storage.getItem('ProductTags.' + item.product_id));
                if (fetchedItemCount === itemCount) callback(tags);
            } else {
                var cartItemUrl = item.url.substring(0, item.url.indexOf('?'));
                $.getJSON(cartItemUrl + ".js", function(product) {
                    storage.setItem('ProductTags.' + product.id, product.tags, 1000 * 60 * 60); // Expire in 1 hour
                    tags = tags.concat(product.tags);
                    fetchedItemCount += 1;
                    if (fetchedItemCount === itemCount) callback(tags);
                });
            }
        }
    };

    init();
};
