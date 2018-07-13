$('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
        $(this).outerHeight($(this).next().outerHeight());
    }
);
$('.reservation-modal-display').on('click', function () {
    $('div#reservation-modal-container').show();
});
