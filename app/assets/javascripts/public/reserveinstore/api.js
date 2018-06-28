ReserveInStore.Api = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};

    var init = function () {
    };

    /**
     * Request modal via the API /api/v1/modal
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     */
    self.getModal = function (params, successCallback, errorCallback) {
        successCallback = successCallback || function () {
        };
        $.ajax({
            url: self.urlPath("modal") + "&" + $.param(params),
            success: function (data, textStatus, jqXHR) {
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                if (errorCallback) errorCallback(response);
            }
        });
    };

    /**
     * Push a new reservation to the server via the /api/v1/store_reservations
     * @param params {Object} data to send with the POST request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     */
    self.createReservation = function (params, successCallback, errorCallback) {
        successCallback = successCallback || function () {
        };
        $.ajax({
            type: "POST",
            url: self.urlPath("store_reservations"),
            data: params,
            success: function (data, textStatus, jqXHR) {
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                if (errorCallback) errorCallback(response);
            },
        });
    };

    /**
     * Get the API url that we need to use given the store API url and public key.
     * @param uri {string} URI path we want to access on the server. IE: 'modal' (no leading slash needed)
     * @returns {string}
     */
    self.urlPath = function (uri) {
        uri = uri || "";
        return opts.apiUrl + '/api/v1/' + uri + '?store_pk=' + opts.storePublicKey;
    };

    init();
};
