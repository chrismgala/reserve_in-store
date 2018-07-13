var polarisTableHeaderHeightFix = function(){
    $('tbody th.Polaris-DataTable__Cell--fixed').each(function () {
            $(this).outerHeight($(this).next().outerHeight());
        }
    );
};

polarisTableHeaderHeightFix();

$('.location-modal-display').on('click', function () {
    $('div#location-New-container').show();
});
