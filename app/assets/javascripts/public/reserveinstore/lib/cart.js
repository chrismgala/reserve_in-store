ReserveInStore.Cart = function (opts) {
    var self = this;
    opts = opts || {};
    var storage = opts.storage;
 
    var init = function () {
        self.setData(opts.app.cart());
    };

    self.setData = function(_data) {
        data = _data;

        ReserveInStore.logger.log("Set cart Data: ", data)
    };

    self.getProductTags = function(callback) {
        var tags = [];
        var cartData = opts.app.cart();
        
        if (!cartData) return callback(tags);

        var itemCount = cartData.length;
        if (itemCount < 1) return callback(tags);

        var fetchedItemCount = 0;       
        for (var i = 0; i < cartData.length; i++) {
            var item = cartData[i];
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
