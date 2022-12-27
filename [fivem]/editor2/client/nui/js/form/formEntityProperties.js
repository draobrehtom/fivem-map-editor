const formEntityProperties = {
    tab: function (value) {
        $("div[form_entity_properties_tab]").hide();
        $("div[form_entity_properties_tab='" + value + "'").show();
    },

    display: function (item) {
        const post = item.post;
        if (!post) { return; }

        const locked = post.locked == 1;

        // Entity name
        document.getElementById("form_entity_properties_title").innerHTML = `
        ` + (locked ? '<i class="fa fa-lock"></i>' : '') + `
        ` + post.model + `
        <span style="color: var(--foxx-blue)">` + getEntityClassName(post.class) + `</span>`;

        // Coords
        document.getElementById("form_entity_properties_input_entity_coord_x").value = post.coords.x;
        $(document.getElementById("form_entity_properties_input_entity_coord_x")).prop('disabled', locked);

        document.getElementById("form_entity_properties_input_entity_coord_y").value = post.coords.y;
        $(document.getElementById("form_entity_properties_input_entity_coord_y")).prop('disabled', locked);

        document.getElementById("form_entity_properties_input_entity_coord_z").value = post.coords.z;
        $(document.getElementById("form_entity_properties_input_entity_coord_z")).prop('disabled', locked);

        // Rotation
        document.getElementById("form_entity_properties_input_input_entity_pitch").value = post.rotation.x;
        $(document.getElementById("form_entity_properties_input_input_entity_pitch")).prop('disabled', locked);

        document.getElementById("form_entity_properties_input_input_entity_roll").value = post.rotation.y;
        $(document.getElementById("form_entity_properties_input_input_entity_roll")).prop('disabled', locked);

        document.getElementById("form_entity_properties_input_input_entity_yaw").value = post.rotation.z;
        $(document.getElementById("form_entity_properties_input_input_entity_yaw")).prop('disabled', locked);

        // Rotation type
        $("#form_entity_properties a.button[property-rotation-type]").removeClass('green');
        if (post.rotationType) {
            const button = $("#form_entity_properties a.button[property-rotation-type='" + post.rotationType + "']")[0];
            if (button) { button.classList.add('green'); }
        }

        // Alpha
        $("#form_entity_properties a.button[property-alpha]").removeClass('blue');
        if (post.alpha) {
            const button = $("#form_entity_properties a.button[property-alpha='" + post.alpha + "']")[0];
            if (button) { button.classList.add('blue'); }
        }

        // LOD
        $("#form_entity_properties a.button[property-lod]").removeClass('blue');
        if (post.lod) {
            const button = $("#form_entity_properties a.button[property-lod='" + post.lod + "']")[0];
            if (button) { button.classList.add('blue'); }
        }

        // Decals
        $("#form_entity_properties_input_entity_decals").val(post.decals != null ? post.decals : 0);

        // Properties
        $.each(post, function (key, value) {
            var toggle = $("a.button.toggle[property='" + key + "']")[0];
            if (toggle) { $(toggle).attr('state', value.toString()); }
        });
    },

    update: function (property, value) {
        if (property == 'decals') { value = parseInt($('select[id=form_entity_properties_input_entity_decals]').val()); }

        callEditorFunction('formEntityProperties.update', { property: property, value: value });
    },

    setAsOrigin: function () {
        callEditorFunction('formEntityProperties.setAsOrigin');
    },

    originMove: function (axis) {
        callEditorFunction('formEntityProperties.originMove', { axis: axis });
    },

    invert: function (axis) {
        callEditorFunction('formEntityProperties.invert', { itype: parseInt($("#form_entity_properties_input_invert_type").val()), axis: axis });
    },

    save: function () { callEditorFunction('formEntityProperties.save'); },

    placeDown: function () { callEditorFunction('formEntityProperties.placeDown'); }
}

$(document).ready(function () {
    // Toggles
    $("body").on('click', 'a.button.toggle', function () {
        const property = $(this).attr('property');
        if (!property) { return; }

        var state = $(this).attr('state');
        state = state == '1' && '0' || '1';
        formEntityProperties.update(property, parseInt(state));
    });

    $("#form_entity_properties input").on('input', null, null, function () {
        // Coords
        const coord_x = parseFloat($("input[id=form_entity_properties_input_entity_coord_x").val());
        const coord_y = parseFloat($("input[id=form_entity_properties_input_entity_coord_y").val());
        const coord_z = parseFloat($("input[id=form_entity_properties_input_entity_coord_z").val());

        // Rotation
        const rot_pitch = parseFloat($("input[id=form_entity_properties_input_input_entity_pitch").val());
        const rot_roll = parseFloat($("input[id=form_entity_properties_input_input_entity_roll").val());
        const rot_yaw = parseFloat($("input[id=form_entity_properties_input_input_entity_yaw").val());

        formEntityProperties.update('coords', { coord_x: coord_x, coord_y: coord_y, coord_z: coord_z });
        formEntityProperties.update('rotation', { rot_pitch: rot_pitch, rot_roll: rot_roll, rot_yaw: rot_yaw });
    });

    // Rotation type
    $("body").on('click', '#form_entity_properties a.button[property-rotation-type]', function () {
        const value = $(this).attr('property-rotation-type');
        if (value) { formEntityProperties.update('rotationType', value); }
    });

    // Entity alpha
    $("body").on('click', '#form_entity_properties a.button[property-alpha]', function () {
        const value = $(this).attr('property-alpha');
        if (value) {
            formEntityProperties.update('alpha', parseInt(value));
        }
    });

    // Entity LOD
    $("body").on('click', '#form_entity_properties a.button[property-lod]', function () {
        const value = $(this).attr('property-lod');
        if (value) {
            formEntityProperties.update('lod', parseInt(value));
        }
    });

    formEntityProperties.tab(1);
});