/**
 * A modal with cancel and action button.
 *
 * Construct with the following hash:
 * {string} modalSelector, selector for the modal
 * {string} closeSelector, selector for the modal close button
 * {string} submitBtnUrl
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var Instore_Reserver_Modal = function (opts) {
    var modalSelector = $(opts.modalSelector);
    var closeSelector = $(opts.closeSelector);
    var btnSelector = $(opts.btnSelector);
    var submitBtnUrl = opts.submitBtnUrl

    var init = function () {
        modalSelector.hide();

        closeSelector.on('click', closeModal);

        btnSelector.on('click', function(e) {
            e.preventDefault();
            Turbolinks.visit(submitBtnUrl);
        });
    };

    var closeModal = function () {
        modalSelector.hide();
    };

    init();
};
