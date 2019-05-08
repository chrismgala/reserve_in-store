class IframePreviewer {
    constructor(opts) {
        this._$previewContainer = opts.$previewContainer;
        this._$previewPanel = opts.$previewPanel;
        this._$fieldsContainer = opts.$fieldsContainer;
        this._$iframe = this._$previewContainer.find('iframe');

        this._opts = opts;

        var containerClasses = 'iframe-preview-container';
        if (opts.containerClasses) containerClasses += ' ' + opts.containerClasses;
        this.$container = $('<div id="previewContainer" class="' + containerClasses + '"></div>');
        this.$cssContainer = $('<span id="cssPreviewContainer"></span>');

        var self = this;
        this.frameReady = false;

        this._maxHeight = opts.maxHeight || 250;

        setTimeout(function() {
            self._waitForFrameToLoad(function() {
                self.$iframeBody = self._$iframe.contents().find('body');
                self.$iframeHtml = self._$iframe.contents().find('html');
                self.$iframeBody.append(self.$container);
                self.$iframeBody.append(self.$cssContainer);

                self._$iframe.show();
            });

            self.update(function() {
                if (self._opts.afterInit) self._opts.afterInit();
            });
        }, 1);

        this._checkEmptyPreview(false);
    }

    _checkEmptyPreview(delay = true) {
        this._$previewPanel.css('opacity', 0.5);
        if (!delay) {
            return this._hideOrShow();
        }

        if (this.previewHideTimeout) clearTimeout(this.previewHideTimeout);

        this.previewHideTimeout = setTimeout(() => {
            this._hideOrShow();
        }, 500);
    }

    _hideOrShow() {
        var html = this._getHtml();
        var hidePreview = this._opts.shouldPreviewBeHidden && this._opts.shouldPreviewBeHidden();
        if (hidePreview || typeof html !== 'string' || html === '') {
            this._$previewPanel.hide();
            this._$previewPanel.css('opacity', 1);
        } else {
            this._$previewPanel.show();
            this._$previewPanel.css('opacity', 1);
        }

        this.updateHeight();
    }

    container() {
        return this._$iframe.contents().find('body').find('#previewContainer');
    }

    updateHeight() {
        if (this._updateHeightTimeout) {
            clearTimeout(this._updateHeightTimeout);
        }

        this._updateHeightTimeout = setTimeout(() => {
            var heights = [ ];

            if (this.$iframeBody) {
                heights = this.$iframeBody.find('img,div,span,a,svg,table').map(function() {
                    var $el = $(this);
                    var height = $el.height();
                    var shadow

                    if ($el.css('box-shadow')) {
                        shadow = Math.max.apply(this, $($el.css('box-shadow').split(' ')).map(function(){ return this.toString().indexOf('px') !== -1 ? (parseInt(this) || 0) : 0; }).toArray());
                        if (shadow) height += shadow*2;
                    }
                    if ($el.css('border-top-width')) {
                        height += parseInt($el.css('border-top-width'));
                    }
                    if ($el.css('border-bottom-width')) {
                        height += parseInt($el.css('border-top-width'));
                    }
                    return height;
                }).toArray();

                heights.push(this.$iframeBody.height());
            }

            if (this.$iframeHtml) {
                heights.push(this.$iframeHtml.outerHeight());
            }

            var peakHeight = Math.max.apply(this, heights);

            if (this.$iframeBody) {
                peakHeight += parseInt(this.$iframeBody.css('padding-top'));
                peakHeight += parseInt(this.$iframeBody.css('padding-bottom'));
                peakHeight += parseInt(this.$iframeBody.css('margin-top'));
                peakHeight += parseInt(this.$iframeBody.css('margin-bottom'));
            }

            var iframeHeight = Math.min(peakHeight, this._maxHeight);
            if (iframeHeight < 20) iframeHeight = 20;
            this._$iframe.height(iframeHeight);

            clearTimeout(this._updateHeightTimeout);
        }, 500);
    }

    flash() {
        if (this._flashingPreview) return false; // Already flashing so don't flash it more.

        var self = this;
        self._flashingPreview = true;
        self._$previewContainer.fadeTo(100, 0.3, function() {
            $(this).fadeTo(500, 1.0, function() {
                self._flashingPreview = false;
            });
        });

        return true;
    }

    _waitForFrameToLoad(then) {
        var self = this;
        if (self.frameReady) return then();

        this.frameReady = false;
        var previewParams = {};
        if (this._opts.getPreviewParams) previewParams = this._opts.getPreviewParams();
        if (this._opts.previewPageCss) previewParams.preview_css = this._opts.previewPageCss;
        previewParams.test_mode = '1';
        if (!this._opts.frontendMode) previewParams.omit_css = true;
        this._$iframe.attr('src', this._opts.iframePreviewPath + "?" + $.param(previewParams));

        this._$iframe.on('load', function() {
            self.frameReady = true;
            return then();
        });
    }

    whenReady(then) {
        var self = this;

        if (self.frameReady) return then();

        var waiter = setInterval(function() {
            if (self.frameReady) {
                clearInterval(waiter);
                return then();
            }
        }, 10);
    }

    update(then) {
        then = then || function() {};

        this.whenReady(() => {
            this._startLoading();

            var css = "<style>" + this.getCss() + "</style>\n";
            this.$cssContainer.html(css);

            var html = this._getHtml();
            this.$container.html(html);

            this.$container.find('a').attr('target', "_blank");

            this._stopLoading();

            this._checkEmptyPreview();

            this.updateHeight();

            then();
        });
    }

    getCss() {
        return this._opts.getCss ? this._opts.getCss() : '';
    }

    getTemplate() {
        return this._opts.getTemplate ? this._opts.getTemplate() : '';
    }

    getPreviewVars() {
        return this._opts.getPreviewVars ? this._opts.getPreviewVars() : {};
    }

    _startLoading() {
        this._$previewContainer.css('opacity', 0.5);
    }

    _stopLoading() {
        this._$previewContainer.css('opacity', 1);
    }

    /*
     * Update the previewPane with the Liquid parsed html template value
     * @return {string} html - rendered HTML
     */
    _getHtml() {
        try {
            var _html = this.getTemplate();

            if (!_html || _html.trim() === '') return "";

            // The javascript Liquid renderer does not support the whitespace stripping tags, so we need to get rid of them here.
            _html = _html.replace(new RegExp(/\s*({%-)/g, 'g'), '{%').replace(new RegExp(/(-%})\s*/, 'g'), '%}');

            var t = Liquid.parse(_html);

            return t.render(this.getPreviewVars());
        } catch(e) {
            console.error(e);
        }
    }

    _flashPreviewPane() {
        if (this._flashingPreview) return false; // Already flashing so don't flash it more.

        this._flashingPreview = true;
        var self = this;
        this._$previewContainer.fadeTo(100, 0.3, function() {
            $(this).fadeTo(500, 1.0, function() {
                self._flashingPreview = false;
            });
        });

        return true;
    }

}
