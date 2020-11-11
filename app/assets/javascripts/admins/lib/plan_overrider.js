/**
 * Class to override a stores properties (recommended plan).
 * @param {object} opts - The options passed through, required for setup
 */
var PlanOverrider = function(opts) {
    opts = opts || {};
    var storeId = opts.store_id;
    var userId = opts.user_id;
    var overriding;

    // jQuery variables
    var $inputSection = $('#' + opts.section_id);
    var $buttonSection = $('#' + opts.button_id);
    var $planDropDown = $('#' + opts.plan_drop_down_id);

    var $submitButton = $inputSection.find('.btn-success');
    var $planButton = $buttonSection.find('.override-plan');
    var $planInput = $inputSection.find('.plan-input');
    var $backButton = $inputSection.find('.btn-cancel');
    var $clearOverrideButton = $inputSection.find('.btn-info');

    var overrideLookup = {
        'recommended_plan': $planInput.find('#planOverrideSelector'),
    };

    var init = function() {
        $planDropDown.chosen({ width: '100%' }).trigger("chosen:updated");
        $backButton.on("click", toggleInputScreen);
        $submitButton.on("click", createTrialExtensionNotePopup);
        $clearOverrideButton.on("click", clearCurrentOverride);
        $planButton.on("click", function() { showingPlanInput('recommended_plan'); });
    };

    /**
     * Determine what input box to display
     * @param showing - if true, show the tab with the same value as showing
     */
    var showingPlanInput = function(showing) {
        toggleInputScreen();
        $planInput.toggle(showing === 'recommended_plan');
        overriding = showing;
    };

    /**
     * Toggle what section to show, whether the type selector screen or the input screen
     */
    var toggleInputScreen = function() {
        $inputSection.toggle();
        $buttonSection.toggle();
    };

    var refreshView = function() {
        window.location.reload();
    };

    var submitOverride = function(note) {
        note = note || "No note.";
        var currentValue = overrideLookup[overriding].val();

        if (!currentValue) {
            var errorMsg = (note.length === 0) ? "You must leave a reason for overriding." : "You must specify the value of the override.";
            swal({ title: "Failed", text: errorMsg, type: "error" });
        } else {
            note = "Override " + overriding + " to " + currentValue + ": " + note;
            $.ajax({
                type: "POST", beforeSend: function(xhr){ xhr.setRequestHeader('X-CSRF-Token', AUTH_TOKEN); }, url: '/admin/stores/override_subscriptions', data: { value: currentValue, overriding: overriding, note: note, user_id: userId, store_id: storeId }, dataType: "json"
            }).done(function (value) {
                swal({ title: "Success", text: "The trial has been extended. Hold on while we refresh the data.", type: "success", onClose: refreshView() });
            }).fail(function (jqXHR, textStatus, errorThrown) {
                swal({ title: "Failed", text: "Your request has failed: " + textStatus + ", " + errorThrown, type: "error" });
            });
        }
    };

    var submitOverrideClear = function(note) {
        note = note || "No note.";

        note = "Cleared " + overriding + " override: " + note;
        $.ajax({
            type: "POST", beforeSend: function(xhr){ xhr.setRequestHeader('X-CSRF-Token', AUTH_TOKEN); }, url: '/admin/stores/override_subscriptions', data: { value: null, overriding: overriding, note: note, user_id: userId, store_id: storeId }, dataType: "json"
        }).done(function (value) {
            swal({ title: "Success", text: "Recommended plan changed. Hold on while we refresh the data.", type: "success", onClose: refreshView() });
        }).fail(function (jqXHR, textStatus, errorThrown) {
            swal({ title: "Failed", text: "Your request has failed: " + textStatus + ", " + errorThrown, type: "error" });
        });
    };

    /**
     * A function to display a general sweet alert popup
     * @throws - if no extend-trial-date is available
     */
    var generalAlert = function(title, text, placeholder, confirm) {
        if ($inputSection.length < 1) throw new Error("The input section was not found.");

        swal({
            title: title,
            text: text,
            input: 'text',
            inputPlaceholder: placeholder,
            showCancelButton: true,
            confirmButtonText: 'Submit',
            showLoaderOnConfirm: true,
            allowOutsideClick: !swal.isLoading,
            preConfirm: confirm
        });
    };

    var clearCurrentOverride = function() {
        generalAlert(
            'Clear Override Note',
            'Are you sure you want to clear the override for ' + overriding + '?',
            'Reason for clearing override',
            submitOverrideClear
        );
    };

    var createTrialExtensionNotePopup = function() {
        generalAlert('Override Note', '', 'Reason for override', submitOverride);
    };

    init();
};

