/**
 * For a data table with Polaris CSS
 * Table headers in the first column will not align with the rest of its corresponding row
 * Shopify solves this by setting the height of every cell in React
 * The function below is used to fix this problem
 *
 * Adjust the height of table headers to be the same as the cell next to it
 */
var polarisTableHeaderFix = function () {
    $('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
            $(this).outerHeight($(this).next().outerHeight());
            var $headerText = $(this).find('p.polaris-header-text');
            $headerText.css('padding-top', ($(this).height() - $headerText.height()) * 0.5 + 'px');
        }
    );
};
