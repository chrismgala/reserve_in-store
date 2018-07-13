var polarisTableHeaderHeightFix = function(){
    $('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
            $(this).outerHeight($(this).next().outerHeight());
        }
    );
};

polarisTableHeaderHeightFix();

$('.reservation-modal-display').on('click', function () {
    $('div#reservation-modal-container').show();
});


// For the modal

$('.reservation-modal-close').on('click', function () {
    $('div#reservation-modal-container').hide();
});
var $form = $('#reservationCreateForm');
// $('#reservationCreateForm').parsley();
$('#reservation-modal-submit').on('click', function () {
    if ($form[0].checkValidity()) {
        $form.submit();
        $('div#reservation-modal-container').hide();
    } else {
        // $form.submit();
        $form[0].reportValidity();
    }
});

$("#reservation-modal-container").on('click', function (event) {
    if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
        if ($('div#reservation-modal-container').is(":visible")) {
            $('div#reservation-modal-container').hide();
        }
    }
});
