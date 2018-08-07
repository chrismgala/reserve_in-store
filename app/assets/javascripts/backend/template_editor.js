// var TemplateEditor = function (opts) {
//     opts = opts || {};
//
//     var init = function () {
//         initAce();
//         // $(opts.submissionButtonSelector).click(updateFormField);
//         // $(opts.resetButtonSelector).on('click', resetFields);
//         // if (opts.previewContainerSelector) {
//         //     $previewContainer = $(opts.previewContainerSelector);
//         //     $(opts.updateButtonSelector).click(updatePreview);
//         //     updatePreview();
//         // }
//         console.log("init");
//     };
//
//     var initAce = function () {
//         templateEditor = ace.edit('ace_location_editor');
//         templateEditor.setTheme("ace/theme/monokai");
//         templateEditor.getSession().setMode("ace/mode/html");
//         templateEditor.getSession().setValue('<p>hello world!</p>');
//         //stops an annoying console error
//         templateEditor.$blockScrolling = Infinity;
//         console.log("initAce");
//     };
//
//     init();
// };

/**
 * This class utilizes ace editors for liquid template modification, and
 * implements rendering the liquid back as a view in-page
 *
 * Construct with the following hash:
 * {string} templateFormFieldSelector, selector for the form field we will submit
 * {string} aceEditorId, selector for the ace editor field
 * {string} resetButtonSelector, selector for the reset button
 // * {string} defaultTemplateSelector, selector for the field which has .val() as the default template
 * {string} submissionButtonSelector, selector for the submit button
 * All three of these hash keys are required if you want previews, otherwise none of them are:
 * {string} [previewContainerSelector], selector for the preview container
 * {string} [updateButtonSelector], selector for the preview update button
 // * {hash} [templateRenderParameters], hash which contains the parameters for rendering the liquid into the preview
 *
 * @param {object} [opts] - An optional hash used for setup, as described above.
 */
var TemplateEditor = function (opts) {
    opts = opts || {};
    var $templateFormField = $(opts.templateFormFieldSelector);
    // var defaultTemplate = $(opts.defaultTemplateSelector).val();
    var templateEditor;
    var $previewContainer;

    /**
     * Initialize the class by setting up the ace editor and adding the event listeners
     */
    var init = function () {
        initAce();
        $(opts.submissionButtonSelector).click(updateFormField); // TODO change to jQuery on click
        $(opts.resetButtonSelector).on('click', resetFields);
        if (opts.previewContainerSelector) {
            $previewContainer = $(opts.previewContainerSelector);
            $(opts.updateButtonSelector).click(updatePreview); // TODO change to jQuery on click
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
     * Update our preview by first validating the liquid, then rendering it into the preview container
     */
    var updatePreview = function () {
        updateFormField();
        // $templateFormField.parsley().validate(); // TODO not validating
        if (true || $templateFormField.parsley().isValid()) {
            // TODO delete later this regex gsub, cuz we are not using Liquid
            // Need to regex out the whitespace removal delimiter because liquid.js doesn't like them.
            // var templateHTML = $templateFormField.val().replace(new RegExp(/\s*({%-)/g, 'g'), '{%').replace(new RegExp(/(-%})\s*/, 'g'), '%}');
            var templateHTML = $templateFormField.val();
            // $previewContainer.html(Liquid.parse(templateHTML).render(opts.templateRenderParameters)); // TODO Ummm not sure what to do
            $previewContainer.html(templateHTML);
        }
    };

    /**
     * Shove the default template into the template editor, then update the preview to match it
     */
    var resetFields = function (e) {
        //needed to stop link from doing anything
        e.preventDefault();
        templateEditor.getSession().setValue(defaultTemplate, -1); // TODO reset default Template value
        updatePreview();
    };

    init();
};

