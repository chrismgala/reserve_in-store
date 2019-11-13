ReserveInStore.InventoryManager = function (opts) {
    var self = this;
    opts = opts || {};
    var api = opts.api,
        storage = opts.storage;

    var productInventoryStore, cartInventoryStore;

    var init = function () {
        productInventoryStore = {};
    };

    self.loadInventory = function(productId, then) {
        api.getInventory({ product_id: productId }, function(_inventory) {
            productInventoryStore[productId] = _inventory;
            storage.setItem('InventoryManager.product.' + productId, _inventory, opts.debugMode ? 1 : 1000*60*15); // Save for 15 minutes unless debug mode is on
            then(_inventory);
        });
    };

    self.getInventory = function(productId, then) {
        var inventory = storage.getItem('InventoryManager.product.' + productId);

        if (inventory) {
            then(inventory);
        } else if (productInventoryStore[productId]) {
            then(productInventoryStore[productId]);
        } else {
            self.loadInventory( productId, function(_inventory) {
                then(_inventory);
            });
        }
    };

    self.loadCartInventory = function(productIdArray, then) {
        api.getCartInventory({ product_ids: productIdArray }, function(_inventory) {
            cartInventoryStore = _inventory;
            storage.setItem('InventoryManager.cart.' + productIdArray, _inventory, opts.debugMode ? 1 : 1000*60*15); // Save for 15 minutes unless debug mode is on
            then(_inventory);
        });
    };

    self.getCartInventory = function(productIdArray, then) {
        var cartInventory = storage.getItem('InventoryManager.cart.' + productIdArray);

        if (cartInventory) {
            then(cartInventory);
        } else if (cartInventoryStore) {
            then(cartInventoryStore);
        } else {
            self.loadCartInventory( productIdArray, function(_inventory) {
                then(_inventory);
            });
        }
    };

    init();
};
