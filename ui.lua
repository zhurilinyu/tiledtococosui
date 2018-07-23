--[[
說明：可隨意修改與運用
an ui for tiled to cocos lua
auth:zhurilinyu@163.com
]]--
uihelper = {}
local gmui = require("gmui")

local visible_size = cc.Director:getInstance():getVisibleSize()
local win_size = cc.Director:getInstance():getWinSize()
local visible_origin = cc.Director:getInstance():getVisibleOrigin()
local frame_size = cc.Director:getInstance():getOpenGLView():getFrameSize()

function uihelper:f(w, m)
    return self:findWidgetByName(w, m)
end

function uihelper:addSwallowEventListener(w)
    local l = cc.EventListenerTouchOneByOne:create()
    l:registerScriptHandler(function(t, e)
            return true
        end, cc.Handler.EVENT_TOUCH_BEGAN )
    l:registerScriptHandler(function(t, e) end, cc.Handler.EVENT_TOUCH_ENDED )
    l:setSwallowTouches(true)
    w:getEventDispatcher():addEventListenerWithSceneGraphPriority(l, w)
    return l
end

function uihelper:create(f)
    local p = require(f)
    local g = {}
    for i = 1, #p.tilesets do
        for j = 1, p.tilesets[i].tilecount do
            local id = p.tilesets[i].tiles[j].id
            local fg = p.tilesets[i].firstgid
            g[id + fg] = string.gsub(p.tilesets[i].tiles[j].image, "%.%.%/", "")
        end
    end

    local c = {}
    local m
    for i = 1, #p.layers do
        if p.layers[i].type == "objectgroup" and p.layers[i].name == "bg" then
            for k, v in ipairs(p.layers[i].objects) do
                if v.gid then
                    m = cc.Sprite:create(g[v.gid])
                    m:setTag(v.id)
                    m.name = v.name
                    m.img_path = g[v.gid]
                    m.visible = p.layers[i].visible
                end
            end
        elseif p.layers[i].type == "objectgroup" then
            for k, v in ipairs(p.layers[i].objects) do
                if v.gid then
                    c[v.id] = cc.Sprite:create(g[v.gid])
                    c[v.id].name = v.name
                    c[v.id]:setLocalZOrder(c[v.id]:getLocalZOrder() + i)
                    c[v.id]:setTag(v.id)
                    c[v.id].img_path = g[v.gid]

                    if v.name == "close" then
                        self:setClickEvent(c[v.id], { endedEvent  = function(va, to, e)
                                    if va then m:removeFromParent(true) m = nil end
                                end,
                            })
                    end

                    if string.find(v.name, "xx") then
                        c[v.id]:setScale(v.width / c[v.id]:getContentSize().width, v.height / c[v.id]:getContentSize().height)
                        c[v.id]:setContentSize(v.width, v.height)
                        c[v.id]:setAnchorPoint(cc.p(0, 0))
                        c[v.id]:setPosition(cc.p(v.x, -v.y))
                    else
                        c[v.id]:setPosition(cc.p(v.x + c[v.id]:getContentSize().width / 2, -v.y + c[v.id]:getContentSize().height / 2))
                    end

                    if v.properties["text"] ~= nil then
                        local u = cc.Label:create()
                        u:setSystemFontName("")
                        u:setSystemFontSize(30)
                        u:setString(v.properties["text"])
                        u:setTag(v.id)
                        u:setIgnoreAnchorPointForPosition(false)
                        u:setPosition(cc.p(c[v.id]:getContentSize().width/2, c[v.id]:getContentSize().height/2))
                        c[v.id]:addChild(u)
                    end
                else
                    if v.properties["text"] ~= nil then
                        c[v.id] = cc.Label:create()
                        c[v.id]:setIgnoreAnchorPointForPosition(false)
                        c[v.id]:setSystemFontSize(v.height)
                        c[v.id]:setSystemFontName("")

                        if v.properties["wrap"] then
                            c[v.id]:setWidth(v.width)
                            c[v.id]:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
                        end
                        if v.properties["anchor_x"] and v.properties["anchor_y"] then
                            c[v.id]:setAnchorPoint(cc.p(v.properties["anchor_x"], v.properties["anchor_y"]))
                            c[v.id]:setPosition(cc.p(v.x + v.properties["anchor_x"] * v.width,
                                    -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1))
                        else
                            c[v.id]:setAnchorPoint(cc.p(0, 0))
                            c[v.id]:setPosition(cc.p(v.x, -v.y - v.height * 1))
                        end
                    else
                        c[v.id] = cc.LayerColor:create(cc.c4b(128, 255, 0, 0))
                        c[v.id]:setIgnoreAnchorPointForPosition(false)
                        c[v.id]:setContentSize(cc.size(v.width, v.height))
                        c[v.id]:setAnchorPoint(cc.p(0, 0))
                        c[v.id]:setPosition(cc.p(v.x, -v.y - v.height))
                    end
                    c[v.id].name = v.name
                    c[v.id].tag = v.id
                end
            end
        end
    end

    for k, v in pairs(c) do
        m:addChild(v)
    end

    local function z(e)
        if e == "enter" then
        elseif e == "exit" then
            m = nil
        end
    end
    m:registerScriptHandler(z)

    m._images = c
    return m
