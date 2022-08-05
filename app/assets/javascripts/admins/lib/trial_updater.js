/**
 * Class to update the duration of a store's trial
 * - Calculates how many seconds should be added to store.trial_ended_at
 * @param {object} opts - The options passed through, required for setup
 */
var TrialUpdater = function(opts) {
    opts = opts || {};
    var storeId = opts.store_id;
    var userId = opts.user_id;
    var trialEndedAt = opts.trial_ended_at;
    var extendingByDays = true;
    // emailStoreOwner determines if we want to email the store owner upon updating their trial.
    // Set to false by default and can be changed to true in createTrialExtensionNotePopup
    var emailStoreOwner = false;

    // jQuery variables
    var $inputSection = $('#' + opts.section_id);
    var $selectorButtonSection = $('#' + opts.button_section_id);

    var $submitButton = $inputSection.find('.btn-success');
    var $dateInput = $inputSection.find('.date-input');
    var $dayInput = $inputSection.find('.number-input');
    var $backButton = $inputSection.find('.btn-cancel');
    var $extendTrialByDays = $selectorButtonSection.find('.extend-by-days');
    var $extendTrialToDate = $selectorButtonSection.find('.extend-to-date');

    var init = function() {
        $backButton.on("click", toggleInputScreen);
        $submitButton.on("click", createTrialExtensionNotePopup);

        $extendTrialByDays.on("click", function() {
            showReauthorizeWarning(function() {
                showingDayInput(true);
            });
        });

        $extendTrialToDate.on("click", function() {
            showReauthorizeWarning(function() {
                showingDayInput(false);
            });
        });
    };

    var showReauthorizeWarning = function(then) {
        if (!opts.subscribed) {
            return then();
        }

        swal({
            type: 'warning',
            title: "Changing Trial Requires Re-authorization",
            html: "<div class=\"text-danger\">Changing the store's trial will only change it locally and won't update for the store own until " +
            "the subscription is authorized again." +
            " Ask store owner to re-authorize the subscription after you change the trial from billing tab.</div>"
        }).then(then, then);
    };

    /**
     * Determine what input box to display
     * @param showingDay - if true, show numerical day input, else show datepicker input
     */
    var showingDayInput = function(showingDay) {
        toggleInputScreen();
        $dayInput.toggle(showingDay);
        $dateInput.toggle(!showingDay);
        extendingByDays = showingDay;
    };

    /**
     * Toggle what section to show, whether the type selector screen or the input screen
     */
    var toggleInputScreen = function() {
        $inputSection.toggle();
        $selectorButtonSection.toggle();
    };

    /**
     * - If calculating by days, return the number of seconds within the given days
     * - If calculating by date, convert the default poorly formatted date and the trial ended date into seconds since
     *   1970/01/01 and subtract to get the net seconds
     * @returns {number} - seconds to add to current trial-ended-at field, or undefined if the input is invalid
     */
    var calculateNetSeconds = function() {
      if (extendingByDays) {
          return $dayInput.val() * 60 * 60 * 24;
      } else {
          var secondsSince1970 = new Date($dateInput.val()).getTime() / 1000;
          var secondsFrom1970ToEndOfTrial = new Date(trialEndedAt).getTime() / 1000;

          return secondsSince1970 - secondsFrom1970ToEndOfTrial;
      }
    };

    var refreshView = function() {
        window.location.reload();
    };

    /**
     * @param seconds
     * @returns {number} - the rounded number of days the seconds make up
     */
    var toDays = function(seconds) {
        return Math.round(seconds / 60 / 60 / 24);
    };

    /**
     * Maximum amount of time we are allowed to add to the trial such that it is not more than 700 days from now
     * @returns {number}
     */
    var maxTrialAddition = function() {
        var curTimeSeconds = new Date().getTime() / 1000;
        var trialEndTimeSeconds = new Date(trialEndedAt).getTime() / 1000;
        return (curTimeSeconds + 700 * 24 * 60 * 60) - trialEndTimeSeconds;
    };

    var submitTrialExtension = function(note) {
        var secondsAddedToTrial = calculateNetSeconds();
        note = note || "No note.";

        if (isNaN(secondsAddedToTrial) || secondsAddedToTrial === 0) {
            swal("Invalid Entry", "You must specify the length of extension.", "error").then(function() { }, function() { });
        } else if (secondsAddedToTrial > maxTrialAddition) { // A bit more than 1 year
            swal("Extension Too Long", "You can't add more than 1 year to the trial. Stripe has a limit of 700 days for any trial.", "error").then(function() { }, function() { });
        } else {
            note = "Extended trial " + toDays(secondsAddedToTrial) + " days: " + note;
            var lengthInSeconds = calculateNetSeconds();
            $.ajax({
                type: "POST",
                beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', AUTH_TOKEN); },
                url: '/admin/stores/extend_trial',
                // The email_owner parameter is posted into the ajax request as a boolean but gets treated as a string in server side.
                // Since this ajax request goes to extend_trial in the stores_controller, this is handled there.
                data: { length: lengthInSeconds, user_id: userId, note: note, store_id: storeId, email_owner: emailStoreOwner },
                dataType: "json"
            }).done(function (value) {
                swal({ title: "Success", text: "The trial has been extended. Hold on while we refresh the data.", type: "success", onClose: refreshView() });
            }).fail(function (jqXHR, textStatus, errorThrown) {
                swal({ title: "Failed", text: "Your request has failed: " + textStatus + ", " + errorThrown, type: "error" });
            });
        }
    };

    /**
     * A function to display a general sweet alert popup
     * @throws - if no extend-trial-date is available
     */
    var createTrialExtensionNotePopup = function() {
        if ($inputSection.length < 1) throw new Error("The trial extension section was not found.");

        swal({
            title: 'Trial Update',
            input: 'text',
            // Also include a checkbox in the confirm pop-up that asks if we want to email the store owner.
            // Swal.fire doesn't support multiple inputs so instead we use raw html for the 2nd input
            html:
                '<input class="email-checkbox hidden" type="checkbox">' +
                '<label for="email-checkbox" class="hidden">Notify Store Owner via E-mail?</label>',
            inputPlaceholder: 'Reason for extension',
            showCancelButton: true,
            confirmButtonText: 'Submit',
            showLoaderOnConfirm: true,
            allowOutsideClick: false,
            customClass: 'swal-trial-update',
            // Before we call submitTrialExtension we see if emailCheckBox is checked.
            // If yes, set emailStoreOwner to true (set to false by default) and it gets passed into submitTrialExtension
            preConfirm: function(message) {
                if ($('.swal-trial-update .email-checkbox').is(':checked')) emailStoreOwner = true;
                submitTrialExtension(message);
            }
        }).then(function() {}, function() {});
    };

    init();
};

