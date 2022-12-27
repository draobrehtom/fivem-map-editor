const editor = {}

$(document).bind('editor:modeChanged', function (e, modeOld, modeNew) {
	editor.mode = modeNew;
});

$(document).bind('nui:stateChanged', function (e, state) {
	nui.overlay({state: !state ? 0 : (state && (!editor.sessionId || editor.sessionId < 1) ? 1 : 0)});
});

$(document).bind('session:clientJoined', function (e, sessionId) {
	editor.sessionId = sessionId;
});

$(document).bind('session:clientLeft', function (e, sessionId) {
	editor.sessionId = -1;
	nui.overlay({ state: 1 });
	nui.aform.make('form_session_browser');
});