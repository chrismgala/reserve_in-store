/**
 * Show / Hide flash notice with success or error message.
 * {string} containerSelector, selector for main container
 * {string} heading
 * {string} message
 * {string} type, eg: success, error
 */
var Instore_Reserver_Toast_Notice  = function (opts) {
    var containerSelector = $('.reserveInStore-toast-container');
    var heading = opts.heading;
    var message = opts.message;
    var type = opts.type;

    var init = function () {
        if (type) createMessage();
        $('.reserveInStore-toast-close').on('click', hideToastMessage);
    };

    var createMessage = function() {
        containerSelector.children('.reserveInStore-toast-container-inner').append(toastHtml);
    }

    var toastHtml = function() {
        html =
            '<div class="reserveInStore-toast-message reserveInStore-toast-' + type + ' toast" role="alert" aria-live="assertive" aria-atomic="true">' +
              '<div class="toast-wrapper">' +
                 '<div class="toast-icon">' + svgIcon() +'</div>' +
                 '<div class="toast-content">' +
                   '<div class="toast-header">' + heading + '</div>' +
                   '<div class="toast-body">' + message + '</div>' +
                 '</div>' +

                 '<div class="close-container">' +
                   '<button type="button" class="reserveInStore-toast-close" data-dismiss="toast" aria-label="Close">' +
                     '<span aria-hidden="true">×</span>' +
                   '</button>' +
                 '</div>' +
              '</div>' +
            '</div>';

        return html;
    };

    var svgIcon = function() {
        var icon;

        if (type === "error") {
            icon = errorSvgIcon();
        } else {
            icon = successSvgIcon();
        }

        return icon;
    }

    var successSvgIcon = function() {
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">\n' +
            '            <rect width="32" height="32" rx="16" fill="#00B884"></rect>\n' +
            '            <path d="M13.4219 21.7344C13.7344 22.0469 14.2656 22.0469 14.5781 21.7344L23.7656 12.5469C24.0781 12.2344 24.0781 11.7031 23.7656 11.3906L22.6406 10.2656C22.3281 9.95312 21.8281 9.95312 21.5156 10.2656L14.0156 17.7656L10.4844 14.2656C10.1719 13.9531 9.67188 13.9531 9.35938 14.2656L8.23438 15.3906C7.92188 15.7031 7.92188 16.2344 8.23438 16.5469L13.4219 21.7344Z" fill="white"></path>\n' +
            '          </svg>';

    };

    var errorSvgIcon = function() {
        return '<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">\n' +
            '<rect width="32" height="32" rx="16" fill="#EE0026"/>' +
            '<path d="M17.8555 15.9805L22.0742 11.8008C22.3086 11.5664 22.3086 11.1367 22.0742 10.9023L21.0977 9.92578C20.8633 9.69141 20.4336 9.69141 20.1992 9.92578L16.0195 14.1445L11.8008 9.92578C11.5664 9.69141 11.1367 9.69141 10.9023 9.92578L9.92578 10.9023C9.69141 11.1367 9.69141 11.5664 9.92578 11.8008L14.1445 15.9805L9.92578 20.1992C9.69141 20.4336 9.69141 20.8633 9.92578 21.0977L10.9023 22.0742C11.1367 22.3086 11.5664 22.3086 11.8008 22.0742L16.0195 17.8555L20.1992 22.0742C20.4336 22.3086 20.8633 22.3086 21.0977 22.0742L22.0742 21.0977C22.3086 20.8633 22.3086 20.4336 22.0742 20.1992L17.8555 15.9805Z" fill="white"/>' +
            '</svg>';
    };

    var hideToastMessage = function() {
        $('.reserveInStore-toast-message').hide();
    };

    init();
};
