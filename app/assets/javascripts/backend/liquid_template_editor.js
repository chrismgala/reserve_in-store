/**
 * This class utilizes ace editors for liquid template modification, and
 * implements rendering the liquid back as a view in-page
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
 * {hash} [templateRenderParameters], hash which contains the parameters for rendering the liquid into the preview
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var LiquidTemplateEditor = function (opts) {
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
        $(opts.submissionButtonSelector).click(updateFormField);
        $(opts.resetButtonSelector).on('click', resetFields);
        if (opts.previewContainerSelector) {
            $previewContainer = $(opts.previewContainerSelector);
            $(opts.updateButtonSelector).click(updatePreview);
            updatePreview();
        }
    };

    /**
     * Initialize the ace editor by setting the theme, mode, and default contents
     */
    var initAce = function () {
        templateEditor = ace.edit(opts.aceEditorId, {passive: false});
        //stops an annoying console error
        templateEditor.$blockScrolling = Infinity;
        templateEditor.setTheme("ace/theme/monokai");
        templateEditor.getSession().setMode("ace/mode/liquid");
        templateEditor.getSession().setValue($templateFormField.val(), -1);
    };

    /**
     * Shift the data from the templateEditor to the form field
     */
    var updateFormField = function () {
        var newHtml = templateEditor.getSession().getValue();
        $templateFormField.val(newHtml);
    };

    /**
     * Update our preview by first validating the liquid, then rendering it into the preview container
     */
    var updatePreview = function () {
        updateFormField();
        $templateFormField.parsley().validate();
        if ($templateFormField.parsley().isValid()) {
            //Need to regex out the whitespace removal delimiter because liquid.js doesn't like them.
            var templateHTML = $templateFormField.val().replace(new RegExp(/\s*({%-)/g, 'g'), '{%').replace(new RegExp(/(-%})\s*/, 'g'), '%}');
            $previewContainer.html(Liquid.parse(templateHTML).render(opts.templateRenderParameters));
        }
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
