class CodeEditor {
    constructor(opts) {
        var self = this;

        this._opts = opts;
        this.$container = typeof opts.containerSelector === 'string' ? $(opts.containerSelector) : opts.containerSelector;
        this._$aceEditor = this.$container.find('.editor');
        this.$textarea = this.$container.find('.editor-hidden-textarea');
        this.$defaultTextarea = this.$container.find('.editor-default-content');
        this.ace = ace.edit(this._$aceEditor.get(0));
        this._$aceContainer = $(this.ace.container);
        this.beautifyFunction = opts.beautifyFunction;
        this._$editorLinks = this.$container.find('.editor-links');
        this._changed = false;

        this._$sampleStateContainer = this.$container.find('.editor-sample-state');
        if (this._$sampleStateContainer.length > 0) {
            this._$sampleStateContainer.each(function() {
                new CampaignStateSampler().outputTo(this);
            });
        }

        this.language = opts.language;
        this._initEditor();


        if (opts.maximizeHeight) {
            this._setupSizeMaximizer();
        } else {
            this._$aceContainer.height(opts.height || 250);
        }

        this._setupExpandAndContractLinks()

    }

    hasDefaultContent() {
        return this.val() === this.defaultVal();
    }

    resetToDefault() {
        this.set(this.defaultVal());
    }

    defaultVal() {
        return this.$defaultTextarea.val().trim();
    }

    val() {
        return this.$textarea.val().trim();
    }

    set(newVal) {
        var oldVal = this.$textarea.val();

        this.ace.getSession().setValue(newVal);
        this.$textarea.val(newVal);

        if (this._opts.onChange) {
            this._opts.onChange(oldVal, newVal);
        }
    }

    hasChanged() {
        return this._changed;
    }

    _setupExpandAndContractLinks() {
        var $expandLink = this._$editorLinks.find('.expand-editor-link');
        var $contractLink = this._$editorLinks.find('.contract-editor-link');
        $expandLink.on('click', function(e) {
            e.preventDefault();
            var $editor = $(this).parent().siblings('.ace_editor');
            $editor.height($editor.height() + 500);
            $editor.addClass('manually-sized');

            // Trigger the resize method on the editor so it resizes its inside viewport
            if ($editor.length > 0 ) ace.edit($editor[0]).resize();

            if ($editor.height() >= 200) {
                $contractLink.show();
            }
        });

        $contractLink.on('click', function(e) {
            e.preventDefault();
            var $editor = $(this).parent().siblings('.ace_editor');
            $editor.height($editor.height() - 200);
            $editor.addClass('manually-sized');

            // Trigger the resize method on the editor so it resizes its inside viewport
            if ($editor.length > 0 ) ace.edit($editor[0]).resize();

            if ($editor.height() < 200) {
                $(this).hide();
            }
        });
    }

    _setupSizeMaximizer() {
        $(window).on('resize', () => { this._maximizeEditor(); } );
        setInterval(()  => { this._maximizeEditor(); }, 250);
        this._maximizeEditor();
    }

    _maximizeEditor() {
        if (this._$aceContainer.hasClass('manually-sized')) return;

        var newHeight = $(window).height() - this.$container.offset().top - this._$editorLinks.height() - 30;
        this._$aceContainer.height(Math.max(newHeight, 100));
    }

    _initEditor() {
        if (this.$textarea.length < 1) {
            console.warn("Missing code editor textarea", this.$textarea);
            throw "Missing the code editor textarea";
        }

        this.ace.setTheme("ace/theme/monokai");
        this.ace.getSession().setMode("ace/mode/" + this.language);

        this.ace.on("change", () => {
            var oldVal = this.$textarea.val(),
                newVal = this.ace.getSession().getValue();
            this.$textarea.val(newVal);
            this._changed = true;

            if (this._opts.onChange) {
                this._opts.onChange(oldVal, newVal);
            }
        });

        this._initBeautification();

        this._initReset();

        // To disable warning message
        this.ace.$blockScrolling = Infinity;
    }

    _initReset() {
        this.$container.find('.reset-to-default').on('click', (e) => {
            e.preventDefault();
            this.resetToDefault();
        });
    }

    _initBeautification() {
        if (typeof this.beautifyFunction !== 'function') return; // No beautifier defined

        this.$container.find('.beautify-link').on('click', (e) => {
            e.preventDefault();
            var originalValue = this.ace.getSession().getValue();
            var beautifiedCode = this.beautifyFunction(originalValue, { indent_size: 4 });
            this.ace.getSession().setValue(beautifiedCode);
        });
    }

}
