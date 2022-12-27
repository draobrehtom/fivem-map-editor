const nui = {
	display: function (item) {
		if (!!nui.state && nui.state == item.state) { return; }
	
		if (item.state == 1) {
			nui.aform.hide();
	
			if (!nui.aform.id) {
				nui.aform.make($('.editor_form')[0].id);
	
				// Show last form
			} else if (nui.aform.id) {
				if ($(document.getElementById(nui.aform.id)).attr('editor-only') && editor.mode != 'edit') {
					nui.aform.id = $('.editor_form')[0].id;
	
				} else if ($(document.getElementById(nui.aform.id)).attr('session-only') && (!editor.sessionId || editor.sessionId < 1)) {
					nui.aform.id = $('.editor_form')[0].id;
				}
				nui.aform.make(nui.aform.id);
			}
			document.getElementById('navbar').style.display = 'flex';
			document.getElementById('flex_container').style.display = 'flex';
	
		} else {
			nui.overlay({state: 0});
			nui.aform.hide();
			document.getElementById('navbar').style.display = 'none';
			document.getElementById('flex_container').style.display = 'none';
		}
	},

	overlay: function (item) { document.getElementById('overlay').style.display = item.state == 1 ? 'block' : 'none'; },

	aform: {
		id: 0,
		lastId: 0,

		hide: function () {
			nui.aform.id = nui.aform.id || nui.aform.lastId;
			if (nui.aform.id == null) { return; }
		
			const element = document.getElementById(nui.aform.id);
			if (element) {
				element.style.display = 'none';
		
				var _formId = nui.aform.id;
				var parentId = $('#' + nui.aform.id).attr('parent-form');
				if (parentId) { _formId = parentId; }
		
				var button = $("span.control[form-id='" + _formId + "']")[0];
				if (button) { button.classList.remove('active'); }
		
				$.post('http://editor2/nui.formHid', JSON.stringify({ id: nui.aform.id }));
		
				if ($(element).hasClass('external')) { nui.aform.id = null; }
			}
		},

		make: function (formId) {
			const element = document.getElementById(formId);
			if (element == null || element.style.display == 'flex') {
				return;
			}
		
			if ($(element).attr('editor-only') && editor.mode != 'edit') {
				return;
		
			} else if ($(element).attr('session-only') && (editor.sessionId == null || editor.sessionId < 1)) {
				return;
			}
		
			if ($(element).hasClass('external') && nui.aform.id && document.getElementById(nui.aform.id).style.display != 'none') { return; }
		
			nui.aform.hide();
			element.style.display = 'flex';
		
			$.post('http://editor2/nui.formShown', JSON.stringify({ id: formId }));
			nui.aform.id = formId;
		
			if (!$(element).hasClass('external')) { nui.aform.lastId = formId; }
		
			var parentId = $('#' + formId).attr('parent-form');
			if (parentId) { formId = parentId; }
		
			var button = $("span.control[form-id='" + formId + "']")[0];
			if (button) { button.classList.add('active'); }
		}
	},
	
	switch: function (item) {
		if (nui.aform.id && nui.aform.id == item.formId) { return; }

		nui.aform.make(item.value);
	},
}

function callEditorFunction(functionName, functionArgs) {
	if (typeof (functionName) != 'string') { return false; }

	$.post('http://editor2/' + functionName, JSON.stringify(functionArgs));
}

$(document).on('keydown', (e) => {
	if ($('input').is(':focus') || ($('.editor-form').is(':visible')) && (e.keyCode > 112 && e.keyCode < 123) == false) { return; }

	callEditorFunction('nui.keyPressed', { key: e.keyCode });
});

$(document).ready(function () {
	// Lua-calls
	window.addEventListener('message', function (event) {
		const post = event.data;
		if (post == null) { return; }

		if (post.action == 'callFunction' && !!post.functionName) {
			var fn = eval(post.functionName);
			if (typeof fn === "function") fn(post);

		} else if (post.action == 'triggerEvent' && !!post.eventName) {
			jQuery.event.trigger(post.eventName, post.args, document, true);
		}
	});

	$('input[noascii]').on('keypress', function (event) {
		var regex = new RegExp("^[a-zA-Z0-9]+$");
		var key = String.fromCharCode(!event.charCode ? event.which : event.charCode);
		if (!regex.test(key)) {
			event.preventDefault();
			return false;
		}
	});

	// Tab switches
	$(".control").click(function () {
		const value = $(this).attr('form-id');
		if (nui.aform.id && nui.aform.id == value) { return; }

		nui.aform.make(value);
	});

	$.post('http://editor2/nui.ready');
});