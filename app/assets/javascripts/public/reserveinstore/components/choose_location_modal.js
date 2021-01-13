ReserveInStore.ChooseLocationModal = function (opts) {
    var self = this;
    opts = opts || {};
    var $ = ReserveInStore.Util.$();
    var api, config, $modalBackground, $modal, $clearSearchLink, visible = false;

    var locationsManager = opts.locationsManager;
    var inventoryManager = opts.inventoryManager;
    var showReserveBtnWhenUnknown = false;
    var inStockTextWhenUnknown = false;

    var inventoryTable;
    var DEFAULT_STOCK_CAPTIONS = ["No Stock", "Low Stock", "In Stock", "Stock Unknown"];

    // check stores_helper for existing key name used.
    var DEFAULT_STOCK_CAPTIONS_KEY = ["no_stock", "low_stock", "in_stock", "stock_unknown"];

    // set this default value for old stores because without reinstalling footer script labels will not be visible.
    var DEFAULT_STOCK_STATUS_LABEL_VISIBLE = {
        in_choose_location_modal_product_page: ["in_stock", "low_stock", "no_stock", "stock_unknown"]
    };

    var storeStockLabelsToDisplay = {};

    var init = function () {
        api = opts.api;
        config = opts.config || {};
        showReserveBtnWhenUnknown = config.stock_status.behavior_when && config.stock_status.behavior_when.stock_unknown.indexOf('show_button') !== -1;
        inStockTextWhenUnknown = config.stock_status.behavior_when && config.stock_status.behavior_when.stock_unknown.indexOf('in_stock') !== -1;
        storeStockLabelsToDisplay = config.stock_status.stock_label || DEFAULT_STOCK_STATUS_LABEL_VISIBLE;
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
        $clearSearchLink = $modal.find(".reserveInStore-locationSearch-clear");
        centerPriceDiv();
        setCloseConditions();

        self.$modalContainer.find('input[name="location_id"]').on('change', function() {
            setTimeout(function() {
                var locationId = self.$modalContainer.find('input[name="location_id"]:checked').val();
                locationsManager.setFavoriteLocationId(locationId);
                self.hide();
            }, 1);
        });

        $modal.find('.reserveInStore-locationSearch-btn').on('click', function(e) {
            e.preventDefault();
            var searchLocationInputValue = $modal.find(".reserveInStore-locationSearch-input").val();
            $modal.find(".ris-location-options").toggleClass("loading");
            opts.app.searchLocations.getSearchData(searchLocationInputValue, function(data)  {
                $modal.find(".ris-location-options").html('');
                $modal.find(".ris-location-options").append(opts.app.searchLocations.renderSearchHtmlChooseLocModal(data));
                updateLocationStockInfo(data);

                self.$modalContainer.find('input[name="location_id"]').on('change', function() {
                    setTimeout(function() {
                        var locationId = self.$modalContainer.find('input[name="location_id"]:checked').val();
                        locationsManager.setFavoriteLocationId(locationId);
                        self.hide();
                    }, 1);
                });

                $modal.find(".ris-location-options").toggleClass("loading");

                if (searchLocationInputValue === '') {
                   $clearSearchLink.hide();
                } else {
                   $clearSearchLink.show();
                }
            });
        });

        $modal.find('.reserveInStore-locationSearch-clear').on('click', function(e) {
            e.preventDefault();
            $modal.find(".reserveInStore-locationSearch-input").val('');
            var searchLocationInputValue = $modal.find(".reserveInStore-locationSearch-input").val();
            $modal.find(".ris-location-options").toggleClass("loading");
            opts.app.searchLocations.getSearchData(searchLocationInputValue, function(data)  {
                $modal.find(".ris-location-options").html('');
                $modal.find(".ris-location-options").append(opts.app.searchLocations.renderSearchHtmlChooseLocModal(data));
                updateLocationStockInfo(data);

                self.$modalContainer.find('input[name="location_id"]').on('change', function() {
                    setTimeout(function() {
                        var locationId = self.$modalContainer.find('input[name="location_id"]:checked').val();
                        locationsManager.setFavoriteLocationId(locationId);
                        self.hide();
                    }, 1);
                });
                $modal.find(".ris-location-options").toggleClass("loading");
                $clearSearchLink.hide();
            });
        });

        locationsManager.whenReady(function(bestLocation) {
            updateLocationStockInfo(locationsManager.getLocations());

            if (!bestLocation) return; // Could not determine best location

            self.$modalContainer.find('input[name="location_id"][value="'+bestLocation.id+'"]').prop('checked', true);
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

    /*
     * This function will show/hide stock status label depending on store settings which stock labels store owner want to show.
     * {string} stockStatusLabelId - stock status label div id eg: '#locationStockStatus-' + locations[i].id
     * {string} stockStatusLabelClassName - which classname we need to add eg: ris-location-stockStatus-in-stock
     * {string} stockStatusLabelDefaultCaption - stock label text that we want to show eg: "No Stock", "Low Stock", "In Stock"....
     * {string} stockStatusLabelWhereToDisplay - which modal and where we want to show eg: in_reserve_modal_product_page_locations
     * {string} stockStatusLabelDefaultCaptionKey - stock status label key: eg: "no_stock", "low_stock", "in_stock"....
     */
    var showHideStockStatusLabel = function (stockStatusLabelId, stockStatusLabelClassName, stockStatusLabelDefaultCaption, stockStatusLabelWhereToDisplay, stockStatusLabelDefaultCaptionKey) {
        var $stockStatusDiv = $modal.find(stockStatusLabelId);
        if (storeStockLabelsToDisplay[stockStatusLabelWhereToDisplay] && storeStockLabelsToDisplay[stockStatusLabelWhereToDisplay].indexOf(stockStatusLabelDefaultCaptionKey) !== -1) {
            $stockStatusDiv.text(stockStatusLabelDefaultCaption);
            $stockStatusDiv.addClass(stockStatusLabelClassName);
        }
    };

    var updateLocationStockInfo = function (locations) {
        var inventoryLocations;
        var $locationContainer, $locationInput, stockStatusId;

        inventoryManager.getInventory(opts.app.getProduct().id, function(_inventory) {
            inventoryTable = _inventory;
            inventoryLocations = inventoryTable[opts.app.getVariant().id];

            for (var i = 0; i < locations.length; i++) {
                $locationContainer = $modal.find('#risLocation-' + locations[i].id);
                $locationInput = $modal.find('#location_id-' + locations[i].id);
                stockStatusId = '#locationStockStatus-' + locations[i].id;
                var whereToShow = 'in_choose_location_modal_product_page';

                if (inventoryLocations[locations[i].platform_location_id] === 'in_stock') {
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
                } else if (inventoryLocations[locations[i].platform_location_id] === 'low_stock') {
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-low-stock', DEFAULT_STOCK_CAPTIONS[1], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[1]);
                } else if (inventoryLocations[locations[i].platform_location_id] === 'out_of_stock') {
                    $locationInput.prop('disabled', true);
                    $locationInput.prop('checked', false);
                    $locationContainer.addClass('ris-location-disabled');
                    showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-no-stock', DEFAULT_STOCK_CAPTIONS[0], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[0]);
                } else {
                    if (inStockTextWhenUnknown) {
                        showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-in-stock', DEFAULT_STOCK_CAPTIONS[2], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[2]);
                    } else {
                        showHideStockStatusLabel(stockStatusId, 'ris-location-stockStatus-stock-unknown', DEFAULT_STOCK_CAPTIONS[3], whereToShow, DEFAULT_STOCK_CAPTIONS_KEY[3]);
                    }
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
