/**
 * A modal pop-up to show flash / toast message .
 *
 * Construct with the following hash:
 * {string} modalSelector, selector for the modal
 * {string} closeSelector, selector for the modal close button
 * {string} okBtnUrl
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var Instore_Reserver_Modal = function (opts) {
    var modalSelector = $(opts.modalSelector);
    var closeSelector = $(opts.closeSelector);
    var btnSelector = $(opts.btnSelector);
    var okBtnUrl = opts.okBtnUrl;

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
            url: okBtnUrl,
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
