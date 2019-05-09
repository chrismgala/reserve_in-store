ReserveInStore.ReserveModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();
    var api, $modalBackground, $reserveModal, $successModal, $form, formDataArray, lineItem = {};

    var locationsManager = opts.locationsManager;

    var init = function () {
        api = opts.api;
    };

    /**
     * Get product id/title and variant id/title, then make API call and display the modal
     */
    self.show = function () {

        var selectedProductInfo = self.loadProductInfo();

        self.$modalContainer = $('#reserveInStore-reserveModalContainer');
        if (self.$modalContainer.length < 1) {
            self.$modalContainer = $('<div class="reserveInStore-modal-container" id="reserveInStore-reserveModalContainer" style="display:none;"></div>').appendTo('body');
        }

        api.getModal(selectedProductInfo, self.insertModal);

        opts.app.trigger('reserve_modal.show reserve_modal.open', self);
    };

    /**
     * Set Product Id, Variant Id and line item properties object, return product title, variant title, line item properties and price to be used in modal
     * @returns {object} Product title, variant title and price, in the form of {product_title: "bleh", variant_title: "bleh", price: "bleh"}
     */
    self.loadProductInfo = function () {
        formDataArray = $('form[action~="/cart/add"]').serializeArray();
        loadLineItem();
        return {
            product_title: opts.app.getProduct().title,
            variant_title: opts.app.getVariant().title,
            price: opts.app.getVariant().price,
            line_item: lineItem
        };
    };

    /**
     * Set line item properties
     */
    var loadLineItem = function () {
        var re_lineItem = /properties\[(.*?)\]/;
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

        self.$modalContainer.find('input[name="reservation[location.id]"]').on('click change', function() {
            var locationId = self.$modalContainer.find('input[name="reservation[location.id]"]:checked').val();
            locationsManager.setFavoriteLocationId(locationId);
        });

        locationsManager.whenReady(function(bestLocation) {
            if (!bestLocation) return; // Could not determine best location

            self.$modalContainer.find('input[name="reservation[location.id]"][value="'+bestLocation.id+'"]').prop('checked', true);
        });

        adjustModalHeight();
    };

    self.hide = self.close = function() {
        self.$modalContainer.hide();

        opts.app.trigger('reserve_modal.close reserve_modal.hide', self);
    };

    var adjustModalHeight = function() {
        var $fit = self.$modalContainer.find('.reserveInStore-modal--fitContents');
        if ($fit.length < 1) return; // No fitting needed.

        var totalHeight = 80;
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
            api.createReservation(serializeFormData(), self.displaySuccessModal, showErrorMessages);
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
    var serializeFormData = function () {
        var product = opts.app.getProduct();
        var variant = opts.app.getVariant();

        var data = $form.serializeArray();
        data.push({name: "reservation[platform_product_id]", value: product.id});
        data.push({name: "reservation[platform_variant_id]", value: variant.id});
        data.push({name: "reservation[line_item]", value: JSON.stringify(lineItem)});
        data.push({name: "product_title", value: product.title});
        data.push({name: "product_handle", value: product.handle});
        data.push({name: "variant_title", value: variant.title});
        return data;
    };

    init();
};
