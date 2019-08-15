ReserveInStore.ReserveCartBtn = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config, component;

    var DEFAULT_SELECTOR = 'form[action~="/cart"] input[type="submit"][name="checkout"],form[action~="/cart"] button[type="submit"][name="checkout"]';
    var DEFAULT_ACTION = 'insert_after';
    var DEFAULT_TPL = '<div class="reserveInStore-btn-container reserveInStore-reserveCart-btn-container"><button class="btn reserveInStore-btn reserveInStore-reserveCart-btn"><span>Reserve In Store</span></button></div>';

    var init = function () {
        config = opts.config || {};

        component = new ReserveInStore.IntegratedComponent({
            dataKey: 'reserveInStore-reserveCartBtn',
            defaults: {
                tpl: DEFAULT_TPL,
                action: DEFAULT_ACTION,
                selector: DEFAULT_SELECTOR
            },
            config: config,
            afterInsert: afterInsert
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

    init();
};
