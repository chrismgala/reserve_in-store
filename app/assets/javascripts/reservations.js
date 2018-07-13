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
