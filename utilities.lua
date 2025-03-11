
--! Basic Colors

Red = {
    r = 1,
    g = 0,
    b = 0,
    a = 1
}
Green = {
    r = 0,
    g = 1,
    b = 0,
    a = 1
}
Blue = {
    r = 0,
    g = 0,
    b = 1,
    a = 1
}
White = {
    r = 1,
    g = 1,
    b = 1,
    a = 1
}
Black = {
    r = 0,
    g = 0,
    b = 0,
    a = 1
}
Blank = {
    r = 0,
    g = 0,
    b = 0,
    a = 0
}

function copyColor(color, copy)
    color.r = copy.r
    color.g = copy.g
    color.b = copy.b
    color.a = copy.a
end

function matchColor(color, other)
    if(color.r ~= other.r)then
        return false
    end
    if(color.g ~= other.g)then
        return false
    end
    if(color.b ~= other.b)then
        return false
    end
    if(color.a ~= other.a)then
        return false
    end
    return true
end

function getColor(color)
    return {color.r, color.g, color.b, color.a}
end

function logColor(color)
    return "(R = " .. color.r .. ", G = " .. color.g .. ", B = " .. color.b .. ", A = ".. color.a .. ")"
end


PixelMap = {
    defaultValue = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    },

    NewMap = function(width, height)
        map = PixelMap
        for col = 0, width do
            map[col] = {}
            for row = 0, height do
                map[col][row] = {
                    r = 0,
                    g = 0,
                    b = 0,
                    a = 0
                }
            end
        end    
        return map;
    end,

    addPixel = function(self, x, y, color)
        print("added pixel at " .. x .. ", " .. y)
        self[x][y].r = color.r
        self[x][y].g = color.g
        self[x][y].b = color.b
        self[x][y].a = color.a
    end,

    removePixel = function(self, x, y)
        copyColor(self[x][y], self.defaultValue)
    end,

    matchPixel = function(self, x1,y1, x2, y2)
        print(matchColor(self[x1][y1], self[x2][y2]))
        return matchColor(self[x1][y1], self[x2][y2])
    end,
    
    pickColor = function(self, x, y)
        return getColor( self[x][y])
    end,

    drawPixelRectangle = function(self, x, y)
        setGraphicsColor(self[x][y])
        love.graphics.rectangle("fill", x, y, 1, 1)
    end,
}

function setGraphicsColor(color)
    love.graphics.setColor(color.r, color.g, color.b, color.a)

end