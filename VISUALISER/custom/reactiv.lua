local visualizer = {}
visualizer.smooth_fft = {}

function visualizer.render(loader,me)
    render.drawSimpleText(64,64,"Hello it's a test")
    render.drawSimpleText(64,64+15,"Data from visualizer: " .. table.toString(me))
    render.drawText(64,64+30,"Data from loader: " .. table.toString(loader,nil,true))
end

return visualizer