const formSessionCreate = {
    create: function () {
        if (formSessionCreate.awaitingCallback) { return; }

        const name = $('#form_session_create_input_session_name').val();
        const maximumSlots = parseInt($('#form_session_create_input_session_maximum_slots').val());
        const password = $('#form_session_create_session_password').val();

        if (name.length < 3 || name.length > 32) {
            callEditorFunction('editor:addNotification', {
                title: 'Session Create',
                message: 'Session name must be at minimum 3 and maximum 64 characters long.',
                icon: 'circle'
            });
            return;
        }

        if (maximumSlots == null || maximumSlots < 0 || maximumSlots > 16) {
            callEditorFunction('editor:addNotification', {
                title: 'Session Create',
                message: 'Session maximum slots must be a number between 0 and 16.',
                icon: 'circle'
            });
            return;
        }

        callEditorFunction('formSessionCreate.create', {
            name: name,
            maximumSlots: maximumSlots,
            password: password
        });
    },

    waitUntilCreated: function () {
        formSessionCreate.awaitingCallback = true;
        document.getElementById('form_session_button_session_create').innerHTML = 'Please wait...';
    },

    createCallback: function () {
        formSessionCreate.awaitingCallback = null;
        document.getElementById('form_session_button_session_create').innerHTML = 'Create<i class="fa fa-circle"></i>';
        nui.aform.make('form_session_browser');
    },
}