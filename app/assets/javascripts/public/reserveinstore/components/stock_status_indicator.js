ReserveInStore.StockStatusIndicator = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config, component, inventoryTable;
    var api = opts.api;

    var currentLocation, onlyAvailableOnline = false, ready = false;

    var DEFAULT_STOCK_CAPTIONS = ["Out of Stock", "Low Stock", "In Stock", "Stock Unknown"];

    var DEFAULT_SELECTOR = '.reserveInStore-btn-container';
    var DEFAULT_ACTION = 'insert_before';
    var DEFAULT_TPL = '<div class="reserveInStore-stockStatus">' +
        '<div class="reserveInStore-stockStatus-location">' +
        '<span class="reserveInStore-stockStatus-status">In Stock</span> @' +
        '<a href="#" onclick="window.reserveInStore.showChooseLocationModal(); return false;" ' +
        'class="reserveInStore-stockStatus-locationName">store location</a>' +
        '</div>' +
        '</div>';

    var init = function () {
        config = opts.config || {};

        component = new ReserveInStore.IntegratedComponent({
            dataKey: 'reserveInStore-stockStatus',
            defaults: {
                tpl: DEFAULT_TPL,
                action: DEFAULT_ACTION,
                selector: DEFAULT_SELECTOR
            },
            visibleInitially: false,
            config: config,
            afterInsert: function(){}
        });
        afterInsert();
    };

    self.whenReady = function(then) {
        var readyCheck = function() {
            if (ready) {
                clearInterval(readyWaiter);
                then();
            }
        };
        var readyWaiter = setInterval(readyCheck, 1);
        readyCheck();
    };

    var afterInsert = function($container, $target) {
        updateInventoryTables(function() {
            opts.app.getLocation(function (bestLocation, favoriteLocation) {
                if (favoriteLocation || (!config.behavior_when || config.behavior_when.no_location_selected !== 'hide')) {
                    currentLocation = bestLocation;
                }
                updateDisplay();

                opts.app.on('variant.change', updateDisplay);
                opts.app.on('location.change', function(data) {
                    currentLocation = data.new;
                    updateDisplay();
                });
                opts.app.on('product.change', function() {
                    updateInventoryTables(updateDisplay);
                });
            });
        });
    };

    var updateInventoryTables = function(then) {
        api.getInventory({ product_id: opts.app.getProduct().id }, function(_inventoryTable) {
            inventoryTable = _inventoryTable;

            if (then) then();
        });
    };


    var useFirstAvailableLocation = function() {
        if (currentLocation) return;
        var inventoryLocations = inventoryTable[opts.app.getVariant().id];

        opts.app.getLocations(function(locations) {
            // First try to find a location with full stock
            for (var i = 0; i < locations.length; i++) {
                if (inventoryLocations[locations[i].platform_location_id] === 'in_stock') {
                    currentLocation = locations[i];
                    return;
                }
            }

            // Next try to find a location with any stock
            for (var i = 0; i < locations.length; i++) {
                if (inventoryLocations[locations[i].platform_location_id] === 'low_stock') {
                    currentLocation = locations[i];
                    return;
                }
            }

            // Next try to find a location with any stock
            for (var i = 0; i < locations.length; i++) {
                currentLocation = locations[i];
                onlyAvailableOnline = true;
                return;
            }
        });

        if (currentLocation || onlyAvailableOnline) {
            updateDisplay();
        }
    };

    var updateDisplay = function() {
        var variant = opts.app.getVariant();
        var inventoryLocations = inventoryTable[variant.id];
        var inventoryStatus;

        var $location = component.find('.reserveInStore-stockStatus-locationName');

        if (onlyAvailableOnline) {
            ReserveInStore.logger.log("Seems to only be available online...", config);
            if (config.behavior_when && !config.behavior_when.show_when_only_available_online) {
                component.hide();
                return;
            }
        }

        if (!currentLocation) {
            if (config.behavior_when && config.behavior_when.no_nearby_locations_and_no_location === 'show_first_available') {
                return useFirstAvailableLocation();
            }

            // Don't show
            ReserveInStore.logger.log("Could not determine best location using geolocating or selection.", self);
            return;
        }

        inventoryStatus = inventoryLocations[currentLocation.platform_location_id];

        if (!inventoryStatus) {
            if (config.behavior_when && config.behavior_when.stock_unknown.indexOf('in_stock') === 0) {
                inventoryStatus = "in_stock";
            } else {
                inventoryStatus = "stock_unknown";
            }
        }


        showStockStatus(inventoryStatus);
        $location.text(currentLocation.name);
        component.show();

        opts.app.setStockStatus(inventoryStatus);

        ready = true;
    };

    var showStockStatus = function(status) {
        var $stockStatus = component.find('.reserveInStore-stockStatus-status');

        $stockStatus.removeClass('reserveInStore-stockStatus-status--outOfStock');
        $stockStatus.removeClass('reserveInStore-stockStatus-status--lowStock');
        $stockStatus.removeClass('reserveInStore-stockStatus-status--inStock');

        var stockCaptions = [];
        var customCaptions = $stockStatus.data('reserveinstore-stockcaptions');
        if (customCaptions) {
            stockCaptions = customCaptions.split('|');
        }

        if (status === 'low_stock') {
            $stockStatus.text(stockCaptions[1] || DEFAULT_STOCK_CAPTIONS[1]);
            $stockStatus.addClass('reserveInStore-stockStatus-status--lowStock')
        } else if (status === 'out_of_stock') {
            $stockStatus.text(stockCaptions[0] || DEFAULT_STOCK_CAPTIONS[0]);
            $stockStatus.addClass('reserveInStore-stockStatus-status--outOfStock')
        } else if (status === 'in_stock') {
            $stockStatus.text(stockCaptions[2] || DEFAULT_STOCK_CAPTIONS[2]);
            $stockStatus.addClass('reserveInStore-stockStatus-status--inStock')
        } else {
            $stockStatus.text(stockCaptions[3] || DEFAULT_STOCK_CAPTIONS[3]);
            $stockStatus.addClass('reserveInStore-stockStatus-status--unknownStock')
        }

        opts.app.trigger('stock_status.change')
    };

    init();
};
