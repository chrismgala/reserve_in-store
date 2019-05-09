var ReserveInStore = ReserveInStore || {};
ReserveInStore.App = function(opts) {
    this.version = '1.1.0.0'; // Version of the JS library.
    var self = this;
    opts = opts || {};

    var config, api, product, reserveModal, chooselocationModal;

    var DEFAULT_BTN_SELECTOR = 'form[action~="/cart/add"]';
    var DEFAULT_BTN_ACTION = 'insert_after';
    var DEFAULT_BTN_TPL = '<div class="reserveInStore-btn-container" data-reserveInStoreBtn="true"><button class="btn reserveInStore-btn"><span>Reserve In Store</span></button></div>';

    var init = function () {
        ReserveInStore.logger = new ReserveInStore.Logger(opts);
        api = new ReserveInStore.Api(opts);

        waitFor$(function jqueryWaitingFunction() {
            loadPushBuffer();

            api.waitForApiConfig(function waitForApi() {
                if (!api.checkConfig()) {
                    return; // Skip setup because config is invalid.
                }

                reserveModal = new ReserveInStore.ReservationCreator({ api: api, product: product });
                chooselocationModal = new ReserveInStore.ChooseLocationModal({ api: api, product: product });

                addReserveInStoreButton();
            });
        });
    };

    /**
     * Add the reserve-in-store button
     */
    var addReserveInStoreButton = function() {
        // detect the add to cart button
        var btnSelector, btnAction, btnTpl;

        if (config.reserve_product_btn && config.reserve_product_btn.action) {
            btnAction = config.reserve_product_btn.action;
        } else {
            btnAction = DEFAULT_BTN_ACTION;
        }

        if (btnAction === 'manual') {
            // Don't try to integrate
        } else if (btnAction === 'auto') {
            insertBtn(DEFAULT_BTN_SELECTOR, DEFAULT_BTN_ACTION);
        } else {
            btnSelector = (config.reserve_product_btn && config.reserve_product_btn.selector) ? config.reserve_product_btn.selector : DEFAULT_BTN_SELECTOR;
            insertBtn(btnSelector, btnAction);
        }
    };

    var insertBtn = function(targetSelector, orientation) {
        var $targets = $(targetSelector);
        var $btnContainer = $((config.reserve_product_btn && config.reserve_product_btn.tpl) ? config.reserve_product_btn.tpl : DEFAULT_BTN_TPL);

        $targets.each(function() {
            var $target = $(this);

            if (!$target.next().data('reserveInStoreBtn')) {
                if (orientation === 'prepend_to') {
                    $target.prepend($btnContainer);
                } else if (orientation === 'append_to') {
                    $target.append($btnContainer);
                } else if (orientation === 'insert_before') {
                    $target.before($btnContainer);
                } else if (orientation === 'insert_after') {
                    $target.after($btnContainer);
                } else { // Manual
                    ReserveInStore.logger.error("Invalid insertion criteria: ", targetSelector, orientation, config);
                    return false;
                }
            }

            var $reserveBtn = $btnContainer.find('.reserveInStore-btn');

            if ($reserveBtn.hasClass('reserveInStore-btn--block')) setButtonWidth($reserveBtn, $target);

            $btnContainer.on('click', function(event) {
                event.preventDefault();
                self.showReserveModal();
                return false;
            });
        });
    };


    self.showChooseLocationModal = function() {
        chooselocationModal.show();
    };

    self.showReserveModal = function() {
        reserveModal.show();
    };

    /**
     * Run a method safely
     * Even if ReserveInStore.App has not yet loaded it will queue up the command
     * Also it will catch any errors and only throw them back up if debug mode is not enabled
     * @param object {object} set object.action to the action you want to run on the class
     */
    self.push = function(object) {
        if (opts.debugMode) {
            return _push(object);
        } else {
            try {
                return _push(object);
            } catch(e) {
                if (console) console.error(e);
            }
        }
    };


     /**
     * Runs a method on the app using the push.
     * @see self.push
     * @param object {object} set object.action to the action you want to run on the class
     * @private
     */
    var _push = function(object) {
        var _callback = typeof object.callback === 'function' ? object.callback : (function() {});

        if (object.action == "configure") {
            // Data should be:  { store_pk: \"#{public_key}\", api_url: \"#{ENV['BASE_APP_URL']}\" }
            config = object.data;
            api.configure({ storePublicKey: object.data.store_pk, apiUrl: object.data.api_url });
        } else if (object.action == "setProduct") {
            // Data should be:  { product: {id: 123, name: "bleh", ...} }
            product = object.data;
        } else {
            console.error("Unknown action: ", object.action);
        }
    };


    var waitFor$ = function(callback) {
        if (window.jQuery || window.Zepto || window.$) return callback();

        var waitSoFar = 0, checkInterval = 10, warningThreshold = 100, loadingZepto = false;

        var jqTimer = setInterval(function() {
            if (window.jQuery || window.Zepto || window.$) {
                clearInterval(jqTimer);
                callback();
            }
            waitSoFar += checkInterval;

            if (waitSoFar == warningThreshold) {
                if (!loadingZepto) {
                    warningThreshold += 1000; // Give it another 60 seconds to load zepto from the CDN
                    ReserveInStore.Util.addZepto(opts);
                    loadingZepto = true;
                } else {
                    clearInterval(jqTimer);
                    throw "Reserve In-Store requires jQuery or Zepto and neither or found or able to be dynamically loaded.";
                }
            }
        }, checkInterval);
    };

    var loadPushBuffer = function() {
        if (typeof opts.pushBuffer === "object") {
            for (var i = 0; i< opts.pushBuffer.length; i++) {
                self.push(opts.pushBuffer[i]);
            }
        }
    };

    /**
     * Set the Reserve In-Store button's width to be the greater of Add To Cart button's width and its default value
     */
    var setButtonWidth = function(reserveBtn, addToCartBtn) {
        var addToCartBtnWidth = parseInt(addToCartBtn.css("width"));
        if (parseInt(reserveBtn.css("width")) < addToCartBtnWidth){
            reserveBtn.css("width", addToCartBtnWidth + "px");
        }
    };


    init();
};
