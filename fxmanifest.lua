fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Zoo Scripts'
description 'zoo_indoorstorm -- the storm heard from indoors'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua',
}

-- two audio scenes of our own that turn the storm's sound groups down,
-- written in the game's own audio mix format
files { 'audio/zoo_storm_mix.dat40.rel' }
data_file 'AUDIO_DYNAMIXDATA' 'audio/zoo_storm_mix.dat'
