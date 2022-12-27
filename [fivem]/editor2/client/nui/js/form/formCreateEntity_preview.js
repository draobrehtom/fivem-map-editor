const formCreateEntity_preview = {
    dumps: {
        objects: {},
        vehicles: {}
    },
    RESULTS_TO_SHOW_PER_PAGE: 100,
    currentIndexStart: 0,
    currentIndexEnd: 0,
    currentIndexMaximum: 0,

    refresh: function () {
        formCreateEntity_preview.listCategories();
        formCreateEntity_preview.filterModels();
    },

    dump: function (dumpName) {
        if (typeof dumpName != 'string') { return }

        jQuery.get('../../client/dump/' + dumpName, function (post) {
            const lines = post.split('\n');

            var dumpCategories = {};
            var dumpModels = { all: [] };
            if (dumpName == 'objects') { dumpModels.inspected = []; }
            var lastCategory = null;
            var lastCategoryHash = null;

            for (var i = 0; i < lines.length; i++) {
                const line = lines[i];
                if (!isEmpty(line)) {
                    const isCategory = line.indexOf('[category=');
                    if (isCategory > -1) {
                        lastCategory = line.substr(line.indexOf('=') + 1, line.length - 12);
                        lastCategoryHash = stringToHash(lastCategory);
                        dumpCategories[lastCategoryHash] = lastCategory;

                    } else {
                        if (!dumpModels[lastCategoryHash]) { dumpModels[lastCategoryHash] = []; }
                        dumpModels['all'].push(line);
                        dumpModels[lastCategoryHash].push(line);
                    }
                }
            }

            formCreateEntity_preview.dumps[dumpName] = {
                categories: dumpCategories,
                models: dumpModels
            };
        });
    },

    listCategories: function () {
        const element = document.getElementById('form_create_entity_preview_input_category');
        if (!element) { return }

        const dumpName = $("#form_create_entity_preview_input_class").val();
        var innerHTML = "<option value='all'>Show all</option>";

        if (dumpName == 'objects') { innerHTML += "<option value='inspected'>Inspected from World</option>"; }

        if (!!formCreateEntity_preview.dumps[dumpName]) {
            $.each(formCreateEntity_preview.dumps[dumpName].categories, function (hash, name) {
                innerHTML += `<option value=${hash}>${name}</option>`;
            });
        }
        element.innerHTML = innerHTML;
    },

    filterModels: function (filter) {
        formCreateEntity_preview.currentResults = [];

        const dumpName = $("#form_create_entity_preview_input_class").val();
        var currentModels = [];
        if (!!formCreateEntity_preview.dumps[dumpName] && !!formCreateEntity_preview.dumps[dumpName].models) {
            const categoryHash = $("#form_create_entity_preview_input_category").val();
            if (dumpName == 'objects' && categoryHash == 'inspected') {
                callEditorFunction('formCreateEntity_preview.filterModels.inspected.objects');
                return;
            }
            currentModels = formCreateEntity_preview.dumps[dumpName].models[categoryHash];
        }

        if (!filter) { filter = $("#form_create_entity_preview_input_filter").val(); }
        if (isEmpty(filter)) { filter = null; }
        else { filter = filter.toLowerCase(); }

        if (currentModels) {
            formCreateEntity_preview.currentIndexMaximum = currentModels.length;
            for (var i = 0, l = formCreateEntity_preview.currentIndexMaximum; i < l; i++) {
                let value = currentModels[i];
                if (!filter || value.toLowerCase().indexOf(filter) >= 0) {
                    formCreateEntity_preview.currentResults.push(value);
                }
            }
        }
        formCreateEntity_preview.currentIndexStart = 0;
        formCreateEntity_preview.currentIndexEnd = Math.min(formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, formCreateEntity_preview.currentResults.length);
        formCreateEntity_preview.listModels();
    },

    listModels: function (resetScroll) {
        const element = document.getElementById('form_create_entity_preview_list_models');
        if (!element) { return; }

        var innerHTML = '';
        const scrollTop = element.scrollTop;
        if (!formCreateEntity_preview.currentResults || formCreateEntity_preview.currentResults.length == 0) {
            document.getElementById("form_create_entity_preview_label_showing_results").innerHTML = 'No results found.';

        } else {
            for (var i = formCreateEntity_preview.currentIndexStart, l = formCreateEntity_preview.currentIndexEnd; i < l; i++) {
                let value = formCreateEntity_preview.currentResults[i];
                innerHTML += `<span class='list_item' value=` + value + `>` + value + `</span>`;
            }
            document.getElementById("form_create_entity_preview_label_showing_results").innerHTML = 'Showing ' + (formCreateEntity_preview.currentIndexStart + 1) + ' - ' + (formCreateEntity_preview.currentIndexEnd) + ' of ' + (formCreateEntity_preview.currentResults.length);
        }
        element.innerHTML = innerHTML;

        if (resetScroll) { element.scrollTop = 0; }
        else { element.scrollTop = scrollTop; }
    },

    switchClass: function (eclass) {
        $("#form_create_entity_preview_input_class").val(eclass);
        formCreateEntity_preview.refresh();
    },

    page: {
        next: function () {
            if ((formCreateEntity_preview.currentIndexStart + formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE) >= formCreateEntity_preview.currentResults.length) {
                formCreateEntity_preview.currentIndexEnd = formCreateEntity_preview.currentResults.length;
                formCreateEntity_preview.currentIndexStart = Math.max(formCreateEntity_preview.currentIndexEnd - formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, 0);
            } else {
                formCreateEntity_preview.currentIndexStart = formCreateEntity_preview.currentIndexStart + formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE;
                formCreateEntity_preview.currentIndexEnd = Math.min(formCreateEntity_preview.currentIndexStart + formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, formCreateEntity_preview.currentResults.length);
            }

            formCreateEntity_preview.listModels(true);
        },

        previous: function () {
            if ((formCreateEntity_preview.currentIndexStart - formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE) <= 0) {
                formCreateEntity_preview.currentIndexStart = 0;
                formCreateEntity_preview.currentIndexEnd = Math.min(formCreateEntity_preview.currentIndexStart + formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, formCreateEntity_preview.currentResults.length);

            } else {
                formCreateEntity_preview.currentIndexStart = formCreateEntity_preview.currentIndexStart - formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE;
                formCreateEntity_preview.currentIndexEnd = Math.min(formCreateEntity_preview.currentIndexStart + formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, formCreateEntity_preview.currentResults.length);
            }

            formCreateEntity_preview.listModels(true);
        }
    },

    listInspectedModels: function (item) {
        formCreateEntity_preview.currentResults = [];

        const dumpName = $("#form_create_entity_preview_input_class").val();
        if (dumpName != item.dumpName) { return; }

        var filter = $("#form_create_entity_preview_input_filter").val();
        if (isEmpty(filter)) { filter = null; }
        else { filter = filter.toLowerCase(); }

        formCreateEntity_preview.currentIndexMaximum = item.models.length;
        for (var i = 0, l = formCreateEntity_preview.currentIndexMaximum; i < l; i++) {
            let value = item.models[i];
            if (!filter || value.indexOf(filter) > -1) {
                formCreateEntity_preview.currentResults.push(value);
            }
        }

        formCreateEntity_preview.currentIndexStart = 0;
        formCreateEntity_preview.currentIndexEnd = Math.min(formCreateEntity_preview.RESULTS_TO_SHOW_PER_PAGE, formCreateEntity_preview.currentResults.length);
        formCreateEntity_preview.listModels();
    }
}

$(document).ready(function () {
    // Preview function
    $("body").on('click', '#form_create_entity_preview_list_models .list_item', function () {
        const value = $(this).attr('value');
        if (!value) { return; }

        callEditorFunction('formCreateEntity.preview', { model: value });
    });

    // Search function
    $("#form_create_entity_preview_input_category").change(function (e) { formCreateEntity_preview.filterModels(); });
    $("#form_create_entity_preview_input_filter").on('input', function (e) { formCreateEntity_preview.filterModels($(this).val()); });

    formCreateEntity_preview.dump('objects');
    formCreateEntity_preview.dump('vehicles');
});