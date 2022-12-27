fx_version 'adamant'
game 'gta5'
lua54 'yes'

name 'editor2'
description 'FOXX Map Editor'
author 'Vizsla @ store.foxx.gg'
version '2.0.0'

shared_scripts {
	'shared/*.lua'
}

client_scripts {
    -- Utils
    'client/utils/common.lua',
    'client/utils/entity.lua',
    'client/utils/entityiter.lua',
    'client/utils/graphics.lua',
    'client/utils/misc.lua',
    'client/utils/pad.lua',
    'client/utils/shapetest.lua',
    'client/utils/system.lua',
    'client/utils/water.lua',
    'client/utils/instructionalbuttons.lua',

    -- Config
    'client/config.lua',

    -- Freecam
    'client/freecam/utils.lua',
    'client/freecam/config.lua',
    'client/freecam/camera.lua',
    'client/freecam/main.lua',
    'client/freecam/restore.lua',

    -- Main
    'client/utils.lua',
    'client/classes/editorthread.lua',
    'client/main.lua',
    'client/cursor.lua',

    -- Editor modes
    'client/modes/edit.lua',
    'client/modes/test.lua',
    'client/modes/main.lua',

    -- Session
    'client/session/classes/session.lua',

    'client/session/main.lua',
    'client/session/utils.lua',
    'client/session/environment.lua',

    'client/session/entity/utils.lua',
    'client/session/entity/create.lua',
    'client/session/entity/sync.lua',
    'client/session/entity/delete.lua',
    'client/session/entity/bulk.lua',
    'client/session/entity/stream.lua',

    -- Interface
    'client/nui/main.lua',
    'client/nui/callback.lua',
    'client/nui/handler.lua',
    'client/nui/luahelper/events.lua',
    'client/nui/luahelper/sessions.lua',
    'client/nui/luahelper/formSessionBrowser.lua',
    'client/nui/luahelper/formSessionCreate.lua',
    'client/nui/luahelper/formSessionEdit.lua',
    'client/nui/luahelper/formCreateEntityPreview.lua',
    'client/nui/luahelper/formCurrentSession.lua',
    'client/nui/luahelper/formCurrentSessionWhitelist.lua',
    'client/nui/luahelper/formCurrentSessionLibrary.lua',
    'client/nui/luahelper/formCurrentSessionEnvironment.lua',
    'client/nui/luahelper/formEntityProperties.lua',

    -- Entity
    'client/entity/classes/editorentity.lua',
    'client/entity/create/spawnpoint.lua',
    'client/entity/create/object.lua',
    'client/entity/create/vehicle.lua',
    'client/entity/utils.lua',
    'client/entity/default.lua',
    'client/entity/select.lua',
    'client/entity/clone.lua',
    'client/entity/delete.lua',
    'client/entity/sync.lua',

    -- Entity preview
    'client/entity/preview/classes/entitypreview.lua',
    'client/entity/preview/main.lua',

    -- World
    'client/world/inspector.lua',
    'client/world/nonpcs.lua',
    'client/world/neverwanted.lua',
    'client/world/clearhud.lua',
    'client/world/blips.lua',

    -- Debugging
    'client/debug/main.lua',

    -- Tools
    'client/tools/movementrecorder/main.lua',
}

server_scripts {
    -- Util
    'server/utils.lua',

	-- Player
	'server/player/classes/fxplayer.lua',
    'server/player/identifier.lua',
    'server/player/utils.lua',
    'server/player/main.lua',

    -- Session
    'server/session/classes/session.lua',
    'server/session/main.lua',
    'server/session/create.lua',
    'server/session/update.lua',
    'server/session/remove.lua',
    'server/session/utils.lua',

    -- Main
    'server/main.lua',

    -- Integration
    'server/integration/discord.lua',
    'server/integration/exportmap.lua',
}

files {
	-- Dumps
	'client/dump/*',

	-- Interface
    'client/nui/img/*',
    'client/nui/svg/*',
    'client/nui/css/*.css',

    'client/nui/js/notification.js',
    'client/nui/js/utils.js',
    'client/nui/js/main.js',
    'client/nui/js/editor.js',

    'client/nui/js/form/formSessionBrowser.js',
    'client/nui/js/form/formSessionCreate.js',
    'client/nui/js/form/formSessionEdit.js',

    'client/nui/js/form/formCreateEntity.js',
    'client/nui/js/form/formCreateEntity.js',
    'client/nui/js/form/formCreateEntity_preview.js',

    'client/nui/js/form/formCurrentSession.js',
    'client/nui/js/form/formCurrentSessionWhitelist.js',
    'client/nui/js/form/formCurrentSessionLibrary.js',
    'client/nui/js/form/formCurrentSessionEnvironment.js',

    'client/nui/js/form/formEntityProperties.js',

	'client/nui/index.html',

	'client/popcycle/popcycle.dat',
}

ui_page 'client/nui/index.html'
data_file 'POPSCHED_FILE' 'client/popcycle/popcycle.dat'