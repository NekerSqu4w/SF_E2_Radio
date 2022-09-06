local lt = love.timer
local lm = love.math

function NewParticle(pos,vel,die_time,size,ang,gravity,air_resistance,color1,color2)
    local p = {}

    pos = pos or {x=150,y=150}
    vel = vel or {x=random(-5,5),y=random(-5,5)}
    die_time = die_time or 2
    color1 = color1 or Color(1,1,1,1)
    color2 = color2 or Color(1,1,1,0)
    size_start = size.start or 15
    size_end = size._end or 0
    start_ang = ang.start or 0
    end_ang = ang._end or 360
    air_resistance = air_resistance or 1.003
    gravity = gravity or {x=0,y=-1}

    p.pos = pos
    p.vel = vel
    p.die_time = die_time
    p.color1 = color1
    p.color2 = color2
    p.size_start = size_start
    p.size_end = size_end
    p.current_size = size_start
    p.air_resistance = air_resistance

    p.gravity = gravity

    p.ang_start = start_ang
    p.ang_end = end_ang
    p.current_ang = start_ang

    p.spawn_at = lt.getTime()

    return p
end