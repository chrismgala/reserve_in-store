ReserveInStore.CookieJar = function(data) {
    var self = this;

    var init = function () {
    };

    self.setCookie = function (name, value, days) {
        var expires = "";
        if (days) {
            var date = new Date();
            date.setTime(date.getTime() + (days*24*60*60*1000));
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = name + "=" + value + expires + "; path=/";
    };

    self.getCookie = function (name, defaultValue) {
        defaultValue = defaultValue || null;
        var nameEQ = name + "=";
        var ca = document.cookie.split(';');
        for(var i=0;i < ca.length;i++) {
            var c = ca[i];
            while (c.charAt(0)==' ') c = c.substring(1,c.length);
            if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
        }

        return defaultValue;
    };

    self.getCookieObject = function(name, defaultValue) {
        var value = self.getCookie(name, defaultValue);
        if (typeof value === 'string') {
            value = JSON.parse(decodeURIComponent(atob(value)));
        }
        return value;
    };

    self.setCookieObject = function(name, value, days) {
        value = btoa(encodeURIComponent(JSON.stringify(value)));
        return self.setCookie(name, value, days);
    };

    init();
};
