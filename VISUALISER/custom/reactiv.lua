local visualizer = {}
visualizer.data_onload = "test"

function visualizer.render(loader,me)
    render.drawSimpleText(64,64,"Hello it's a test")
    render.drawSimpleText(64,64+15,"Data from visualizer: " .. table.toString(me))
end

return visualizer