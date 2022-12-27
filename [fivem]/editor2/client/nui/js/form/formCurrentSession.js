const formCurrentSession = {
    entities: {
        dump: [],
        RESULTS_TO_SHOW_PER_PAGE: 100,
        currentIndexStart: 0,
        currentIndexEnd: 0,
        currentIndexMaximum: 0,

        cache: function (post) {
            const entities = post.entities;
            if (!entities) { return; }

            formCurrentSession.entities.dump = entities;
            formCurrentSession.entities.filter();

            // Entity count
            document.getElementById('form_current_session_title').innerHTML = (entities.length == 0 ? 'No' : entities.length) + ' Entit' + (entities.length == 1 ? 'y' : 'ies') + ' Created';
            document.getElementById('form_current_session_created_entities').style.display = entities.length == 0 ? 'none' : 'flex';
            document.getElementById('form_current_session_label_total_remove_worlds').innerHTML = post.statistics.removeWorlds || 0;
            document.getElementById('form_current_session_label_total_spawnpoints').innerHTML = post.statistics.spawnpoints || 0;
            document.getElementById('form_current_session_label_total_objects').innerHTML = post.statistics.objects || 0;
            document.getElementById('form_current_session_label_total_vehicles').innerHTML = post.statistics.vehicles || 0;
        },

        filter: function () {
            if (!formCurrentSession.entities.dump) { return; }

            const element = document.getElementById('form_current_session_list_created_entities');
            if (!element) { return; }

            var filterStr = $("#form_current_session_created_entities_input_filter").val();
            if (isEmpty(filterStr)) { filterStr = null; }
            else { filterStr = filterStr.toLowerCase(); }

            formCurrentSession.entities.currentResults = [];
            $.each(formCurrentSession.entities.dump, function (key, value) {
                if (!filterStr || value.id.toLowerCase().indexOf(filterStr) >= 0 || value.name.toLowerCase().indexOf(filterStr) >= 0) {
                    formCurrentSession.entities.currentResults.push(value);
                }
            });
            formCurrentSession.entities.currentIndexMaximum = formCurrentSession.entities.currentResults.length;
            formCurrentSession.entities.currentIndexStart = 0;
            formCurrentSession.entities.currentIndexEnd = Math.min(formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE, formCurrentSession.entities.currentResults.length);
            formCurrentSession.entities.list();
        },

        list: function () {
            const element = document.getElementById('form_current_session_list_created_entities');
            if (!element) { return; }

            var innerHTML = '';
            if (!formCurrentSession.entities.currentResults || formCurrentSession.entities.currentResults.length == 0) {
                document.getElementById("form_current_session_created_entities_label_showing_results").innerHTML = 'No results found.';

            } else {
                for (var i = formCurrentSession.entities.currentIndexStart, l = formCurrentSession.entities.currentIndexEnd; i < l; i++) {
                    let value = formCurrentSession.entities.currentResults[i];
                    let icon;
                    if (value.class == 0) { icon = 'fa fa-eraser'; }
                    else if (value.class == 1) { icon = 'fa fa-map-pin'; }
                    else if (value.class == 2) { icon = 'fa fa-cube'; }
                    else if (value.class == 3) { icon = 'fa fa-bicycle'; }
                    else { icon = 'fa fa-lock'; }

                    innerHTML += `
                    <span class='list_item' value=` + value.id + `>
                        <table width='100%'>
                            <tr>
                                <td width='5%'>
                                    <i class="` + icon + `"></i>
                                </td>
                                <td width='25%'>
                                    ` + value.id + `
                                </td>
                                <td width='55%'>
                                    ` + value.name + `
                                </td>
                                <td width='15%'>
                                    <div class="flex_row stretch center_items right">
                                        <a onclick="formCurrentSession.entities.select('` + value.id + `')"><i class="fa fa-hand-o-up"></i></a>
                                        <a onclick="formCurrentSession.entities.delete('` + value.id + `')"><i class="fa fa-trash"></i></a>
                                    </div>
                                </td>
                            </tr>
                        </table>
                    </span>`;
                }
                document.getElementById("form_current_session_created_entities_label_showing_results").innerHTML = 'Showing ' + (formCurrentSession.entities.currentIndexStart + 1) + ' - ' + (formCurrentSession.entities.currentIndexEnd) + ' of ' + (formCurrentSession.entities.currentResults.length);
            }
            element.innerHTML = innerHTML;
        },

        quickFilter: function (str) {
            document.getElementById("form_current_session_created_entities_input_filter").value = str.toString();
            formCurrentSession.entities.filter();
        },

        select: function (id) {
            if (editor.mode != 'edit' || !id) { return; }
            callEditorFunction('formCurrentSession.entities.select', { value: id });
        },

        delete: function (id) {
            if (editor.mode != 'edit' || !id) { return; }
            callEditorFunction('formCurrentSession.entities.delete', { value: id });
        },

        page: {
            next: function () {
                if ((formCurrentSession.entities.currentIndexStart + formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE) >= formCurrentSession.entities.currentResults.length) {
                    formCurrentSession.entities.currentIndexEnd = formCurrentSession.entities.currentResults.length;
                    formCurrentSession.entities.currentIndexStart = Math.max(formCurrentSession.entities.currentIndexEnd - formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE, 0);
                } else {
                    formCurrentSession.entities.currentIndexStart = formCurrentSession.entities.currentIndexStart + formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE;
                    formCurrentSession.entities.currentIndexEnd = Math.min(formCurrentSession.entities.currentIndexStart + formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE, formCurrentSession.entities.currentResults.length);
                }

                formCurrentSession.entities.list();
            },

            previous: function () {
                if ((formCurrentSession.entities.currentIndexStart - formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE) <= 0) {
                    formCurrentSession.entities.currentIndexStart = 0;
                    formCurrentSession.entities.currentIndexEnd = Math.min(formCurrentSession.entities.currentIndexStart + formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE, formCurrentSession.entities.currentResults.length);

                } else {
                    formCurrentSession.entities.currentIndexStart = formCurrentSession.entities.currentIndexStart - formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE;
                    formCurrentSession.entities.currentIndexEnd = Math.min(formCurrentSession.entities.currentIndexStart + formCurrentSession.entities.RESULTS_TO_SHOW_PER_PAGE, formCurrentSession.entities.currentResults.length);
                }

                formCurrentSession.entities.list();
            }
        },
    },

    map: {
        title: function (post) {
            const name = post.name;
            const meta = post.meta || [];

            $('#form_current_session_info_input_current_map_name').val(name || '');
            $('#form_current_session_info_input_current_map_author').val(meta.author || '');
            $('#form_current_session_info_input_current_map_description').val(meta.description || '');

            document.getElementById('form_current_session_info_label_current_map').innerHTML = name || 'Draft (unsaved)';
            document.getElementById('form_current_session_info_unload_map').style.display = name ? 'flex' : 'none';
        },

        save: function () {
            const name = $('#form_current_session_info_input_current_map_name').val();
            if (name.length < 4) {
                callEditorFunction('editor:addNotification', {
                    title: 'Map Save',
                    message: 'Map name must be atleast 4 characters long.',
                    icon: 'circle'
                });
                return;
            }

            callEditorFunction('formCurrentSession.map.save', {
                name: name,
                meta: {
                    author: $('#form_current_session_info_input_current_map_author').val(),
                    description: $('#form_current_session_info_input_current_map_description').val()
                }
            });
        },

        unload: function () { callEditorFunction('formCurrentSession.map.unload'); },
    }
}

$(document).ready(function () {
    // Search function
    $("#form_current_session_created_entities_input_filter").on('input', function (e) { formCurrentSession.entities.filter($(this).val()); });
});