end

function uihelper:findWidgetByName(widget, widgetName)
    for _, v in pairs(widget._images) do
        if v.name == widgetName then
            return v
        end
    end
    return nil
end

local function isRectContainsPoint(t, o)
    local p = t:convertToNodeSpace(o:getLocation())
    local s = t:getContentSize()
    local r = cc.rect(0, 0, s.width, s.height)
    if cc.rectContainsPoint(r, p) then
        return true
    else
        return false
    end
end

function uihelper:setClickEvent(w, r, a)
    r = r or {}
    local b = r.beganEvent or function() end
    local c = r.movedEvent or function() end
    local d = r.cancelledEvent or function() end
    local e = r.endedEvent or function() end
    local f = true
    if r.swallowTouches ~= nil then
        f = r.swallowTouches
    end

    a = a or {}
    local g = a.beganAct or function() end
    local h = a.movedAct or function() end
    local o = a.cancelledAct or function() end
    local p = a.endedAct or function() end

    local l = cc.EventListenerTouchOneByOne:create()
    l:registerScriptHandler(function(t, y)
            if isRectContainsPoint(y:getCurrentTarget(), t) then
                g(y:getCurrentTarget())
                local v = b(true, t, y)
                if v ~= nil then return v else return true end
            else
                local v = b(false, t, y)
                if v ~= nil then return v else return false end
            end
        end, cc.Handler.EVENT_TOUCH_BEGAN
    )

    l:registerScriptHandler(function(t, y)
            if isRectContainsPoint(y:getCurrentTarget(), t) then
                if c then c(true, t, y) end
            else
                if c then c(false, t, y) end
            end
        end, cc.Handler.EVENT_TOUCH_MOVED
    )

    l:registerScriptHandler(function(t, y)
            o(y:getCurrentTarget())
            d()
        end, cc.Handler.EVENT_TOUCH_CANCELLED
    )

    l:registerScriptHandler(function(t, y)
            p(y:getCurrentTarget())
            if isRectContainsPoint(y:getCurrentTarget(), t) then
                e(true, t, y)
            else
                e(false, t, y)
            end
        end, cc.Handler.EVENT_TOUCH_ENDED
    )
    if f then l:setSwallowTouches(f) end
    w:getEventDispatcher():addEventListenerWithSceneGraphPriority(l, w)
    w.listener = l
end

