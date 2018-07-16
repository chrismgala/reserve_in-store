/**
 * For a data table with Polaris CSS
 * Table headers in the first column will not align with the rest of corresponding row
 * Shopify solves this by setting the height of every cell in React
 *
 * Adjust the height of table headers to be the same as the cell next to it
 */
var polarisTableHeaderHeightFix = function () {
    $('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
            $(this).outerHeight($(this).next().outerHeight());
        }
    );
};
