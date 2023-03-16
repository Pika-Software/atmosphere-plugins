local filesystem = atmosphere.Require( 'filesystem' )
local logger = atmosphere.Require( 'logger' )

Plugin.Name = 'Shaders'
Plugin.Author = 'Pika Software'
Plugin.BinaryName = 'egsm'

local log = logger.Create( Plugin.Name, Color( 150, 150, 100 ) )
if not util.IsBinaryModuleInstalled( Plugin.BinaryName ) then
    log:Error( 'Binary module not installed! [https://github.com/devonium/EGSM]' )
    return
end

if not pcall( require, Plugin.BinaryName ) then
    log:Error( 'Installation of the binary module failed!' )
    return
end

if not filesystem.IsDir( 'shaders' ) then
    filesystem.Delete( 'shaders' )
    filesystem.CreateDir( 'shaders' )
end

log:Info( 'Initialised successfully.' )