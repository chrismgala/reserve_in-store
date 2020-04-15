ReserveInStore.ChooseLocationModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();
    var api, $modalBackground, $modal, visible = false;

    var locationsManager = opts.locationsManager;
    var inventoryManager = opts.inventoryManager;

    var inventoryTable;
    var DEFAULT_STOCK_CAPTIONS = ["No Stock", "Low Stock", "In Stock"];

    var init = function () {
        api = opts.api;
    };

    /**
     * Get product id/title and variant id/title, then make API call and display the modal
     */
    self.show = function () {
        if (visible) return; // Already visible

        self.$modalContainer = $('#reserveInStore-chooseLocationModalContainer');
        if (self.$modalContainer.length < 1) {
            self.$modalContainer = $('<div class="reserveInStore-chooseLocationModal-container" id="reserveInStore-chooseLocationModalContainer" style="display:none;"></div>').appendTo('body');
        }

        api.getLocationsModal(locationsManager.getLocationProductParams(), self.createModal);
    };


    /**
     * Insert the HTML code of two modals into the container:
     * $modal is for creating new reservation, collecting customer's information
     * $successModal is to be displayed after new reservation is created
     * @param modalHTML {string} the HTML code of two modals
     */
    self.createModal = function (modalHTML) {
        self.$modalContainer.html(modalHTML);
        self.$modalContainer.show();
        $modalBackground = self.$modalContainer.find('.reserveInStore-modal-background');
        $modal = $modalBackground.find('.reserveInStore-reserve-modal');
        centerPriceDiv();
        setCloseConditions();

        self.$modalContainer.find('input[name="location_id"]').on('change', function() {
            setTimeout(function() {
                var locationId = self.$modalContainer.find('input[name="location_id"]:checked').val();
                locationsManager.setFavoriteLocationId(locationId);
                self.hide();
            }, 1);
        });

        locationsManager.whenReady(function(bestLocation) {
            if (!bestLocation) return; // Could not determine best location

            self.$modalContainer.find('input[name="location_id"][value="'+bestLocation.id+'"]').prop('checked', true);

            updateLocationStockInfo(locationsManager.getLocations());
        });

        adjustModalHeight();

        visible = true;

        opts.app.trigger('choose_location_modal.create', self);

        opts.app.trigger('choose_location_modal.show choose_location_modal.open', self);
    };

    self.hide = self.close = function() {
        if (!visible) return; // Already hidden

        self.$modalContainer.hide();

        visible = false;

        opts.app.trigger('choose_location_modal.close choose_location_modal.hide', self);
    };

    var adjustModalHeight = function() {
        var $fit = self.$modalContainer.find('.reserveInStore-modal--fitContents');
        if ($fit.length < 1) return; // No fitting needed.

        var totalHeight = 80;
        $fit.children().each(function() {
            var $el = $(this);
            totalHeight += $el.height();
            if ($el.css('padding-top')) totalHeight += parseInt($el.css('padding-top'));
            if ($el.css('padding-bottom')) totalHeight += parseInt($el.css('padding-bottom'));
            if ($el.css('margin-top')) totalHeight += parseInt($el.css('margin-top'));
            if ($el.css('margin-bottom')) totalHeight += parseInt($el.css('margin-bottom'));
        });

        $fit.css('max-height', totalHeight);
    };

    var updateLocationStockInfo = function (locations) {
        var inventoryLocations;
        var $locationContainer, $locationInput, $stockStatusDiv;

        inventoryManager.getInventory(opts.app.getProduct().id, function(_inventory) {
            inventoryTable = _inventory;
            inventoryLocations = inventoryTable[opts.app.getVariant().id];

            for (var i = 0; i < locations.length; i++) {
                $locationContainer = $modal.find('#risLocation-' + locations[i].id);
                $locationInput = $modal.find('#location_id-' + locations[i].id);
                $stockStatusDiv = $modal.find('#locationStockStatus-' + locations[i].id);

                if (inventoryLocations[locations[i].platform_location_id] === 'in_stock') {
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[2]);
                    $stockStatusDiv.addClass('ris-location-stockStatus-in-stock');
                } else if (inventoryLocations[locations[i].platform_location_id] === 'low_stock') {
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[1]);
                    $stockStatusDiv.addClass('ris-location-stockStatus-low-stock');
                } else if (inventoryLocations[locations[i].platform_location_id] === 'out_of_stock') {
                    $locationInput.prop('disabled', true);
                    $locationInput.prop('checked', false);
                    $locationContainer.addClass('ris-location-disabled');
                    $stockStatusDiv.text(DEFAULT_STOCK_CAPTIONS[0]);
                    $stockStatusDiv.addClass('ris-location-stockStatus-no-stock');
                }
            }
        });
    };

    /**
     * Center the price
     */
    var centerPriceDiv = function () {
        var $priceDiv = $modal.find('.ris-product-price');
        $priceDiv.css('padding-top', ($modal.find('.ris-product-detail').height()-$priceDiv.height())*0.5 + 'px');
    };

    /**
     * Set close conditions to two modals: click on the "x", "OK" or click anywhere outside of the modal
     */
    var setCloseConditions = function () {
        var $span = $modalBackground.find(".reserveInStore-reserve-close, .reserveInStore-success-close");
        $span.on('click', function () {
            self.hide();
        });

        $(document).on('click', function (event) {
            if (!$(event.target).closest('.reserveInStore-reserve-modal, .reserveInStore-success-modal', $modalBackground).length) {
                self.hide();
            }
        });
    };

    init();
};
