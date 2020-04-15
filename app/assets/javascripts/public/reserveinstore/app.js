var ReserveInStore = ReserveInStore || {};
ReserveInStore.App = function(opts) {
    this.version = '1.2.4.3'; // Version of the JS library.
    var self = this;
    opts = opts || {};
    opts.app = self;
    self.opts = opts;

    var config, api, storage;
    var product, variant, cart, stockStatus;
    var reserveModal, chooselocationModal, variantLoader;
    var locationsManager, inventoryManager;
    var reserveProductBtn, reserveCartBtn, stockStatusIndicator;

    var eventListeners = {
        "reserve_modal.show": [],
        "reserve_modal.open": [],
        "reserve_modal.create": [],
        "reserve_modal.submit": [],
        "reserve_modal.close": [],
        "reserve_modal.hide": [],
        "choose_location_modal.show": [],
        "choose_location_modal.open": [],
        "choose_location_modal.create": [],
        "choose_location_modal.close": [],
        "choose_location_modal.hide": [],
        "variant.change": [],
        "product.change": [],
        "location.change": [],
        "stock_status.change": [],
        "init": []
    };

    var init = function () {
        self.debugMode = opts.debugMode || (window.location.toString().indexOf('ris_debug=1') !== -1);
        ReserveInStore.logger = new ReserveInStore.Logger(opts);

        if (self.debugMode) {
            ReserveInStore.logger.log("Loaded version " + self.version)
        }

        ReserveInStore.Util.waitFor$(function jqueryWaitingFunction() {
            api = new ReserveInStore.Api(opts);
            storage = new ReserveInStore.LocalStorage(opts);

            if (window.location.toString().indexOf('clear_cache') !== -1) {
                self.clearCache();
            }

            loadPushBuffer();

            api.waitForApiConfig(function waitForApi() {
                if (!api.checkConfig()) {
                    return; // Skip setup because config is invalid.
                }

                load();

                self.trigger('init', self);
            });
        });
    };

    var load = function() {
        var componentOpts = {
            api: api,
            storage: storage,
            app: self,
            config: config || {}
        };

        variantLoader = new ReserveInStore.VariantLoader(componentOpts);

        locationsManager = new ReserveInStore.LocationsManager(componentOpts);
        componentOpts.locationsManager = locationsManager;

        inventoryManager = new ReserveInStore.InventoryManager(componentOpts);
        componentOpts.inventoryManager = inventoryManager;

        reserveModal = new ReserveInStore.ReserveModal(componentOpts);
        chooselocationModal = new ReserveInStore.ChooseLocationModal(componentOpts);

        if (product) {
            reserveProductBtn = new ReserveInStore.ReserveProductBtn({
                config: config || {},
                onClick: self.showReserveModal,
                app: self
            });

            stockStatusIndicator = new ReserveInStore.StockStatusIndicator({
                config: config.stock_status || {},
                api: api,
                product: product,
                variant: variant,
                app: self
            });
        }

        reserveCartBtn = new ReserveInStore.ReserveCartBtn({
            config: config.reserve_cart_btn || {},
            onClick: self.showReserveModal,
            app: self
        });

    };

    self.clearCache = function() {
        storage.clear();
    };

    self.showChooseLocationModal = function(e) {
        if (typeof e !== 'undefined' && e.constructor === Event) {
            e.preventDefault();
        }
        chooselocationModal.show.apply(chooselocationModal, arguments);

        return false;
    };

    self.showReserveModal = function() {
        if (typeof e !== 'undefined' && e.constructor === Event) {
            e.preventDefault();
        }
        reserveModal.show.apply(reserveModal, arguments);
    };

    self.configure = function(_config) {
        config = _config;
        api.configure({ storePublicKey: _config.store_pk, apiUrl: _config.api_url });
    };

    self.setProduct = function(_product) {
        var original = product;

        product = _product;

        if (original !== variant) {
            self.trigger('product.change', { old: original, new: variant, original: original });
        }

        // ReserveInStore.logger.log("Set product: ", product)
    };

    self.getStockStatus = function(callback) {
        if (!stockStatusIndicator) {
            return callback(null);
        }
        return stockStatusIndicator.whenReady(function() {
            callback(stockStatus);
        });
    };

    self.setStockStatus = function(_stockStatus) {
        var original = stockStatus;

        stockStatus = _stockStatus;

        if (original && original !== stockStatus) {
            self.trigger('stock_status.change', { old: original, new: stockStatus, original: original });
        }
    };

    self.setVariant = function(_variant) {
        var original = variant;

        variant = _variant;

        if (original && original !== variant) {
            self.trigger('variant.change', { old: original, new: variant, original: original });
        }

        // ReserveInStore.logger.log("Set variant: ", variant)
    };

    self.setCart = function(_cart) {
        cart = _cart;

        ReserveInStore.logger.log("Set cart: ", cart)
    };

    self.getLocation = function(callback) {
        return locationsManager.whenReady(callback);
    };

    self.getLocations = function(callback) {
        return locationsManager.whenReady(function() {
            callback(locationsManager.getLocations())
        });
    };

    self.getProduct = function() { return product; };
    self.getVariant = function() { return variant; };
    self.getCart = function() { return cart; };

    self.getProductTag = function() {
        var prod = opts.app.getProduct();
        if (!prod) return '';
        storage.setItem('ProductTags.' + prod.id, prod.tags);
        return prod.tags;
    };
    
    self.getCartItemsProdTagArray = function(callback) {
        var cart = opts.app.getCart();
        var cartItems = cart.items;
        var cartItemsProdTagArray = [];
        var loopCount = 0;
        
        if ((!cart) || (cartItems.length == 0)) callback('');

        self.getCartItemProductTag(function(productTag) {
            loopCount = loopCount + 1;
            cartItemsProdTagArray = cartItemsProdTagArray.concat(productTag);
            if (loopCount == cartItems.length) {
                callback(cartItemsProdTagArray);
            }    
        });    
    };

    self.getCartItemProductTag = function(callback) {
        var cart = opts.app.getCart();
        var cartItems = cart.items;
        
        if ((!cart) || (cartItems.length == 0)) callback('');
        
        for (var i = 0; i < cartItems.length; i++) {
            (function(i) {
                if (storage.getItem('ProductTags.' + cartItems[i].product_id)) {
                    callback(storage.getItem('ProductTags.' + cartItems[i].product_id));
                } else {
                    var cartItemUrl = cartItems[i].url.substring(0, cartItems[i].url.indexOf('?'));
                    $.getJSON(cartItemUrl + ".js", function(product) {
                        storage.setItem('ProductTags.' + product.id, product.tags);
                        callback(product.tags);
                    });
                }
            })(i);
        }
    };

    self.trigger = function(codes, data) {
        codes = codes.split(' ');

        for (var ci = 0; ci < codes.length; ci++) {
            var code = codes[ci];

            var listeners = eventListeners[code] || [];

            // ReserveInStore.logger.log("Event triggered ", code, data, listeners);

            for (var i = 0; i < listeners.length; i++) {
                listeners[i](data);
            }
        }
    };

    self.on = function(eventCodes, callback) {
        eventCodes = eventCodes.split(' ');
        for (var i = 0; i < eventCodes.length; i++) {
            var eventCode = eventCodes[i].trim();
            if (!eventListeners[eventCode]) {
                var validEventCodes = Object.keys(eventListeners).join(", ");
                throw "Invalid event code requested: '"+eventCode+"'. Valid event codes are: " + validEventCodes;
            }

            // ReserveInStore.logger.log("Event listener attached", eventCode, callback);

            eventListeners[eventCode].push(callback);
        }
    };


    /**
     * Run a method safely
     * Even if ReserveInSdtore.App has not yet loaded it will queue up the command
     * Also it will catch any errors and only throw them back up if debug mode is not enabled
     * @param method {string} action you want to run on the class
     * @param data {object} parameter data you want to pass to the method
     */
    self.push = function(method, data) {
        if (opts.debugMode) {
            return _push(method, data);
        } else {
            try {
                return _push(method, data);
            } catch(e) {
                if (window.console && !Fera.Util.ie()) window.console.error(e);
            }
        }
    };


    /**
     * Runs a method on the app using the push.
     * @see self.push
     * @param method {string} action you want to run on the class
     * @param data {object} parameter data you want to pass to the method
     * @private
     */
    var _push = function(method, data) {
        var object;
        if (typeof method === 'object') {
            object = method;
        } else {
            object = {
                action: method,
                data: data,
                callback: typeof data === 'object' ? data.callback : undefined
            };
        }

        if (object.action === "configure") {
            self.configure(object.data);
        } else if (object.action === "setProduct") {
            self.setProduct(object.data || object.product);
        } else if (object.action === "setCart") {
            self.setCart(object.data || object.cart);
        } else if (object.action === "showChooseLocationModal") {
            self.showChooseLocationModal()
        } else if (object.action === "showReserveModal") {
            self.showReserveModal();
        } else if (object.action === "on") {
            self.on(object.data.event, object.data.callback);
        } else {
            ReserveInStore.logger.error("Unknown action: ", object.action);
        }
    };


    /**
     * Loads from the fera.push buffer of actions and data.
     *
     * @param filters.except {string} - (optional) if specified, will exclude all actions from the push buffer that match the specified
     * @param filters.only {string} - (optional) if specified, will ONLY include actions from the push buffer that match the specified
     */
    var loadPushBuffer = function(filters) {
        filters = filters || {};
        var hasExclusions = typeof filters.except !== 'undefined' && filters.except;
        var hasInclusions = typeof filters.only !== 'undefined' && filters.only;

        opts.pushBuffer = opts.pushBuffer || [];
        if (typeof opts.pushBuffer === "object" && opts.pushBuffer.length && opts.pushBuffer.length > 0) {
            var skipNext = false;
            for (var i = 0; i< opts.pushBuffer.length; i++) {
                if (skipNext) {
                    skipNext = false;
                    continue;
                }

                var nextItem = opts.pushBuffer[i];
                if (hasExclusions) {
                    var shouldSkip = false;
                    for(var q=0; q<filters.except.length; q++) {
                        if (nextItem.action === filters.except[q]) {
                            shouldSkip = true;
                            break;
                        }
                    }
                    if (shouldSkip) continue;
                }
                if (hasInclusions && nextItem.action !== filters.only) continue;

                if (typeof nextItem === 'string') {
                    self.push(nextItem, opts.pushBuffer[i+1]);
                    skipNext = true;
                } else {
                    self.push(nextItem);
                }
            }
        }
    };

    init();
};
