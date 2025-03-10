suit = require 'vendors/suit'

--! TOOLS
Tools = {
    PENCIL = 0,
    ERASER = 1,
    BUCKET = 2,
    COLOR_PICKER = 3

}

CurrentTool = Tools.PENCIL

--!fonts


local pencilArea = 1
local eraserArea = 1
local pixelArray = {
    x,
    y,
    r,
    g,
    b
}
local pixelScale = 10
local showFinalGraphic = false
local screenshotCanvas
local currentColor = {r = 1,g = 1,b = 1,a = 1}
local sliderR = {value = 1, min = 0.0, max = 1.0}
local sliderG = {value = 1, min = 0.0, max = 1.0}
local sliderB = {value = 1, min = 0.0, max = 1.0}
local labelR = ""
local labelG = ""
local labelB = ""

local AdjustingColor = false
local mousePos = {}

local started = false

function pixelArray:addPixel(xpos, ypos, color)
    print("modified pixel at ".. xpos .. ", ".. ypos.. ", ".. color.r .. ", ".. color.g .. ", ".. color.b)
    self[#self+1] = {
        x = xpos,
        y = ypos,
        r = color.r,
        g = color.g,
        b = color.b
    }
end

function pixelArray:copyPixel(xpos,ypos)
    pixel = {
        x = xpos,
        y = ypos,
        r = pixelArray:getPixelAt(x,y).r,
        g = pixelArray:getPixelAt(x,y).g,
        b = pixelArray:getPixelAt(x,y).b
    }
    return pixel
end

function pixelArray:hasPixel(xpos, ypos)
    local out = 0;
    for i = 1, #self do
        if(self[i].x == xpos and self[i].y == ypos)then
            out = i;
        end
    end
    return out
end

