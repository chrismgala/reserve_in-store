$('.simpleTabs').each(function() {
    var $container = $(this);
    var $tabContainer = $container.find('.simpleTabs-tabs');
    var $panelContainer = $container.find('.simpleTabs-panels');

    function openTab($a) {
        var $li = $a.closest('li');
        var $panel = $container.find($a.attr('href'));
        $li.siblings().removeClass('active');
        $li.addClass('active');
        $panelContainer.children('div').removeClass('active');
        $panel.addClass('active');
    }
    $tabContainer.find('a').on('click', function(e) {
        e.preventDefault();
        openTab($(this));
    });

    if ($panelContainer.children('div.active').length === 0) {
        openTab($tabContainer.find('a').first());
    }
});
