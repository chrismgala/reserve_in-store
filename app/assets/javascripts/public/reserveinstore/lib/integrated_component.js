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
        self.$container = $(config.tpl || opts.defaults.tpl);

        if (opts.visibleInitially === false) self.$container.hide();

        self.$targets.each(function() {
            var $target = $(this);

            if (orientation === 'prepend_to') {
                if (!$target.children().first().data(opts.dataKey)) {
                    $target.prepend(self.$container);
                }
            } else if (orientation === 'append_to') {
                if (!$target.children().last().data(opts.dataKey)) {
                    $target.append(self.$container);
                }
            } else if (orientation === 'insert_before') {
                if (!$target.prev().data(opts.dataKey)) {
                    $target.before(self.$container);
                }
            } else if (orientation === 'insert_after') {
                if (!$target.next().data(opts.dataKey)) {
                    $target.after(self.$container);
                }
            } else { // Manual
                ReserveInStore.logger.error("Invalid insertion criteria: ", targetSelector, orientation, config);
                return false;
            }

            opts.afterInsert(self.$container, $target);

            self.$container.data(opts.dataKey, self);
        });
    };

    self.show = function() {
        return self.$container.show.apply(self.$container, arguments);
    };
    self.hide = function() {
        return self.$container.hide.apply(self.$container, arguments);
    };
    self.find = function() {
        return self.$container.find.apply(self.$container, arguments);
    };
    self.each = function() {
        return self.$container.each.apply(self.$container, arguments);
    };
    self.children = function() {
        return self.$container.children.apply(self.$container, arguments);
    };
    self.parents = function() {
        return self.$container.parents.apply(self.$container, arguments);
    };



    init();
};
