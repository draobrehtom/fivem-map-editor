const formCurrentSessionLibrary = {
    list: function (post) {
        const maps = post.maps;
        if (!maps) { return; }

        const currentMap = post.currentMap;
        const element = document.getElementById('form_current_session_library_list_maps');
        if (!element) { return; }

        var count = 0;
        var innerHTML = '';
        $.each(maps, function (key, value) {
            count++;
            var isCurrent = currentMap == value.name;
            var color = isCurrent ? 'var(--foxx-green)' : 'var(--foxx-bright)';
            innerHTML += `
            <span class='list_item'>
                <table width='100%'>
                    <tr>
                        <td width='5%'>
                            <i class="fa fa-circle" style="color: ` + color + `;"></i>
                        </td>
                        <td width='20%'>
                            <span style="color: ` + color + `;">` + value.name + `</span>
                        </td>
                        <td width='20%'>
                            <span style="color: ` + color + `;">` + value.meta.author + `</span>
                        </td>
                        <td width='25%'>
                            <span style="color: ` + color + `;">` + value.meta.description + `</span>
                        </td>
                        <td width='20%'>
                            <span style="color: ` + color + `;">` + value.lastSaved + `</span>
                        </td>
                        <td width='10%'>
                            <span class="flex_row stretch center_items right">
                                ` + (!isCurrent ? `<a onclick="formCurrentSessionLibrary.load('` + value.name + `')"><i class="fa fa-play"></i></a>` : ``) + `
                                <a onclick="formCurrentSessionLibrary.export('` + value.name + `')"><i class="fa fa-download"></i></a>
                            </span>
                        </td>
                    </tr>
                </table>
            </span>`;
        });

        element.innerHTML = innerHTML;
        document.getElementById('form_current_session_library_title').innerHTML = (count == 0 ? 'No' : count) + ' Map' + (count == 1 ? '' : 's') + ' Found';
    },

    load: function (value) {
        nui.aform.make('form_current_session');
        callEditorFunction('formCurrentSessionLibrary.load', { name: value });
    },

    export: function (value) {
        callEditorFunction('formCurrentSessionLibrary.export', { name: value });
    }
}