function pixelArray:removePixel()
    self[#self] = nil
end

function pixelArray:removePixelAt(xpos, ypos)
    index = pixelArray:getIndexAt(xpos, ypos)

    if(not (index == 0)) then
        for i = index, #self do
            if(i == #self) then
                print("DELETED PIXEL AT " .. "(" .. self[i].x .. ", " .. self[i].y.. ")")
                self[i] = nil
            else
                self[i] = self[i+1]
            end
        end
    end 
end

function pixelArray:changeColor(index, rval,gval,bval)
    pixelArray[index].r = rval;
    pixelArray[index].g = gval;
    pixelArray[index].b = bval;
end

function pixelArray:getIndexAt(xpos, ypos)
    index = 0
    for i = 1, #self do
        if(self[i].x == xpos and self[i].y == ypos) then
            index = i
            break
        end
    end

    if index == 0 then
        print("PIXEL POSITION NOT VALIDP")
    end

    return index
end

function pixelArray:getPixelAt(x,y)
    return pixelArray[pixelArray:getIndexAt(x,y)]
end

function pixelArray:matchColor(index, otherIndex)
    if(self[index].r ~= self[otherIndex].r) then
        return false
    end
    if(self[index].g ~= self[otherIndex].g) then
        return false
    end
    if(self[index].b ~= self[otherIndex].b) then
        return false
    end
    return true
end

function pickColor(xpos, ypos)
    i = pixelArray:getIndexAt(xpos, ypos)

    currentColor.r = pixelArray[i].r
    currentColor.g = pixelArray[i].g
    currentColor.b = pixelArray[i].b
end

function drawPixel(x, y, color)
    if(pixelArray:hasPixel(x,y) > 0)then
        pixelArray:removePixelAt(x,y)
    end
    pixelArray:addPixel(x,y,color)
end

function erasePixel(x,y)
    if(pixelArray:hasPixel(x,y) > 0) then
        pixelArray:removePixelAt(x,y)
    end
end

function floodFill(x,y)
    -- TODO implement this
    print("TO BE IMPLEMENTED")
    startingPixel = pixelArray:getIndexAt(x,y)

    print(x,y)  
    print(startingPixel)
    print(pixelArray:getIndexAt(x+1, y))

    if(pixelArray:matchColor(startingPixel, pixelArray:getIndexAt(x+1,y))) then
        drawPixel(x + 1, y, {0,1,0,1}) -- this is debug
    end

    if(pixelArray:matchColor(startingPixel, pixelArray:getIndexAt(x-1,y))) then
        drawPixel(x - 1, y, {0,1,0,1})
    end

    if(pixelArray:matchColor(startingPixel, pixelArray:getIndexAt(x,y+1))) then
        drawPixel(x, y-1, {0,1,0,1})
    end

    if(pixelArray:matchColor(startingPixel, pixelArray:getIndexAt(x,y-1))) then
        drawPixel(x, y+1, {0,1,0,1})
    end

end

function love.load()
    love.filesystem.setIdentity("screenshots", false)
    --! setting windows and canvas.
    love.window.setMode(800, 800)
    canvasTransform = love.math.newTransform()
    canvasTransform:scale(pixelScale,pixelScale);
    canvas = love.graphics.newCanvas(100, 100)
    canvas:setFilter("nearest", "nearest", 1)
    finalCanvasTransform = love.math.newTransform()
    finalCanvasTransform:scale(2,2)
    finalCanvas = love.graphics.newCanvas(400,400)
    screenshotCanvas = love.graphics.newCanvas(800,800) 
    love.graphics.setDefaultFilter("nearest", "nearest")

    
    
    local fragdir = love.filesystem.read('shader.frag')
    shader = love.graphics.newShader(fragdir)
    
    --send data to GPU
    shader:send('inputSize', {love.graphics.getWidth(), love.graphics.getHeight()})
    shader:send('textureSize', {love.graphics.getWidth(), love.graphics.getHeight()})
end

function love.update(dt)

    if(started == false) then
        love.graphics.setColor(math.random(0,255)/255.0,math.random(0,255)/255.0,math.random(0,255)/255.0,1)
        return;
    end
        love.graphics.setColor(1,1,1,1)

    --!Setting up UI
    rows1 = suit.layout:rows{
        pos = {10, 10},
        min_height = 300,
        {200, 30},
        {200, 30},
        {200, 30}
    }
    rows2 = suit.layout:rows{
        pos = {250, 10},
        min_height = 300,
        {200, 30},
        {200, 30},
        {200, 30}
    }

    --! Getting mouse pos
    mousePos.x, mousePos.y = love.mouse.getPosition()
    mpx = math.floor(mousePos.x/(pixelScale * 2))
    mpy = math.floor(mousePos.y/(pixelScale * 2))


    --! Manual Color Picker
    if AdjustingColor then
        
        suit.Slider(sliderR, {vertical = false, id = 'red slider'}, rows1.cell(1))
        suit.Slider(sliderG, {vertical = false, id = 'green slider'}, rows1.cell(2))
        suit.Slider(sliderB, {vertical = false, id = 'blue slider'}, rows1.cell(3))

        

        suit.Label(math.floor(sliderR.value * 255), {align="left"}, rows2.cell(1))
        suit.Label(math.floor(sliderG.value * 255), {align="left"}, rows2.cell(2))
        suit.Label(math.floor(sliderB.value * 255), {align="left"}, rows2.cell(3))


        currentColor.r = sliderR.value;
        currentColor.g = sliderG.value;
        currentColor.b = sliderB.value;
        
    else
        

        --! picking tool
        if(love.mouse.isDown(1)) then
            if(CurrentTool == Tools.PENCIL) then
               drawPixel(mpx,mpy, currentColor) 
            elseif (CurrentTool == Tools.ERASER) then
                erasePixel(mpx,mpy)
            elseif (CurrentTool == Tools.BUCKET) then
                floodFill(mpx,mpy)
            elseif (CurrentTool == Tools.COLOR_PICKER) then
                pickColor(mpx,mpy)
            else 
                print("NO TOOL SELECTED!!!")
            end
        end
    
        --!Erase shortcut
        if(love.mouse.isDown(2)) then
            if(pixelArray:hasPixel(mpx,mpy)) then
                pixelArray:removePixelAt(mpx,mpy)
            end
        end
            
        --!Colorpicker shortcut
        if(love.mouse.isDown(3)) then
            pickColor(mpx, mpy)
        end

        --! Printing the whole pixel array.
        -- print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        -- for i = 1, #pixelArray do
        --     print("p" .. i .. " = " .. pixelArray[i].x ..", ".. pixelArray[i].y..", ".. pixelArray[i].r..", ".. pixelArray[i].g..", ".. pixelArray[i].b)
        -- end

        --! Writing to the canvas.
        canvas:renderTo(function()
            love.graphics.clear()
            for i = 1, #pixelArray do
                love.graphics.setColor(pixelArray[i].r, pixelArray[i].g, pixelArray[i].b, 1)
                love.graphics.rectangle("fill",pixelArray[i].x, pixelArray[i].y,1, 1)
            end
            --for pixel in pixelArray do
            --    love.graphics.rectangle("fill",pixel.x, pixel.y,1, 1)
            --end
        end)
        
    end 
end

function love.draw()
    
    if(started == false) then
        love.graphics.print("Welcome to Lua Paint!", 40, 40,0, 4)
        love.graphics.print("this is my first project in Lua and Love2D,\nhere are some shortcuts you might wanna know.", 40, 120,0,1.5)
        love.graphics.print("press 1 to use pencil.\nPress 2 to use eraser (you can also use right click).\nPress 3 to use bucket tool (not yet implemented). \nPress 4 to use color picker.(you can also use middle click)\nPress I to open the color slider.\nPress Enter to apply Shaders.\nPress C to take save your drawing.", 40, 200,0,1.5)
        
        love.graphics.print("PRESS SPACE TO CONTINUE", 40, 700, 0, 4.3)
        return
    end

    love.graphics.setCanvas(finalCanvas)
    love.graphics.clear()--clear display
    love.graphics.setBackgroundColor(.01,.01,.15,1)
    
    --draw any stuff here
    
    if(showFinalGraphic) then
        love.graphics.setColor(.3,.3,.3,.3)
    else
        love.graphics.setColor(1,1,1,.5)
    end
    
    -- if not showFinalGraphic then
    for i = 0, 800/pixelScale do
        love.graphics.line(i * (pixelScale), 0, i * (pixelScale), 800)
        love.graphics.line(0,i * (pixelScale), 800, i * (pixelScale))
    end
    -- end
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(canvas, canvasTransform)
    love.graphics.setCanvas()  

    if showFinalGraphic then
        love.graphics.setShader(shader)
        love.graphics.draw(finalCanvas, finalCanvasTransform)
        love.graphics.setShader()
    else
        love.graphics.draw(finalCanvas, finalCanvasTransform)
        -- love.graphics.print(mpx .. ", " .. mpy, 10, 10)
    end
    
    if AdjustingColor then
        suit.draw();
        love.graphics.setColor(currentColor.r, currentColor.g, currentColor.b, 1)
        love.graphics.circle("fill", 110, 210, 100, 40)
        love.graphics.setColor(1,1,1,1)
    else
        for key, value in pairs(Tools) do
            if(value == CurrentTool) then
                love.graphics.print("Current Tool: " .. key, 20, 20, 0, 1.5)
            end
        end
        
    end
end

function love.keypressed(key, scancode, isrepeat)
    if(key == "backspace") then
        pixelArray:removePixel()
        return;
    end
    if(key == "escape") then
        love.event.quit()
        return;
    end
    if(key == "return") then
        showFinalGraphic = not showFinalGraphic
        return;
    end
    if(key == "i") then
        AdjustingColor = not AdjustingColor
        return;
    end
    if(key == "1") then
        CurrentTool = Tools.PENCIL
        print("current tool set to pencil")
        return;
    end
    if(key == "2") then
       CurrentTool = Tools.ERASER 
       print("current tool set to eraser")
       return;
    end
    if(key == "3") then
        CurrentTool = Tools.BUCKET
        print("current tool set to bucket")
        return;
    end
    if(key == "4") then
        CurrentTool = Tools.COLOR_PICKER
        print("current tool set to color picker")
        return;
    end

    if(key == "c") then
        print("screenshot taken!")
        love.graphics.captureScreenshot("/Screenshot"..os.time()..".png")
    end
    if(key == "space") then
        started = true
    end
end

function math.round(n)
    return math.floor(n + 0.5)
end