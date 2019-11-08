ReserveInStore.ReserveModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();
    var api, $modalBackground, $reserveModal, $successModal, $form, formDataArray;

    var locationsManager = opts.locationsManager;
    var inventoryTable;
    var DEFAULT_STOCK_CAPTIONS = ["No Stock", "Low Stock", "In Stock"];

    var product, variant, cart, lineItem = {};

    var init = function () {
        api = opts.api;

        buildInventoryTable();
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

        var modalParams = { cart: getCartObject() };
        api.getReservationModal(modalParams, {}, function(response) {
            self.insertModal(response.content);
        });

        opts.app.trigger('reserve_modal.show reserve_modal.open', self);
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
        self.$modalContainer.show();
        $modalBackground = self.$modalContainer.find('.reserveInStore-modal-background');
        $reserveModal = $modalBackground.find('.reserveInStore-reserve-modal');
        $successModal = $modalBackground.find('.reserveInStore-success-modal');
        centerPriceDiv();
        setCloseConditions();

        $form = $reserveModal.find(".reserveInStore-reservation-form");
        setSubmitConditions();

        self.$modalContainer.find('input[name="reservation[location_id]"]').on('click change', function() {
            var locationId = self.$modalContainer.find('input[name="reservation[location_id]"]:checked').val();
            locationsManager.setFavoriteLocationId(locationId);
        });

        locationsManager.whenReady(function(bestLocation) {
            if (!bestLocation) return; // Could not determine best location

            self.$modalContainer.find('input[name="reservation[location_id]"][value="'+bestLocation.id+'"]').prop('checked', true);

            updateLocationStockInfo(locationsManager.getLocations());
        });

        adjustModalHeight();

        opts.app.trigger('reserve_modal.create', self);
    };

    self.hide = self.close = function() {
        self.$modalContainer.hide();

        opts.app.trigger('reserve_modal.close reserve_modal.hide', self);
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

    var buildInventoryTable = function () {
        inventoryTable = {};
        if (opts.app.getProduct()) {
            api.getInventory({ product_id: opts.app.getProduct().id }, function(_inventoryTable) {
                inventoryTable = _inventoryTable;
            });
        } else if(opts.app.getCart()) {
            //TODO: try to get this working with carts
            //The point is to add a stock indicator to the location list and filter locations with no stock,
            //currently this works in the Product page but not the Cart page.
        }
    };

    var updateLocationStockInfo = function (locations) {
        var inventoryLocations;
        var $locationContainer, $locationInput, $stockStatusDiv;

        if (product && variant) {
            inventoryLocations = inventoryTable[variant.id];

            for (var i = 0; i < locations.length; i++) {
                $locationInput = $reserveModal.find('#reservation_location_id-' + locations[i].id );
                $locationContainer = $locationInput.parent().parent().parent();
                $stockStatusDiv = $locationContainer.find('.ris-location-stock-status');

                if (inventoryLocations[locations[i].platform_location_id] === 'low_stock') {
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[1]);
                    $stockStatusDiv.addClass('ris-location-stock-status-low-stock');
                } else if (inventoryLocations[locations[i].platform_location_id] === 'in_stock') {
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[2]);
                    $stockStatusDiv.addClass('ris-location-stock-status-in-stock');
                } else {
                    $locationInput.prop('disabled', true);
                    $locationContainer.addClass('ris-location-disabled');
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[0]);
                    $stockStatusDiv.addClass('ris-location-stock-status-no-stock');
                }
            }
        }
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
        var $span = $modalBackground.find(".reserveInStore-reserve-close, .reserveInStore-success-close");
        $span.on('click', function () {
            self.hide();
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
            api.createReservation(getFormData(), self.displaySuccessModal, showErrorMessages);
        } else {
            $form.find('input, select').addClass('reserveInStore-attempted');
            $form[0].reportValidity();
        }
    };

    /**
     * Display a nice modal to say "thank you... etc" and whatever is configured to display via the store settings
     */
    self.displaySuccessModal = function () {
        opts.app.trigger('reserve_modal.submit', self);

        $reserveModal.hide();
        $successModal.show();
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
        return data;
    };

    init();
};
