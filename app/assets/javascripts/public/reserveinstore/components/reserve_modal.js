ReserveInStore.ReserveModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();
    var api, config, $modalBackground, $reserveModal, $successModal, $form, $clearSearchLink, formDataArray;

    var locationsManager = opts.locationsManager;
    var inventoryManager = opts.inventoryManager;
    var showReserveBtnWhenUnknown = false;
    var inStockTextWhenUnknown = false;
    var discountCode;
    var checkoutWithoutClearingCart;
    var customReservationId = opts.api.generateUniqueUUID();

    // inventoryData and stockData is a 3-level nested hash that contains data pertaining to product stock by location,
    // the fields should look like this:
    // * product id: key for the 1st level of the hash
    //        * variant_id: key for the 2nd level of the hash
    //                 * location_id: key for the 3rd level of the hash
    //                 * stock value: value for the 3rd level of the hash. This data is what we are ultimately after
    // { product_id_1: {variant_id_1: {location_1: stock_value_1, location_2:
    var inventoryData = {};
    var stockData = {};

    var DEFAULT_STOCK_CAPTIONS = ["No Stock", "Low Stock", "In Stock", " out of ", " items available", "stock unknown", "available"];

    // check stores_helper for existing key name used
    var DEFAULT_STOCK_CAPTIONS_KEY = ["no_stock", "low_stock", "in_stock", " out of ", "x_items_available", "stock_unknown", "all_items_available"];

    // setting this default value for old stores because without reinstalling footer script labels will not be visible
    var DEFAULT_STOCK_STATUS_LABEL_VISIBLE = {
        in_reserve_modal_product_page_locations: ["in_stock", "low_stock", "no_stock", "stock_unknown"],
        in_reserve_modal_cart_page_locations: ["x_items_available", "no_stock"],
        in_reserve_modal_cart_items: ["in_stock", "low_stock", "no_stock", "stock_unknown"],
        in_choose_location_modal_product_page: ["in_stock", "low_stock", "no_stock", "stock_unknown"]
    };

    var product, variant, cart, lineItem = {};

    var reservationFormFieldPair = {};

    var storeStockLabelsToDisplay = {};

    var init = function () {
        api = opts.api;
        config = opts.config || {};
        showReserveBtnWhenUnknown = config.stock_status.behavior_when && config.stock_status.behavior_when.stock_unknown.indexOf('show_button') !== -1;
        inStockTextWhenUnknown = config.stock_status.behavior_when && config.stock_status.behavior_when.stock_unknown.indexOf('in_stock') !== -1;
        storeStockLabelsToDisplay = config.stock_status.stock_label || DEFAULT_STOCK_STATUS_LABEL_VISIBLE;
        checkoutWithoutClearingCart = config.checkout_without_clearing_cart;
        updateCartOnAjax();
    };

    /**
     * Get product id/title and variant id/title, then make API call and display the modal
     */
    self.show = function () {
        if (arguments.length === 2) {
            if (typeof arguments[0] === 'object') {
                product = arguments[0];
            } else {
                throw "Invalid arguments provided to new reservation modal. See docs.reserveinstore.com";
            }
            if (typeof arguments[1] === 'object') {
                variant = arguments[1];
            } else {
                throw "Invalid arguments provided to new reservation modal. See docs.reserveinstore.com";
            }
        } else if (arguments.length === 1) {
            if (typeof arguments[0] === 'object') {
                if (typeof arguments[0].length !== 'undefined') {
                    cart = { items: arguments[1] };
                } else {
                    cart = arguments[1];
                }
            } else {
                throw "Invalid arguments provided to new reservation modal. See docs.reserveinstore.com";
            }
        } else {
            if (opts.app.getProduct()) {
                product = opts.app.getProduct();
                variant = opts.app.getVariant();
            } else if (opts.app.getCart()) {
                cart = opts.app.getCart();
            } else {
                throw "Could not detect what is being reserved, likely due to bad API usage. See docs.reserveinstore.com";
            }
        }

        self.$modalContainer = $('#reserveInStore-reserveModalContainer');
        if (self.$modalContainer.length < 1) {
            self.$modalContainer = $('<div class="reserveInStore-modal-container" id="reserveInStore-reserveModalContainer" style="display:none;"></div>').appendTo('body');
        }

        if (opts.app.getProduct()) {
            var modalParams = { cart: getCartObject() };
            api.getReservationModal(modalParams, locationsManager.getLocationProductParams(), function(response) {
                self.insertModal(response.content);
            });
        } else {
            opts.app.cart.getAjaxData(function(cartData) {
                cart = cartData;
                var modalParams = { cart: getCartObject() };
                opts.app.cart.getProductTags(function(tags) {
                    api.getReservationModal(modalParams, { product_tag_filter: tags, current_page: "cart" }, function(response) {
                        self.insertModal(response.content);
                    });
                });
            });
        }

        opts.app.trigger('reserve_modal.show reserve_modal.open', self);
    };


    /**
     * will remove later after some test
     * @deprecated in favor of #opts.app.cart.getAjaxData(function(cartData)
     */
    var updateCartOnAjax = function() {
        $(document).on('ajaxComplete', function( event, xhr, settings ) {
            if (xhr.status >= 300) return; // Bad ajax request, don't do anything

            if (settings && settings.url.indexOf('/cart.js') !== -1) {
                // nothing to do for now
            } else if (settings && /\/cart\/(add|update|clear|change)/.test(settings.url)) {
                opts.app.setCart(JSON.parse(xhr.responseText));
            }
        });
    };

    var getCartObject = function() {
        var _cart = {}, item;

        if (product && variant) {
            // product mode
            item = {
                product_title: product.title,
                variant_title: variant.title,
                product_id: product.id,
                variant_id: variant.id,
                total: variant.price,
                variant: variant,
                product: product
            };
            item.price = item.total;

            _cart = { items: [item] };

            // ReserveInStore.logger.info("Sending via PRODUCT mode", items);
        } else if(cart) {
            _cart = $.extend({}, cart);

            for (var i = 0; i < _cart.items.length; i++) {
                _cart.items[i].total = _cart.items[i].line_price;
                _cart.items[i].price = _cart.items[i].line_price;
            }

            ReserveInStore.logger.info("Sending via CART mode", _cart);
        } else {
            ReserveInStore.logger.logWarning("Could not determine cart object.", self);
        }

        return _cart
    };

    /**
     * Set Product Id, Variant Id and line item properties object, return product title, variant title, line item properties and price to be used in modal
     * @deprecated in favor of #getCartObject()
     * @returns {object} Product title, variant title and price, in the form of {product_title: "bleh", variant_title: "bleh", price: "bleh"}
     */
    var getLegacyModalParams = function () {
        loadLineItem();
        return {
            product_title: product.title,
            variant_title: variant.title,
            price: variant.price,
            line_item: lineItem
        };
    };

    /**
     * Set line item properties
     * @deprecated in favor of #getCartObject()
     */
    var loadLineItem = function () {
        var re_lineItem = /properties\[(.*?)\]/;
        formDataArray = $('form[action~="/cart/add"]').serializeArray();

        formDataArray.find(function (obj) {
            var matchLineItem = obj.name.match(re_lineItem);
            if (matchLineItem) {
                lineItem[matchLineItem[1]] = obj.value;
            }
        });
    };

    /**
     * Insert the HTML code of two modals into the container:
     * $reserveModal is for creating new reservation, collecting customer's information
     * $successModal is to be displayed after new reservation is created
     * @param modalHTML {string} the HTML code of two modals
     */
    self.insertModal = function (modalHTML) {
        self.$modalContainer.html(modalHTML);
        ReserveInStore.Util.showWithoutTransform(self.$modalContainer);
        $modalBackground = self.$modalContainer.find('.reserveInStore-modal-background');
        $reserveModal = $modalBackground.find('.reserveInStore-reserve-modal');
        $successModal = $modalBackground.find('.reserveInStore-success-modal');
        $clearSearchLink = $reserveModal.find(".reserveInStore-locationSearch-clear");
        centerPriceDiv();
        setCloseConditions();
        inputFormValue();

        $form = $reserveModal.find(".reserveInStore-reservation-form");
        setSubmitConditions();

        self.$modalContainer.find('input[name="reservation[location_id]"]').on('click change', function() {
            var locationId = self.$modalContainer.find('input[name="reservation[location_id]"]:checked').val();
            locationsManager.setFavoriteLocationId(locationId);
            getStockInfo(locationId);
        });

        $reserveModal.find('.reserveInStore-locationSearch-btn').on('click', function(e) {
            e.preventDefault();
            var searchLocationInputValue = $reserveModal.find(".reserveInStore-locationSearch-input").val();
            $reserveModal.find(".ris-location-options").toggleClass("loading");
            opts.app.searchLocations.getSearchData(searchLocationInputValue, function(data)  {
                $reserveModal.find(".ris-location-options").html('');
                $reserveModal.find(".ris-location-options").append(opts.app.searchLocations.renderSearchHtml(data));

                if (opts.app.getProduct()) {
                    updateLocationStockInfo(data);
                } else {
                    updateCartLocationStockInfo(data);
                }
                self.$modalContainer.find('input[name="reservation[location_id]"]').on('click change', function() {
                    var locationId = self.$modalContainer.find('input[name="reservation[location_id]"]:checked').val();
                    locationsManager.setFavoriteLocationId(locationId);
                    getStockInfo(locationId);
                });

                $reserveModal.find(".ris-location-options").toggleClass("loading");

                if (searchLocationInputValue === '') {
                    $clearSearchLink.hide();
                } else {
                    $clearSearchLink.show();
                }
            });
        });

        $reserveModal.find('.reserveInStore-locationSearch-clear').on('click', function(e) {
            e.preventDefault();
            $reserveModal.find(".reserveInStore-locationSearch-input").val('');
            var searchLocationInputValue = $reserveModal.find(".reserveInStore-locationSearch-input").val();
            $reserveModal.find(".ris-location-options").toggleClass("loading");
            opts.app.searchLocations.getSearchData(searchLocationInputValue, function(data)  {
                $reserveModal.find(".ris-location-options").html('');
                $reserveModal.find(".ris-location-options").append(opts.app.searchLocations.renderSearchHtml(data));

                if (opts.app.getProduct()) {
                    updateLocationStockInfo(data);
                } else {
                    updateCartLocationStockInfo(data);
                }
                self.$modalContainer.find('input[name="reservation[location_id]"]').on('click change', function() {
                    var locationId = self.$modalContainer.find('input[name="reservation[location_id]"]:checked').val();
                    locationsManager.setFavoriteLocationId(locationId);
                    getStockInfo(locationId);
                });
                $reserveModal.find(".ris-location-options").toggleClass("loading");
                $clearSearchLink.hide();
            });
        });

        locationsManager.whenReady(function(bestLocation) {
            // make sure we have the reservation modal, location info, AND stock info before we update the display
            if (product) {
                inventoryManager.getInventory(product.id, function(_inventory) {
                    inventoryData[product.id] = _inventory;
                    updateLocationStockInfo(locationsManager.getLocations());
                    if (bestLocation) getProductStockInfo(bestLocation.id);
                });
            } else if (cart) {
                var cartItems = cart.items;
                var productIdArray = [];
                for (var i = 0; i < cartItems.length; i++) {
                    productIdArray.push(cartItems[i].product_id);
                }
                inventoryManager.getCartInventory(productIdArray, function(_inventory) {
                    inventoryData = _inventory;
                    updateCartLocationStockInfo(locationsManager.getLocations());
                    if (bestLocation) getCartItemsStockInfo(bestLocation.id);
                });
            }

            if (!bestLocation) return; // Could not determine best location

            self.$modalContainer.find('input[name="reservation[location_id]"][value="'+bestLocation.id+'"]').prop('checked', true);

        });

        adjustModalHeight();

        opts.app.trigger('reserve_modal.create', self);
    };

    self.hide = self.close = function() {
        self.$modalContainer.hide();
        opts.app.trigger('reserve_modal.close reserve_modal.hide', self);
    };

    var rememberFormInputValue = function() {
        $('.reserveInStore-reservation-form input[type="text"]').each(function() {
            if ($(this).attr("name").length > 0) {
                reservationFormFieldPair[$(this).attr("name")] = $(this).val();
            }
        });
    };

    var inputFormValue = function () {
        $('.reserveInStore-reservation-form input[type="text"]').each(function() {
            $(this).val(reservationFormFieldPair[$(this).attr("name")]);
        });
    };

    var adjustModalHeight = function() {
        var $fit = self.$modalContainer.find('.reserveInStore-modal--fitContents');
        if ($fit.length < 1) return; // No fitting needed.

        var totalHeight = 120;
        $fit.children().each(function() {
            var $el = $(this);
            totalHeight += $el.height();
            if ($el.css('padding-top')) totalHeight += parseInt($el.css('padding-top'));
            if ($el.css('padding-bottom')) totalHeight += parseInt($el.css('padding-bottom'));
            if ($el.css('margin-top')) totalHeight += parseInt($el.css('margin-top'));
            if ($el.css('margin-bottom')) totalHeight += parseInt($el.css('margin-bottom'));
        });

        $fit.css('max-height', totalHeight);
    };

    /*
     * This function will show/hide stock status label depending on store settings which stock labels store owner want to show.
     * {string} stockStatusLabelId - stock status label div id eg: '#locationStockStatus-' + locations[i].id
     * {string} stockStatusLabelClassName - which classname we need to add eg: ris-location-stockStatus-in-stock
     * {string} stockStatusLabelDefaultCaption - stock label text that we want to show eg: "No Stock", "Low Stock", "In Stock"....
     * {string} stockStatusLabelWhereToDisplay - which modal and where we want to show eg: in_reserve_modal_product_page_location
     * {string} stockStatusLabelDefaultCaptionKey - stock status label key: eg: "no_stock", "low_stock", "in_stock"....
     */
    var showHideStockStatusLabel = function (stockStatusLabelId, stockStatusLabelClassName, stockStatusLabelDefaultCaption, stockStatusLabelWhereToDisplay, stockStatusLabelDefaultCaptionKey) {
        var $stockStatusDiv = $reserveModal.find(stockStatusLabelId);
        if (storeStockLabelsToDisplay[stockStatusLabelWhereToDisplay] && storeStockLabelsToDisplay[stockStatusLabelWhereToDisplay].indexOf(stockStatusLabelDefaultCaptionKey) !== -1) {
            $stockStatusDiv.text(stockStatusLabelDefaultCaption);
            $stockStatusDiv.addClass(stockStatusLabelClassName);
        }
    };

    /**
     * This function will update the location Divs in the reserve modal with stock information.
     * @param locations - all valid locations for this store
     */
    var updateLocationStockInfo = function (locations) {
        var inventoryLocations, stockStatus;
        var $locationContainer, $locationInput, stockStatusId;

        if (!inventoryData) return;

        //get stock data for each location for the current product/variant
        if (inventoryData[product.id]) {
            inventoryLocations = inventoryData[product.id][variant.id];
        }

        if (inventoryLocations) {
            var whereToShow = 'in_reserve_modal_product_page_locations';
            // go through each location and update it with stock status
            for (var i = 0; i < locations.length; i++) {
                $locationContainer = $reserveModal.find('#risLocation-' + locations[i].id);
                $locationInput = $reserveModal.find('#reservation_location_id-' + locations[i].id);
                stockStatusId = '#locationStockStatus-' + locations[i].id;

                stockStatus = inventoryLocations[locations[i].platform_location_id];

                if (stockStatus === 'in_stock') {
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
                } else if (stockStatus === 'low_stock') {
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-low-stock', DEFAULT_STOCK_CAPTIONS[1], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[1]);
                } else if (stockStatus === 'out_of_stock') {
                    // if there is no stock, then disable the location so that it cannot be selected
                    $locationInput.prop('disabled', true);
                    $locationInput.prop('checked', false);
                    $locationContainer.addClass('ris-location-disabled');
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-no-stock', DEFAULT_STOCK_CAPTIONS[0], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[0]);
                } else {
                    if (inStockTextWhenUnknown) {
                        showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
                    } else {
                        showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-stock-unknown', DEFAULT_STOCK_CAPTIONS[5], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[5]);
                    }
                }
            }
        }

    };

    /**
     * This function has the same purpose as the previous one, only it works with cart data.
     * The process is a bit differrent, because we have to consider the stock levels of all products
     * in the cart.
     * @param locations - all valid locations for this store
     */
    var updateCartLocationStockInfo = function (locations) {
        var inventoryLocations, stockStatus;
        var $locationContainer, $locationInput, stockStatusId;

        var cartItems = cart.items;
        if (!cartItems || !inventoryData) return;

        for (var i = 0; i < locations.length; i++) {
            var stockCount = cartItems.length;
            inventoryLocations = '';

            // for each location, look at the stock levels for all cart items and determine how many of them are
            // available.
            for (var j = 0; j < cartItems.length; j++) {
                if (inventoryData[cartItems[j].product_id]) {
                    inventoryLocations = inventoryData[cartItems[j].product_id][cartItems[j].variant_id];
                }

                if (inventoryLocations !== '') {
                    stockStatus = inventoryLocations[locations[i].platform_location_id];

                    if (stockStatus === 'out_of_stock' || (!showReserveBtnWhenUnknown && stockStatus === 'unknown_stock') || (!showReserveBtnWhenUnknown && !stockStatus)) {
                        stockCount -= 1;
                    }
                }
            }

            $locationContainer = $reserveModal.find('#risLocation-' + locations[i].id);
            $locationInput = $reserveModal.find('#reservation_location_id-' + locations[i].id);
            stockStatusId = '#locationStockStatus-' + locations[i].id;
            var whereToShow = 'in_reserve_modal_cart_page_locations';
            // set the stock status based on how many items are available in this location
            if (stockCount === 0) {
                $locationInput.prop('disabled', true);
                $locationContainer.addClass('ris-location-disabled');
                showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-no-stock', DEFAULT_STOCK_CAPTIONS[0], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[0]);
            } else if ((stockCount < cartItems.length) && (stockCount > 0)) {
                // this caption will read "X out of Y items available"
                var stockStatusText = stockCount + DEFAULT_STOCK_CAPTIONS[3] + cartItems.length + DEFAULT_STOCK_CAPTIONS[4];
                showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-low-stock', stockStatusText, whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[4]);
            } else {
                showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[6], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[6]);
            }
        }
    };
    
    var getLocationPlatformId = function (locationId) {
        var locations = JSON.parse(JSON.stringify(locationsManager.getLocations()));
        
        for (var i = 0; i < locations.length; i++) {
            if (locations[i].id == locationId) {
                return locations[i].platform_location_id;
            }
        }
        return ''; 
    };    
    
    var getStockInfo = function (locationId) {
        if (product) {
            inventoryManager.getInventory(product.id, function(_inventory) {
                inventoryData[product.id] = _inventory;
                getProductStockInfo(locationId);
            });
        } else if (cart) {
            var cartItems = cart.items;
            var productIdArray = [];
            for (var i = 0; i < cartItems.length; i++) {
                productIdArray.push(cartItems[i].product_id);
            }
            inventoryManager.getCartInventory(productIdArray, function(_inventory) {
                inventoryData = _inventory;
                getCartItemsStockInfo(locationId);
            });
        }
    };
    
    var getProductStockInfo = function (locationId) {
        var inventoryLocations, stockStatus;
        var productIsOutOfStock = false;
        var currentLocationPlatformId = getLocationPlatformId(locationId);
        
        if (!inventoryData) return;

        if (inventoryData[product.id]) {
            inventoryLocations = inventoryData[product.id][variant.id];
        }

        if (inventoryLocations !== '') {
            stockStatus = inventoryLocations[currentLocationPlatformId];
            updateProductsStockInfo(variant.id, stockStatus);

            if (stockStatus === 'out_of_stock' || (!showReserveBtnWhenUnknown && stockStatus === 'unknown_stock') || (!showReserveBtnWhenUnknown && !stockStatus)) {
                productIsOutOfStock = true;
            }
        }

        showHideNoStockMessage(productIsOutOfStock);
    };

    var getCartItemsStockInfo = function (locationId) {
        var inventoryLocations, stockStatus;
        var cartItemOutOfStock = false;
        var currentLocationPlatformId = getLocationPlatformId(locationId);
        
        var cartItems = cart.items;
        if (!cartItems || !inventoryData) return;

        for (var k = 0; k < cartItems.length; k++) {
            if (inventoryData[cartItems[k].product_id]) {
                inventoryLocations = inventoryData[cartItems[k].product_id][cartItems[k].variant_id];
            }

            if (inventoryLocations !== '') {
                stockStatus = inventoryLocations[currentLocationPlatformId];
                updateProductsStockInfo(cartItems[k].variant_id, stockStatus);

                if (stockStatus === 'out_of_stock' || (!showReserveBtnWhenUnknown && stockStatus === 'unknown_stock') || (!showReserveBtnWhenUnknown && !stockStatus)) {
                    cartItemOutOfStock = true;
                }
            }
        }

        showHideNoStockMessage(cartItemOutOfStock);
    };
  
    /**
     * update stock message on each product / cart item
     */
    var updateProductsStockInfo = function (variantId, stockStatus) {
        var itemStockStatusId = '#cartItemStockStatus-' + variantId;
        var $itemStockStatusDiv = $reserveModal.find(itemStockStatusId);
        $itemStockStatusDiv.removeClass();
        $itemStockStatusDiv.text('');
        $itemStockStatusDiv.addClass('ris-cart-item-stockStatus ');

        var whereToShow = 'in_reserve_modal_cart_items';
        
        if (stockStatus === 'in_stock') {
            showHideStockStatusLabel(itemStockStatusId, 'ris-cart-item-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
        } else if (stockStatus === 'low_stock') {
            showHideStockStatusLabel(itemStockStatusId, 'ris-cart-item-stockStatus-low-stock', DEFAULT_STOCK_CAPTIONS[1], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[1]);
        } else if (stockStatus === 'out_of_stock') {
            showHideStockStatusLabel(itemStockStatusId, 'ris-cart-item-stockStatus-no-stock', DEFAULT_STOCK_CAPTIONS[0], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[0]);
        } else {
            if (inStockTextWhenUnknown) {
                showHideStockStatusLabel(itemStockStatusId, 'ris-cart-item-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
            } else {
                showHideStockStatusLabel(itemStockStatusId, 'ris-cart-item-stockStatus-stock-unknown', DEFAULT_STOCK_CAPTIONS[5], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[5]);
            }
        }
    };

    /**
     * hide reservation button, show message if stock status is out_of_stock 
     */
    var showHideNoStockMessage = function (productIsOutOfStock) {
        var $submitBtn = $reserveModal.find(".reserveInStore-form-submit");
        var $noStockMessageDiv = $reserveModal.find(".ris-no-stock-message"); 
        if (productIsOutOfStock) {
            $noStockMessageDiv.show();
            $submitBtn.hide(); 
        } else { 
            $noStockMessageDiv.hide();
            $submitBtn.show(); 
        }
    };

    var checkReserveItemsStock = function (formData) {
        var reserveItems = formData.reservation.cart.items;
        var productIdArray = [];
        for (var i = 0; i < reserveItems.length; i++) {
            productIdArray.push(reserveItems[i].product_id);
        }
        api.getStockAvail({ product_ids: productIdArray }, function(stock) {
            stockData = stock;
            if (showHideReserveItemsNotAvailMessage(formData.reservation.location_id, reserveItems)) {
                api.createReservation(getFormData(), self.displaySuccessModal, showErrorMessages);
            }
        });
    };

    var showHideReserveItemsNotAvailMessage = function (locationId, reserveItems) {
        var reservedQty = 1;
        var currentLocationPlatformId = getLocationPlatformId(locationId);
        var reserveItemsStockAvail = true;
        var $reserveItemsNotAvailMessageDiv = $reserveModal.find('.ris-cart-items-not-avail');
        var $reserveIsTextSpan = $reserveModal.find('.ris-is-text');
        var $reserveAreTextSpan = $reserveModal.find('.ris-are-text');
        var productName = "";
        var totalItemNotAvail = 0;
        for (var k = 0; k < reserveItems.length; k++) {
            if (reserveItems[k].quantity !== undefined) {
                reservedQty = reserveItems[k].quantity;
            } else {
                reservedQty = 1;
            }
            if (reservedQty > stockData[reserveItems[k].product_id][reserveItems[k].variant_id][currentLocationPlatformId]) {
                reserveItemsStockAvail = false;
                productName = productName + reserveItems[k].product_title + ", ";
                totalItemNotAvail = totalItemNotAvail + 1;
            }
        }

        if (!reserveItemsStockAvail) {
            $reserveItemsNotAvailMessageDiv.show();
            $reserveModal.find('.ris-cartItems-list-qty-not-avail').text(productName.slice(0, -2));

            // if there are more than 1 items not available show text "are" else show text "is"
            if (totalItemNotAvail > 1) {
                $reserveAreTextSpan.show();
                $reserveIsTextSpan.hide();
            } else {
                $reserveIsTextSpan.show();
                $reserveAreTextSpan.hide();
            }
            rememberFormInputValue();
        } else {
            $reserveItemsNotAvailMessageDiv.hide();
        }
        return reserveItemsStockAvail;
    };

    /**
     * Center the price
     */
    var centerPriceDiv = function () {
        var $priceDiv = $reserveModal.find('.ris-product-price');
        $priceDiv.css('padding-top', ($reserveModal.find('.ris-product-detail').height()-$priceDiv.height())*0.5 + 'px');
    };

    /**
     * Set close conditions to two modals: click on the "x", "OK" or click anywhere outside of the modal
     */
    var setCloseConditions = function () {
        $reserveModal.find(".reserveInStore-reserve-close").on('click', function () {
            self.hide();
        });

        $successModal.find('.reserveInStore-success-close').on('click', function() {
            if (window.location.toString().indexOf('/cart') !== -1) {
                window.location.reload();
            } else {
                self.hide();
            }
        });

        $(document).on('click', function (event) {
            if (!$(event.target).closest('.reserveInStore-reserve-modal, .reserveInStore-success-modal', $modalBackground).length) {
                self.hide();
            }
        });
    };

    /**
     * Set submit conditions to the modal:
     * click on the "Reserve" button or press the enter key in the last input field
     */
    var setSubmitConditions = function () {
        var $submitBtn = $reserveModal.find(".reserveInStore-form-submit");
        $submitBtn.on('click', function () {
            self.submitForm();
        });
        $form.on('submit', function () {
            self.submitForm();
        });
        $form.find('input:visible').last().on('keypress', function (e) {
            if (e.keyCode === 13) {
                self.submitForm();
            }
        });
    };

    /**
     * Submit the form
     * If the form has been validated, make an Ajax call to create new reservation
     * Otherwise, show html 5 validation errors
     */
    self.submitForm = function () {
        if ($form[0].checkValidity()) {
            checkReserveItemsStock(getFormData());
        } else {
            $form.find('input, select').addClass('reserveInStore-attempted');
            $form[0].reportValidity();
        }
    };

    /**
     * redirect to checkout page if reservation is from cart page and checkout_without_clearing_cart is enabled.
     * Display a nice modal to say "thank you... etc" and whatever is configured to display via the store settings
     */
    self.displaySuccessModal = function () {
        if (cart && checkoutWithoutClearingCart) {
            var email = $reserveModal.find('input[name="reservation[customer_email]"').val();

            // Save for 10 minutes I think 10 minutes should be enough to complete checkout.
            opts.storage.setItem('checkoutSuccessMessageTpl', config.checkout_success_message_tpl, opts.debugMode ? 1 : 1000*60*10);

            discountCode = config.discount_code;
            // Save for 10 minutes I think 10 minutes should be enough to complete checkout.
            opts.storage.setItem('reservationCustomId', customReservationId, opts.debugMode ? 1 : 1000*60*10);
            window.location = '/checkout?discount=' + discountCode +
                '&note=In-store reservation id: ' + customReservationId + "" +
                "&checkout[email]=" + email;

        } else {
            opts.app.trigger('reserve_modal.submit', self);
            $reserveModal.hide();
            ReserveInStore.Util.showWithoutTransform($successModal);

            // If we're reserving a whole cart then clear the cart
            if (!product && !variant && cart && !$reserveModal.find(".reserveInStore-form-submit").val()) {
                clearCart();
            }
        }
    };

    /**
     * Empty the cart using the Shopify API
     *
     * @param then
     */
    var clearCart = function(then) {
        $.ajax({
            method: 'GET',
            type: 'GET', // An alias for method. It's here for back compatibility with versions of jQuery prior to 1.9.0, I guess.
            data: {},
            dataType: 'json',
            url: '/cart/clear',
            complete: function(response) {
                if (typeof then === 'function') then();
            }
        });
    };

    /**
     * Display errors messages came from the server in a list
     * In theory, this function should never be called, since we are using HTML 5 form validation
     * @param data {object} Response to the failed Ajax call
     */
    var showErrorMessages = function (data) {
        var errorMessages = "";
        if (typeof data.responseJSON === 'object' && Object.keys(data.responseJSON).length > 0) {
            $.each(data.responseJSON, function (key, value) {
                errorMessages += "<li>" + value + "</li>";
            });
        } else {
            errorMessages += "<li>An unknown error occurred.</li>";
        }
        $reserveModal.find(".reserveInStore-error-ul").html(errorMessages).show();
    };

    /**
     * Serializes the form's elements, and add product id and variant id
     * @returns {object} Array of all information needed to generate new reservation
     */
    var getFormData = function () {
        var data = ReserveInStore.Util.serializeObject($form);
        data.reservation.cart = getCartObject();

        if (cart && checkoutWithoutClearingCart) {
            data.reservation.custom_reservation_id = customReservationId;
        }

        return data;
    };

    init();
};