function uihelper:setClickEvent2(w, a)
    a = a or function() end
    local l = cc.EventListenerTouchOneByOne:create() -- EventListenerTouchAllAtOnce
    l:registerScriptHandler(function(t, e)
            if isRectContainsPoint(e:getCurrentTarget(), t) then
                local v = a(e:getCurrentTarget(), "began", true)
                if v ~= nil then return v else return true end
            else
                local v = a(e:getCurrentTarget(), "began", false)
                if v ~= nil then return v else return false end
            end
        end, cc.Handler.EVENT_TOUCH_BEGAN
    )

    l:registerScriptHandler(function(t, e)
            a(e:getCurrentTarget(), "moved", true)
        end, cc.Handler.EVENT_TOUCH_MOVED
    )

    l:registerScriptHandler(function(t, e)
            if isRectContainsPoint(e:getCurrentTarget(), t) then
                a(e:getCurrentTarget(), "cancel", true)
            else
                a(e:getCurrentTarget(), "cancel", false)
            end
        end, cc.Handler.EVENT_TOUCH_CANCELLED
    )

    l:registerScriptHandler(function(t, e)
            if isRectContainsPoint(e:getCurrentTarget(), t) then
                a(e:getCurrentTarget(), "ended", true)
            else
                a(e:getCurrentTarget(), "ended", false)
            end
        end, cc.Handler.EVENT_TOUCH_ENDED
    )
    if swallowTouches then l:setSwallowTouches(swallowTouches) end
    w:getEventDispatcher():addEventListenerWithSceneGraphPriority(l, w)
    w.listener = l
end

function uihelper:_createSprite(a, b, k, v, i, c, g)
    local s = cc.Sprite:create(b[v.gid])
    s.name = v.name
    s:setLocalZOrder(s:getLocalZOrder() + i)
    s:setTag(v.id)
    s.img_path = b[v.gid]

    if v.name == "close" then
        self:setClickEvent(s, { endedEvent  = function(va, t, e)
                    if va then a:removeFromParent(true) a = nil end
                end,
            })
    end

    if string.find(v.name, "xx") then
        s:setScale(v.width / s:getContentSize().width, v.height / s:getContentSize().height)
        s:setContentSize(v.width, v.height)
        s:setAnchorPoint(cc.p(0, 0))
        if a.bg_sp then
            s:setPosition(cc.p(v.x, -v.y))
        else
            s:setPosition(cc.p(v.x, -v.y))
        end
    else
        s:setIgnoreAnchorPointForPosition(false)
        s:setAnchorPoint(cc.p(0.5, 0.5))

        if a.bg_sp then
            s:setPosition(cc.p(
                    v.x + s:getContentSize().width / 2,
                    0 - v.y + s:getContentSize().height / 2)
            )
        else
            s:setPosition(cc.p(
                    v.x + s:getContentSize().width / 2,
                    g - v.y + s:getContentSize().height / 2)
            )
        end

        if v.properties["anchor_x"] and v.properties["anchor_y"] then
            s:setAnchorPoint(cc.p(v.properties["anchor_x"], v.properties["anchor_y"]))
            if a.bg_sp then
                s:setPosition(cc.p(
                        v.x + v.properties["anchor_x"] * v.width,
                        -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1))
            else
                s:setPosition(cc.p(v.x + v.properties["anchor_x"] * v.width,
                        g -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1
                    ))
            end
        end
    end

    if v.properties["text"] ~= nil then
        local l = cc.Label:create()
        l:setSystemFontName("")
        l:setSystemFontSize(30)
        l:setString(v.properties["text"])
        l:setIgnoreAnchorPointForPosition(false)
        l:setTag(v.id)
        l:setPosition(cc.p(s:getContentSize().width/2, s:getContentSize().height/2))
        s.text_label = l
        s:addChild(l)


    elseif v.properties["edit"] ~= nil then
        local h = ""
        if v.properties["holder"] then
            h = v.properties["holder"]
        end
        local e = gmui:createEbox(s:getContentSize().height,
            h, s,
            cc.KEYBOARD_RETURNTYPE_DONE,
            cc.EDITBOX_INPUT_MODE_SINGLELINE,
            cc.EDITBOX_INPUT_FLAG_SENSITIVE,
            b[v.gid],
            cc.p(s:getContentSize().width/2, s:getContentSize().height/2),
            cc.size(s:getContentSize().width, s:getContentSize().height))
        e:setTag(v.id)
        e:setIgnoreAnchorPointForPosition(false)
        e:setAnchorPoint(cc.p(0.5, 0.5))
    end
    return s
end

