/**
 * This class solves the issue of parsley form bindings when combined with turbolinks.
 * We simply manually run parsley on form button click.
 *
 * Construct with the following hash:
 * {string} formSelector, selector for the form field we will submit
 * {string} btnSelector, selector for the submit button
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var ParsleyBinder = function (opts) {
    var $form = $(opts.formSelector);
    var init = function () {
        $(opts.btnSelector).on('click', validateParsley);
    };
    var validateParsley = function (e) {
        $form.parsley().validate();
        if (!$form.parsley().isValid()) {
            e.preventDefault();
        }
    };
    init();
};
