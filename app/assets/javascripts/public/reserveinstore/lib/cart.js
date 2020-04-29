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
