Plugin.Name = 'Discord RPC'
Plugin.Author = 'Pika Software'
Plugin.Description = 'A plugin for sending game session information to Discord.'

-- Localization & Requires
local discord = atmosphere.Require( 'discord' )
local steam = atmosphere.Require( 'steam' )
local logger = discord.Logger
local IsValid = IsValid
local hook = hook

-- Discord application client ID
local clientID = '1016151516761030717'

-- Client API
do

    local link = atmosphere.Require( 'link' )

    link.Receive( 'discord.rpc.setRoundEndTime', discord.SetRoundEndTime )
    link.Receive( 'discord.rpc.startStopwatch', discord.StartStopwatch )
    link.Receive( 'discord.rpc.clearTime', discord.ClearTime )

end

module( 'atmosphere.discord.rpc', package.seeall )

-- Convenient functions
function SteamInfo()
    local clientInfo = steam.GetClientInfo()
    if clientInfo and clientInfo.steamid then
        steam.GetUser( steam.IDTo64( clientInfo.steamid ) ):Then( function( result )
            discord.SetupIcon( result.nickname, result.avatar )
        end, function( err )
            logger:Warn( 'Getting steam user info failed - %s', err )
        end )
    end
end

do

    local api = atmosphere.Require( 'api' )
    function MapInfo( mapName )
        discord.SetImageText( mapName )

        api.GetMapIcon( mapName ):Then( function( imageURL )
            discord.SetImage( imageURL )
        end, function()
            discord.SetImage( 'no_icon' )
        end )
    end

end

function MenuInfo( title, logo )
    if ( title ~= discord.GetTitle() ) then
        discord.StartStopwatch()
    end

    discord.SetupImage( title, logo )
    discord.SetTitle( title )

    SteamInfo()
end

do

    local pages = atmosphere.Require( 'pages' )

    function PageInfo( panel )
        if not IsValid( panel ) then
            panel = pages.Get()
        end

        if IsValid( panel ) then
            local pageName = panel.APageName
            if isstring( pageName ) then
                MenuInfo( pageName, 'clouds' )
                return
            end
        end

        MenuInfo( '#atmosphere.mainmenu', 'clouds' )
    end

    hook.Add( 'PageChanged', 'atmosphere.discord.rpc', PageInfo )

end

-- Discord Connect Managment
do

    local timer = timer
    local attempts = 1

    local function connect()
        if discord.IsConnected() then return end
        logger:Info( 'Searching for a client...' )

        local code = discord.Init( clientID )
        if (code == 0) then
            logger:Info( 'Client detected, pending connection...' )
            attempts = 1
            return
        end

        local delay = attempts * 2
        timer.Create( 'atmoshere.discord.rpc.reconnect', delay, 1, connect )
        logger:Warn( 'Client disconnected (Code: %s), next attempt after %s sec.', code, delay )
        attempts = math.Clamp( attempts + 1, 1, 15 )
    end

    hook.Add( 'DiscordConnected', 'atmosphere.discord.rpc', function()
        timer.Remove( 'atmoshere.discord.rpc.reconnect' )
        logger:Info( 'Client successfully connected!' )
    end )

    hook.Add( 'DiscordDisconnected', 'atmosphere.discord.rpc', function()
        timer.Create( 'atmoshere.discord.rpc.reconnect', 0.25, 1, connect )
        logger:Warn( 'Client disconnected, reconnecting...' )
    end )

    hook.Add( 'DiscordReady', 'atmosphere.discord.rpc', function()
        discord.Update()
    end )

    hook.Add( 'DiscordLoaded', 'atmosphere.discord.rpc', function()
        connect()
        PageInfo()
    end )

end

-- Language Change
hook.Add( 'LanguageChanged', 'atmosphere.discord.rpc', discord.Update )

-- Loading Info
hook.Add( 'LoadingStarted', 'atmosphere.discord.rpc', function()
    discord.Clear()
    discord.StartStopwatch()
    discord.SetImage( 'no_icon' )
    discord.SetImageText( 'unknown' )
    discord.SetState( '#atmosphere.connecting_to_server' )
end )

local convars = atmosphere.Require( 'convars' )
local server = atmosphere.Require( 'server' )

