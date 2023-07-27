/**
 * Show / Hide flash notice with success or error message.
 * {string} containerSelector, selector for main container
 * {string} message
 * {string} type, eg: success, error
 */
var Instore_Reserver_Flash_Notice  = function (opts) {
    var containerSelector = $('.inSoreReserver-flash-container');
    var message = opts.message;
    var type = opts.type;

    var init = function () {
        if (type) createMessage();
    };

    var createMessage = function() {
        containerSelector.children('.inSoreReserver-flash-container-inner').html(messageHtml);
    }

    var messageHtml = function() {
        html =
            '<div class="inSoreReserver-flash-message inSoreReserver-flash-' + type + '" role="alert" aria-live="assertive" aria-atomic="true">' +
              '<div class="inSoreReserver-flash-wrapper">' +
                '<div class="inSoreReserver-flash-content">' +
                   '<div class="inSoreReserver-flash-body">' + message + '</div>' +
                 '</div>' +
              '</div>' +
            '</div>';

        return html;
    };

    init();
};
