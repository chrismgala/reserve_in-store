$('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
        $(this).outerHeight($(this).next().outerHeight());
    }
);
console.log('locations.js');

$('.location-modal-display').on('click', function () {
    $('div#locationModal-container').show();
});
