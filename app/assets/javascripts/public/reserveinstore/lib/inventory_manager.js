ReserveInStore.InventoryManager = function (opts) {
    var self = this;
    opts = opts || {};
    var api = opts.api,
        storage = opts.storage;
    var inventoryLoaded = {};


    self.updateInventory = function(productId) {
        if (!inventoryLoaded[productId]) {
            api.getInventory({ product_id: productId }, function(_inventory) {
                storage.setItem('InventoryManager.inventory.' + productId, _inventory, opts.debugMode ? 1 : 1000*60*15); // Save for 15 minutes unless debug mode is on
                inventoryLoaded[productId] = true;
            });
        }
    };

    self.getInventory = function(productId) {
        if (!inventoryLoaded[productId]) {
            self.updateInventory(productId);
        }
        return storage.getItem('InventoryManager.inventory.' + productId);
    };
};
