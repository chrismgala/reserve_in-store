ReserveInStore.ReservationCreator = function (opts) {
    var self = this;
    opts = opts || {};
    var api, $modal, $form, productId, variantId;

    var init = function () {
        api = new ReserveInStore.Api(opts);
    };

    /**
     * Get product id/title and variant id/title, then make API call and display the modal
     */
    self.displayModal = function () {
        var productVariantTitles = self.setProductAndVariantId();
        api.getModal(productVariantTitles, self.insertModal);
    };

    /**
     * Set Product ID/Title and Variant Id/Title
     * @returns {object} Product and variant titles, in the form of {product_title: "bleh", variant_title: "bleh"}
     */
    self.setProductAndVariantId = function () {
        setVariantID();
        variantId = variantId || opts.product.variants[0].id;
        var variantTitle = $.grep(opts.product.variants, function (obj) {
            return obj.id === variantId;
        })[0].title;
        productId = opts.product.id;
        return {product_title: opts.product.title, variant_title: variantTitle};
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
     * Insert the HTML code of modal into the container
     * @param modalHTML {string} the HTML code of modal
     */
    self.insertModal = function (modalHTML) {
        opts.$modalContainer.html(modalHTML);
        opts.$modalContainer.show();
        $modal = opts.$modalContainer.find('.reserveInStore-modal');
        setCloseConditions();

        $form = $modal.find("#reserveInStore-reservation-form");
        setSubmitConditions();
    };

    /**
     * Set close conditions to the modal: click on the "x" or click anywhere outside of the modal
     */
    var setCloseConditions = function () {
        var $span = $modal.find(".reserveInStore-close-modal");
        $span.on('click', function () {
            opts.$modalContainer.hide();
        });

        $(document).on('click', function (event) {
            if (!$(event.target).closest('.reserveInStore-modal-content').length) {
                opts.$modalContainer.hide();
            }
        });
    };

    /**
     * Set submit conditions to the modal:
     * click on the "Reserve" button or press the enter key in the last input field
     */
    var setSubmitConditions = function () {
        var $submitBtn = $modal.find(".reserveInStore-form-submit");
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
     * Submit the form, make an Ajax call to create new reservation
     */
    self.submitForm = function () {
        alert('submit');
    };

    init();
};
