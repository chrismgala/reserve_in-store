/**
 * This class utilizes ace editors for HTML template modification, and
 * implements rendering the HTML back as a view in-page
 *
 * Construct with the following hash:
 * {string} templateFormFieldSelector, selector for the form field we will submit
 * {string} aceEditorId, selector for the ace editor field
 * {string} resetButtonSelector, selector for the reset button
 * {string} defaultTemplateSelector, selector for the field which has .val() as the default template
 * {string} submissionButtonSelector, selector for the submit button
 * All three of these hash keys are required if you want previews, otherwise none of them are:
 * {string} [previewContainerSelector], selector for the preview container
 * {string} [updateButtonSelector], selector for the preview update button
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var HTMLTemplateEditor = function (opts) {
    opts = opts || {};
    var $templateFormField = $(opts.templateFormFieldSelector);
    var defaultTemplate = $(opts.defaultTemplateSelector).val();
    var templateEditor;
    var $previewContainer;

    /**
     * Initialize the class by setting up the ace editor and adding the event listeners
     */
    var init = function () {
        initAce();
        $(opts.submissionButtonSelector).on('click', updateFormField);
        $(opts.resetButtonSelector).on('click', resetFields);
        if (opts.previewContainerSelector) {
            $previewContainer = $(opts.previewContainerSelector);
            $(opts.updateButtonSelector).on('click', updatePreview);
            updatePreview();
        }
    };

    /**
     * Initialize the ace editor by setting the theme, mode, and default contents
     */
    var initAce = function () {
        templateEditor = ace.edit(opts.aceEditorId);
        templateEditor.setTheme("ace/theme/monokai");
        templateEditor.getSession().setMode("ace/mode/html");
        templateEditor.getSession().setValue($templateFormField.val(), -1);
        //stops an annoying console error
        templateEditor.$blockScrolling = Infinity;
    };

    /**
     * Shift the data from the templateEditor to the form field
     */
    var updateFormField = function () {
        var newHtml = templateEditor.getSession().getValue();
        $templateFormField.val(newHtml);
    };

    /**
     * Update our preview by render the HTML into the preview container
     */
    var updatePreview = function () {
        updateFormField();
        $previewContainer.html($templateFormField.val());
    };


    /**
     * Shove the default template into the template editor, then update the preview to match it
     */
    var resetFields = function (e) {
        //needed to stop link from doing anything
        e.preventDefault();
        templateEditor.getSession().setValue(defaultTemplate, -1);
        updatePreview();
    };

    init();
};

