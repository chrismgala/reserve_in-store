ReserveInStore.ReserveBtn = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config;

    var DEFAULT_BTN_SELECTOR = 'form[action~="/cart/add"]';
    var DEFAULT_BTN_ACTION = 'insert_after';
    var DEFAULT_BTN_TPL = '<div class="reserveInStore-btn-container" data-reserveInStoreBtn="true"><button class="btn reserveInStore-btn"><span>Reserve In Store</span></button></div>';

    var init = function () {
        config = opts.config || {};

        // detect the add to cart button
        var btnSelector, btnAction, btnTpl;

        btnAction = config.action || DEFAULT_BTN_ACTION;

        if (btnAction === 'manual') {
            // Don't try to integrate
        } else if (btnAction === 'auto') {
            insertBtn(DEFAULT_BTN_SELECTOR, DEFAULT_BTN_ACTION);
        } else {
            btnSelector = config.selector || DEFAULT_BTN_SELECTOR;
            insertBtn(btnSelector, btnAction);
        }
    };

    var insertBtn = function(targetSelector, orientation) {
        var $targets = $(targetSelector);
        var $btnContainer = $(config.tpl || DEFAULT_BTN_TPL);

        $targets.each(function() {
            var $target = $(this);

            if (!$target.next().data('reserveInStoreBtn')) {
                if (orientation === 'prepend_to') {
                    $target.prepend($btnContainer);
                } else if (orientation === 'append_to') {
                    $target.append($btnContainer);
                } else if (orientation === 'insert_before') {
                    $target.before($btnContainer);
                } else if (orientation === 'insert_after') {
                    $target.after($btnContainer);
                } else { // Manual
                    ReserveInStore.logger.error("Invalid insertion criteria: ", targetSelector, orientation, config);
                    return false;
                }
            }

            var $reserveBtn = $btnContainer.find('.reserveInStore-btn');

            if ($reserveBtn.hasClass('reserveInStore-btn--block')) setButtonWidth($reserveBtn, $target);

            $btnContainer.on('click', function(event) {
                event.preventDefault();
                self.showReserveModal();
                return false;
            });
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
