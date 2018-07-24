/**
 * Add padding to app wrapper to prevent content overlay
 * Padding need to be set in Javascript, because the height of top navigation bar changes as the
 * browser's default font size changes
 */
var addPaddingToAppWrapper = function () {
    $('div.app-wrapper').css('padding-top', $('div.top_navbar').outerHeight());
};