function uihelper:_createLabel(a, b, k, v, i, c, g)
    local l = cc.Label:create()
    l:setIgnoreAnchorPointForPosition(false)
    l:setSystemFontSize(v.height)
    l:setSystemFontName("")
    l:setString(v.properties["text"])

    if v.properties["anchor_x"] and v.properties["anchor_y"] then
        l:setAnchorPoint(cc.p(v.properties["anchor_x"], v.properties["anchor_y"]))
        if a.bg_sp then
            l:setPosition(cc.p(
                    v.x + v.properties["anchor_x"] * v.width,
                    -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1))
        else
            l:setPosition(cc.p(v.x + v.properties["anchor_x"] * v.width,
                    g -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1
                ))
        end
    else
        l:setAnchorPoint(cc.p(0, 0))
        if a.bg_sp then
            l:setPosition(cc.p(v.x, -v.y - v.height * 1))
        else
            l:setPosition(cc.p(v.x, g -v.y - v.height * 1))
        end
    end

    if v.properties["wrap"] then
        l:setWidth(v.width)
        l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    end
    if v.properties["type"] == "right" then
        l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
    end
    if v.properties["color"] then
        l:setColor(cc.c3b(v.properties["color"]))
    end
    return l
end

function uihelper:_setPosition(w, b, g, v)
    if v.properties["anchor_x"] and v.properties["anchor_y"] then
        w:setAnchorPoint(cc.p(v.properties["anchor_x"], v.properties["anchor_y"]))
        if b then
            w:setPosition(cc.p(
                    v.x + v.properties["anchor_x"] * v.width,
                    -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1
            ))
        else
            w:setPosition(cc.p(
                    v.x + v.properties["anchor_x"] * v.width,
                    g -v.y - v.height * 1 + v.properties["anchor_y"] * v.height * 1
            ))
        end
    else
        w:setAnchorPoint(cc.p(0, 0))
        if b then
            w:setPosition(cc.p(v.x, -v.y - v.height))
        else
            w:setPosition(cc.p(v.x, g - (v.height + v.y)))
        end
    end
end

function uihelper:_create_text_shape(a, b, k, v, i, c, g)
    local l = cc.Label:create()
    l:setIgnoreAnchorPointForPosition(false)
    if v.pixelsize then
        l:setSystemFontSize(v.pixelsize)
    else
        l:setSystemFontSize(v.height)
    end
    l:setSystemFontName("")
    l:setString(v.text)
    self:_setPosition(l, a.bg_sp, g, v)

    if v.wrap then
        l:setWidth(v.width)
    end

    if v.color then l:setColor(cc.c3b(table.unpack(v.color))) end
    if v.valign then
        if v.valign == "center" then
            l:setVerticalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        elseif v.valign == "right" then
            l:setVerticalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
        elseif v.valign == "left" then
            l:setVerticalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        end
    else
        l:setVerticalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    end
    if v.halign then
        if v.halign == "center" then
            l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        elseif v.halign == "right" then
            l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
        elseif v.halign == "left" then
            l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        end
    else
        l:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    end
    return l
end

