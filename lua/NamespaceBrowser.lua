#!/usr/bin/env lua
------------------------------------------
-- GENERATED FILE, DO NOT EDIT DIRECTLY --
------------------------------------------
function DEBUG(fmt, ...)
print("DEBUG: " .. string.format(fmt, ...))
end
Events = {}
Events.Names = {
"ChatCommand",
"EmotePlayed",
"FileLoaded",
"FileSaved",
"Keyboard",
"Loop",
"Mouse",
"NewGame",
"NewPlayer",
"PlayerDataLoaded",
"PlayerDied",
"PlayerGetCheese",
"PlayerLeft",
"playerMeep",
"PlayerRespawn",
"PlayerVampire",
"PlayerWon",
"PopupAnswer",
"SummoningCancel",
"SummoningEnd",
"SummoningStart",
"TextAreaCallback"
}
Events.CONTINUE = 0
Events.STOP = 1
Events.Handlers = {}
Events.addHandler = function(handler)
table.insert(Events.Handlers, handler)
end
Events.pipeline = function(event)
local function f(...)
for _, handler in ipairs(Events.Handlers) do
if handler[event] then
local r = handler[event](...)
if not r then
r = 0
end
if r == Events.STOP then
return
end
end
end
end
return f
end
Events.init = function()
for i, _ in ipairs(Events.Names) do
Events.Names[i] = "event" .. Events.Names[i]
end
for _, event in ipairs(Events.Names) do
if not _G[event] then
for _, handler in ipairs(Events.Handlers) do
if handler[event] then
_G[event] = Events.pipeline(event)
break
end
end
end
end
end
GUI = {}
Events.addHandler(GUI)
GUI.rgb = function(r,g,b)
return r * 256 * 256 + g * 256 + b
end
GUI.null = {}
GUI.null.isVisibleForPlayer = function(p)
return false
end
GUI.Controls = {}
GUI.baseid = 0
GUI.defaultbg = GUI.rgb(0,0,128)
GUI.defaultbc = GUI.rgb(255,255,255)
GUI.defaultba = 0.8
GUI.autoCloseEqual = 1
GUI.autoCloseGreaterThanOrEqual = 2
GUI.Control = {}
GUI.Control.show = function(c,p)
if c.autoCloseGroup then
for i,c2 in ipairs(GUI.Controls) do
if c2.autoCloseGroup and c.id ~= c2.id then
if c.autoCloseGroupBehaviour == GUI.autoCloseEqual and c.autoCloseGroup == c2.autoCloseGroup then
c2:hide(p)
elseif c.autoCloseGroupBehaviour == GUI.autoCloseGreaterThanOrEqual and c2.autoCloseGroup >= c.autoCloseGroup then
c2:hide(p)
end
end
end
end
if c.onShow then
c:onShow()
end
ui.addTextArea(GUI.baseid + c.id, c.html, p, c.x, c.y, c.w, c.h, c.bg, c.bc, c.ba)
if p then
c.isVisible[p] = true
else
c.isVisible = {}
c.isVisible['*'] = true
end
end
GUI.Control.hide = function(c,p)
if c.onHide then
c:onHide()
end
ui.removeTextArea(GUI.baseid + c.id, p)
if p then
c.isVisible[p] = false
else
c.isVisible = {}
end
if c.destroyOnClose == true then
GUI.Controls[c.id] = GUI.null
end
end
GUI.Control.toggle = function(c,p)
if c:isVisibleForPlayer(p) then
c:hide(p)
else
c:show(p)
end
end
GUI.Control.isVisibleForPlayer = function(c,p)
if c.isVisible[p] == true then
return true
end
if c.isVisible['*'] == true then
return true
end
return false
end
function GUI.Control:new(x,y,w,h)
local c = {}
c.x = x
c.y = y
c.w = w
c.h = h
c.id = #GUI.Controls + 1
c.text = ""
c.html = ""
c.isVisible = {}
c.isVisibleForPlayer = GUI.Control.isVisibleForPlayer
c.autoCloseGroupBehaviour = GUI.autoCloseEqual
c.destroyOnClose = false
c.bg = GUI.defaultbg
c.bc = GUI.defaultbc
c.ba = GUI.defaultba
table.insert(GUI.Controls,c)
c.show = GUI.Control.show
c.hide = GUI.Control.hide
c.toggle = GUI.Control.toggle
return c
end
GUI.Label = {}
GUI.Label.setText = function(c,text)
if not text then
text = ""
end
c.text = text
c.html = text
end
function GUI.Label:new(x,y,w,h,text)
c = GUI.Control:new(x,y,w,h)
c.type = "GUI.Label"
c.setText = GUI.Label.setText
c:setText(text)
return c
end
GUI.Button = {}
GUI.Button.setText = function(c,text)
if not text then
text = ""
end
c.text = text
c.html = '<a href="event:' .. c.id .. '" >' .. text .. '</a>'
end
function GUI.Button:new(x,y,w,h,text)
c = GUI.Control:new(x,y,w,h)
c.type = "GUI.Button"
c.setText = GUI.Button.setText
c:setText(text)
return c
end
GUI.List = {}
GUI.List.clear = function(c)
c.children = {}
end
GUI.List.add = function(c, child)
child.parent = c
child.id = #c.children + 1
child:setText(child.text)
table.insert(c.children, child)
c.html = '' --'<ol>'
for i,child in ipairs(c.children) do
if c.html:len() > 1950 then
break
end
if child.type == "GUI.Label" then
c.html = c.html .. child.html .. '<br>'
elseif child.type == "GUI.Button" then
c.html = c.html .. child.html .. '<br>'
end
end
end
function GUI.List:new(x,y,w,h)
c = GUI.Control:new(x,y,w,h)
c.type = "GUI.List"
c.children = {}
c.add = GUI.List.add
c.clear = GUI.List.clear
return c
end
GUI.eventTextAreaCallback = function(id,p,callback)
local c = GUI.Controls[id]
if c then
if c.onClick then
c:onClick(id,p,callback)
return Events.STOP
end
end
end
GUI.eventMouse = function(p,x,y)
bAutoClose = true
r = Events.CONTINUE
for i,c in ipairs(GUI.Controls) do
if c:isVisibleForPlayer(p) and x > c.x and x < (c.x+c.w) and y > c.y and y < (c.y + c.h) then
bAutoClose = false
r = Events.STOP
end
end
if bAutoClose == true then
for i,c in ipairs(GUI.Controls) do
if c.autoCloseGroup and c:isVisibleForPlayer(p) then
c:hide(p)
r = Events.STOP
end
end
end
return r
end
function onShow(c)
c:clear()
c:add( GUI.Label:new(0, 0, 0, 0, c.header) )
for p,_ in pairs(c.root) do
c:add( GUI.Button:new(0, 0, 0, 0, p) )
end
end
function onClick(c, id, p, callback)
text = c.children[tonumber(callback)].text
full = c.header .. text
local _,depth = string.gsub(full, "%.", "")
local value = c.root[text]
if type(value)=="table" then
local sublist = GUI.List:new(c.x + c.w + 16, 30, c.w, 360)
sublist.root = value
sublist.onShow = c.onShow
sublist.onClick = c.onClick
sublist.header = full .. '.'
sublist.autoCloseGroup = depth
sublist.autoCloseGroupBehaviour = GUI.autoCloseGreaterThanOrEqual
sublist.destroyOnClose = true
sublist:show(p)
else
local label = GUI.Label:new(c.x + c.w + 16, 30, c.w, 360, '['..type(value)..'] '..tostring(value))
label.autoCloseGroup = depth
label.autoCloseGroupBehaviour = GUI.autoCloseGreaterThanOrEqual
label.destroyOnClose = true
label:show(p)
end
end
GUI.Label:new(700, 300, "Hello")
list_tfm = GUI.List:new(10, 30, 180, 80)
list_tfm.header = 'tfm.'
list_tfm.root = tfm
list_tfm.onShow = onShow
list_tfm.onClick = onClick
list_system = GUI.List:new(10, 120, 180, 180)
list_system.header = 'system.'
list_system.root = system
list_system.onShow = onShow
list_system.onClick = onClick
list_ui = GUI.List:new(10, 310, 180, 80)
list_ui.header = 'ui.'
list_ui.root = ui
list_ui.onShow = onShow
list_ui.onClick = onClick
tfm.exec.newGame()
list_tfm:show()
list_system:show()
list_ui:show()
function eventNewGame()
for p,_ in pairs(tfm.get.room.playerList) do
system.bindMouse(p,yes)
end
end
Events.init()
