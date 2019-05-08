ReserveInStore.Logger = function(opts) {
    opts = opts || {};
    var self = this;

    var init = function() {
    };

    self.info = function() {
        if (opts.debugMode && window.console && !ReserveInStore.Util.ie()) {
            if (typeof arguments[0] === 'string') arguments[0] = "[ReserveInStore] " + arguments[0];
            console.info.apply(this, arguments);
        }
    };

    self.log = function() {
        if (opts.debugMode && window.console && !ReserveInStore.Util.ie()) {
            if (typeof arguments[0] === 'string') arguments[0] = "[ReserveInStore] " + arguments[0];
            console.log.apply(this, arguments);
        }
    };

    /**
     * Same thing as #warn but will only output the warning if debugMode is on.
     */
    self.logWarning = function() {
        if (opts.debugMode && window.console && !ReserveInStore.Util.ie()) {
            if (typeof arguments[0] === 'string') arguments[0] = "[ReserveInStore] " + arguments[0];
            console.apply(this, arguments);
        }
    };

    self.warn = function() {
        if (window.console && !ReserveInStore.Util.ie()) {
            if (typeof arguments[0] === 'string') arguments[0] = "[ReserveInStore] " + arguments[0];
            console.warn.apply(this, arguments);
        }
    };

    self.error = function() {
        if (window.console && !ReserveInStore.Util.ie()) {
            if (typeof arguments[0] === 'string') arguments[0] = "[ReserveInStore] " + arguments[0];
            console.error.apply(this, arguments);
        }
    };

    init();
};
