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

        btnSelector.on('click', showMessage);
        closeSelector.on('click', closeModal);
    };

    var closeModal = function () {
        modalSelector.hide();
    };

    var showMessage = function () {
        $.ajax({
            url: submitBtnUrl,
            type: 'GET',
            success: function(response) {
                if (response.type === "success") {
                    new Instore_Reserver_Toast_Notice({
                        heading: 'Saved Successfully',
                        type: response.type,
                        message: response.message,
                    });
                    closeModal();
                    location.reload();
                } else {
                    new Instore_Reserver_Flash_Notice({
                        type: response.type,
                        message: response.message,
                    });
                }
            },
            error: function(response) {
                new Instore_Reserver_Flash_Notice({
                    type: 'error',
                    message: response.error,
                });
            }
        });
    };

    init();
};
