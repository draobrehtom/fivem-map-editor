const formCurrentSessionWhitelist = {
    tab: function (value) {
        $("div[form_current_session_whitelist_tab]").hide();
        $("div[form_current_session_whitelist_tab='" + value + "'").show();
    },

    list: function (post) {
        if (!!post.err) {
            formCurrentSessionWhitelist.tab(1);
            return;
        }

        const players = post.players;
        if (!players) { return; }

        const currentMap = post.currentMap;
        const element = document.getElementById('form_current_session_whitelist_list_players');
        if (!element) { return; }

        var innerHTML = '';
        $.each(players, function (key, value) {
            var color = !!post.whitelistEnabled ? 'var(--foxx-yellow)' : value.aced == 1 ? 'var(--foxx-green)' : 'var(--foxx-red)';
            innerHTML += `
            <span class='list_item' onclick='formCurrentSessionWhitelist.toggleAce(` + value.uId + `, ` + value.aced + `)'>
                <table width='100%'>
                    <tr>
                        <td width='5%'>
                            <i class="fa fa-user"></i>
                        </td>
                        <td width='35%'>
                            ` + value.uId + `
                        </td>
                        <td width='35%'>
                            ` + value.data.playerName + `
                        </td>
                        <td width='25%'>
                            <i class="fa fa-check" style="color: ` + color + `;"></i>
                        </td>
                    </tr>
                </table>
            </span>`;
        });
        element.innerHTML = innerHTML;
        $("#form_current_session_whitelist_input_disable_whitelist").prop("checked", !!post.whitelistEnabled ? true : false);
        formCurrentSessionWhitelist.tab(2);
    },

    toggleAce: function (playerUId, ace) {
        callEditorFunction('formCurrentSessionWhitelist.toggleAce', { id: playerUId, ace: ace == 1 ? 0 : 1 });
    },

    save: function () {
        const disableWhitelist = $("#form_current_session_whitelist_input_disable_whitelist").prop('checked');
        callEditorFunction('formCurrentSessionWhitelist.save', { disableWhitelist: disableWhitelist });
    }
}