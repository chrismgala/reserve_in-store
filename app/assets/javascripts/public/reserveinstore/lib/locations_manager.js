ReserveInStore.LocationsManager = function (opts) {
    var self = this;
    opts = opts || {};
    var api = opts.api,
        storage = opts.storage,
        geo = new ReserveInStore.Geo({ localStorage: storage });
    var geoReady = false, locationsReady = false, ready = false;
    var locations;

    var favoriteLocation;

    var init = function() {
        loadData();

        waitForAllReady();

        self.whenReady(function(bestLocation) {
            ReserveInStore.logger.info("Location Manager ALL Ready!", favoriteLocation, locations, geo, bestLocation);
        })
    };

    self.whenReady = function(then) {
        var readyCheck = function() {
            if (ready) {
                clearInterval(readyWaiter);
                then(self.getBestLocation(), favoriteLocation);
            }
        };
        var readyWaiter = setInterval(readyCheck, 1);
        readyCheck();
    };

    self.getLocations = function() {
        return locations;
    };

    self.setFavoriteLocationId = function(locationId) {
        var _locations = self.where({ id: locationId });
        if (_locations.length < 1) return false;
        self.setFavoriteLocation(_locations[0]);
        return true;
    };

    self.setFavoriteLocation = function(location) {
        var originalLocation = favoriteLocation;
        favoriteLocation = location;
        storage.setItem('LocationsManager.favoriteLocation', location, 1000*60*60*24*365); // Save for 1 year.

        if (originalLocation !== location) {
            opts.app.trigger('location.change', { old: originalLocation, new: location, original: originalLocation });
        }
    };

    self.getBestLocation = function() {
        if (favoriteLocation) {
            return favoriteLocation;
        }

        return null; //self.findNearestLocation();
    };

    self.findNearestLocation = function() {
        // Match country, region and city
        var matches = self.where({ country: geo.ipResult.country_name, state: geo.ipResult.region_name, city: geo.ipResult.city });
        if (matches.length > 0) return matches[0];

        // Match country, region
        matches = self.where({ country: geo.ipResult.country_name, state: geo.ipResult.region_name });
        if (matches.length > 0) return matches[0];

        // Match country
        matches = self.where({ country: geo.ipResult.country_name });
        if (matches.length > 0) return matches[0];

        return null
    };

    self.where = function(attr) {
        var matchedLocations = [];

        for (var i = 0; i < locations.length; i ++) {
            var location = locations[i];
            var attrKeys = Object.keys(attr);
            var matchedAllAttr = true;
            for (var ki = 0; ki < attrKeys.length; ki++) {
                var attrKey = attrKeys[ki];
                if (location[attrKey] != attr[attrKey]) {
                    matchedAllAttr = false;
                    break;
                }
            }
            if (matchedAllAttr) matchedLocations.push(location);
        }

        return matchedLocations;
    };


    var waitForAllReady = function() {
        var readyCheck = function() {
            if (geoReady && locationsReady) {
                ready = true;
                clearInterval(readyWaiter);
            }
        };
        var readyWaiter = setInterval(readyCheck, 1);
        readyCheck();
    };

    var loadData = function() {
        favoriteLocation = storage.getItem('LocationsManager.favoriteLocation');

        loadLocations();

        geo.getLocationInfo(function() {
            geoReady = true;
        });
    };

    var loadLocations = function() {
        locations = storage.getItem('LocationsManager.locations');

        if (!locations) {
            api.getLocations({}, function(_locations) {
                locations = _locations;
                storage.setItem('LocationsManager.locations', locations, opts.debugMode ? 1 : 1000*60*15); // Save for 15 minutes unless debug mode is on
                locationsReady = true;
                if (favoriteLocation) ready = true;
            });
        } else {
            locationsReady = true;
            if (favoriteLocation) ready = true;
        }
    };

    init();
};
