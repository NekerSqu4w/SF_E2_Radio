local visualizer = {}

visualizer.smooth_fft = {}

visualizer.buffer = {}
visualizer.buffer.buffers = {"BUFFER1", "BUFFER2"}
visualizer.buffer.buffernum = 1
render.createRenderTarget("BUFFER1")
render.createRenderTarget("BUFFER2")

visualizer.retro_screen = require("retro_screen.txt")

function visualizer.render(loader,me,scrW,scrH)
    local nextbuffer = (me.buffer.buffernum % #me.buffer.buffers)+1
    render.setRenderTargetTexture(me.buffer.buffers[me.buffer.buffernum])
    render.selectRenderTarget(me.buffer.buffers[nextbuffer])
    render.clear(Color(0,0,0,255))

    render.setColor(Color(255, 255, 255, 180))
    render.drawTexturedRect(-8/4, -8/4, 1024+8, 1024+8)
    
    render.setColor(Color(255, 255, 255, 60))
    render.drawTexturedRect(0, 0, 1024, 1024)

    local m = Matrix()
    m:rotate(Angle(0,45,0))
    m:setTranslation(Vector(256,256,0))
                        
    render.pushMatrix(m)
    render.drawTexturedRect(-256, -256, 1024, 1024)
    render.popMatrix()
 
    render.setColor(Color(255,255,255))

    num = 100
    for i=1, num do
        me.smooth_fft[i] = math.lerp(timer.frametime()*10,me.smooth_fft[i] or 0, loader.FFT.fft2[i] or 0)
    
        r = 100 + loader.bassfft*60 + me.smooth_fft[i] * 150
        r2 = 100 + loader.bassfft*60 + (me.smooth_fft[i-1] or me.smooth_fft[num] or 0) * 150
        x,y = math.cos((i/num) * (math.pi*2)) * r,math.sin((i/num) * (math.pi*2)) * r
        lx,ly = math.cos(((i-1)/num) * (math.pi*2)) * r2,math.sin(((i-1)/num) * (math.pi*2)) * r2

        render.setColor(Color((i / num) * 360 + loader.bassfft/2 * 230,1,1):hsvToRGB())
        render.drawLine(256+x,256+y,256+lx,256+ly)
    
    
        r = 100 - loader.bassfft*60 - me.smooth_fft[i] * 80
        r2 = 100 - loader.bassfft*60 - (me.smooth_fft[i-1] or me.smooth_fft[num] or 0) * 80
        x,y = math.cos((i/num) * (math.pi*2)) * r,math.sin((i/num) * (math.pi*2)) * r
        lx,ly = math.cos(((i-1)/num) * (math.pi*2)) * r2,math.sin(((i-1)/num) * (math.pi*2)) * r2
    
        render.setColor(Color((i / num) * 360 + loader.bassfft/2 * 230,1,1):hsvToRGB())
        render.drawLine(256+x,256+y,256+lx,256+ly)
    end
    
    render.selectRenderTarget(nil)

    me.retro_screen.push()
    render.setColor(Color(255,255,255))
    render.setRenderTargetTexture(me.buffer.buffers[nextbuffer])
    render.drawTexturedRect(scrW/2 - 1024/4,0,1024,1024)
    me.retro_screen.pop()
                        
    me.buffer.buffernum = nextbuffer

    me.retro_screen.draw(512,512,false)
end

return visualizer