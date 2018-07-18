/**
 * Make the Polaris modal interactive, perform HTML 5 validation before submit
 * @param {object} opts Classes and IDs related to current modal, used to select elements and attach event handlers
 *                 (including showClass, containerID, formID, closeClass and submitBtnID)
 */
var PolarisModal = function (opts) {
    opts = opts || {};
    var $form, $modalContainer;

    this.init = function () {
        $modalContainer = $('div#' + opts.containerID);
        $form = $('#' + opts.formID);
        this.bindShowBtn();
        this.bindForm();
        this.setCloseConditions();

    };

    /**
     * When click on the "Add New bleh" Button, show the modal
     */
    this.bindShowBtn = function () {
        if (opts.showClass) {
            $('.' + opts.showClass).on('click', function () {
                $modalContainer.show();
            });
        }
    };

    /**
     * When attempting to submit the form, check if it has been validated
     * If it fails the validation, show html 5 validation errors
     */
    this.bindForm = function () {
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
    this.setCloseConditions = function () {
        $('.' + opts.closeClass).on('click', function () {
            $modalContainer.hide();
        });
        $modalContainer.on('click', function (event) {
            if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
                $modalContainer.hide();
            }
        });
    };

    this.init();
};
