ReserveInStore.ReservationCreator = function (opts) {
    var self = this;
    opts = opts || {};
    var api, $modalBackground, $reserveModal, $successModal, $form, productId, variantId;

    var init = function () {
        api = new ReserveInStore.Api(opts);
    };

    /**
     * Get product id/title and variant id/title, then make API call and display the modal
     */
    self.displayModal = function () {
        var selectedProductInfo = self.setProductAndVariantId();
        api.getModal(selectedProductInfo, self.insertModal);
    };

    /**
     * Set Product ID and Variant Id, return product title, variant title and price to be used in modal
     * @returns {object} Product title, variant title and price, in the form of {product_title: "bleh", variant_title: "bleh", price: "bleh"}
     */
    self.setProductAndVariantId = function () {
        setVariantID();
        variantId = variantId || opts.product.variants[0].id;
        var variant = $.grep(opts.product.variants, function (obj) {
            return obj.id === variantId;
        })[0];
        productId = opts.product.id;
        return {product_title: opts.product.title, variant_title: variant.title, price: variant.price};
    };

    /**
     * Get variant ID from the add to cart form, if failed, try parsing the URL to get variant ID
     */
    var setVariantID = function () {
        var variantIdEntry = $('form[action~="/cart/add"]').serializeArray().find(function (obj) {
            return obj.name === "id";
        });

        if (variantIdEntry) {
            variantId = parseInt(variantIdEntry.value);
        } else {
            tryGetVariantIdFromURL()
        }
    };

    /**
     * If variant id is in url's query string, set variant ID
     */
    var tryGetVariantIdFromURL = function () {
        var re_variant = /variant=(.*?)(&|$)/,
            matchVariantId = window.location.href.match(re_variant);
        if (matchVariantId) {
            variantId = parseInt(matchVariantId[1]);
        }
    };

    /**
     * Insert the HTML code of two modals into the container:
     * $reserveModal is for creating new reservation, collecting customer's information
     * $successModal is to be displayed after new reservation is created
     * @param modalHTML {string} the HTML code of two modals
     */
    self.insertModal = function (modalHTML) {
        opts.$modalContainer.html(modalHTML);
        opts.$modalContainer.show();
        $modalBackground = opts.$modalContainer.find('.reserveInStore-modal-background');
        $reserveModal = $modalBackground.find('.reserveInStore-reserve-modal');
        $successModal = $modalBackground.find('.reserveInStore-success-modal');
        setCloseConditions();

        $form = $reserveModal.find(".reserveInStore-reservation-form");
        setSubmitConditions();
    };

    /**
     * Set close conditions to two modals: click on the "x", "OK" or click anywhere outside of the modal
     */
    var setCloseConditions = function () {
        var $span = $modalBackground.find(".reserveInStore-reserve-close, .reserveInStore-success-close");
        $span.on('click', function () {
            opts.$modalContainer.hide();
        });

        $(document).on('click', function (event) {
            if (!$(event.target).closest('.reserveInStore-reserve-modal, .reserveInStore-success-modal', $modalBackground).length) {
                opts.$modalContainer.hide();
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
        var data = $form.serializeArray();
        data.push({name: "reservation[platform_product_id]", value: productId});
        data.push({name: "reservation[platform_variant_id]", value: variantId});
        return data;
    };

    init();
};
