ReserveInStore.Api = function(opts) {
    var self              = this;
    var config;
    var $                 = ReserveInStore.Util.$();
    opts                  = opts || {};
    var visitorId;
    self.requestFailCount = 0;

    var init = function() {
        // visitorId = opts.visitorId;
    };

    /**
     * Configure the API with URL and other settings
     * @param _config
     */
    self.configure = function(_config) {
        config = _config;
        if (!config.api_url || config.api_url.length <= 0) {
            config.api_url = "https://app.reserveInStore.io/api/v1/";
        }

        if (config.api_url[config.api_url.length - 1] != '/') {
            config.api_url = config.api_url + '/';
        }
    };

    /**
     * Checks configuration and warns and returns the result.
     * @returns {boolean} True if ready to accept requests, false otherwise
     */
    self.checkConfig = function() {
        if (!self.validConfig()) {
            opts.logger.error("Missing Banana Stand API key. This usually means that part of your integration is incomplete. Please contact our support team.");
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
                opts.logger.warn("Waited more than " + (warningThreshold / 1000) + " seconds for Banana Stand api credentials and still don't have them. Please contact our support team for help if this is unexpected.");
            }
            return false;
        };

        if (!checkFunc()) {
            checkInterval = setInterval(checkFunc, checkEvery);
        }
    };

    /**
     *
     * @returns {boolean} True if config is valid, false otherwise.
     */
    self.validConfig = function() {
        if (!config || !config.store_pk) {
            return false;
        }

        return true;
    };

    // /**
    //  * Push a Product View event to the server.
    //  * @param params URL params to send with the GET request.
    //  * @param callback {function} (optional) Functional callback to *attempt* to run after the event is pushed. Sometimes this doesn't work since we are loading the GET request as an image.
    //  * @param async {boolean} (optional, default: true) Should we tell the server to process the event asynchronously, or right now before responding?
    //  */
    // self.pushViewEvent = function(params, callback, async) {
    //     params.eventType = 'view';
    //     return self.pushEvent(params, callback, async);
    // };
    //
    // /**
    //  * Push an event to the server
    //  * @param params URL params to send with the GET request.
    //  * @param callback {function} (optional) Functional callback to *attempt* to run after the event is pushed. Sometimes this doesn't work since we are loading the GET request as an image.
    //  * @param async {boolean} (optional, default: true) Should we tell the server to process the event asynchronously, or right now before responding?
    //  */
    // self.pushEvent = function(params, callback, async) {
    //     callback = callback || function() {};
    //     async = typeof async === 'undefined' ? true : async;
    //
    //     opts.logger.log("Banana Stand is pushing event:", params);
    //
    //     var additionalParams = { visitor_id: visitorId };
    //     if (!async) additionalParams.async = false;
    //
    //     if (params.additional_data) {
    //         opts.logger.log("Detected additional params: ", params.additional_data);
    //         additionalParams.additional_data = params.additional_data;
    //     }
    //
    //     opts.logger.log("Additional URL params with push event are: ", additionalParams);
    //
    //     var _url = self.url('push_event/'+params.eventType+'/p/'+params.productId+'/c/'+(params.customerId || 0)+".png?"+$.param(additionalParams));
    //
    //     var img = document.createElement('img');
    //     img.src = _url;
    //     $(img).on('load', function() {
    //         opts.logger.log("Pushed event with params: ", params);
    //
    //         callback($(img));
    //     });
    // };

    /**
     * Request content via the content containers API on the server
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     * @returns {Promise} Response from ajax function call.
     */
    self.getContent = function (params, successCallback, errorCallback) {
        successCallback          = successCallback || function () {
        };
        params.visitor_id = visitorId;
        if (opts.testMode) params.test_mode = opts.testMode;
        var _url = self.url('content/containers.json?' + $.param(params));
        return $.ajax({
            url: _url,
            success: function (data, textStatus, jqXHR) {
                self.requestFailCount = 0; // reset on success
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                self.requestFailCount += 1;
                if (errorCallback) errorCallback(response);
            }
        });
    };

    /**
     * Request content via the content containers API on the server
     * @param params URL params to send with the GET request.
     * @param successCallback {function} (optional) Callback to run if the request is successful. This will not be called if the request fails.
     * @param errorCallback {function} (optional) Callback to run if the request failed.
     * @returns {Promise} Response from ajax function call.
     */
    self.getModal = function (params, successCallback, errorCallback) {
        successCallback          = successCallback || function () {
        };
        return $.ajax({
            url: opts.apiUrl + '/api/v1/modal?store_pk=' + opts.storePublicKey,
            success: function (data, textStatus, jqXHR) {
                self.requestFailCount = 0; // reset on success
                successCallback(data, textStatus, jqXHR);
            },
            error: function (response) {
                self.requestFailCount += 1;
                if (errorCallback) errorCallback(response);
            }
        });
    };

    /**
     * Get the API url that we need to use given the store public key.
     * @param uri {string} URI path we want to access on the server. IE: 'content/containers.json' (no leading slash needed)
     * @returns {string}
     */
    self.url = function(uri) {
        uri = uri || "";
        return opts.apiUrl + '/api/v1/' + config.store_pk + '?store_pk=' + uri;
    };

    init();
};
