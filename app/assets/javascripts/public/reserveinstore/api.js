ReserveInStore.Api = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config;

    var init = function () {
        if (opts.storePublicKey) {
            self.configure(opts);
        }
    };

    /**
     * Checks configuration and warns and returns the result.
     * @returns {boolean} True if ready to accept requests, false otherwise
     */
    self.checkConfig = function() {
        if (!self.validConfig()) {
            ReserveInStore.logger.error("Missing API key. This usually means that part of your integration is incomplete. Please contact our support team.");
            return false;
        }

        return true;
    };

    self.configure = function(_config) {
        config = _config;
    };

    /**
     *
     * @returns {boolean} True if config is valid, false otherwise.
     */
    self.validConfig = function() {
        if (!config || !config.storePublicKey) {
            return false;
        }

        return true;
    };

    /**
     * Waits for API key credentials to be valid before continuing. This protected against any race conditions.
     * @param callback {function} - function to run when API creds are OK.
     */
    self.waitForApiConfig = function(callback) {
        var warningThreshold = 10000; // How long before we display a warning that config is not yet ready
        var waitedSoFar = 0;
        var checkEvery = 1;
        var checkInterval;

        var checkFunc = function() {
            if (self.validConfig()) {
                if (checkInterval) clearInterval(checkInterval);
                callback();
                return true;
            }
            waitedSoFar += checkEvery;
            if (waitedSoFar === warningThreshold) {
                ReserveInStore.logger.warn("Waited more than " + (warningThreshold / 1000) + " seconds for ReserveInStore api credentials and still don't have them. Please contact our support team for help if this is unexpected.");
            }
            return false;
        };

        if (!checkFunc()) {
            checkInterval = setInterval(checkFunc, checkEvery);
        }
    };

    /**
     * Request modal via the API /api/v1/modal
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     */
    self.getLocations = function (params, successCallback, errorCallback) {
        successCallback = successCallback || function () { };

        $.ajax({
            url: self.urlPath("locations.json") + "&" + $.param(params),
            success: function (data, textStatus, jqXHR) {
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                if (errorCallback) errorCallback(response);
            }
        });
    };


    /**
     * Request modal via the API /api/v1/modal
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     */
    self.getLocationsModal = function (params, successCallback, errorCallback) {
        successCallback = successCallback || function () {
        };
        $.ajax({
            url: self.urlPath("locations/modal") + "&" + $.param(params),
            success: function (data, textStatus, jqXHR) {
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                if (errorCallback) errorCallback(response);
            }
        });
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
            url: self.urlPath("reservations/modal") + "&" + $.param(params),
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
            method: "POST",
            url: self.urlPath("reservations"),
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
        return config.apiUrl + '/api/v1/' + uri + '?store_pk=' + config.storePublicKey;
    };

    init();
};
