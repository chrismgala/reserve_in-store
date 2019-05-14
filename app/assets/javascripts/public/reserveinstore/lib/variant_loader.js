ReserveInStore.VariantLoader = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();

    var variant, $form;


    var init = function() {
        $form = $('form[action~="/cart/add"]');

        loadVariant();

        $form.find(':input').on('change', function() {
           setTimeout(function() {
               loadVariant();
           }, 1);
        });

        $(window).on('hashchange', function(e){
            setTimeout(function() {
                loadVariant();
            }, 1);
        });
    };

    /**
     * Get variant ID from the add to cart form, if failed, try parsing the URL to get variant ID
     */
    var loadVariant = function () {
        var variantId = findVariantId();
        variant = findVariant(variantId);

        if (opts.app.getVariant() !== variant) {
            opts.app.setVariant(variant);
        }
    };

    var findVariant = function(variantId) {
        var prod = opts.app.getProduct();
        if (!prod) return null;

        return $.grep(prod.variants, function (obj) {
            return parseInt(obj.id) === parseInt(variantId);
        })[0];
    };

    var findVariantId = function() {
        variantId = tryGetVariantIdFromURL();
        if (variantId && variantId !== '') return parseInt(variantId);

        var formDataArray = $form.serializeArray();
        var variantIdEntry = formDataArray.find(function (obj) {
            return obj.name === "id";
        });
        var variantId;

        if (variantIdEntry) {
            variantId = parseInt(variantIdEntry.value);
            return variantId;
        }

        var prod = opts.app.getProduct();

        if (!prod) return null;

        return parseInt(prod.variants[0].id);
    };

    /**
     * If variant id is in url's query string, set variant ID
     */
    var tryGetVariantIdFromURL = function () {
        var re_variant = /variant=(.*?)(&|$)/,
            matchVariantId = window.location.href.match(re_variant);
        if (matchVariantId) {
            return parseInt(matchVariantId[1]);
        }

        return null;
    };

    init();
};
