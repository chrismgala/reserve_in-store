var ReserveInStore = ReserveInStore || {};
ReserveInStore.App = function(opts) {
    this.version = '0.1.0.0'; // Version of the JS library.
    var self = this;
    opts = opts || {};

    var init = function () {

        waitFor$(function jqueryWaitingFunction() {
            loadPushBuffer();

            addReserveInStoreButton();
        });
    };

    /**
     * Add the reserve-in-store button
     */
    var addReserveInStoreButton = function() {
        // detect the add to cart button
        var $addToCartBtns = $('form[action~="/cart/add"] button[type=submit],form[action~="/cart/add"] input[type=submit],.product-form__cart-submit,.add-to-cart, .addToCart, #addToCart, #add-to-cart, .add-to-cart input.button');

        $addToCartBtns.each(function() {
            var $addToCartBtn = $(this);

            if ($addToCartBtn.parent().find('[data-reserveInStoreBtn=true]').length <= 0 ){
                $addToCartBtn.after('<div class="reserveInStore-btn-container" data-reserveInStoreBtn="true"><button class="btn reserveInStore-btn"><span>Reserve In Store</span></button></div>');
                opts.$modalContainer = $('<div class="reserveInStore-modal-container" style="display:none;"></div>').appendTo('body');
            }

            var reservationCreator = new ReserveInStore.ReservationCreator(opts);

            var $reserveBtnContainer = $addToCartBtn.parent().find('.reserveInStore-btn-container');

            setButtonWidth($reserveBtnContainer.find('.reserveInStore-btn'), $addToCartBtn);

            $reserveBtnContainer.on('click', function(event) {
                event.preventDefault();
                reservationCreator.displayModal();
                return false;
            });
        });
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
            opts.storePublicKey = object.data.store_pk;
            opts.apiUrl = object.data.api_url;
        } else if (object.action == "setProduct") {
            // Data should be:  { product: {id: 123, name: "bleh", ...} }
            opts.product = object.data;
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
