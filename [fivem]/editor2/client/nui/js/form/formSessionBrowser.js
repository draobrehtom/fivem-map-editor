const formSessionBrowser = {
    list: {
        refresh: function (item) {
            const element = document.getElementById('form_session_browser_list_sessions');
            if (element == null) { return; }

            var count = 0;
            var innerHTML = '';
            $.each(item.sessions, function (key, session) {
                if (session) {
                    count++;
                    let displayColor = session.displayColor != null ? '#' + session.displayColor : '#fafafa';
                    innerHTML += `
                    <span class='list_item'
                        value=` + session.id + `>
                        <div class='flex_col'>
                            <h2 class='flex_row center_items'>
                                ` + session.name + `
                                ` + (!session.secure || session.editable == 1 ? `<small><a onclick="formSessionBrowser.session.join('` + session.id + `')"><i class="fa fa-sign-in"></i>Quick join</a></small>` : ``) + `
                                <span style='color: ` + displayColor + `; margin-left: auto;'>
                                    <i class="` + (session.secure ? 'fa fa-lock' : 'fa fa-circle') + `"></i>
                                </span>
                            </h2>
                            <span class='flex_row center_items'>
                                <small class='flex_row center_items'>
                                    <i class='fa fa-user'></i>
                                    created by ` + (session.ownerName ? session.ownerName : 'noone :(') + `, 
                                    ` + session.playerCount + ` of ` + (session.maximumSlots == 0 ? '∞' : session.maximumSlots) + ` player(s) active
                                </small>
                                
                            </span>
                        </div>
                    </span>`;
                }
            });

            element.innerHTML = innerHTML;
            document.getElementById('form_session_browser_title').innerHTML = `Found ${count} Session${count == 1 ? '' : 's'} For You`;
            document.getElementById('form_session_browser_button_session_leave').style.display = item.inSession == true ? 'flex' : 'none';
        }
    },

    session: {
        display: function (item) {
            const info = item.details;
            if (!info) { document.getElementById('form_session_browser_session_info').style.display = 'none'; return; }

            let sessionId = info.id;
            let sessionName = info.name || 'Undefined';
            let sessionPlayerCount = info.playerCount || 0;
            let sessionMaximumSlots = info.maximumSlots || 0;
            if (sessionMaximumSlots == 0) { sessionMaximumSlots = '∞'; }
            let sessionSecure = info.secure;
            let sessionCanEdit = info.editable == 1;
            let sessionDisplayColor = info.displayColor != null ? '#' + info.displayColor : 'white';

            document.getElementById('form_session_browser_selected_session').style.display = 'flex';
            document.getElementById('form_session_browser_session_join_password').style.display = sessionSecure ? 'flex' : 'none';
            document.getElementById('form_session_browser_selected_session_title').innerHTML = '<span class="flex_row stretch center_items" style="gap: 10px;"><i class="' + (sessionSecure ? 'fa fa-lock' : 'fa fa-circle') + '" style="color: ' + sessionDisplayColor + ';"></i>' + sessionName + '</span></span>';
            document.getElementById('form_session_browser_selected_session_edit').style.display = sessionCanEdit == true ? 'flex' : 'none';
            $('#input_join_session_password').val('');

            let innerHTML = '';
            if (sessionPlayerCount > 0) {
                $.each(info.players, function (playerId, playerName) {
                    if (playerName) {
                        innerHTML += `<span class='list_item'>
                            <span class='flex_row stretch center_items'>
                                <i class="fa fa-user"></i>` + playerName + `
                            </span>
                        </span>`;
                    }
                });
            } else {
                innerHTML += `<span class='list_item'>
                <span class='flex_row stretch center_items'>
                    This session is empty.
                </span>
            </span>`;
            }
            document.getElementById('form_session_browser_selected_session_list_players').innerHTML = innerHTML;
        },

        select: function (id) {
            formSessionBrowser.selectedId = id;
            callEditorFunction('formSessionBrowser.session.select', { id: id });
        },

        join: function (id) {
            if (!id) { id = formSessionBrowser.selectedId; }
            if (!id) { return; }

            callEditorFunction('formSessionBrowser.session.join', {
                id: id,
                password: $('#input_join_session_password').val()
            });
        },

        edit: function () {
            if (formSessionBrowser.selectedId == null) { return; }

            callEditorFunction('formSessionBrowser.session.edit', { id: formSessionBrowser.selectedId });
            nui.aform.make('form_session_edit');
        },

        leave: function () {
            callEditorFunction('formSessionBrowser.session.leave');
        },
    },
}

$(document).ready(function () {
    $("body").on('click', '#form_session_browser_list_sessions .list_item', function () {
        const value = $(this).attr('value');
        if (!value) { return; }

        formSessionBrowser.session.select(value);
    });
});