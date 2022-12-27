SPAWNPOINT_MODEL = 'prop_mp_placement'
local DEFAULT_ENTITY_PROPERTIES = protect({
    ['locked'] = 0,
    ['visible'] = 1,
    ['alpha'] = 255,
    ['lod'] = 5000,
    ['frozen'] = 1,
    ['lights'] = 0,
    ['collisions'] = 1,
    ['invincible'] = 0,
    ['dynamic'] = 0,
    ['gravity'] = 0,
    ['decals'] = 0,
    ['rotationType'] = 'heading'
})
_G.DEFAULT_ENTITY_PROPERTIES = table.copy(DEFAULT_ENTITY_PROPERTIES)
protect(_G.DEFAULT_ENTITY_PROPERTIES)
