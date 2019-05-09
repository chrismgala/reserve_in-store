/**
 * Used for Geolocation of the current visitor
 * @param opts
 * @constructor
 */
ReserveInStore.Geo = function (opts) {
    var self         = this;
    var url          = "https://geo.bananastand.io/json/";
    var $            = ReserveInStore.Util.$();
    var localStorage = opts.localStorage;

    var init = function () {
        self.ipResult = null;
        loadFromLocalStorage();
    };

    /**
     * @returns {boolean} true if the geolocator class has stored location info and no further server call is needed.
     */
    this.hasStoredInfo = function () {
        return self.ipResult !== null;
    };

    /**
     * Gets you the geo location result from the server for the current visitor.
     * @param {function} callback once the geolocation is complete. This will use local storage so it won't make the same call again with in the same 2 hour period for this user.
     */
    this.getLocationInfo = function (callback) {
        callback = callback || function() {};
        if (self.ipResult) {
            callback(self.ipResult);
        } else {
            self.geolocateIp(callback);
        }
    };

    /**
     * Trigger fetching of new geolocation results that are stored locally.
     * @param {function} callback called back when geolocation is complete and response is received from remote server.
     * @param runCallbackAnyway {boolean} if true and if request failed run callback anyway with null parameter
     */
    this.geolocateIp = function (callback, runCallbackAnyway) {
        callback = callback || function () {
        };

        $.ajax({
            method: 'GET',
            url: url,
            success: function (response) {
                storeResult(response);

                callback(self.ipResult);
            },
            dataType: "jsonp",
            error: function (jqXHR, textStatus, errorThrown) {
                if (runCallbackAnyway) callback({});
            }
        });
    };

    var loadFromLocalStorage = function () {
        if (typeof localStorage === 'undefined') return;

        try {
            self.ipResult = localStorage.getObject(geoLocateKey());
        } catch (e) {
            // Data was invalid
        }
    };

    var storeResult = function (response) {
        self.ipResult = response;

        if (typeof localStorage !== 'undefined') {
            localStorage.setItem(geoLocateKey(), self.ipResult, 2 * 60 * 60 * 1000);
        }
    };

    var geoLocateKey = function () {
        return "Geo.geolocateIp.result";
    };

    init();
};
