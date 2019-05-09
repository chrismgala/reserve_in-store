$(document).ready(function() {
    // Polaris-Collapsible--fullyOpen
    $('[data-toggle]').each(function() {
        var $el = $(this);
        var $target = $($el.data('toggle'));

        $el.on('click', function(e) {
            e.preventDefault();
            $target.toggle();
        });
    })
});
