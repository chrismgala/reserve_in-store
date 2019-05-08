/**
 * Display certain blocks if a checkbox or radio button is on or not off
 * # Automatic Usage
 * ```
 *      <label><input type="checkbox" id="test">Check here if you are cool</label>
 *
 *      <div class="display-if-selected-option" data-if_enabled_selector="#test">
 *          You are cool.
 *      </div>
 *      <div class="display-if-selected-option" data-if_enabled_selector="#test" data-if_not_enabled="true">
 *          You are NOT cool.
 *      </div>
 * ```
 * # Manual Usage
 * Automatically triggers if the class values are set one the DOM is available, however if you want
 * to trigger it manually (for ajax or dynamic content), then use $('some-element').displayIfSelectedValue();
 */
var DisplayIfEnabled = function($targetEl) {
    var self = this;

    var $questionEl = $($targetEl.data('if_enabled_selector'));
    var inverse = $targetEl.data('if_not_enabled') === true;
    var displayIfValue = $targetEl.data('if_enabled_value');
    var displayIfNotValue = $targetEl.data('if_enabled_not_value');

    var init = function() {
        $questionEl.on('change' + (displayIfValue ? ' click' : ''), function() {
            self.showOrHide();
        });

        self.showOrHide();
    };

    this.showOrHide = function() {
        var numChecks = $questionEl.map(function() {
            var $thisQuestionEl = $(this);
            if (displayIfValue) {
                return ($thisQuestionEl.val() == displayIfValue) ? 1 : 0;
            } else if (displayIfNotValue) {
                return ($thisQuestionEl.val() != displayIfNotValue) ? 1 : 0;
            } else {
                var checked = $thisQuestionEl.is(':checked');
                return checked ? (inverse ? 0 : 1): (inverse ? 1 : 0);
            }
        }).toArray().reduce(function(a, b) { return a + b; }, 0);

        if ($questionEl.length > 0 && numChecks == $questionEl.length) {
            $targetEl.show();
        } else {
            $targetEl.hide();
        }

        return this;
    };

    init();
};

$.fn.displayIfEnabled = function displayIfEnabled(options) {
    if (!this.data('displayIfEnabled')) {
        if (this.hasClass('display-if-enabled')) {
            this.each(function() {
                $(this).data('displayIfEnabled', new DisplayIfEnabled($(this)));
            });
        } else {
            this.find('.display-if-enabled').each(function() {
               $(this).displayIfEnabled(options);
            });

            return this;
        }
    }

    return this;
};

$(document).ready(function() {
    $('.display-if-enabled').displayIfEnabled();
});
