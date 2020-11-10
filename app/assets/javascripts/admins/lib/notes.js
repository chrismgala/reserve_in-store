/**
 * Class to add Admin Notes
 * @param {object} opts - The options passed through, required for setup
 */
var AdminNotesUpdater = function(opts) {
    opts = opts || {};
    var storeId = opts.store_id;
    var $adminNote = $('#' + opts.notes_id);
    var $adminNoteButton = $('#' + opts.button_id);
    var $adminNotesSection = $('#' + opts.section_id);

    var init = function() {
        $adminNoteButton.on("click", editAdminNotesPopup);
    };

    var refreshNote = function(value) {
        $adminNote.html(value.admin_notes);
    };

    var submitNote = function(note) {
        $.ajax({
            type: "POST",
            beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', AUTH_TOKEN); },
            url: '/admin/stores/notes',
            data: { note: note, store_id: storeId },
            dataType: "json"
        }).done(function (value) {
            swal({ title: "Success", text: "The note has been saved.", type: "success", onClose: refreshNote(value) });
        }).fail(function (jqXHR, textStatus, errorThrown) {
            swal({ title: "Failed", text: "Your request has failed: " + textStatus + ", " + errorThrown, type: "error" });
        });
    };

    /**
     * A function to display a general sweet alert popup
     * @throws - if no adminNotesSection is available
     */
    var editAdminNotesPopup = function() {
        if ($adminNotesSection.length < 1) throw new Error("The Admin notes section was not found.");

        swal({
            title: 'Admin Notes',
            input: 'textarea',
            inputPlaceholder: 'Type note here',
            showCancelButton: true,
            confirmButtonText: 'Submit',
            showLoaderOnConfirm: true,
            allowOutsideClick: !swal.isLoading,
            preConfirm: submitNote
        });
    };

    init();
};
