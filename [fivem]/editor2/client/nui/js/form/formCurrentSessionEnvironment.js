const formCurrentSessionEnvironment = {
    apply: function() {
        callEditorFunction('formCurrentSessionEnvironment.apply', {
            weather: parseInt($('#form_current_session_environment_input_weather').val()),
            time: {
                hour: parseInt($('#form_current_session_environment_input_hour').val()),
                minute: parseInt($('#form_current_session_environment_input_minute').val())
            }
        });
    },

    updateFields: function (item) {
        const weather = item.weather || 1;
        const hour = item.time[0] || 12;
        const minute = item.time[1] || 0;

        $('#form_current_session_environment_input_weather').val(weather);
        $('#form_current_session_environment_input_hour').val(hour);
        $('#form_current_session_environment_input_minute').val(minute);
    },
}