local convars = atmosphere.Require( 'convars' )
atmosphere.Require( 'buttons' )

Plugin.Name = 'Cursor Magic'
Plugin.Author = 'AngoNex'
Plugin.Description = 'A little funny plugin)'

Plugin.BindName = 'cursor_magic'

Plugin.Amplitude = convars.Create( 'cursor_magic_amplitude', 200, TYPE_NUMBER, ' - ', true )

Plugin.Mode = convars.Create( 'cursor_magic_mode', 'infinity', TYPE_STRING, ' - ', true )

Plugin.Speed = convars.Create( 'cursor_magic_speed', 5, TYPE_NUMBER, ' - ', true )
Plugin.Delay = convars.Create( 'cursor_magic_delay', 11.111, TYPE_NUMBER, ' - ', true )

hook.Add( 'BindPress', Plugin.Name, function( bind, pressed )
    if ( bind == Plugin.BindName ) then
        if not pressed then
            hook.Remove( 'Think', Plugin.Name )
            return
        end

        local x, y = input.GetCursorPos()
        hook.Add( 'Think', Plugin.Name, function()
            local amplitude = Plugin.Amplitude:GetValue()
            local speed = Plugin.Speed:GetValue()
            local delay = Plugin.Delay:GetValue()
            local cx, cy = input.GetCursorPos()

            local mode = Plugin.Mode:GetValue()
            if ( mode == 'infinity' ) then
                cx = cx + ( x + math.cos( CurTime() * speed ) * amplitude - cx ) / delay
                cy = cy + ( y + math.sin( CurTime() * speed * 2 ) * amplitude / 2 - cy ) / delay
            elseif ( mode == 'circle' ) then
                cx = cx + ( x + math.cos( CurTime() * speed ) * amplitude - cx ) / delay
                cy = cy + ( y + math.sin( CurTime() * speed ) * amplitude - cy ) / delay
            elseif ( mode == 'spiral' ) then
                local radius = amplitude / 2 + math.sin( CurTime() * speed / 5  ) * amplitude / 2
                cx = x + (  math.cos( CurTime() * speed ) * radius - cx ) / delay
                cy = y + ( math.sin( CurTime() * speed ) * radius - cy ) / delay
            end

            input.SetCursorPos( cx, cy )
        end )
    end
end )