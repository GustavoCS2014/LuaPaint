suit = require 'vendors/suit'
require 'utilities'

WIDTH = 80
HEIGHT = 50
--! MUST BE INT, PREFERABLE DIVISIBLE BY 2
SCALING_FACTOR = 10

--! TOOLS
Tools = {
    PENCIL = 0,
    ERASER = 1,
    BUCKET = 2,
    COLOR_PICKER = 3

}

CurrentTool = Tools.PENCIL

local pencilArea = 1
local eraserArea = 1

local pixelScale = 10
local screenshotCanvas
local currentColor = {r = 1,g = 1,b = 1,a = 1}

local sliderR = {value = 1, min = 0.0, max = 1.0}
local sliderG = {value = 1, min = 0.0, max = 1.0}
local sliderB = {value = 1, min = 0.0, max = 1.0}

local labelR = ""
local labelG = ""
local labelB = ""

local showFinalGraphic = false
local AdjustingColor = false
local started = false
local inputEnabled = true

local mousePos = {}



function pickColor(x, y)
    currentColor = getColor(CanvasData, x, y)
end

function draw(x, y, color)
    -- CanvasData:setPixel(x,y,1,1,1,1)
    if(matchColor(getColor(CanvasData,x,y), color)) then
        print("same color at: " .. x .. ", " .. y.. ", " .. logColor(color))
       return 
    end
    drawPixel(CanvasData,x,y,color)
end

function erasePixel(x,y)
    removePixel(CanvasData,x,y)
end

function floodFill(x,y)
    -- TODO implement this
    
    if(x >= WIDTH or x < 0) then return end
    if(y >= HEIGHT or y < 0) then return end
    local originalColor = {r,g,b,a}
    local targetColor = {r,g,b,a}
    
    copyColor(originalColor, getColor(CanvasData,x,y))
    print("bucketing " .. x .. ", " .. y .. ", " .. logColor(originalColor))

    copyColor(targetColor, currentColor)

    if(matchColor(targetColor, originalColor)) then
        return
    end

    drawPixel(CanvasData, x,y,targetColor)

    local down = {x = x, y = y+1}
    local up = {x = x, y = y-1}
    local left = {x = x-1, y = y}
    local right = {x = x+1,y = y}

    print("R = " .. right.x .. ", " .. right.y.. "\n".."L = " .. left.x .. ", " .. left.y.. "\n".."U = " .. up.x .. ", " .. up.y.. "\n".."D = " .. down.x .. ", " .. down.y)

    if(right.x < WIDTH) then 
        if matchColor(originalColor,getColor(CanvasData,right.x, right.y)) then
            floodFill(x+1, y)
        end
     end
    if(left.x >= 0) then 
        if matchColor(originalColor,getColor(CanvasData,left.x, left.y)) then
            floodFill(x-1, y)
        end
     end
    if(down.y < HEIGHT) then 
        if matchColor(originalColor,getColor(CanvasData, down.x, down.y)) then
            floodFill(x, y+1)
        end
     end
    if(up.y >= 0) then 
        if matchColor(originalColor,getColor(CanvasData, up.x, up.y)) then
            floodFill(x, y-1)
        end
     end

    
    
    


end


--!-------------------------------------------------------------------
--!                      LOAD METHOD
--!-------------------------------------------------------------------

function love.load()
    --! Importan Variables
    love.window.setMode(WIDTH*SCALING_FACTOR, HEIGHT*SCALING_FACTOR)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.filesystem.setIdentity("screenshots", false)
    
    canvas = love.graphics.newCanvas(WIDTH, HEIGHT)
    CanvasData = canvas:newImageData()

    --! Setting Canvas
    canvasTransform = love.math.newTransform()
    canvasTransform:scale(SCALING_FACTOR,SCALING_FACTOR)

    finalCanvas = love.graphics.newCanvas(WIDTH*SCALING_FACTOR,HEIGHT*SCALING_FACTOR)

    screenshotCanvas = love.graphics.newCanvas(WIDTH*SCALING_FACTOR,HEIGHT*SCALING_FACTOR) 

    --! Shaders
    local fragdir = love.filesystem.read('shader.frag')
    shader = love.graphics.newShader(fragdir)
    
    --send data to GPU
    shader:send('inputSize', {WIDTH*SCALING_FACTOR, HEIGHT*SCALING_FACTOR})
    shader:send('textureSize', {WIDTH*SCALING_FACTOR, HEIGHT*SCALING_FACTOR})
end

