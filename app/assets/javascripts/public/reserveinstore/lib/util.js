ReserveInStore.Util = {
    /**
     * Tells you if the element selector is visible in any way in view.
     * @param $el jquery element selector
     * @returns {boolean} True if it is, false otherwise
     */
    isFullyVisible: function ($el) {
        if ($el.data('always_visible')) {
            return true;
        }

        if (typeof $ !== 'undefined' && $.fn && $.fn.jquery) {
            if (!$el.is(':visible')) {
                return false;
            }
        }

        if (!ReserveInStore.Util.isScrolledIntoView($el)) {
            return false;
        }
        if ($el.css('display') == 'none' || $el.css('visibility') == 'hidden' || $el.css('opacity') == 0) {
            return false;
        }

        var $parent = $el.parent();
        while ($parent.prop("tagName") !== 'BODY') {
            if ($parent.css('visibility') == 'hidden' || $parent.css('opacity') == 0) {
                return false;
            }
            $parent = $parent.parent();
        }

        return true;
    },

    /**
     * Opposite of #isFullyVisible()
     * @param $el jquery element selector
     * @returns {boolean} True if the element selector is NOT visible in any way in view.
     */
    isFullyInvisible: function ($el) {
        return !ReserveInStore.Util.isFullyVisible($el);
    },

    /**
     * Tells you if an element is scrolled into the current viewport
     * @param $el jquery element selector
     * @returns {boolean} True if it is, false otherwise
     */
    isScrolledIntoView: function ($el) {
        var docViewTop    = $(window).scrollTop();
        var docViewBottom = docViewTop + $(window).height();

        var elemTop    = $el.offset().top;
        var elemBottom = elemTop + $el.height();

        return ((elemBottom <= docViewBottom) && (elemTop >= docViewTop));
    },

    /**
     * Adds the Zepto library to the current document body
     */
    addZepto: function (opts) {
        var s   = document.createElement("script");
        s.type  = "text/javascript";
        s.async = !0;
        // TODO This is accessing vendor/assets/bower_components/zepto/zepto.js right now
        // Later may move it to cdn
        // opts.apiUrl is not set rn
        s.src   = "https://879409cc.ngrok.io/assets/zepto/zepto" + (opts.debugMode ? '' : '.min') + ".js";
        document.body.appendChild(s);
    },

    /**
     * @returns {*} jQuery or Zepto depending on what's available
     */
    $: function () {
        if (typeof jQuery !== 'undefined') return jQuery;
        return Zepto;
    },

    /**
     * @param str {string} String to capitalize the first letter of
     * @returns {string} joe => Joe
     */
    capitalizeFirstLetter: function (str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    },

    /**
     * Shuffles array in place.
     * @param a {Array} a items An array containing the items.
     */
    shuffleArray: function (a) {
        var j, x, i;
        for (i = a.length - 1; i > 0; i--) {
            j    = Math.floor(Math.random() * (i + 1));
            x    = a[i];
            a[i] = a[j];
            a[j] = x;
        }
        return a;
    },

    /**
     * Returns true is value is null or empty
     * @param value {*}
     */
    isNullOrEmpty: function (value) {
        return (!value || value === undefined || value === "" || value.length === 0);
    },


    /**
    *  Base64 encode / decode
    *  http://www.webtoolkit.info
    */

    // private property
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

    // public method for encoding
    encode: function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i      = 0;

        input = ReserveInStore.Util._utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output +
                this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
                this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
    },

    // public method for decoding
    decode: function (input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i      = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = this._keyStr.indexOf(input.charAt(i++));
            enc2 = this._keyStr.indexOf(input.charAt(i++));
            enc3 = this._keyStr.indexOf(input.charAt(i++));
            enc4 = this._keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

        }

        output = ReserveInStore.Util._utf8_decode(output);

        return output;

    },

    // private method for UTF-8 encoding
    _utf8_encode: function (string) {
        string      = string.replace(/\r\n/g, "\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if ((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // private method for UTF-8 decoding
    _utf8_decode: function (utftext) {
        var string = "";
        var i      = 0;
        var c      = c1 = c2 = 0;

        while (i < utftext.length) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if ((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i + 1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i + 1);
                c3 = utftext.charCodeAt(i + 2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

};
