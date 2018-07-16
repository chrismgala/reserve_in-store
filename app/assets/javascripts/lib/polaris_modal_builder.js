var PolarisModal = function (opts) {
    opts = opts || {};
    var $form, $modalContainer;

    this.init = function () {
        $modalContainer = $('div#' + opts.containerID);
        $form = $('#' + opts.formID);
        this.bindShowBtn();
        this.bindForm();
        this.setCloseConditions();

    };

    this.bindShowBtn = function () {
        if (opts.showClass) {
            $('.' + opts.showClass).on('click', function () {
                $modalContainer.show();
            });
        }
    };

    this.bindForm = function () {
        $('#' + opts.submitBtnID).on('click', function () {
            if ($form[0].checkValidity()) {
                $form.submit();
                $modalContainer.hide();
            } else {
                $form[0].reportValidity();
            }
        });
    };

    this.setCloseConditions = function () {
        $('.' + opts.closeClass).on('click', function () {
            console.log($modalContainer);
            $modalContainer.hide();
        });
        $modalContainer.on('click', function (event) {
            if (!$(event.target).closest('.Polaris-Modal-Dialog__Modal').length) {
                $modalContainer.hide();
            }
        });
    };

    this.init();
};
