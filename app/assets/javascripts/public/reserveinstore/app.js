var ReserveInStore = ReserveInStore || {};
ReserveInStore.App = function(opts) {
    this.version = '1.1.0.0'; // Version of the JS library.
    var self = this;
    opts = opts || {};

    var config, api, product, reserveModal, chooselocationModal;

    var btn;

    var init = function () {
        ReserveInStore.logger = new ReserveInStore.Logger(opts);
        api = new ReserveInStore.Api(opts);

        ReserveInStore.Util.waitFor$(function jqueryWaitingFunction() {
            loadPushBuffer();

            api.waitForApiConfig(function waitForApi() {
                if (!api.checkConfig()) {
                    return; // Skip setup because config is invalid.
                }

                load();
            });
        });
    };

    var load = function() {
        reserveModal = new ReserveInStore.ReservationCreator({ api: api, product: product });
        chooselocationModal = new ReserveInStore.ChooseLocationModal({ api: api, product: product });

        btn = new ReserveInStore.ReserveBtn({ config: config.reserve_product_btn || {} });
    };

    self.showChooseLocationModal = function() {
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
        product = _product;
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
