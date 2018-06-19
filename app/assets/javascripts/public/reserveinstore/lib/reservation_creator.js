ReserveInStore.ReservationCreator = function(opts, containers){
    var self              = this;
    // var $                 = ReserveInStore.Util.$();
    opts                  = opts || {};
    var api;

    self.requestFailCount = 0;

    var init = function () {
        api = new ReserveInStore.Api(opts)
    };

    self.displayModal = function(){
        api.getModal(containers.modalContainer, self.insertModal);
    };

    self.insertModal = function(data){
        containers.modalContainer[0].innerHTML = data;
        // Get the modal
        var modal = containers.modalContainer.find('#reserveinstore-modal');

        // Get the <span> element that closes the modal
        var span = modal.find("#reserveinstore-close-modal");
        // When the user clicks on <span> (x), close the modal
        span[0].onclick = function() {
            modal[0].style.display = "none";
        };

        // When the user clicks anywhere outside of the modal, close it
        window.onclick = function(event) {
            if (event.target == modal[0]) {
                modal[0].style.display = "none";
            }
        };
    };

    init();
};
