ReserveInStore.Api = function(opts) {
    var self              = this;
    var $                 = ReserveInStore.Util.$();
    opts                  = opts || {};

    var init = function() {
    };

    /**
     * Request modal via the API /api/v1/modal
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     * @returns {Promise} Response from ajax function call.
     */
    self.getModal = function (params, successCallback, errorCallback) {
        successCallback          = successCallback || function () {
        };
        return $.ajax({
            url: self.url("modal") + "&" + $.param(params),
            success: function (data, textStatus, jqXHR) {
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                if (errorCallback) errorCallback(response);
            }
        });
    };

    /**
     * Get the API url that we need to use given the store API url and public key.
     * @param uri {string} URI path we want to access on the server. IE: 'modal' (no leading slash needed)
     * @returns {string}
     */
    self.url = function(uri) {
        uri = uri || "";
        return opts.apiUrl + '/api/v1/' + uri + '?store_pk=' + opts.storePublicKey;
    };

    init();
};
