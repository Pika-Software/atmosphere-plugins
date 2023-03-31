local logger = atmosphere.Require( 'logger' )

Plugin.Name = 'EGSM'
Plugin.Author = 'devonium'
Plugin.BinaryName = ( BRANCH == 'x86-64' or BRANCH == 'chromium' ) and 'egsm_chromium' or 'egsm'

local log = logger.Create( Plugin.Name, Color( 150, 150, 100 ) )
if not util.IsBinaryModuleInstalled( Plugin.BinaryName ) then
    log:Error( 'Binary module not installed! [https://github.com/devonium/EGSM]' )
    return
end

if not pcall( require, Plugin.BinaryName ) then
    log:Error( 'Installation of the binary module failed!' )
    return
end

if not EGSM then
    log:Error( 'Initialization failed, no global table.' )
    return
end

if ( EGSM.Version <= 0 ) then
    log:Error( 'Initialization failed, incorrect version.' )
    return
end

log:Info( 'Initialised successfully, version: %s', string.Version( EGSM.Version ) )