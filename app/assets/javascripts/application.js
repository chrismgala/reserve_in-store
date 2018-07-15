// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require jquery
//
//= require_tree ./lib/

console.log('application.js')

/**
 *
 * @param action action associated with current modal, can be either "new" or "edit"
 */
var LocationModal = function (action) {
    // this.opts = opts;
    // this.$form = opts.form;
    var $modalContainer = $('div#location-' + action + '-container');

    this.init = function () {
        console.log("init");
        this.bindForm();
        this.setCloseConditions();

    };

    this.bindForm = function () {
        var $form = $('#location-' + action + '-form');

        $('#location-' + action + '-submit').on('click', function () {
            if ($form[0].checkValidity()) {
                $form.submit();
                $('div#location-' + action + '-container').hide();
            } else {
                $form[0].reportValidity();
            }
        });
    };

    this.setCloseConditions = function () {
        $('.location-' + action + '-close').on('click', function () {
            $('div#location-' + action + '-container').hide();
        });

        // $modalContainer.on('click', function (event) {
        //     if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
        //     //     if ($modalContainer.is(":visible")) {
        //             $modalContainer.hide();
        //     //     }
        //     }
        // });
    };

    this.init();
};
