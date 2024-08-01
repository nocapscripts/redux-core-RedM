fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'redux-core'
version '1.4.2'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/locale.lua',
    'locale/en.lua',
    'locale/*.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
    'client/main.lua',
    'client/functions.lua',
    'client/loops.lua',
    'client/events.lua',
    'client/drawtext.lua',
    'client/prompts.lua',
    'client/pvp.lua',

    'client/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/functions.lua',
    'server/player.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/exports.lua',
    'server/debug.lua',

    'database/sv_db.lua',
    'database/database.lua',
    'client/utils.lua',
    'server/sv_restart.lua',
    'server/sv_cron.lua'
}

dependency {
    'oxmysql',
    'ox_lib'
}

lua54 'yes'
