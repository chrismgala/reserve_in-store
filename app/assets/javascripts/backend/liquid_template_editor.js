var LiquidTemplateEditor = function(opts) {
    opts = opts || {};
    var self = this;

    var $previewContainer;

    var init = function () {
        self.$form = $('#'+ opts.attr + '_section');
        self.liveUpdating = false;
        $previewContainer = $('#'+ opts.attr + '_preview_pane');

        setupTemplateEditor();

        setupIframePreview();

        $(opts.switchSelector).on('change', function() {
            setTimeout(function() {
                self.preview.updateHeight();
            }, 1);
        })
    };


    var setupTemplateEditor = function() {
        if (self.$form.find('.template-editor-container').length > 0) {
            self.liquidEditor = new CodeEditor({
                containerSelector: self.$form.find('.template-editor-container'),
                beautifyFunction: html_beautify,
                language: 'liquid',
                maximizeHeight: false
            });

            self.liquidEditor.ace.on("change", function() { self.preview.update(); });
            self.liquidEditor.ace.on("paste", function() { self.preview.update(); });
            self.liquidEditor.ace.on("blur", function() { self.preview.update(); });
            self.liquidEditor.ace.getSession().on("changeAnnotation", function() { self.preview.update(); });
        }
    };

    var setupIframePreview = function() {
        self.preview = new IframePreviewer({
            maxHeight: 1000,
            frontendMode: opts.frontendMode,
            containerClasses: opts.containerClasses,
            iframePreviewPath: '/stores/iframe_preview',
            $fieldsContainer: self.$form,
            $previewPanel: $previewContainer,
            $previewContainer: $previewContainer,
            getPreviewVars: function() {
                return self.getPreviewVars();
            },
            getCss: function() { return self.getCss(); },
            getTemplate: function() { return self.getTemplate(); },
            afterInit: function() {
                self.$previewPane = self.preview.container();
                if (opts.afterInit) opts.afterInit();

                self.previewReady = true;
            },
            shouldPreviewBeHidden: function() {
                if (!opts.hideWithoutCode) return false;

                if (!self.liquidEditor) return false;
                if (self.liquidEditor.hasChanged()) return false;
                if (!self.liquidEditor.hasDefaultContent()) return false;

                return true;
            },
            previewPageCss: opts.previewPageCss
        });
    };

    this.getPreviewVars = function() {
        return opts.previewVars || {}; // TODO
    };
    this.getCss = function() {
        return opts.extraCss || ''; // TODO
    };
    this.getTemplate = function() {
        return self.liquidEditor.val(); // TODO
    };


    init();
};
