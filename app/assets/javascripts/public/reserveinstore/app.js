var ReserveInStore = ReserveInStore || {};
ReserveInStore.App = function(opts) {
    this.version = '1.1.1.0'; // Version of the JS library.
    var self = this;
    opts = opts || {};

    var config, api, storage, product, variant, reserveModal, chooselocationModal, variantLoader;

    var btn, locationsManager;

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
        "init": []
    };

    var init = function () {
        self.debugMode = opts.debugMode;
        ReserveInStore.logger = new ReserveInStore.Logger(opts);

        ReserveInStore.Util.waitFor$(function jqueryWaitingFunction() {
            api = new ReserveInStore.Api(opts);
            storage = new ReserveInStore.LocalStorage(opts);

            if (window.location.toString().indexOf('clear_cache') !== -1) {
                storage.clear();
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
            app: self
        };

        variantLoader = new ReserveInStore.VariantLoader(componentOpts);

        locationsManager = new ReserveInStore.LocationsManager(componentOpts);
        componentOpts.locationsManager = locationsManager;

        reserveModal = new ReserveInStore.ReserveModal(componentOpts);
        chooselocationModal = new ReserveInStore.ChooseLocationModal(componentOpts);

        btn = new ReserveInStore.ReserveBtn({
            config: config.reserve_product_btn || {},
            onClick: self.showReserveModal,
            app: self
        });

        btn = new ReserveInStore.StockStatusIndicator({
            config: config.stock_status || {},
            onLocationClick: function(e) {
                self.showChooseLocationModal()
            },
            api: api,
            product: product,
            variant: variant,
            app: self
        });
    };

    self.showChooseLocationModal = function(e) {
        if (typeof e !== 'undefined' && e.constructor === Event) {
            e.preventDefault();
        }
        chooselocationModal.show();
    };

    self.showReserveModal = function() {
        reserveModal.show();
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

        ReserveInStore.logger.log("Loaded product: ", product)
    };

    self.setVariant = function(_variant) {
        var original = variant;

        variant = _variant;

        if (original && original !== variant) {
            self.trigger('variant.change', { old: original, new: variant, original: original });
        }

        ReserveInStore.logger.log("Loaded variant: ", variant)
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

    self.trigger = function(codes, data) {
        codes = codes.split(' ');

        for (var ci = 0; ci < codes.length; ci++) {
            var code = codes[ci];

            var listeners = eventListeners[code] || [];

            ReserveInStore.logger.log("Event triggered ", code, data, listeners);

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

            ReserveInStore.logger.log("Event listener attached", eventCode, callback);

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
            self.setProduct(object.data || object.product)
        } else if (object.action === "showChooseLocationModal") {
            self.showChooseLocationModal()
        } else if (object.action === "showReserveModal") {
            self.showReserveModal()
        } else if (object.action === "on") {
            self.on(object.data.event, object.data.callback)
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
