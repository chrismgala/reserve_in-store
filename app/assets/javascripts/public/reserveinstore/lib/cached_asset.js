/**
 * This is a standalone script that allows us to load cached resources via localStorage to speed initial load times.
 *
 * @version 0.2.1
 *
 * @param opts.url {string} - url to the asset
 * @param opts.name {string} - name of the asset (lowercase, underscores, no special characters)
 * @param opts.expiresIn {integer} - number of seconds to cache the asset in local storage for
 * @constructor
 */
var ReserveInStoreCachedAsset = function(opts) {
    var self = this;
    this.version = '0.2.1';

    var name = opts.name || opts.url.split('?')[0].split('#')[0];
    var storageKey = 'ReserveInStore.AssetCache.' + name;
    var now = ((new Date()).getTime() / 1000);
    var contentType =  opts.type || (opts.url.indexOf('.html') !== -1 ? 'text/template' : (opts.url.indexOf('.css') !== -1 ? 'text/css' : "text/javascript"));

    self.load = function(callback) {
        callback = callback || function() {};
        if (self.content) {
            return callback(self.content);
        }
        if (!loadFromCache()) {
            getHttpContent(opts.url, function(content) {
                self.content = content;

                outputScript(content);
                self.save(content);

                callback(content);
            });
        } else {
            callback(self.content);
        }

        return true;
    };

    self.save = function(content) {
        var expiryTime = now + (opts.expiresIn || 900);

        if (!isLocalStorageEnabled() || !content) {
            return false;
        }

        var entry = {
            name: name,
            url: opts.url,
            expires: expiryTime,
            content: content
        };

        window.localStorage.setItem(storageKey, JSON.stringify(entry));

        return true;
    };

    self.clear = function() {
        window.localStorage.removeItem(storageKey);
        return false;
    };

    var loadFromCache = function() {
        if (!isLocalStorageEnabled()) return false;

        var rawEntry = window.localStorage.getItem(storageKey);
        if (!rawEntry || typeof rawEntry !== 'string') {
            return null;
        }

        var entry = JSON.parse(rawEntry);
        if (entry.expires < now || entry.url !== opts.url) {
            return self.clear(); // Entry is expired;
        }

        self.content = entry.content;

        outputScript(self.content);

        return true;
    };

    var outputScript = function(content) {
        if (document.getElementById(storageKey)) return; // Don't output the same script twice

        var s   = document.createElement(contentType === 'text/css' ? 'style' : "script");
        s.type  = contentType;
        s.id = storageKey;
        s.async = !0;
        s.innerHTML = content;
        document.body.appendChild(s);
    };

    var getHttpContent = function(url, callback) {
        var req = new XMLHttpRequest();

        req.async = true;
        req.onreadystatechange = function() {
            if (this.readyState == 4 && this.status < 300) {
                callback(this.responseText);
            }
        };

        req.open("GET", url, true);
        req.send();
    };

    var isLocalStorageEnabled = function () {
        var testItemKey = 'test';
        try {
            window.localStorage.setItem(testItemKey, 't');
            window.localStorage.removeItem(testItemKey);
            return 1;
        } catch (e) {
            return 0;
        }
    };
};
