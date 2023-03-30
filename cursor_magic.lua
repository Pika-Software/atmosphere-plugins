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

        local startX, startY = input.GetCursorPos()
        local boolean = true

        hook.Add( 'Think', Plugin.Name, function()
            local speed = Plugin.Speed:GetValue()
            local delay = Plugin.Delay:GetValue()
            local cx, cy = input.GetCursorPos()

            local x, y = cx, cy

            local mode = Plugin.Mode:GetValue()
            if ( mode == 'infinity' ) then
                x = x + ( startX + math.cos( CurTime() * speed ) * Plugin.Amplitude:GetValue() - cx ) / delay
                y = y + ( startY + math.sin( CurTime() * speed * 2 ) * Plugin.Amplitude:GetValue() / 2 - cy ) / delay
            elseif ( mode == 'circle' ) then
                x = x + ( startX + math.cos( CurTime() * speed ) * Plugin.Amplitude:GetValue() - cx ) / delay
                y = y + ( startY + math.sin( CurTime() * speed ) * Plugin.Amplitude:GetValue() - cy ) / delay
            elseif ( mode == 'spiral' ) then
                local radius = Plugin.Amplitude:GetValue() / 2 + math.sin( CurTime() * speed / 5  ) * Plugin.Amplitude:GetValue() / 2
                x = startX + (  math.cos( CurTime() * speed ) * radius - cx ) / delay
                y = startY + ( math.sin( CurTime() * speed ) * radius - cy ) / delay
            elseif ( mode == 'apple' ) then
                local radius = Plugin.Amplitude:GetValue() / 2 + math.sin( CurTime() ) * Plugin.Amplitude:GetValue() / 2
                x = x + ( startX + math.cos( CurTime() * speed ) * radius - cx ) / delay
                y = y + ( startY + math.sin( CurTime() * speed ) * radius - cy ) / delay
            elseif ( mode == 'sun' ) then
                local radius = Plugin.Amplitude:GetValue() / 2 + math.sin( CurTime() * 10 ) * Plugin.Amplitude:GetValue() / 2
                x = x + ( startX + math.cos( CurTime() * speed ) * radius - cx ) / delay
                y = y + ( startY + math.sin( CurTime() * speed ) * radius - cy ) / delay
            elseif ( mode == 'rhombus' ) then
                x = x + math.Clamp( math.sin( CurTime() ) * Plugin.Amplitude:GetValue(), -1, 1 )
                y = y + math.Clamp( math.cos( CurTime() ) * Plugin.Amplitude:GetValue(), -1, 1 )
            elseif ( mode == 'triangle' ) then
                x = x + math.Clamp( math.sin( CurTime() ) * Plugin.Amplitude:GetValue(), -1, 1 )
                if math.sin( CurTime() ) >= 0.009 then
                    boolean = false
                end

                if math.sin( CurTime() ) <= 0.001 then
                    boolean = true
                end

                if boolean then
                    y = y + math.Clamp( math.cos( CurTime() ) * Plugin.Amplitude:GetValue(), -1, 1 )
                end
            end

            input.SetCursorPos( x, y )
        end )
    end
end )