--!-------------------------------------------------------------------
--!                      UPDATE LOOP
--!-------------------------------------------------------------------

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
    mpx = math.floor(mousePos.x/(SCALING_FACTOR) )
    mpy = math.floor(mousePos.y/(SCALING_FACTOR))


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
        
        --! While mouse Pressed
        if(inputEnabled) then
            if(love.mouse.isDown(1) and CurrentTool ~= Tools.BUCKET) then
                if(CurrentTool == Tools.PENCIL) then
                    -- CanvasData:setPixel(mpx,mpy, currentColor)
                   draw(mpx,mpy, currentColor)
                elseif (CurrentTool == Tools.ERASER) then
                    erasePixel(mpx,mpy)
                elseif (CurrentTool == Tools.BUCKET) then
                    return
                elseif (CurrentTool == Tools.PICKER) then
                    pickColor(mpx,mpy)
                else 
                    print("NO TOOL SELECTED!!!")
                end
            end
        end

    
        --!Erase shortcut
        if(love.mouse.isDown(2)) then
            erasePixel(mpx,mpy)
        end
            
        --!Colorpicker shortcut
        if(love.mouse.isDown(3)) then
            pickColor(mpx, mpy)
        end

        --! Writing to the canvas.
        -- canvas:renderTo(function()
        --     love.graphics.clear()

        --     for x = 0, WIDTH do
        --         for y = 0, HEIGHT do
        --             CanvasData:drawPixelRectangle(x,y)  
        --         end
        --     end

            -- for i = 1, #pixelArray do
            --     love.graphics.setColor(pixelArray[i].r, pixelArray[i].g, pixelArray[i].b, 1)
            --     love.graphics.rectangle("fill",pixelArray[i].x, pixelArray[i].y,1, 1)
            -- end
            --for pixel in pixelArray do
            --    love.graphics.rectangle("fill",pixel.x, pixel.y,1, 1)
            --end
        -- end)
        
    end 
end

--!-------------------------------------------------------------------
--!                      DRAW LOOP
--!-------------------------------------------------------------------

function love.draw()
    if(AdjustingColor or not started) then
        inputEnabled = false
    else
         inputEnabled = true
    end

    --! Starting Screen
    if(started == false) then
        love.graphics.print("Welcome to Lua Paint!", 40, 40,0, 4)
        love.graphics.print("this is my first project in Lua and Love2D,\nhere are some shortcuts you might wanna know.", 40, 120,0,1.5)
        love.graphics.print("press 1 to use pencil.\nPress 2 to use eraser (you can also use right click).\nPress 3 to use bucket tool (not yet implemented). \nPress 4 to use color picker.(you can also use middle click)\nPress I to open the color slider.\nPress Enter to apply Shaders.\nPress C to take save your drawing.", 40, 200,0,1.5)
        
        love.graphics.print("PRESS SPACE TO CONTINUE", 40, 700, 0, 4.3)
        return
    end

    --! First Render pass
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
    for x = 1, WIDTH do
        love.graphics.line(x * (SCALING_FACTOR), 0, x * (SCALING_FACTOR), HEIGHT*SCALING_FACTOR)
    end

    for y = 1, HEIGHT do
        love.graphics.line(0,y * (SCALING_FACTOR), WIDTH*SCALING_FACTOR, y * (SCALING_FACTOR))
    end
    -- end
    love.graphics.setColor(1,1,1,1)
    local pixelCanvas = love.graphics.newImage(CanvasData)
    love.graphics.draw(pixelCanvas, canvasTransform)
    love.graphics.setCanvas()  

    --! Final Render Pass

    if showFinalGraphic then
        love.graphics.setShader(shader)
        love.graphics.draw(finalCanvas)
        love.graphics.setShader()
    else
        love.graphics.draw(finalCanvas)
        -- love.graphics.print(mpx .. ", " .. mpy, 10, 10)
    end
    

    --! showing the color selector.
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

--!-------------------------------------------------------------------
--!                      INPUT HANDLING
--!-------------------------------------------------------------------

function love.mousepressed(x, y, button, isTouch, presses)
    if (not inputEnabled) then return end
    if(CurrentTool == Tools.BUCKET) then
        floodFill(mpx,mpy)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if(key == "backspace") then
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
        CurrentTool = Tools_PICKER
        print("current tool set to color picker")
        return;
    end

    if(key == "c") then
        print("screenshot taken!")
        ssName = "/Screenshot"..os.time()  .. ".png"
        love.graphics.captureScreenshot(ssName)
        -- os.rename("%appdata%/LOVE/screenshots".. ssName, "D:/LUA/Screenshots" .. ssName )
    end
    if(key == "space") then
        started = true
    end

    if(key == "u") then
        print("the color is " .. logColor(getColor(CanvasData, mpx, mpy)))
    end
end
