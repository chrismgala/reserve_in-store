ReserveInStore.ReserveProductBtn = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config, component;

    var DEFAULT_SELECTOR = 'form[action~="/cart/add"] .product-form__buttons, form[action~="/cart/add"]';
    var DEFAULT_ACTION = 'insert_after';
    var DEFAULT_TPL = '<div class="reserveInStore-btn-container reserveInStore-reserveProduct-btn-container"><button class="btn reserveInStore-btn reserveInStore-reserveProduct-btn"><span>Reserve In Store</span></button></div>';

    var showWhenUnknown = false;

    var init = function () {
        config = opts.config || {};

        showWhenUnknown = config.stock_status.behavior_when && config.stock_status.behavior_when.stock_unknown.indexOf('show_button') !== -1;

        component = new ReserveInStore.IntegratedComponent({
            dataKey: 'reserveInStore-reserveProductBtn',
            defaults: {
                tpl: DEFAULT_TPL,
                action: DEFAULT_ACTION,
                selector: DEFAULT_SELECTOR
            },
            config: config.reserve_product_btn,
            afterInsert: afterInsert
        });

        opts.app.on('stock_status.change', function(eventData) {
            toggleIfOutOfStock(component.$containers);
        });
    };

    var afterInsert = function($container, $target) {
        var $reserveBtn = $container.find('.reserveInStore-btn');

        if ($reserveBtn.hasClass('reserveInStore-btn--block')) setButtonWidth($reserveBtn, $target);

        $container.on('click', function(event) {
            event.preventDefault();
            opts.onClick();
            return false;
        });

        toggleIfOutOfStock($container);
    };

    /**
     * Set the Reserve In-Store button's width to be the greater of Add To Cart button's width and its default value
     */
    var setButtonWidth = function(reserveBtn, addToCartBtn) {
        var addToCartBtnWidth = parseInt(addToCartBtn.css("width"));
        if (parseInt(reserveBtn.css("width")) < addToCartBtnWidth){
            reserveBtn.css("width", addToCartBtnWidth + "px");
        }
    };

    var toggleIfOutOfStock = function($container) {
        opts.app.getStockStatus(function(stockStatus) {
            if (stockStatus === 'out_of_stock' || (!showWhenUnknown && stockStatus === 'stock_unknown')) {
                $container.hide();
            } else if(stockStatus) {
                $container.show();
            } else {
                $container.hide();
            }
        });
    };

    init();
};
