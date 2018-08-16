/**
 * Add parsley validation to liquid forms
 *
 * REQUIRES:
 * All liquid forms are flagged with data-parsley-validate
 * All liquid inputs are flagged with data-parsley-liquid
 * All liquid inputs that require validation only if visible provide
 * data-validate-if-checked="#{selector for a .is(':checked') jquery operation}"
 */


/**
 * Function to try parsing the liquid
 * Returns true or false depending on if the parse was successful.
 * @param value {string} - the liquid
 * @returns {boolean} - if we could parse or not
 */
var parse = function (value) {
    try {
        // The javascript Liquid renderer does not support the whitespace stripping tags, so we need to get rid of them here.
        value = value.replace(new RegExp(/\s*({%-)/g, 'g'), '{%').replace(new RegExp(/(-%})\s*/, 'g'), '%}');
        Liquid.parse(value);
        return true;
    } catch (error) {
        window.Parsley.addMessage('en', "liquid", '<p><strong>' + error + '</strong></p>');
        return false;
    }
};

/**
 * Function to validate the liquid by parsing it.
 * Skip parsing if the liquid will be inactive.
 * @param value {string} - the liquid.
 * @returns {boolean} - if we passed validation.
 */
var validation = function (value, req, instance) {
    var flagId = instance.$element.data('validate-if-checked');
    if (flagId !== undefined) {
        if ($(flagId).is(':checked')) {
            return parse(value);
        }
        return true;
    } else {
        return parse(value);
    }
};

//add the validator
if (window.Parsley) {
    window.Parsley.addValidator("liquid", {
        validateString: validation
    });
}