hook.Add( 'LoadingFinished', 'atmosphere.discord.rpc', function()
    if server.IsConnected() then return end
    discord.Clear()
    PageInfo()
end )

local loadingStatus = convars.Create( 'discord_loading_status', true, TYPE_BOOL, ' - Displays the connection process in your Discord activity.', true )
hook.Add( 'LoadingStatusChanged', 'atmosphere.discord.rpc', function( status )
    if not loadingStatus:GetValue() then return end
    if server.IsConnected() then return end
    discord.SetTitle( status )
end )

local gamemode = atmosphere.Require( 'gamemode' )

-- Game Info
hook.Add( 'ServerDetails', 'atmosphere.discord.rpc', function( result )
    MapInfo( result.Map )

    if loadingStatus:GetValue() then return end
    discord.SetState( gamemode.GetName( result.Gamemode ) )
    discord.SetTitle( result.Name )
end )

do

    local string = string
    local util = util

    hook.Add( 'ClientConnected', 'atmosphere.discord.rpc', function()
        SteamInfo()

        discord.SetState( gamemode.GetName( server.GetGamemode() ) )
        discord.SetTitle( server.GetHostName() )
        MapInfo( server.GetMap() )
        discord.StartStopwatch()

        local secret = { server.GetAddress() }
        if (secret[ 1 ] == 'loopback') then
            local sid64 = server.GetSteamID64()
            if not sid64 then sid64 = steam.IDTo64( steam.GetClientInfo().steamid ) end

            secret[ 1 ] = 'p2p:' .. sid64
            secret[ 3 ] = cvars.String( 'sv_password' )
            secret[ 2 ] = util.GetUUID()
        elseif string.IsP2P( secret[ 1 ] ) then
            secret[ 2 ] = discord.GetPartyID() or util.GetUUID()
            secret[ 3 ] = cvars.String( 'password' )
        else
            secret[ 2 ] = string.format( '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', string.byte( secret[ 1 ], 1, 16 ) )
            secret[ 3 ] = cvars.String( 'password' )
        end

        discord.SetJoinSecret( util.Base64Encode( table.concat( secret, ';' ) ) )
        discord.SetPartyID( secret[ 2 ] )
    end )

    local console = atmosphere.Require( 'console' )

    hook.Add( 'DiscordJoin', 'atmosphere.discord.rpc', function( joinSecret )
        local secret = util.Base64Decode( joinSecret )
        if not secret then return end

        local secretData = string.Split( secret, ';' )
        if (#secretData < 1) then return end

        local address = secretData[ 1 ]
        if not address then return end

        local partyID = secretData[ 2 ]
        if (partyID ~= nil) then
            discord.SetPartyID( partyID )

            local password = secretData[ 3 ]
            if (password ~= nil and password ~= '') then
                console.Run( 'password', password )
            end
        end

        discord.Logger:Info( 'Connecting to %s', address )
        server.Join( address )
    end )

end

do

    local serverDelay = convars.Create( 'discord_server_delay', 3, TYPE_NUMBER, ' - Time interval between server information updates.', true, 1, 120 )
    local CurTime = CurTime
    local nextUpdate = 0

    hook.Add( 'Think', 'atmosphere.discord.rpc', function()
        if not server.IsConnected() then return end

        local time = CurTime()
        if (nextUpdate > time) then return end
        nextUpdate = time + serverDelay:GetValue()

        discord.SetPartySize( server.GetPlayerCount(), server.GetMaxPlayers() )
        discord.SetTitle( server.GetHostName() )
    end )

end

hook.Add( 'ClientDisconnected', 'atmosphere.discord.rpc', function()
    discord.Clear()
    PageInfo()
end )

-- Discord invite notification
do

    local notifications = atmosphere.Require( 'notifications' )

    hook.Add( 'DiscordInvite', 'atmosphere.discord.rpc', function( activityType, user, data )
        if ( data.application_id ~= clientID ) then return end

        local panel = notifications.Create()
        if not IsValid( panel ) then return end

        panel:SetTitle( 'You have been invited to the server.' )
        panel:SetupAvatar( discord.GetAvatarURL( user.id, user.avatar ) )
        panel:SetDescription( user.username .. ', invites you to join the game, you can accept it on Discord.' )
        panel:SetAllowClose( true )
        panel:SetLifeTime( 5 )
    end )

end