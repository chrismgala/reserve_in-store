/**
 * Display certain blocks if the value of a field is something specific.
 * # Automatic Usage
 * ```
 *      <select id="test">
 *          <option value="foo">foo</option>
 *          <option value="bar">bar</option>
 *      </select>
 *      <div class="display-if-selected-option" data-if_selected_option="#test" data-selected_value="foo">
 *          You selected "foo".
 *      </div>
 * ```
 * # Manual Usage
 * Automatically triggers if the class values are set one the DOM is available, however if you want
 * to trigger it manually (for ajax or dynamic content), then use $('some-element').displayIfSelectedValue();
 */
var DisplayIfSelectedValue = function($targetEl) {
    var self = this;
    var $questionEl = $($targetEl.data('if_selected_option'));
    var displayIfValueIs = String($targetEl.data('selected_value'));
    if (typeof displayIfValueIs !== 'undefined') displayIfValueIs = String(displayIfValueIs);

    var displayIfValuesAre = $targetEl.data('selected_values');
    var displayIfNotValue = $targetEl.data('selected_value_not');
    if (typeof displayIfNotValue !== 'undefined') displayIfNotValue = String(displayIfNotValue);

    var init = function() {
        $questionEl.on('change', function() {
            self.showOrHide();
        });

        self.showOrHide();
    };

    this.showOrHide = function() {
        var numChecks = $questionEl.map(function() {
            var $thisQuestionEl = $(this);
            if (displayIfNotValue) {
                return String($thisQuestionEl.val()) !== displayIfNotValue;
            } else if (displayIfValuesAre) {
                return displayIfValuesAre.split(",").indexOf(String($thisQuestionEl.val())) !== -1;
            } else {
                return String($thisQuestionEl.val()) === displayIfValueIs;
            }
        }).toArray().reduce(function(a, b) { return a + b; }, 0);

        if ($questionEl.length > 0 && numChecks == $questionEl.length) {
            $targetEl.show();
        } else {
            $targetEl.hide();
            if ($targetEl.is('option')) {
                var $sel = $targetEl.parent();
                //  Triggering in a timeout so other show/hide actions can run first.
                setTimeout(function() {
                    var $firstEl;
                    $sel.find('option').each(function() {
                        if ($(this).css('display') !== 'none') $firstEl = $(this);
                    });
                    if ($firstEl) $sel.val($firstEl.val());
                }, 10);
            }
        }

        return this;
    };

    init();
};

$.fn.displayIfSelectedValue = function displayIfSelectedValue(options) {
    if (!this.data('displayIfSelectedValue')) {

        if (this.hasClass('display-if-selected-option')) {
            this.each(function() {
                $(this).data('displayIfEnabled', new DisplayIfSelectedValue($(this)));
            });
        } else {
            this.find('.display-if-selected-option').each(function() {
                $(this).displayIfSelectedValue(options);
            });

            return this;
        }
    }

    return this;
};

$(document).ready(function() {
    $('.display-if-selected-option').displayIfSelectedValue();
});

