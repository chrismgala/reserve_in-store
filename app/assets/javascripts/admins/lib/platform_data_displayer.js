/**
 * Class to implement reservation product platform_data buttons
 * Can pass in option parameter title to set the title of the popup.
 * @param {object} opts - The options passed through, required for setup
 */
var AdminPlatformDataDisplayer = function(opts) {

    opts = opts || {};
    var $dataTable = $('#' + opts.tableId);
    var $dataButtons = $dataTable.find('.' + opts.buttonClass);

    /**
     * Prepare our buttons for clicking.
     * For each data button, store the current element into $button and then set up a listener
     * for a click event on the button. This listener will execute displayData with the text
     * from the first dataClass element that is beneath the $button that is clicked.
     * @constructs
     */
    var init = function () {
        $dataButtons.each(function () {
            var $button = $(this);
            $button.on("click", function() {
                displayData($button.find('.' + opts.dataClass).first().text());
            });
        });
    };

    /**
     * Construct an html table out of the provided json object.
     * Create a temp table which contains all heading code for a vertical html table.
     * Then for each json object pair, build a th/td pair, in which any non-null JSON object
     * is going to recursively build another table. Then return the table with concluding tags.
     * @param {object} jsonObject - A json object to be parsed into a table
     * @return {string} - An html table string
     */
    var buildHtmlTable = function (jsonObject) {
        //strings often end up in arrays, and when we recur they will end up constructing a table for each character
        //that is bad, so we stop that here.
        if (typeof jsonObject === "string") {
            return jsonObject;
        }
        var tempTable = '<div class="swal-table"><table class="table table-responsive table-striped">';
        for (var key in jsonObject) {
            var keyVal = jsonObject[key];
            if (typeof keyVal === "object") {
                if (keyVal !== null && keyVal !== undefined) {
                    if (keyVal.constructor === [].constructor) {
                        keyVal.forEach(function (item, index) {
                            tempTable += '<tr><th>' + key +' #' + (index+1) + '</th><td>' + buildHtmlTable(item) + '</td></tr>';
                        });
                    } else {
                        tempTable += '<tr><th>' + key + '</th><td>' + buildHtmlTable(keyVal) + '</td></tr>';
                    }
                }
            }
            else {
                tempTable += '<tr><th>' + key + '</th><td>' + jsonObject[key] + '</td></tr>';
            }

        }
        return tempTable + '</table></div>';
    };

    /**
     * Create a swal notification with a table built out of the provided json string.
     * Utilize the helper function and JSON.parse to convert out string json into an html
     * table string. Proceed to call swal to create the notification.
     * @param {string} stringJsonObject - A string representation of a JSON object to output
     */
    var displayData = function (stringJsonObject) {
        var htmlTable = buildHtmlTable(JSON.parse(stringJsonObject));
        swal({
            title: (opts.title || "Platform Data"),
            html: htmlTable,
            customClass: 'swal2-fullScreen'
        }).then(function() {}, function() {});
    };

    init();
};
