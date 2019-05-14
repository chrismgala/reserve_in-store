ReserveInStore.IntegratedComponent = function (opts) {
    var self = this;
    var $ = ReserveInStore.Util.$();
    opts = opts || {};
    var config;

    var init = function () {
        config = opts.config || {};

        // detect the add to cart button
        var selector, action;

        action = config.action || opts.defaults.action;

        self.$containers = $();

        if (action === 'manual') {
            // Don't try to integrate
        } else if (action === 'auto') {
            insert(opts.defaults.selector, opts.defaults.action);
        } else {
            selector = config.selector || opts.defaults.selector;
            insert(selector, action);
        }
    };

    var insert = function(targetSelector, orientation) {
        self.$targets = $(targetSelector);

        self.$targets.each(function() {
            var $container = $(config.tpl || opts.defaults.tpl);
            var $target = $(this);

            if (opts.visibleInitially === false) $container.hide();

            if (orientation === 'prepend_to') {
                if (!$target.children().first().data(opts.dataKey)) {
                    $target.prepend($container);
                }
            } else if (orientation === 'append_to') {
                if (!$target.children().last().data(opts.dataKey)) {
                    $target.append($container);
                }
            } else if (orientation === 'insert_before') {
                if (!$target.prev().data(opts.dataKey)) {
                    $target.before($container);
                }
            } else if (orientation === 'insert_after') {
                if (!$target.next().data(opts.dataKey)) {
                    $target.after($container);
                }
            } else { // Manual
                ReserveInStore.logger.error("Invalid insertion criteria: ", targetSelector, orientation, config);
                return false;
            }

            $container.data(opts.dataKey, self);

            self.$containers = self.$containers.add($container);

            opts.afterInsert($container, $target);
        });
    };

    self.show = function() {
        return self.$containers.show();
    };
    self.hide = function() {
        return self.$containers.hide();
    };
    self.find = function() {
        return self.$containers.find(arguments[0]);
    };
    self.each = function() {
        return self.$containers.each(arguments[0]);
    };
    self.children = function() {
        return self.$containers.children(arguments[0]);
    };
    self.parents = function() {
        return self.$containers.parents(arguments[0]);
    };



    init();
};
