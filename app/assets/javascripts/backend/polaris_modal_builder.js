/**
 * Make the Polaris modal interactive, perform HTML 5 validation before submit
 * @param {object} opts Classes and IDs related to current modal, used to select elements and attach event handlers
 *                 (including showClass, containerID, formID, closeClass and submitBtnID)
 */
var PolarisModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $form, $modalContainer;

    var init = function () {
        $modalContainer = $('div#' + opts.containerID);
        $form = $('#' + opts.formID);
        bindShowBtn();
        bindForm();
        setCloseConditions();

    };

    this.show = function() {
        if (opts.chooseProductsFirst) {
            ShopifyApp.Modal.productPicker({ 'selectMultiple': false }, function(success, data) {
                if (!success) return;

                if (data.products.length > 0) {
                    var prod = data.products[0];
                    var options = [];
                    for (var i = 0 ; i < prod.variants.length; i++) {
                        options.push('<option value="' + prod.variants[i].id + '">' + prod.variants[i].title + '</option>');
                    }

                    $form.find('#reservation_platform_variant_id').html(options.join("\n"));
                    $form.find('#reservation_platform_product_id').val(prod.id);

                    $modalContainer.show();
                } else {
                    console.error(data.errors);
                }
            });
        } else {
            $modalContainer.show();
        }
    };

    this.hide = function() {
        $modalContainer.hide();
    };


    /**
     * When click on the "Add New bleh" Button, show the modal
     */
    var bindShowBtn = function () {
        $(opts.triggerSelector).on('click', function () {
            self.show();
        });
    };


    /**
     * When attempting to submit the form, check if it has been validated
     * If it fails the validation, show html 5 validation errors
     */
    var bindForm = function () {
        $('#' + opts.submitBtnID).on('click', function () {
            if ($form[0].checkValidity()) {
                $form.submit();
                $modalContainer.hide();
            } else {
                $form[0].reportValidity();
            }
        });
    };

    /**
     * Set close conditions to the modal: click on the "x", "Cancel" or anywhere outside of the modal
     */
    var setCloseConditions = function () {
        $('.' + opts.closeClass).on('click', function () {
            self.hide();
        });
        $modalContainer.on('click', function (event) {
            if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
                self.hide();
            }
        });
    };

    init();
};
