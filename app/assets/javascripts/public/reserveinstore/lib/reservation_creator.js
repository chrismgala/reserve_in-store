ReserveInStore.ReservationCreator = function(opts, containers){
    var self              = this;
    opts                  = opts || {};
    var api, modal, form, productId, variantId;

    var init = function () {
        api = new ReserveInStore.Api(opts);
    };

    self.displayModal = function(){
        self.getProductAndVariantId(window.location.href);
    };

    /**
     * Get current viewing product and variant information by visiting current site's json
     * @param url url of current site
     */
    self.getProductAndVariantId = function(url){
        // Check if variant id is in query parameters
        var re_variant = /variant=(.*?)(&|$)/,
            matchVariantId = url.match(re_variant);
        if (matchVariantId){
            variantId = parseInt(url.match(re_variant)[1]);
        }

        // parse the url to be in the form of "https://store.com/products/product.json"
        if (url.indexOf('?') > 0){
            url = url.substr(0, url.indexOf('?'));
        }
        url = url + '.json';

        $.ajax({
            url: url,
            success: function (data, textStatus, jqXHR) {
                setProductVariantInfo(data);
            },
            error: function (response) {
                alert('error');  // TODO
            }
        });

        var setProductVariantInfo = function(data){
            productId = data.product.id;
            variantId = variantId || data.product.variants[0].id;
            var variantTitle = $.grep(data.product.variants, function(obj){ return obj.id === variantId;})[0].title;

            var productVariantNames = { product_title: data.product.title, variant_title: variantTitle };
            api.getModal(productVariantNames, self.insertModal);
        };
    };

    /**
     * Insert the HTML code of modal into the container
     * @param modalHTML the HTML code of modal
     */
    self.insertModal = function(modalHTML){
        containers.modalContainer[0].innerHTML = modalHTML;
        modal = containers.modalContainer.find('#reserveInStore-modal');
        self.setCloseConditions();
        
        form = modal.find("#reserveInStore-reservation-form");
        self.setSubmitConditions();
    };

    /**
     * Set close conditions to the modal: click on the "x" or click anywhere outside of the modal
     */
    self.setCloseConditions = function(){
        var span = modal.find("#reserveInStore-close-modal");
        span[0].onclick = function() {
            modal[0].style.display = "none";
        };

        window.onclick = function(event) {
            if (event.target == modal[0]) {
                modal[0].style.display = "none";
            }
        };
    };

    /**
     * Set submit conditions to the modal:
     * click on the "Reserve" button or press the enter key in the last input field
     */
    self.setSubmitConditions = function(){
        var submitBtn = modal.find("#reserveInStore-submit-modal");
        submitBtn[0].onclick = function () {
            self.submitForm();
        };
        form.on('submit', function() { self.submitForm(); });
        form.find('input:visible').last().on('keypress', function(e) {
            if (e.keyCode === 13) {
                self.submitForm();
            }
        });
    };

    /**
     * Submit the form, make a ajax call to create new reservation
     */
    self.submitForm = function() {
        alert('submit');
    };

    init();
};
