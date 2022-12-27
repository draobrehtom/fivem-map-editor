const formSessionEdit = {
    updateFields: function(post) {
        if (!post) { return; }
    
        document.getElementById('form_session_edit_title').innerHTML = post.fields.name;
        $('#form_session_edit_input_session_name').val(post.fields.name);
        $('#form_session_edit_input_session_maximum_slots').val(parseInt(post.fields.maximumSlots));
        $('#form_session_edit_input_session_password').val(post.fields.password || '');
    },
    
    remove: function () {
        if (formSessionBrowser.selectedId == null) { return; }
    
        callEditorFunction('formSessionEdit.remove', { id: formSessionBrowser.selectedId });
        nui.aform.make('form_session_browser');
    },
    
    save: function () {
        if (formSessionBrowser.selectedId == null) { return; }
    
        const name = $('#form_session_edit_input_session_name').val();
        const maximumSlots = parseInt($('#form_session_edit_input_session_maximum_slots').val());
        const password = $('#form_session_edit_input_session_password').val();
    
        if (name.length < 3 || name.length > 32) {
            callEditorFunction('editor:addNotification', {
                title: 'Session Configuration',
                message: 'Session name must be at minimum 3 and maximum 64 characters long.',
                icon: 'circle'
            });
            return;
        }
    
        if (maximumSlots == null || maximumSlots < 0 || maximumSlots > 16) {
            callEditorFunction('editor:addNotification', {
                title: 'Session Configuration',
                message: 'Session maximum slots must be a number between 0 and 16.',
                icon: 'circle'
            });
            return;
        }
    
        callEditorFunction('formSessionEdit.save', {
            id: formSessionBrowser.selectedId,
            details: {
                name: name,
                maximumSlots: maximumSlots,
                password: password
            }
        });
    
        nui.aform.make('form_session_browser');
    }
}