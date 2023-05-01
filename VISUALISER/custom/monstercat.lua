local visualizer = {}

visualizer.smooth_fft = {}
visualizer.titleFont = render.createFont("FontAwesome",60,800,true)
visualizer.authorFont = render.createFont("FontAwesome",35,0,true)

function visualizer.render(loader,me,scrW,scrH)
    render.setColor(Color(150,150,150))
    render.setRenderTargetTexture("coverBlurBuffer")
    render.drawTexturedRect(0, 0, scrW, scrW)
    render.setRenderTargetTexture()


    num = 52
    for i=0, num do
        me.smooth_fft[i] = math.lerp(timer.frametime()*10,me.smooth_fft[i] or 0, loader.FFT.fft2[i] or 0)

        local val = 2 + me.smooth_fft[i] * scrH/2

        //draw drop shadow
        render.setColor(Color(0,0,0))
        render.drawRect(100 - 5 + (i/num) * (scrW - 200) + 1,scrH/2 - val + 1,10,val)
        
        //
        render.setColor(Color(255,255,255))
        render.drawRect(100 - 5 + (i/num) * (scrW - 200),scrH/2 - val,10,val)
    end

    //draw drop shadow
    render.setColor(Color(0, 0, 0))
    render.drawRect(100-5+1, scrH/2 + 10+1, 100, 100)

    render.setColor(Color(255, 255, 255))
    render.setMaterial(loader.cover)
    render.drawTexturedRect(100-5, scrH/2 + 10, 100, 100)
    render.setMaterial()


    //draw drop shadow
    render.setFilterMag(1)
    render.setFilterMin(1)
    render.setColor(Color(0, 0, 0))
    render.setFont(me.titleFont)
    render.drawSimpleText(100+5 + 100+1,scrH/2+15+1,loader.current_track.detail.title)
    render.setFont(me.authorFont)
    render.drawSimpleText(100+5 + 100+1,scrH/2 + 100+1,loader.current_track.detail.author,0,TEXT_ALIGN.BOTTOM)

    //
    render.setColor(Color(255, 255, 255))
    render.setFont(me.titleFont)
    render.drawSimpleText(100+5 + 100,scrH/2+15,loader.current_track.detail.title)
    render.setFont(me.authorFont)
    render.drawSimpleText(100+5 + 100,scrH/2 + 100,loader.current_track.detail.author,0,TEXT_ALIGN.BOTTOM)
    
    
    render.setFilterMag(3)
    render.setFilterMin(3)
end

//executed only when switch to another visualizer
//can be usefull to remove render target
function visualizer.on_switch()
end

return visualizer