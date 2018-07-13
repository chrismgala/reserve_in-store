polarisTableHeaderHeightFix();

$('.location-modal-display').on('click', function () {
    $('div#location-new-container').show();
});


/**
 *
 * @param action action associated with current modal, can be either "new" or "edit"
 */
var LocationModal = function (action) {
    // this.opts = opts;
    // this.$form = opts.form;
    var self = this;

    this.init = function () {
        this.bindForm();

    };

    this.bindForm = function (){
        console.log("bindform");
        $('.location-' + action + '-close').on('click', function () {
            $('div#location-' + action + '-container').hide();
        });
        var $form = $('#location-'+action+'-form');

        $('#location-' + action + '-submit').on('click', function () {
            if ($form[0].checkValidity()) {
                $form.submit();
                $('div#location-' + action + '-container').hide();
            } else {
                $form[0].reportValidity();
            }
        });

        $('#location-'+action+'-container').on('click', function (event) {
            if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
                if ($('div#location-' + action + '-container').is(":visible")) {
                    $('div#location-' + action + '-container').hide();
                }
            }
        });
    };

    this.getCurrentState = function () {

    };

    this.init();
};

