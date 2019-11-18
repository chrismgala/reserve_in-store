ReserveInStore.InventoryManager = function (opts) {
    var self = this;
    opts = opts || {};
    var api = opts.api;
    var storage = opts.storage;

    var inventoryStore, cartInventoryStore;

    var init = function () {
        inventoryStore = {};
    };

    /**
     * This function will retrieve the inventory levels for a single product from the API and then save them
     * in the local store.
     * @param productId
     * @param then - the callback function to return the inventory after it has been saved
     */
    self.loadInventory = function(productId, then) {
        api.getInventory({ product_id: productId }, function(_inventory) {
            inventoryStore[productId] = _inventory;
            storage.setItem('InventoryManager.product.' + productId, _inventory, opts.debugMode ? 1 : 1000*60*15); // Save for 15 minutes unless debug mode is on
            then(_inventory);
        });
    };

    /**
     * This function will attempt to return product Inventories that are saved locally. If the products is not
     * available in local storage, this function will call loadInventory to read the inventory using the API
     * @param productId
     * @param then - the callback function to return the inventory after it has been retrieved
     */
    self.getInventory = function(productId, then) {
        var inventory = storage.getItem('InventoryManager.product.' + productId);

        if (inventory) {
            then(inventory);
        } else if (inventoryStore[productId]) {
            then(inventoryStore[productId]);
        } else {
            self.loadInventory(productId, then);
        }
    };

    /**
     * This function will retrieve a set of product inventories from the API endpoint and then save them in the
     * local store.
     * @param productIdArray - contains a set of Product IDs from the cart
     * @param then - the callback function to return the inventory after it has been saved
     */
    self.loadCartInventory = function(productIdArray, then) {
        api.getCartInventory({ product_ids: productIdArray }, function(_inventory) {

            // loop through the returned inventory and save each product separately.
            // The point of saving products separately is that they can be retrieved separately as well.
            for (var i = 0; i < productIdArray.length; i++) {
                inventoryStore[productIdArray[i]] = _inventory[productIdArray[i]];
                // Save for 15 minutes unless debug mode is on
                storage.setItem('InventoryManager.product.' + productIdArray[i], _inventory[productIdArray[i]], opts.debugMode ? 1 : 1000*60*15);
            }

            then(_inventory);
        });
    };

    /**
     * This function will attempt to return product Inventories that are saved locally. If any products are not
     * available in local storage, this function will call loadCartInventory to read the inventory using the API
     * @param productIdArray - contains a set of Product IDs from the cart
     * @param then - the callback function to return the inventory after it has been retrieved
     */
    self.getCartInventory = function(productIdArray, then) {
        var cartInventory = {};
        var missingProductIds = [];

        // go through the items and 
        for (var i = 0; i < productIdArray.length; i++) {
            var inventory = storage.getItem('InventoryManager.product.' + productIdArray[i]);

            if (inventory) {
                cartInventory[productIdArray[i]] = inventory;
            } else if (inventoryStore[productIdArray[i]]) {
                cartInventory[productIdArray[i]] = inventoryStore[productIdArray[i]]
            } else {
                missingProductIds.push(productIdArray[i]);
            }
        }

        if (missingProductIds.length > 0) {
            self.loadCartInventory( missingProductIds, function(_inventory) {
                for (var i = 0; i < missingProductIds.length; i++) {
                    cartInventory[missingProductIds[i]] = _inventory[missingProductIds[i]]
                }

                then(cartInventory);
            });
        } else {
            then(cartInventory);
        }
    };

    init();
};
