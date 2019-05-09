/**
 *  LocalStorage
 *  It uses window.localStorage if available. If not falls back to using the CookieJar object.
 */
ReserveInStore.LocalStorage = function (opts) {
    opts = opts || {};
    var self                 = this;
    self.localStorageEnabled = false;

    var init = function () {
        self.localStorageEnabled = isLocalStorageEnabled();
        self.cookieJar           = opts.cookieJar || new ReserveInStore.CookieJar();
        self.namespace           = "ReserveInStore";
    };

    self.clear = function() {
        if (!self.localStorageEnabled) {
            return true;
        }

        var keys = Object.keys(window.localStorage);
        for (var i = 0; i < keys.length; i++) {
            if (keys[i].indexOf(self.namespace) === 0) {
                window.localStorage.removeItem(keys[i]);
            }
        }
    };

    /**
     * Save value for the key
     */
    self.setItem = function (key, value, milliseconds) {
        if (self.localStorageEnabled) {
            if (self.namespace !== '') key = self.namespace + '.' + key;

            value = {
                value: value,
                timestamp: milliseconds ? new Date().getTime() + milliseconds : null
            };

            value = ReserveInStore.Util.encode(JSON.stringify(value));

            window.localStorage.setItem(key, value);
        } else {

            if (milliseconds) self.cookieJar.setCookie(key, value, milliseconds / 24 * 60 * 60 * 1000);
            else self.cookieJar.setCookie(key, value);
        }
    };

    /**
     * Get value for the key
     */
    self.getItem = function (key, defaultValue) {
        try {
            if (self.namespace !== '') key = self.namespace + '.' + key;

            defaultValue = defaultValue || null;
            if (self.localStorageEnabled) {
                var returnValue = window.localStorage.getItem(key);

                if (returnValue) {
                    returnValue = JSON.parse(ReserveInStore.Util.decode(returnValue));
                    if (returnValue.timestamp) {
                        if (new Date().getTime() < returnValue.timestamp) {
                            return returnValue.value;
                        } else {
                            return defaultValue;
                        }
                    }

                    return returnValue.value;
                } else {
                    return defaultValue;
                }
            } else {
                return self.cookieJar.getCookie(key);
            }
        } catch (e) {
            return null;
        }
    };

    /**
     * Save object value for the key
     */
    self.setObject = function (key, value, milliseconds) {
        return self.setItem(key, value, milliseconds);
    };

    /**
     * Get object value for the key
     */
    self.getObject = function (key, defaultValue) {
        return self.getItem(key, defaultValue);
    };

    /**
     * Delete an item given a key
     */
    self.removeItem = function(key) {
        if (self.localStorageEnabled) {
            window.localStorage.removeItem(key);
        }
    };

    /**
     * Returns true if localStorage is enabled, otherwise false
     */
    var isLocalStorageEnabled = function () {
        var testItemKey = 'LocalStorage.test';
        try {
            window.localStorage.setItem(testItemKey, 'test');
            window.localStorage.removeItem(testItemKey);
            return true;
        } catch (e) {
            return false;
        }
    };

    init();
};