function uihelper:create2(f)
    local d = require(f)
    local a = {}
    for i = 1, #d.tilesets do
        for j = 1, d.tilesets[i].tilecount do
            local id = d.tilesets[i].tiles[j].id
            local fg = d.tilesets[i].firstgid
            a[id + fg] = string.gsub(d.tilesets[i].tiles[j].image, "%.%.%/", "")
        end
    end

    local c = {}
    local b
    local e, g = 0, 0
    for i = 1, #d.layers do
        if d.layers[i].type == "objectgroup" and d.layers[i].name == "bg" then
            for k, v in ipairs(d.layers[i].objects) do
                e = v.width
                g = v.height
                b = cc.Layer:create()
                b:setIgnoreAnchorPointForPosition(false)
                b:setContentSize(cc.size(v.width, v.height))
                b:setAnchorPoint(cc.p(0.5, 0.5))
                b:setTag(v.id)
                b.name = v.name

                if  not v.gid then
                else
                    local t = cc.Sprite:create(a[v.gid])
                    t:setTag(v.id)
                    t.name = v.name
                    t.img_path = a[v.gid]
                    t.visible = d.layers[i].visible
                    t:setAnchorPoint(cc.p(0.5, 0.5))
                    t:setPosition(cc.p(b:getContentSize().width / 2,
                            b:getContentSize().height / 2))
                    b.bg_sp = t
                    b:addChild(t)
                end
            end
        elseif d.layers[i].type == "objectgroup" then
            for k, v in ipairs(d.layers[i].objects) do
                if v.gid then
                    if v.properties["s9sprite"] ~= nil then
                        local h = a[v.gid]
                        local l = v.properties["ret_x"] or 0
                        local o = v.properties["ret_y"] or 0
                        local p = v.properties["ret_w"] or 0
                        local q = v.properties["ret_h"] or 0
                        c[v.id] = cc.Scale9Sprite:create(h,
                        cc.rect(0, 0, 0, 0),
                        cc.rect(l, o, p, q))

                        local r, s = v.x, -v.y
                        local t, u = v.width, v.height
                        c[v.id]:setContentSize(cc.size(t, u))
                        c[v.id]:setPosition(cc.p(v.x + t / 2, v.y - u / 2))
                        c[v.id].name = v.name
                        c[v.id].tag = v.id
                    else
                        c[v.id] = self:_createSprite(b, a, k, v, i, e, g)
                    end
                else
                    if v.shape == "text" then
                        c[v.id] = self:_create_text_shape(b, a, k, v, i, e, g)
                        c[v.id].name = v.name
                        c[v.id].tag = v.id
                    elseif v.shape == "rectangle" then
                        if v.properties["text"] ~= nil then
                             c[v.id] = self:_createLabel(b, a, k, v, i, e, g)
                        elseif v.properties["s9sprite"] ~= nil then
                            local w = v.properties["ret_x"] or 0
                            local x = v.properties["ret_y"] or 0
                            local y = v.properties["ret_w"] or 0
                            local z = v.properties["ret_h"] or 0
                            c[v.id] = cc.Scale9Sprite:create(v.properties["s9sprite"],
                            cc.rect(0, 0, 0, 0),
                            cc.rect(w, x, y, z))
                            c[v.id]:setContentSize(cc.size(v.width, v.height))
                            self:_setPosition(c[v.id], b.bg_sp, g, v)
                        elseif string.find(v.name, "xx") then
                            c[v.id] = cc.Layer:create()
                            c[v.id]:setIgnoreAnchorPointForPosition(false)
                            c[v.id]:setContentSize(cc.size(v.width, v.height))
                            c[v.id]:setAnchorPoint(cc.p(0, 0))
                            self:_setPosition(c[v.id], b.bg_sp, g, v)
                        else
                            c[v.id] = cc.LayerColor:create(cc.c4b(128, 255, 0, 255))
                            c[v.id]:setIgnoreAnchorPointForPosition(false)
                            c[v.id]:setAnchorPoint(cc.p(0, 0))
                            c[v.id]:setContentSize(cc.size(v.width, v.height))
                            self:_setPosition(c[v.id], b.bg_sp, g, v)
                        end

                        c[v.id].name = v.name
                        c[v.id].tag = v.id
                    end
                end
            end
        end
    end
    b._c = {}
    for k, v in pairs(c) do
        b:addChild(v)
        b._c[v.name] = v
    end

    b._images = c
    local function m(event)
        if event == "enter" then
        elseif event == "exit" then
            b = nil
        end
    end
    b:registerScriptHandler(m)
    return b
end

function uihelper:getWorldPositionLabel(w, m)
    local c = uihelper:f(w, m)
    local x, y = uihelper:getWorldPosition(w, m)
    local t = cc.Label:create()
    t:setIgnoreAnchorPointForPosition(false)
    t:setSystemFontSize(c:getSystemFontSize())
    t:setSystemFontName(c:getSystemFontName())
    t:setWidth(c:getWidth())
    t:setHorizontalAlignment(c:getHorizontalAlignment())
    t:setAnchorPoint(c:getAnchorPoint())
    t:setPosition(cc.p(x, y))
    return t, x, y
end

function uihelper:getWorldPosition(w, m)
    local c = uihelper:f(w, m)
    if c then
        local a = w:getContentSize()
        local b = w:getAnchorPoint()
        if b == nil then b = { x=0,y=0} end
        local g = b.x * a.width
        local d = b.y * a.height
        local e, f = w:getPosition()
        return e - g + c:getPositionX(), f - d + c:getPositionY()
    else
        return 0, 0
    end
end

return uihelper
