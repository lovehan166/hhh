-- JBS v3.2 library-based entry point. Run this file ONLY; restart the game before upgrading.
local function loadLibrary()
-- JBS UI library v3.2. Evaluating this file returns an API; it creates no window.
-- Compatible with the CreateWindow/Tab/control/Notify calls used by JBS v3.1.
local environment=(type(getgenv)=="function" and getgenv()) or _G
local KEY="__JBSMetalLibraryV32"
local cached=environment[KEY]
if cached then
 assert(cached.Version=="3.2", "JBS 库版本冲突，请重新进入游戏")
 return cached
end
local Library={Version="3.2",GameState="idle"}
local instance,window
local function currentGui()
 local player=game:GetService("Players").LocalPlayer
 assert(player,"JBS 必须在游戏客户端运行")
 return player:WaitForChild("PlayerGui")
end
local function legacyConflict()
 local roots={currentGui()}
 local ok,core=pcall(function() return game:GetService("CoreGui") end)
 if ok and core then roots[#roots+1]=core end
 for _,root in ipairs(roots) do
  for _,node in ipairs(root:GetDescendants()) do
   if node:IsA("ScreenGui") and (node.Name=="JBS_91_78_Showcase" or (node.Name=="JBS_Metal_v31" and not (instance and instance:IsAlive()))) then return node.Name end
   if node:IsA("TextLabel") or node:IsA("TextButton") then
    local text=node.Text or ""
    if text=="JBS 鸡巴骚" or text=="JBS鸡巴骚" or text=="JBS 力量传奇 · 金属版" then return text end
   end
  end
 end
 -- Original JBS exposes these flags even when its window has been hidden/destroyed.
 -- Before this library's own game starts, they are evidence of an older game session.
 if Library.GameState=="idle" then
  for _,key in ipairs({"auto_train","auto_rebirth","auto_wheel","auto_petbuy","auto_packrebirth","auto_eategg","auto_fasttrain","auto_boss"}) do
   if rawget(_G,key)~=nil then return "旧版 JBS 功能状态" end
  end
 end
end
local function checkLegacy()
 local conflict=legacyConflict()
 assert(not conflict,"检测到旧 JBS（"..tostring(conflict).."）。请退出并重新进入游戏，只运行新版启动文件；不要同时运行原脚本或旧 UI。")
end
local function createRenderer()
-- JBS 91&78 · native pink-purple metal grille
-- Embedded metal renderer; game-dependent entry point. See the bundled README.
-- Game callbacks are supplied through the embedded compatibility adapter.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "请在客户端 LocalScript 中运行")
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("JBS_Metal_v31")
assert(not previous, "JBS 已在运行")
local scene = {version="metal-grid-2", width=1016, height=726, palette={base="#16091F", panel="#251033", pink="#FF4FD8", violet="#A855F7", pearl="#D8B4FE", white="#FFE6FA"}, pattern={pitchX=42, pitchY=28, size=13}, navigation={{id="main", label="主要", icon="bolt"}, {id="travel", label="传送", icon="pin"}, {id="pets", label="宠物", icon="pet"}, {id="boss", label="Boss", icon="crown"}, {id="pack", label="换包重生", icon="weight"}}, features={}}
local colorCache={}
local function rgb(hex)
 if not colorCache[hex] then colorCache[hex]=Color3.fromHex(hex:gsub("#", "")) end
 return colorCache[hex]
end
local P = scene.palette
local WHITE = Color3.new(1,1,1)
local function make(class, properties, parent)
 local object = Instance.new(class)
 for key, value in pairs(properties) do object[key] = value end
 object.Parent = parent
 return object
end
local function corner(object, radius) make("UICorner", {CornerRadius=UDim.new(0,radius)}, object) end
local function gradient(object, stops, rotation)
 local keys = {}
 for _, stop in ipairs(stops) do keys[#keys+1] = ColorSequenceKeypoint.new(stop[1],rgb(stop[2])) end
 return make("UIGradient",{Color=ColorSequence.new(keys),Rotation=rotation or 0},object)
end
local function stroke(object, color, thickness, transparency)
 return make("UIStroke",{Color=rgb(color),Thickness=thickness or 1,Transparency=transparency or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},object)
end
local function frame(parent,name,x,y,w,h,color,r,z,alpha)
 local o=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=rgb(color or P.base),BackgroundTransparency=alpha or 0,BorderSizePixel=0,Active=false,ZIndex=z or 1},parent)
 if r then corner(o,r) end
 return o
end
local function label(parent,name,text,x,y,w,h,size,color,bold,z)
 -- 分级字号：窗口外观大字（≥18pt）保持原尺寸；内容区小字放大 1.75 倍提升可读性；Tribe/背景水印/悬浮按钮文字保持原样
 -- 外观项：LOGO 43/45、标题 20/25、导航 19、按钮图标 20-26 均恢复原始大小；内容项：功能名 16→22、状态 12→17、说明 11-13→15-18、输入值 15→21
 return make("TextLabel",{Name=name,Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,BorderSizePixel=0,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=(size>=18 or name=="Tribe" or name=="JBSMetalMark" or name=="Text") and size or math.floor(size*1.75+.5),TextColor3=rgb(color or P.white),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=false,Active=false,Selectable=false,ZIndex=z or 5},parent)
end
local function button(parent,name,x,y,w,h,r)
 local b=make("TextButton",{Name=name,Text="",Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Selectable=true,ClipsDescendants=true,ZIndex=5},parent)
 if r then corner(b,r) end
 return b
end
local connections, tweens, temporaries = {}, {}, {}
local destroyed=false
local function connect(event,callback)
 local c=event:Connect(callback);connections[#connections+1]=c;return c
end
local function tween(object, properties, duration, delay)
 local t=TweenService:Create(object,TweenInfo.new(duration or .22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,0,false,delay or 0),properties)
 tweens[t]=true
 t.Completed:Once(function() tweens[t]=nil end)
 t:Play();return t
end
local gui=make("ScreenGui",{Name="JBS_Metal_v31",ResetOnSpawn=false,DisplayOrder=30,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
gui:SetAttribute("JBSLibraryVersion","3.2")
local viewport=frame(gui,"Viewport",0,0,0,0,P.base,nil,1,1)
viewport.Size=UDim2.fromScale(1,1)
local canvas=frame(viewport,"ReferenceCanvas",0,0,1016,726,P.base,nil,1,1)
canvas.Position=UDim2.fromScale(.5,.5);canvas.AnchorPoint=Vector2.new(.5,.5)
local scale=make("UIScale",{Scale=1},canvas)
local expanded=false
local function fit()
 local size=viewport.AbsoluteSize
 scale.Scale=math.max(.05,math.min((size.X-44)/1016,(size.Y-44)/726,expanded and 1.6 or 1.2))
end
connect(viewport:GetPropertyChangedSignal("AbsoluteSize"),fit);fit()
-- Ordinary Frames keep content visible on low-memory mobile clients.
local shell=make("Frame",{Name="Window",Size=UDim2.fromOffset(1016,726),BackgroundColor3=WHITE,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2},canvas)
make("UIScale",{Scale=0.92},shell)  -- 整窗缩放:稍微变小(约8%)
corner(shell,28)
local shellMetal=gradient(shell,{{0,"#64245D"},{.3,P.panel},{.58,P.base},{1,"#572476"}},30)
local rim=stroke(shell,P.white,1.5,.08)
local metalStops={{0,"#8B439F"},{.28,P.pink},{.43,P.pearl},{.49,P.white},{.53,"#562168"},{.7,P.violet},{1,"#D777D1"}}
local rimGradient=gradient(rim,metalStops,25)
local glows={}
for i,thickness in ipairs({16,9,4}) do
 local g=frame(canvas,"AmbientRim"..i,0,0,1016,726,P.base,28,1,1)
 local s=stroke(g,P.pink,thickness,.96-i*.025)
 glows[#glows+1]={object=g,stroke=s}
end
local inner=frame(shell,"InnerEdge",5,5,1006,716,P.base,23,2,1);stroke(inner,P.pearl,1,.78)
local headerLine=frame(shell,"HeaderLine",28,93,960,1,P.pearl,nil,3,.82)
local logo=label(shell,"HeaderJBS","JBS",28,21,89,52,43,P.white,true)
logo.TextColor3=WHITE
local logoGradient=gradient(logo,{{0,"#B36DCC"},{.25,P.pink},{.41,P.pearl},{.47,P.white},{.51,"#642075"},{.66,"#F38CD9"},{1,P.pearl}},15)
label(shell,"Title","JBS 力量传奇",135,24,320,26,20,P.white,true)
label(shell,"Tribe","部落 ID · 91&78",135,53,300,19,12,P.pearl)
for i=0,15 do
 local slat=frame(shell,"HeaderMetal",618+i*12,27,1,39,P.pearl,nil,3,.62)
 gradient(slat,{{0,"#69256C"},{.43,P.pink},{.5,P.white},{.59,"#713087"},{1,P.pearl}},75)
end
local minimize=button(shell,"Minimize",858,28,32,32,8)
local expand=button(shell,"Expand",902,28,32,32,8)
local close=button(shell,"Close",946,28,32,32,8)
label(minimize,"Glyph","—",6,0,26,30,20,P.pearl)
label(expand,"Glyph","□",7,0,26,30,22,P.pearl)
label(close,"Glyph","×",8,0,24,30,26,P.pearl)
local side=frame(shell,"Sidebar",13,94,350,619,P.panel,18,3,1)
local content=frame(shell,"Content",375,94,628,619,P.panel,18,3)
content.BackgroundColor3=WHITE;content.ClipsDescendants=true
local contentMetal=gradient(content,{{0,"#74286D"},{.45,"#2C103F"},{1,"#5D257C"}},34)
stroke(content,P.pearl,1,.38)
-- The glyph prototype is reused; one shared render loop controls spatial reflection.
-- All marks remain upright. Safe inset keeps their bounds inside the rounded corners.
local glyphs={}
local prototype=label(nil,"JBSMetalMark","JBS",0,0,29,17,scene.pattern.size,P.white,true,2)
prototype.TextColor3=WHITE
local protoGradient=gradient(prototype,{{0,"#A663BB"},{.27,"#F4AFE2"},{.42,P.white},{.49,"#7A398F"},{.67,"#BD76DE"},{1,"#EC97D6"}},90)
local function pattern(parent,w,h,opacity)
 local material=frame(parent,"BrandMaterial",0,0,w,h,P.base,nil,1,1)
 material.ClipsDescendants=true
 for row=0,math.floor((h-30)/28) do
  local y=12+row*28
  for col=0,math.floor(w/42) do
   local x=12+col*42+(row%2)*21
   if x+29<w-12 then
    local glyph=prototype:Clone();glyph.Position=UDim2.fromOffset(x,y);glyph.TextTransparency=1-opacity;glyph.Parent=material
    glyphs[#glyphs+1]={object=glyph,x=x,y=y,width=w,base=opacity}
   end
  end
 end
end
pattern(side,350,619,.29);pattern(content,628,619,.65);prototype:Destroy()
local searchMaterial=frame(side,"SearchMaterial",8,0,334,70,P.white,17,4)
searchMaterial.BackgroundColor3=WHITE
gradient(searchMaterial,{{0,"#542354"},{1,P.panel}},25)
stroke(searchMaterial,P.pearl,1,.55)
local search=make("TextBox",{Name="Search",PlaceholderText="搜索功能",Text="",ClearTextOnFocus=false,Position=UDim2.fromOffset(8,0),Size=UDim2.fromOffset(334,70),BackgroundTransparency=1,BackgroundColor3=WHITE,BorderSizePixel=0,TextColor3=rgb(P.white),PlaceholderColor3=rgb(P.pearl),Font=Enum.Font.Gotham,TextSize=24,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},side)
corner(search,17)
make("UIPadding",{PaddingLeft=UDim.new(0,24),PaddingRight=UDim.new(0,18)},search)
for i=1,#scene.navigation do
 local backing=frame(side,"NavigationBacking",8,90+(i-1)*72,334,57,P.panel,12,3,.08)
end
local selection=frame(side,"SelectedNavigation",8,90,334,57,P.white,12,4)
selection.BackgroundColor3=WHITE;gradient(selection,{{0,"#E73CBD"},{.7,P.violet},{1,"#7F33D0"}},15);stroke(selection,P.white,1,.48)
local selectionGlow=frame(selection,"LightStrip",0,15,3,26,P.white,2,5)
local menuButtons={}
-- Consistent lightweight vector icons. These are UI symbols, with no external assets.
local function line(parent,x1,y1,x2,y2,color,width)
 local dx,dy=x2-x1,y2-y1
 local o=frame(parent,"IconStroke",(x1+x2)/2,(y1+y2)/2,math.sqrt(dx*dx+dy*dy),width or 1.6,color,1,6)
 o.AnchorPoint=Vector2.new(.5,.5);o.Rotation=math.deg(math.atan2(dy,dx));return o
end
local function icon(parent,kind,x,y)
 local p=frame(parent,"Icon",x,y,24,24,P.base,nil,6,1)
 local paths={bolt={{13,2,4,14},{4,14,11,14},{11,14,10,22},{10,22,20,9},{20,9,13,9},{13,9,13,2}},weight={{7,12,17,12},{4,7,4,17},{7,5,7,19},{17,5,17,19},{20,7,20,17}},pin={{4,9,12,3},{12,3,20,9},{20,9,18,15},{18,15,12,22},{12,22,6,15},{6,15,4,9}},pet={{4,9,3,3},{3,3,9,6},{9,6,15,6},{15,6,21,3},{21,3,20,16},{20,16,16,20},{16,20,8,20},{8,20,4,16},{4,16,4,9},{8,12,8,13},{16,12,16,13},{10,16,12,18},{12,18,14,16}},crown={{3,6,8,11},{8,11,12,3},{12,3,16,11},{16,11,21,6},{21,6,19,19},{19,19,5,19},{5,19,3,6},{6,16,18,16}},spark={{12,2,15,9},{15,9,22,12},{22,12,15,15},{15,15,12,22},{12,22,9,15},{9,15,2,12},{2,12,9,9},{9,9,12,2}}}
 for _,v in ipairs(paths[kind] or paths.spark) do line(p,v[1],v[2],v[3],v[4],P.pearl) end
 return p
end
for i,item in ipairs(scene.navigation) do
 local b=button(side,item.id,8,90+(i-1)*72,334,57,12)
 icon(b,item.icon,24,16)
 local title=label(b,"Label",item.label,68,0,210,57,19,P.pearl)
 label(b,"Index",string.format("%02d",i),299,0,27,57,11,P.pearl)
 menuButtons[i]={button=b,title=title,item=item}
end
frame(side,"SignatureRule",24,505,302,1,P.pearl,nil,4,.7)
local sideLogo=label(side,"SideJBS","JBS",24,524,140,50,45,P.white,true)
sideLogo.TextColor3=WHITE
local sideLogoGradient=gradient(sideLogo,metalStops,20)
local signatureSubtitle=label(side,"SignatureSubtitle","部落专属",24,576,84,18,11,P.pearl)
signatureSubtitle.TextXAlignment=Enum.TextXAlignment.Center
label(side,"IDs","91&78",219,548,105,39,25,P.white,true)
local titleGuard=frame(content,"TitleGuard",1,1,626,115,P.panel,17,3,.02)
make("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.35,0),NumberSequenceKeypoint.new(.65,.8),NumberSequenceKeypoint.new(1,1)})},titleGuard)
local pageTitle=label(content,"PageTitle","主要",26,23,325,35,25,P.white,true)
local description=label(content,"Description","功能列表",26,65,350,20,12,P.pearl)
local edition=frame(content,"Edition",474,26,127,33,P.white,7,4)
gradient(edition,{{0,"#AC4B9E"},{1,"#62288B"}},20);stroke(edition,P.pearl,1,.45)
label(edition,"EditionText","JBS · 91&78",12,0,106,33,12,P.white,true)
local list=make("Frame",{Name="Features",Position=UDim2.fromOffset(22,116),Size=UDim2.fromOffset(584,398),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5},content)
local footer=frame(content,"FooterShade",1,521,626,97,P.panel,nil,3,.13)
make("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},footer)
local dot=frame(content,"StatusLight",27,578,5,5,P.white,3,5);stroke(dot,P.pink,3,.72)
label(content,"Footer","JBS · 力量传奇",40,563,350,34,13,P.white,true)
label(content,"FooterIDs","91&78",530,563,85,34,14,P.white,true)
local stars={}
for i=1,16 do
 local x=28+(i*37)%570
 local y=i<=6 and 10+(i*7)%85 or 530+(i*13)%64
 local s=frame(content,"Spark",x,y,2,2,P.white,1,2,.5)
 stars[#stars+1]={object=s,phase=i*.77}
 if i%4==0 then
  for _,size in ipairs({{1,10},{10,1}}) do
   local ray=frame(s,"StarRay",1,1,size[1],size[2],P.white,nil,2,.3)
   ray.AnchorPoint=Vector2.new(.5,.5)
  end
 end
end
local notice=frame(shell,"ReadyNotice",410,620,570,90,P.white,12,15)
gradient(notice,{{0,"#852A77"},{1,"#3C185E"}},15);stroke(notice,P.pearl,1,.25)
label(notice,"Mark","JBS",17,10,66,44,26,P.white,true,16)
label(notice,"Ready","界面已就绪",95,10,450,25,15,P.white,true,16)
label(notice,"Details","91&78 · 金属印记",95,35,450,46,11,P.pearl,false,16)
notice.Details.TextWrapped=true
notice.Visible=false
local restore=button(viewport,"RestoreJBS",0,0,132,46,14) -- 收起后的悬浮按钮
restore.Position=UDim2.fromScale(.5,.5);restore.AnchorPoint=Vector2.new(.5,.5);restore.BackgroundTransparency=0;restore.BackgroundColor3=WHITE
stroke(restore,P.pearl,1,.2);gradient(restore,{{0,"#982A80"},{1,"#6539A3"}},20)
local restoreLabel=label(restore,"Text","JBS 鸡巴骚",0,0,132,46,16,P.white,true) -- 注意：TextButton.Text 是属性(字符串)，不能用 restore.Text 访问子标签，必须接住 label() 的返回值
restoreLabel.TextXAlignment=Enum.TextXAlignment.Center -- 文字居中
restore.Visible=false
-- ===== 新增：悬浮窗拖动 =====
-- 原因：canvas 被固定在屏幕中心（scale .5,.5），且全脚本没有任何拖动输入处理，因此窗口无法移动
-- 方案：标题栏热区按住即可拖动整个窗口（避开右上角三个窗口按钮）；收起后的悬浮按钮同样可拖动；拖动范围不限
local dragHandle=button(shell,"DragHandle",13,8,830,78)
local dragging,dragStart,dragStartPos
local restoreDragging,restoreMoved,restoreStart,restoreStartPos
connect(dragHandle.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true;dragStart=input.Position;dragStartPos=canvas.Position
  input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
 end
end)
connect(restore.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  restoreDragging=true;restoreMoved=false;restoreStart=input.Position;restoreStartPos=restore.Position
  input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then restoreDragging=false end end)
 end
end)
connect(UserInputService.InputChanged,function(input)
 if not dragging and not restoreDragging then return end
 if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
 if dragging then
  local delta=input.Position-dragStart
  canvas.Position=UDim2.new(.5,dragStartPos.X.Offset+delta.X,.5,dragStartPos.Y.Offset+delta.Y)
 end
 if restoreDragging then
  local delta=input.Position-restoreStart
  if math.abs(delta.X)+math.abs(delta.Y)>8 then restoreMoved=true end
  restore.Position=UDim2.new(restoreStartPos.X.Scale,restoreStartPos.X.Offset+delta.X,restoreStartPos.Y.Scale,restoreStartPos.Y.Offset+delta.Y)
 end
end)
-- WindUI-compatible binding layer. All callbacks are supplied by the original game file.
local actionEvent=make("BindableEvent",{Name="UISelectionChanged"},gui)
local scroll=make("ScrollingFrame",{Name="ControlScroll",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=5,ScrollBarImageColor3=rgb(P.pink),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true,ZIndex=5},list)
local category="main"
local cards={}
local empty=label(scroll,"Empty","没有匹配的功能",4,4,564,70,15,P.pearl)
empty.TextXAlignment=Enum.TextXAlignment.Center;empty.Visible=false
local adapter,window={},{}
local toggleKeys={
 ["自动重生"]="auto_rebirth",["自动锻炼"]="auto_train",["自动轮盘"]="auto_wheel",
 ["自动购买"]="auto_petbuy",["自动打Boss"]="auto_boss",["换包重生"]="auto_packrebirth",
 ["快速锻炼"]="auto_fasttrain",["自动吃蛋"]="auto_eategg",
}
local displayNames={
 ["目标次数"]="自动重生 · 目标次数",["自动购买"]="自动购买宠物 / 光环",
 ["购买一次"]="购买所选宠物 / 光环",["悬停高度"]="Boss 悬停高度",
 ["送蛋"]="赠送蛋白蛋",["自动吃蛋"]="自动使用蛋白蛋",
 ["快速锻炼"]="快速锻炼",
}
-- UI-only lifetime: every toast gets its own three-second deadline.
-- Heartbeat is independent of decorative animation pause/focus handling.
local NOTICE_DURATION=3
local noticeToken,noticeDeadline=0,0
local progressTrack=frame(notice,"CountdownTrack",18,77,534,4,"#281034",2,16)
stroke(progressTrack,P.pearl,1,.75)
local progressFill=frame(progressTrack,"CountdownFill",0,0,534,4,P.white,2,17)
gradient(progressFill,{{0,P.pink},{.52,P.violet},{.86,P.pearl},{1,P.white}},0)
stroke(progressFill,P.pink,2,.55)
local countdown=label(notice,"Countdown","3.0s",488,9,64,23,11,P.pearl,false,17)
countdown.TextXAlignment=Enum.TextXAlignment.Right
notice.Ready.Size=UDim2.fromOffset(380,25)
notice.Details.Size=UDim2.fromOffset(450,34)
notice.Active=false
local function updateNoticeCountdown()
 if not notice.Visible then return end
 local remaining=math.max(0,noticeDeadline-os.clock())
 progressFill.Size=UDim2.fromScale(remaining/NOTICE_DURATION,1)
 countdown.Text=string.format("%.1fs",math.ceil(remaining*10)/10)
 if remaining<=0 then notice.Visible=false end
end
connect(RunService.Heartbeat,updateNoticeCountdown)
-- Presentation only: retain original feature callbacks and their parameters.
local function formatNoticeContent(content,title)
 local message=tostring(content or "")
 message=message:gsub("，无限", ""):gsub(",%s*无限", "")
 message=message:gsub("自动重生已开启", "自动重生以开始"):gsub("自动重生已开始", "自动重生以开始")
 local closed=string.find(tostring(title or ""),"已关闭",1,true) or string.find(message,"已关闭",1,true) or string.find(message,"已停止",1,true)
 message=message:gsub("%s*开🦌开🦌", ""):gsub("%s*🐍了🐍了", "")
 message=message..(closed and " 🐍了🐍了" or " 开🦌开🦌")
 return message
end
function adapter:Notify(options)
 if destroyed then return end
 noticeToken=noticeToken+1;local token=noticeToken
 noticeDeadline=os.clock()+NOTICE_DURATION
 gui:SetAttribute("NoticeSequence",noticeToken)
 notice.Ready.Text=tostring(options.Title or "JBS")
 notice.Details.Text=formatNoticeContent(options.Content,options.Title)
 progressFill.Size=UDim2.fromScale(1,1)
 countdown.Text="3.0s"
 notice.Visible=shell.Visible and gui.Enabled
 task.delay(NOTICE_DURATION,function()
  if not destroyed and token==noticeToken then
   progressFill.Size=UDim2.fromScale(0,1)
   countdown.Text="0.0s"
   notice.Visible=false
  end
 end)
 -- When the window is hidden, retain a short native notification instead.
 if not notice.Visible then
  pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=options.Title or "JBS",Text=notice.Details.Text,Duration=NOTICE_DURATION}) end)
 end
end
local function syncToggle(c)
 if c.kind~="Toggle" then return end
 local key=toggleKeys[c.originalTitle]
 if key then c.value=_G[key]==true end
 c.state.Text=c.busy and "处理中" or (c.value and "已开启" or "已关闭")
 c.track.BackgroundColor3=rgb(c.value and P.pink or "#5A3565")
 c.knob.Position=UDim2.fromOffset(c.value and 25 or 3,3)
 c.edge.Transparency=c.value and .12 or .6
 c.button:SetAttribute("Value",c.value)
end
local function invoke(c,value)
 if destroyed or c.busy then return end
 c.busy=true
 if c.kind=="Toggle" then syncToggle(c) end
 if c.kind=="Button" then c.state.Text="处理中…" end
 task.spawn(function()
  local ok,err=pcall(c.options.Callback or function() end,value)
  c.busy=false
  if destroyed then return end
  if c.kind=="Toggle" then syncToggle(c) end
  if c.kind=="Button" then c.state.Text="执行 ›" end
  if not ok then
   adapter:Notify({Title="操作未完成",Content=tostring(err),Duration=7})
   warn("[JBS Metal UI] "..tostring(err))
  end
 end)
end
local function filterCards(animate)
 local y,count=4,0;local q=string.lower(search.Text)
 for _,c in ipairs(cards) do
  local show=c.item.category==category and (q=="" or (c.kind~="Divider" and c.kind~="Section" and string.find(string.lower(c.item.label.." "..c.originalTitle),q,1,true)~=nil))
  c.button.Visible=show
  if show then
   c.y=y;c.button.Position=UDim2.fromOffset(4,y);y=y+c.height+8
   if c.kind~="Divider" and c.kind~="Section" then count=count+1 end
  end
 end
 scroll.CanvasSize=UDim2.fromOffset(0,y+6)
 empty.Visible=count==0;description.Text=(q~="" and "搜索结果" or "功能列表")
 if animate then
  scroll.CanvasPosition=Vector2.zero
  list.Position=UDim2.fromOffset(22,125);
  tween(list,{Position=UDim2.fromOffset(22,116),},.22)
 end
end
-- Dropdown is a window-level modal, so neither the page nor its scroll area clips it.
local popup=frame(shell,"DropdownModal",380,112,600,488,P.base,16,30,.02)
popup.Visible=false;stroke(popup,P.pink,1,.1)
local popupTitle=label(popup,"Title","选择",18,12,500,30,18,P.white,true,31)
local popupClose=button(popup,"CloseDropdown",552,10,32,32,8);popupClose.ZIndex=32
label(popupClose,"Glyph","×",4,0,28,32,24,P.white,false,33)
local popupSearch=make("TextBox",{Name="OptionSearch",Position=UDim2.fromOffset(18,52),Size=UDim2.fromOffset(564,40),BackgroundColor3=rgb(P.panel),BorderSizePixel=0,Text="",PlaceholderText="搜索选项",TextColor3=rgb(P.white),PlaceholderColor3=rgb(P.pearl),TextSize=26,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=31},popup)
corner(popupSearch,8)
local popupList=make("ScrollingFrame",{Name="Options",Position=UDim2.fromOffset(18,102),Size=UDim2.fromOffset(564,366),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=5,ScrollBarImageColor3=rgb(P.pink),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true,ZIndex=31},popup)
local popupOwner,popupConnections=nil,{}
local function clearOptions()
 for _,c in ipairs(popupConnections) do c:Disconnect() end
 table.clear(popupConnections)
 for _,child in ipairs(popupList:GetChildren()) do child:Destroy() end
end
local function closePopup()
 popup.Visible=false;popupOwner=nil;clearOptions()
end
local drawOptions
local function refreshPlayerOptions(c)
 if c.originalTitle~="送蛋目标" then return end
 local values={}
 for _,p in ipairs(Players:GetPlayers()) do if p~=player then table.insert(values,p.Name) end end
 c.handle:Refresh(values,false)
end
local function openPopup(c)
 closePopup();popupOwner=c;refreshPlayerOptions(c)
 popupTitle.Text=c.item.label;popupSearch.Text="";popup.Visible=true
 popupList.CanvasPosition=Vector2.zero;drawOptions()
end
drawOptions=function()
 clearOptions()
 local c=popupOwner;if not c then return end
 local q=string.lower(popupSearch.Text);local n=0
 local function option(text,value)
  local b=button(popupList,"Option"..n,0,n*43,551,37,8);b.ZIndex=32
  b.BackgroundTransparency=0;b.BackgroundColor3=rgb(value==c.value and "#713175" or P.panel)
  label(b,"Label",text,12,0,526,37,15,P.white,false,33)
  popupConnections[#popupConnections+1]=b.Activated:Connect(function()
   if c.busy then return end
   c.value=value;c.valueLabel.Text=value or "请选择";closePopup();invoke(c,value)
  end)
  n=n+1
 end
 if c.options.AllowNone then option("清除选择",nil) end
 for _,value in ipairs(c.values) do
  if string.find(string.lower(tostring(value)),q,1,true) then option(tostring(value),value) end
 end
 if n==0 then label(popupList,"EmptyOptions","没有可选项，请稍后刷新",12,0,520,44,16,P.pearl,false,33);n=1 end
 popupList.CanvasSize=UDim2.fromOffset(0,n*43)
end
connect(popupClose.Activated,closePopup)
connect(popupSearch:GetPropertyChangedSignal("Text"),drawOptions)
connect(shell:GetPropertyChangedSignal("Visible"),function() if not shell.Visible then closePopup() end end)
local activeSlider,sliderInput=nil,nil
local function sliderAt(c,x)
 local low,high=c.options.Value.Min,c.options.Value.Max
 local a=math.clamp((x-c.slider.AbsolutePosition.X)/math.max(1,c.slider.AbsoluteSize.X),0,1)
 local step=10^(c.options.Value.Precision or 0)
 local value=math.clamp(math.floor((low+(high-low)*a)*step+.5)/step,low,high)
 if value==c.value then return end
 c.value=value;c.valueLabel.Text=tostring(value)
 c.fill.Size=UDim2.fromScale((value-low)/math.max(1,high-low),1)
 c.thumb.Position=UDim2.fromScale((value-low)/math.max(1,high-low),.5)
 invoke(c,value)
end
connect(UserInputService.InputChanged,function(input)
 if activeSlider and (input==sliderInput or (sliderInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then sliderAt(activeSlider,input.Position.X) end
end)
connect(UserInputService.InputEnded,function(input)
 if activeSlider and (input==sliderInput or input.UserInputType==Enum.UserInputType.MouseButton1) then activeSlider=nil;sliderInput=nil end
end)
connect(UserInputService.WindowFocusReleased,function() activeSlider=nil;sliderInput=nil end)
local function addControl(tab,kind,options)
 options=options or {}
 local originalTitle=options.Title or ""
 local title=displayNames[originalTitle] or originalTitle
 local height=(kind=="Section" and 30) or (kind=="Divider" and 4) or ((kind=="Input" or kind=="Dropdown" or kind=="Slider") and 92) or 64
 local b=button(scroll,kind.."_"..(#cards+1),4,4,566,height,11)
 local fill=gradient(b,{{0,"#4B1B50"},{.6,"#2A103F"},{1,"#5A2572"}},15)
 b.BackgroundTransparency=.01;b.BackgroundColor3=WHITE
 local edge=stroke(b,P.pearl,1,.6)
 local c={button=b,item={id=tostring(#cards+1),label=title,category=tab.id},originalTitle=originalTitle,kind=kind,options=options,edge=edge,fill=fill,y=4,height=height,hover=false,sweep=2,busy=false}
 cards[#cards+1]=c;b:SetAttribute("ControlType",kind);b:SetAttribute("OriginalTitle",originalTitle)
 local handle={};c.handle=handle
 if kind=="Divider" then
  b.BackgroundTransparency=1;edge.Transparency=1
  frame(b,"Rule",12,1,540,1,P.pearl,nil,6,.75)
 elseif kind=="Section" then
  b.BackgroundTransparency=1;edge.Transparency=1
  label(b,"SectionTitle",title,12,0,530,30,13,P.pearl,true)
 else
  local name=label(b,"FeatureName",title,16,0,kind=="Toggle" and 350 or 530,kind=="Toggle" and height or 40,16,P.white,true)
  name.TextTruncate=Enum.TextTruncate.AtEnd
  if kind=="Toggle" then
   c.value=options.Value==true
   c.state=label(b,"State","已关闭",382,0,82,height,12,P.pearl)
   c.track=frame(b,"Switch",482,19,50,26,"#5A3565",13,6)
   c.knob=frame(c.track,"Knob",3,3,20,20,P.white,10,7)
   syncToggle(c)
   connect(b.Activated,function()
    if not popup.Visible and not c.busy then c.value=not c.value;invoke(c,c.value) end
   end)
  elseif kind=="Button" then
   name.Size=UDim2.fromOffset(415,height)
   c.state=label(b,"State","执行 ›",452,0,102,height,13,P.pearl)
   connect(b.Activated,function()
    if popup.Visible then return end
    gui:SetAttribute("SelectedFeature",title);actionEvent:Fire(title);invoke(c)
   end)
  elseif kind=="Input" then
   local box=make("TextBox",{Name="Value",Position=UDim2.fromOffset(16,43),Size=UDim2.fromOffset(532,37),BackgroundColor3=rgb(P.base),BorderSizePixel=0,Text=tostring(options.Value or ""),PlaceholderText=options.Placeholder or "请输入",ClearTextOnFocus=options.ClearTextOnFocus==true,TextColor3=rgb(P.white),PlaceholderColor3=rgb(P.pearl),TextSize=26,Font=Enum.Font.Gotham,ZIndex=7},b)
   corner(box,7)
   connect(box.FocusLost,function() invoke(c,box.Text) end)
  elseif kind=="Dropdown" then
   c.values=table.clone(options.Values or {});c.value=options.Value
   c.valueLabel=label(b,"Value",c.value or "请选择",16,41,494,40,15,P.pearl)
   c.valueLabel.TextTruncate=Enum.TextTruncate.AtEnd
   label(b,"Arrow","⌄",520,41,26,40,20,P.pearl)
   function handle:Refresh(values,clear)
    c.values=table.clone(values or {})
    if clear or (c.value~=nil and not table.find(c.values,c.value)) then
     c.value=nil;c.valueLabel.Text="请选择";invoke(c,nil)
    end
    if popupOwner==c then drawOptions() end
   end
   connect(b.Activated,function() if not c.busy then openPopup(c) end end)
  elseif kind=="Slider" then
   local v=options.Value;c.value=v.Default
   name.Size=UDim2.fromOffset(440,40)
   c.valueLabel=label(b,"Value",tostring(c.value),480,0,70,40,16,P.pearl,true)
   c.slider=button(b,"Slider",20,45,526,34,0);c.slider.ZIndex=7
   local track=frame(c.slider,"Track",0,14,526,6,"#5A3565",3,7)
   c.fill=frame(track,"Fill",0,0,0,6,P.pink,3,8)
   local a=(c.value-v.Min)/math.max(1,v.Max-v.Min)
   c.fill.Size=UDim2.fromScale(a,1)
   c.thumb=frame(track,"Thumb",0,0,18,18,P.white,9,9);c.thumb.AnchorPoint=Vector2.new(.5,.5);c.thumb.Position=UDim2.fromScale(a,.5)
   connect(c.slider.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
     activeSlider=c;sliderInput=input;sliderAt(c,input.Position.X)
    end
   end)
  end
  connect(b.MouseEnter,function() tween(edge,{Transparency=.15},.16) end)
  connect(b.MouseLeave,function() tween(edge,{Transparency=(kind=="Toggle" and c.value) and .12 or .6},.16) end)
 end
 filterCards(false)
 return handle
end
local tabCount=0
function adapter:CreateWindow(options)
 shell.Title.Text="JBS 力量传奇"
 shell.Tribe.Text=""
 shell.Tribe.Visible=false
 return window
end
function window:Tab(options)
 tabCount=tabCount+1;local nav=scene.navigation[tabCount]
 assert(nav,"界面页面数量超出配置")
 local tab={id=nav.id}
 for _,kind in ipairs({"Input","Toggle","Button","Dropdown","Slider","Section","Divider"}) do
  tab[kind]=function(self,opts) return addControl(self,kind,opts) end
 end
 return tab
end
for i,m in ipairs(menuButtons) do
 connect(m.button.Activated,function()
  closePopup();activeSlider=nil;sliderInput=nil
  category=m.item.id;gui:SetAttribute("SelectedPage",category);pageTitle.Text=m.item.label
  tween(selection,{Position=UDim2.fromOffset(8,90+(i-1)*72)},.28)
  for _,other in ipairs(menuButtons) do other.title.TextColor3=rgb(other==m and P.white or P.pearl) end
  filterCards(true)
 end)
end
connect(search:GetPropertyChangedSignal("Text"),function() filterCards(true) end)
local function updatePlayerOptions()
 for _,c in ipairs(cards) do if c.kind=="Dropdown" and c.originalTitle=="送蛋目标" then refreshPlayerOptions(c) end end
end
connect(Players.PlayerAdded,updatePlayerOptions)
connect(Players.PlayerRemoving,function() task.defer(updatePlayerOptions) end)
connect(gui.Destroying,clearOptions)

local elapsed,acc=0,0
local visible=true
local animation
local function render(t,dt)
 local pointer=UserInputService:GetMouseLocation()
 local mx=math.clamp((pointer.X-content.AbsolutePosition.X)/math.max(1,content.AbsoluteSize.X),0,1)
 local angle=28+(mx-.5)*20
 contentMetal.Rotation=angle+math.sin(t*.3)*8
 contentMetal.Offset=Vector2.new(math.sin(t*.22)*.12,0)
 shellMetal.Rotation=30+math.sin(t*.25)*10
 rimGradient.Rotation=(t*40)%360
 rimGradient.Offset=Vector2.new(math.sin(t*.7)*.35,math.cos(t*.7)*.35)
 logoGradient.Offset=Vector2.new(math.sin(t*.8)*.65,0)
 sideLogoGradient.Offset=Vector2.new(math.sin(t*.5)*.45,0)
 for _,g in ipairs(glyphs) do
  local beam=(t/7.2%1)*(g.width+619*.52+330)-180
  local d=(g.x+g.y*(.48+(mx-.5)*.12))-beam
  local light=math.exp(-((d/63)^2))
  local narrow=math.exp(-((d/16)^2))
  g.object.TextTransparency=1-math.min(1,g.base+light*.3+narrow*.32)
  g.object.TextColor3= d<0 and rgb(P.pink):Lerp(WHITE,1-light*.35) or rgb(P.pearl):Lerp(WHITE,1-light*.4)
 end
 for _,s in ipairs(stars) do s.object.BackgroundTransparency=.35+.6*(.5+.5*math.sin(t*(.8+s.phase*.03)+s.phase)) end
 for _,c in ipairs(cards) do
  if c.sweep<1.2 and c.hover and c.button.Visible then c.sweep=c.sweep+dt*3;c.shine.Offset=Vector2.new(c.sweep,0) end
 end
 for _,c in ipairs(cards) do syncToggle(c) end
end
local function stop()
 if animation then animation:Disconnect();animation=nil end
 for t in pairs(tweens) do t:Cancel() end
 table.clear(tweens)
 for object in pairs(temporaries) do object:Destroy() end
 table.clear(temporaries)
 shell.Position=UDim2.fromOffset(0,0)
 list.Position=UDim2.fromOffset(22,116)
 for i,m in ipairs(menuButtons) do if m.item.id==category then selection.Position=UDim2.fromOffset(8,90+(i-1)*72) end end
 for _,c in ipairs(cards) do c.button.Position=UDim2.fromOffset(4,c.y) end
end
local function start()
 if animation or destroyed or not visible or not gui.Enabled then return end
 animation=RunService.RenderStepped:Connect(function(dt)
  acc=acc+dt
  if acc<1/30 then return end
  local step=acc;acc=0;elapsed=elapsed+step;render(elapsed,step)
 end)
end
local function reveal()
 visible=true;shell.Visible=true;restore.Visible=false;elapsed=0;acc=0
 for _,g in ipairs(glows) do g.object.Visible=true end
 shell.Position=UDim2.fromOffset(0,20)
 tween(shell,{Position=UDim2.fromOffset(0,0)},.7)
 list.Position=UDim2.fromOffset(22,128);tween(list,{Position=UDim2.fromOffset(22,116),},.5,.3)
 start()
end
local function hide()
 closePopup();activeSlider=nil;sliderInput=nil
 visible=false;stop();shell.Visible=false;restore.Visible=true;notice.Visible=false
 for _,g in ipairs(glows) do g.object.Visible=false end
end
connect(close.Activated,hide);connect(minimize.Activated,hide)
connect(restore.Activated,function() if restoreMoved then restoreMoved=false return end reveal() end) -- 拖动结束的释放不触发展开
connect(expand.Activated,function() expanded=not expanded;fit() end)
connect(gui:GetPropertyChangedSignal("Enabled"),function() if gui.Enabled then start() else stop() end end)
connect(UserInputService.WindowFocusReleased,stop)
connect(UserInputService.WindowFocused,start)
connect(shell:GetPropertyChangedSignal("Visible"),function() if shell.Visible and visible then start() else stop() end end)
connect(gui.Destroying,function()
 destroyed=true;stop()
 for _,c in ipairs(connections) do c:Disconnect() end
end)
local showEvent=make("BindableEvent",{Name="ShowWindow"},gui)
connect(showEvent.Event,reveal)
gui:SetAttribute("SelectedPage","main")
filterCards(false);render(0,0);reveal()

function adapter:Show() if not destroyed then reveal() end end
function adapter:Destroy() if not destroyed then gui:Destroy() end end
function adapter:IsAlive() return not destroyed and gui.Parent~=nil end
return adapter

end
function Library:CreateWindow(options)
 if instance and instance:IsAlive() then instance:Show();return window end
 if self.GameState=="running" or self.GameState=="failed" then error("JBS 界面已失效，请重新进入游戏，避免重复功能循环",0) end
 checkLegacy()
 local before=currentGui():FindFirstChild("JBS_Metal_v31")
 local ok,result=pcall(createRenderer)
 if not ok then
  local gui=currentGui():FindFirstChild("JBS_Metal_v31")
  if gui and gui~=before and gui:GetAttribute("JBSLibraryVersion")=="3.2" then gui:Destroy() end
  error(result,0)
 end
 instance=result
 window=instance:CreateWindow(options or {})
 for _,message in ipairs(self.PendingNotifications or {}) do instance:Notify(message) end
 self.PendingNotifications=nil
 return window
end
function Library:Notify(options)
 if instance and instance:IsAlive() then return instance:Notify(options) end
 self.PendingNotifications=self.PendingNotifications or {}
 self.PendingNotifications[#self.PendingNotifications+1]=options
end
function Library:Show()
 if instance and instance:IsAlive() then instance:Show() end
end
function Library:Destroy()
 assert(self.GameState=="idle","游戏功能仍属于当前会话，请重新进入游戏后换版；不能只销毁 UI 再重复初始化功能")
 if instance then instance:Destroy() end
 instance=nil;window=nil
end
function Library:BeginGame()
 if self.GameState=="running" then
  assert(instance and instance:IsAlive(),"JBS 界面已失效，请重新进入游戏，避免重复功能循环")
  self:Show();return false,"already-running"
 end
 if self.GameState=="starting" or self.GameState=="checking" then return false,"already-starting" end
 assert(self.GameState~="failed","JBS 上次启动未完成，请重新进入游戏后重试")
 -- Reserve before any WaitForChild yield to prevent two concurrent launchers.
 self.GameState="checking"
 local ok,err=pcall(function()
  -- Keep the old flag check active before the new game writes its own flags.
  local conflict=legacyConflict()
  if not conflict then
   for _,key in ipairs({"auto_train","auto_rebirth","auto_wheel","auto_petbuy","auto_packrebirth","auto_eategg","auto_fasttrain","auto_boss"}) do
    if rawget(_G,key)~=nil then conflict="旧版 JBS 功能状态";break end
   end
  end
  assert(not conflict,"检测到旧 JBS（"..tostring(conflict).."）。请重新进入游戏，仅运行新版启动文件。")
 end)
 if not ok then self.GameState="idle";error(err,0) end
 self.GameState="starting"
 return true
end
function Library:FinishGame(ok,err)
 self.GameState=ok and "running" or "failed"
 self.LastError=ok and nil or tostring(err)
end
environment[KEY]=Library
return Library

end
local function loadGame()
-- Game module v3.2: returns a function accepting JBS_UI; no UI/network loader here.
return function(WindUI)
 assert(type(WindUI)=="table" and WindUI.Version=="3.2" and type(WindUI.BeginGame)=="function","请传入 JBS_UI v3.2 库，不要再加载旧 WindUI")
 local proceed,reason=WindUI:BeginGame()
 if not proceed then return WindUI,reason end
 local function runOriginalGame()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- ==================== 原生通知（不依赖UI库） ====================
local function notify(title, text, dur)
        pcall(function()
                StarterGui:SetCore("SendNotification", {
                        Title = title,
                        Text = text,
                        Duration = dur or 5,
                })
        end)
end

-- ==================== 主保护 ====================
local okMain, errMain = pcall(function()

-- ==================== 游戏对象（带超时） ====================
local rEvents = ReplicatedStorage:WaitForChild("rEvents", 15)
local rebirthRemote = rEvents and rEvents:WaitForChild("rebirthRemote", 10) or nil
local muscleEvent = player:WaitForChild("muscleEvent", 10)
local leaderstats = player:WaitForChild("leaderstats", 10)
local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") or nil
local strengthStat = leaderstats and leaderstats:FindFirstChild("Strength") or nil

-- 重生需求力量计算（官方公式，用户提供）
local function calculateRequiredStrength()
        local stats = player:FindFirstChild("leaderstats")
        local rb = stats and stats:FindFirstChild("Rebirths")
        local rebirthCount = rb and rb.Value or 0
        local baseRequired = 10000 + 5000 * rebirthCount
        return math.max(1, math.floor(baseRequired * 0.5))
end

-- ==================== 重生请求：多协议自动试探引擎 ====================
-- 本游戏remote均为"字符串命令"协议(rep/openFortuneWheel/equipPet/punch等),
-- 重生的确切命令字串未知(原版"rebirthRequest"与无参调用均无效),
-- 故轮换尝试多种命令与通道,命中(重生数+1)即锁定,之后每次重生直接复用
local rebirthCallVariants = {
        { "rebirthRemote", "rebirthRequest" },
        { "rebirthRemote", "rebirth" },
        { "rebirthRemote" },
        { "rebirthRemote", "Rebirth" },
        { "rebirthRemote", "buyRebirth" },
        { "rebirthRemote", "requestRebirth" },
        { "rebirthRemote", "doRebirth" },
        { "muscleEvent", "rebirth" },
        { "muscleEvent", "rebirthRequest" },
}
local rebirthVariantIndex = 1
local rebirthVariantLocked = false

local function fireRebirthAttempt()
        local v = rebirthCallVariants[rebirthVariantIndex]
        local remote = (v[1] == "rebirthRemote") and rebirthRemote or muscleEvent
        if not remote then return end
        if remote:IsA("RemoteFunction") then
                pcall(function()
                        if #v >= 2 then remote:InvokeServer(v[2]) else remote:InvokeServer() end
                end)
        else
                pcall(function()
                        if #v >= 2 then remote:FireServer(v[2]) else remote:FireServer() end
                end)
        end
end

local function advanceRebirthVariant()
        if rebirthVariantLocked then return end
        rebirthVariantIndex = (rebirthVariantIndex % #rebirthCallVariants) + 1
end

local function lockRebirthVariant()
        rebirthVariantLocked = true
end

local function unlockRebirthVariant()
        rebirthVariantLocked = false
end

-- 宠物商店对象：rEvents.cPetShopRemote + shared.runtime.cPetShopFolder
local cPetShopRemote = rEvents and rEvents:FindFirstChild("cPetShopRemote", 3)
local sharedFolder = ReplicatedStorage:FindFirstChild("shared", 5)
local runtimeFolder = sharedFolder and sharedFolder:FindFirstChild("runtime", 5)
local cPetShopFolder = runtimeFolder and runtimeFolder:FindFirstChild("cPetShopFolder", 5)

task.spawn(function()
        task.wait(0.5)
        local missing = {}
        if not rEvents then table.insert(missing, "rEvents") end
        if not rebirthRemote then table.insert(missing, "rebirthRemote") end
        if not muscleEvent then table.insert(missing, "muscleEvent") end
        if not cPetShopRemote or not cPetShopFolder then table.insert(missing, "宠物商店") end
        if #missing > 0 then
                WindUI:Notify({
                        Title = "部分功能不可用",
                        Content = "未找到: " .. table.concat(missing, ", "),
                        Duration = 8,
                })
        end
end)

-- ==================== 状态 ====================
_G.auto_train = false    -- 自动锻炼
_G.auto_rebirth = false  -- 自动重生
_G.auto_wheel = false    -- 自动轮盘
_G.auto_petbuy = false   -- 自动买宠物
_G.auto_packrebirth = false -- 换包重生
_G.auto_eategg = false    -- 自动吃蛋
_G.auto_fasttrain = false  -- 快速锻炼(极速自适应)
_G.auto_boss = false     -- 自动打Boss
local rbTarget = 0       -- 重生目标次数(0=无限)
local giftAmount = 0     -- 送蛋数量(0=全部)

local trainThread, rebirthThread, wheelThread, petbuyThread
local packrebirthThread
local eateggThread
local fasttrainThread
local bossHoverConn    -- Boss心跳循环连接(自动击杀版)

local function stop(t)
        if t then
                pcall(function() task.cancel(t) end)
        end
end

-- ==================== 反挂机（双保险） ====================
player.Idled:Connect(function()
        -- 方式1：按键模拟(部分执行器上更稳)
        pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
        end)
        -- 方式2：鼠标模拟
        pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
end)

-- ==================== 窗口 ====================
local Window = WindUI:CreateWindow({
        Title = "JBS 力量传奇",
        Author = "v3.1",
        Folder = "JBS_V3",
        Icon = "sparkles",
        IconThemed = true,
        Theme = "Midnight",
        Size = UDim2.fromOffset(560, 400),
        Transparent = false,
        Acrylic = false,
        SideBarWidth = 200,
        ScrollBarEnabled = true,
        HideSearchBar = false,
        Resizable = true,
})

local MainTab = Window:Tab({ Title = "主要", Icon = "zap", ShowTabTitle = true })
local TeleportTab = Window:Tab({ Title = "传送", Icon = "map-pin", ShowTabTitle = true })
local PetTab = Window:Tab({ Title = "宠物", Icon = "cat", ShowTabTitle = true })
local BossTab = Window:Tab({ Title = "Boss", Icon = "skull", ShowTabTitle = true })
local PackTab = Window:Tab({ Title = "换包重生", Icon = "refresh", ShowTabTitle = true })

-- ==================== 功能：自动锻炼 ====================
local function autoTrainLoop()
        while _G.auto_train do
                pcall(function()
                        muscleEvent:FireServer("rep")
                end)
                task.wait(0.1)
        end
end

-- ==================== 功能：自动重生（可设目标次数） ====================
local function autoRebirthLoop()
        while _G.auto_rebirth do
                pcall(function()
                        -- 达到目标次数自动停止
                        if rbTarget > 0 and rebirths and rebirths.Value >= rbTarget then
                                _G.auto_rebirth = false
                                WindUI:Notify({
                                        Title = "重生完成",
                                        Content = "已达到目标次数 " .. rbTarget .. "，自动重生已停止",
                                        Duration = 4,
                                })
                                return
                        end
                        if rebirthRemote then
                                -- 公式门控：力量达到重生需求才发请求
                                local canRebirth = true
                                if strengthStat and rebirths then
                                        canRebirth = strengthStat.Value >= calculateRequiredStrength()
                                end
                                if canRebirth then
                                        local before = rebirths and rebirths.Value or 0
                                        fireRebirthAttempt()
                                        task.wait(0.2)
                                        if rebirths and rebirths.Value > before then
                                                lockRebirthVariant()  -- 命中,锁定这种调用方式
                                        else
                                                advanceRebirthVariant()
                                        end
                                end
                        end
                end)
                task.wait(0.5)
        end
end

-- ==================== 功能：自动轮盘（幸运抽奖） ====================
local function autoWheelLoop()
        while _G.auto_wheel do
                pcall(function()
                        local remote = rEvents and rEvents:FindFirstChild("openFortuneWheelRemote")
                        local shared = ReplicatedStorage:FindFirstChild("shared")
                        local catalogs = shared and shared:FindFirstChild("catalogs")
                        local wheelChances = catalogs and catalogs:FindFirstChild("fortuneWheelChances")
                        local wheel = wheelChances and wheelChances:FindFirstChild("Fortune Wheel")
                        if remote and wheel then
                                if remote:IsA("RemoteFunction") then
                                        remote:InvokeServer("openFortuneWheel", wheel)
                                else
                                        remote:FireServer("openFortuneWheel", wheel)
                                end
                        end
                end)
                task.wait(1)
        end
end

-- ==================== 功能：买宠物 ====================
-- 购买：cPetShopFolder:FindFirstChild(宠物名) -> cPetShopRemote:InvokeServer(宠物对象)
-- 反编译把参数丢成了FindFirstChild(nil)，此处用下拉选择的名字重建

-- 内置宠物/光环列表（动态读取失败时的兜底）
local FALLBACK_PETS = {
        "不稳定幻影", "以太仙灵小兔", "伏特爪", "冰波传奇企鹅", "反应堆兽",
        "地狱火", "地狱火龙", "大超新星", "幻影创世龙", "星界电光",
        "暗星猎人", "核心小狗", "橙色刺猬", "橙色飞马", "永恒巨型攻击",
        "永恒打击利维坦", "熵爆炸", "电光", "白色凤凰", "白色飞马",
        "等离子掠夺者", "紫色光环", "紫色新环", "紫色猎鹰", "紫色龙",
        "红色光环", "红色小猫", "红色火龙", "红色释火者", "终极超新星飞马",
        "绿色光环", "绿色蝴蝶", "绿色释火者", "肌肉之王", "肌肉老师",
        "能量闪电", "蓝色光环", "蓝色凤凰", "顶峰霸主", "魔法蝴蝶",
        "黄色光环", "黄色蝴蝶", "黄金维金人", "黑暗德古拉", "黑暗电光",
        "黑暗蝎尾怪传奇", "黑暗闪电", "黑暗风暴", "黑暗魔像",
}

-- 动态获取商店宠物列表（优先游戏内实时列表，失败回退内置列表）
local function getPetShopList()
        local names = {}
        pcall(function()
                local shared = ReplicatedStorage:FindFirstChild("shared")
                local runtime = shared and shared:FindFirstChild("runtime")
                local folder = runtime and runtime:FindFirstChild("cPetShopFolder")
                if folder then
                        for _, item in ipairs(folder:GetChildren()) do
                                table.insert(names, item.Name)
                        end
                end
        end)
        if #names == 0 then
                names = FALLBACK_PETS
        end
        table.sort(names)
        return names
end

-- 购买一只宠物，返回 成功标志, 提示信息
local function buyPet(name)
        if not cPetShopRemote or not cPetShopFolder then
                return false, "未找到宠物商店对象(游戏可能未加载完)"
        end
        if not name or name == "" then
                return false, "请先选择宠物"
        end
        local pet = cPetShopFolder:FindFirstChild(name)
        if not pet then
                return false, "商店里没有: " .. name
        end
        if cPetShopRemote:IsA("RemoteFunction") then
                cPetShopRemote:InvokeServer(pet)
        else
                cPetShopRemote:FireServer(pet)
        end
        return true, "已购买: " .. name
end

-- 自动购买循环（每0.5秒一次）
local selectedPet = ""
local function autoPetBuyLoop()
        while _G.auto_petbuy do
                pcall(function()
                        if selectedPet ~= "" then
                                buyPet(selectedPet)
                        end
                end)
                task.wait(0.5)
        end
end

-- ==================== 功能：自动打Boss（林玉自动击杀版，替换原多Boss轮换版） ====================
-- 机制：锁定Boss判定箱(BossDamageHitbox) -> 头顶绕圈贴脸输出
--       工具拳 + 双手firetouchinterest + muscleEvent三路齐发
--       自动维持体格 -> Boss死后传送到宝箱自动开 -> 等下一轮刷新
local bossHeight = 65      -- 头顶高度(判定箱上方格数)
local bossOrbitRadius = 5  -- 绕圈半径
local bossOrbitSpeed = 30  -- 绕圈速度(越大越快)
local bossTilt = true      -- 身体倾斜朝Boss
local bossPunchRate = 120  -- 每秒出拳次数(拉满)
local bossSizeVal = 2      -- 挂机期间保持的体格
local hitbox = nil         -- 当前锁定的Boss判定箱

-- 玩家muscleEvent(带回退重找)
local function getMuscleEvent()
        return muscleEvent or player:FindFirstChild("muscleEvent")
end

-- 触发附近交互(开宝箱/领奖励用)
local function interactNearby(myPos)
        local count = 0
        for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled then
                        local p = d.Parent
                        local pos = nil
                        if p then
                                if p:IsA("BasePart") then
                                        pos = p.Position
                                elseif p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then
                                        pos = p.Parent.Position
                                elseif p:IsA("Model") then
                                        pos = p:GetPivot().Position
                                end
                        end
                        if pos and (pos - myPos).Magnitude <= 25 then
                                pcall(fireproximityprompt, d)
                                count = count + 1
                        end
                end
        end
        return count
end

-- 销毁全图传送门(防止打Boss时被吸走)
local function destroyPortals()
        pcall(function()
                for _, obj in ipairs(game:GetDescendants()) do
                        if obj.Name == "RobloxForwardPortals" then
                                obj:Destroy()
                        end
                end
        end)
end

-- 刷新Boss判定箱：竞技场内任意含"Boss"名字的文件夹下的BossDamageHitbox
local function refreshHitbox()
        hitbox = nil
        local ev = workspace:FindFirstChild("Events")
        local arena = ev and ev:FindFirstChild("BossArena")
        if not arena then return end
        for _, f in ipairs(arena:GetChildren()) do
                if f.Name:find("Boss") then
                        local br = f:FindFirstChild("BossDamageHitbox", true)
                        if br and br.Parent then
                                hitbox = br
                                return
                        end
                end
        end
end

-- 找Boss宝箱
local function findChest()
        local chest = workspace:FindFirstChild("BossChest")
        if not chest then return nil end
        local base = chest:FindFirstChild("CommonChest_Base", true)
        if not base then
                for _, d in ipairs(chest:GetDescendants()) do
                        if d:IsA("BasePart") then
                                base = d
                                break
                        end
                end
        end
        return base
end

-- 主循环：心跳驱动(开启时连接，关闭时断开)
local function startBossLoop()
        local me = getMuscleEvent()
        local sr = rEvents and rEvents:FindFirstChild("changeSpeedSizeRemote")
        local ang = 0
        local lastSz = 0
        local cacheT = 0
        local punchAcc = 0
        local lastPrompt = 0
        local promptCount = 0

        bossHoverConn = RunService.Heartbeat:Connect(function(dt)
                if not _G.auto_boss then return end

                local ch = player.Character
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if not root or not hum or hum.Health <= 0 then return end

                local t = tick()
                if t - lastSz >= 1 then
                        lastSz = t
                        task.spawn(function()
                                if sr then pcall(function() sr:InvokeServer("changeSize", bossSizeVal) end) end
                        end)
                end

                -- 判定箱销毁立即清引用，每0.5秒重新扫描
                if hitbox and not hitbox.Parent then
                        hitbox = nil
                end
                if t - cacheT >= 0.5 or not hitbox then
                        cacheT = t
                        task.spawn(refreshHitbox)
                end

                local tool = ch:FindFirstChild("Punch")

                if tool and hitbox and hitbox.Parent then
                        -- Boss战：头顶绕圈贴脸输出
                        promptCount = 0
                        local bp = hitbox.Position
                        hum.PlatformStand = true
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        ang = (ang + bossOrbitSpeed * dt) % (math.pi * 2)
                        local sp = Vector3.new(bp.X + math.cos(ang) * bossOrbitRadius, bp.Y + bossHeight, bp.Z + math.sin(ang) * bossOrbitRadius)
                        root.CFrame = bossTilt and CFrame.lookAt(sp, Vector3.new(bp.X, sp.Y, bp.Z)) or CFrame.new(sp)
                        pcall(function() tool:Activate() end)
                        local lh = ch:FindFirstChild("LeftHand")
                        local rh = ch:FindFirstChild("RightHand")
                        if lh then
                                pcall(firetouchinterest, hitbox, lh, 0)
                                pcall(firetouchinterest, hitbox, lh, 1)
                        end
                        if rh then
                                pcall(firetouchinterest, hitbox, rh, 0)
                                pcall(firetouchinterest, hitbox, rh, 1)
                        end
                        punchAcc = math.min(punchAcc + bossPunchRate * dt, bossPunchRate)
                        while punchAcc >= 1 do
                                punchAcc = punchAcc - 1
                                if me then
                                        me:FireServer("punch", "leftHand")
                                        me:FireServer("punch", "rightHand")
                                end
                        end
                else
                        -- Boss没了：维持体形、补装备、传送宝箱开箱
                        hum.PlatformStand = true
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        if not tool then
                                local bp2 = player:FindFirstChild("Backpack")
                                local pk = bp2 and bp2:FindFirstChild("Punch")
                                if pk then
                                        pcall(function() hum:EquipTool(pk) end)
                                end
                        end
                        local base = findChest()
                        if base then
                                local cpos = base:IsA("BasePart") and base.Position or base:GetPivot().Position
                                root.CFrame = CFrame.new(cpos.X, cpos.Y + 3, cpos.Z)
                                if promptCount < 10 and t - lastPrompt >= 0.3 then
                                        lastPrompt = t
                                        promptCount = promptCount + 1
                                        interactNearby(root.Position)
                                end
                        end
                end
        end)
end


-- ==================== 功能：换包重生 ====================
-- 练力量时穿练速装，重生前换重生倍率装，轮回不停
local PETS = {
        ["Omega Overlord"]      = { repSpeed = 20, strength = 0,  durability = 0,  rebirth = 0 },
        ["Swift Samurai"]       = { repSpeed = 15, strength = 0,  durability = 0,  rebirth = 0 },
        ["Powercore Hound"]     = { repSpeed = 0,  strength = 25, durability = 15, rebirth = 0 },
        ["Titanium Hydra"]      = { repSpeed = 0,  strength = 0,  durability = 0,  rebirth = 2 },
        ["Tribal Overlord"]     = { repSpeed = 0,  strength = 0,  durability = 0,  rebirth = 2 },
        ["Inferno Unicorn"]     = { repSpeed = 0,  strength = 25, durability = 25, rebirth = 0 },
        ["Common Boss Pet"]     = { repSpeed = 5,  strength = 0,  durability = 0,  rebirth = 0 },
        ["Rare Boss Pet"]       = { repSpeed = 7,  strength = 0,  durability = 0,  rebirth = 0 },
        ["Epic Boss Pet"]       = { repSpeed = 10, strength = 0,  durability = 0,  rebirth = 0 },
        ["Rainbow Boss Pet"]    = { repSpeed = 10, strength = 7,  durability = 0,  rebirth = 0 },
        ["Legendary Boss Pet"]  = { repSpeed = 10, strength = 10, durability = 0,  rebirth = 0 },
        ["Mythic Boss Pet"]     = { repSpeed = 10, strength = 20, durability = 0,  rebirth = 0 },
        ["Inferno Drake"]       = { repSpeed = 40, strength = 0,  durability = 0,  rebirth = 0 },
}
local MAX_PET_SLOTS = 12    -- 宠物栏上限
local TARGET_REP_SPEED = 100 -- 练速目标
local trainRate = 1200      -- 自适应锻炼速率(极速版600~2400，起步即满速)

-- 卸下全部宠物
local function unequipAllPets()
        local petsFolder = player:FindFirstChild("petsFolder")
        if not petsFolder then return end
        for _, folder in ipairs(petsFolder:GetChildren()) do
                if folder:IsA("Folder") then
                        for _, pet in ipairs(folder:GetChildren()) do
                                local equipRemote = rEvents and rEvents:FindFirstChild("equipPetEvent")
                                if equipRemote then
                                        equipRemote:FireServer("unequipPet", pet)
                                end
                        end
                end
        end
        task.wait(0.1)
end

-- 装备单个宠物
local function equipOnePet(pet)
        local equipRemote = rEvents and rEvents:FindFirstChild("equipPetEvent")
        if equipRemote then
                equipRemote:FireServer("equipPet", pet)
        end
end

-- 扫描仓库里所有在数值表里的宠物
local function getOwnedPets()
        local owned = {}
        local petsFolder = player:FindFirstChild("petsFolder")
        if not petsFolder then return owned end
        for _, folder in ipairs(petsFolder:GetChildren()) do
                if folder:IsA("Folder") then
                        for _, pet in ipairs(folder:GetChildren()) do
                                local cfg = PETS[pet.Name]
                                if cfg then
                                        table.insert(owned, {
                                                instance = pet,
                                                name = pet.Name,
                                                repSpeed = cfg.repSpeed or 0,
                                                strength = cfg.strength or 0,
                                                durability = cfg.durability or 0,
                                                rebirth = cfg.rebirth or 0,
                                        })
                                end
                        end
                end
        end
        return owned
end

-- 练速装：先凑repSpeed到100%，剩余格子补力量/耐力
local function equipFarmingPets()
        unequipAllPets()
        local pets = getOwnedPets()
        local equipped, count, repSpeed = {}, 0, 0
        table.sort(pets, function(a, b) return a.repSpeed > b.repSpeed end)
        for _, pet in ipairs(pets) do
                if count >= MAX_PET_SLOTS or repSpeed >= TARGET_REP_SPEED then break end
                if pet.repSpeed > 0 then
                        equipOnePet(pet.instance)
                        equipped[pet.instance] = true
                        count = count + 1
                        repSpeed = repSpeed + pet.repSpeed
                end
        end
        local rest = {}
        for _, pet in ipairs(pets) do
                if not equipped[pet.instance] then table.insert(rest, pet) end
        end
        table.sort(rest, function(a, b)
                return (a.strength + a.durability) > (b.strength + b.durability)
        end)
        for _, pet in ipairs(rest) do
                if count >= MAX_PET_SLOTS then break end
                if pet.strength > 0 or pet.durability > 0 then
                        equipOnePet(pet.instance)
                        equipped[pet.instance] = true
                        count = count + 1
                end
        end
        return repSpeed, count
end

-- 重生装：按重生倍率降序装满
local function equipRebirthPets()
        unequipAllPets()
        local pets = getOwnedPets()
        table.sort(pets, function(a, b) return a.rebirth > b.rebirth end)
        local count, totalMultiplier = 0, 0
        for _, pet in ipairs(pets) do
                if count >= MAX_PET_SLOTS then break end
                if pet.rebirth > 0 then
                        equipOnePet(pet.instance)
                        count = count + 1
                        totalMultiplier = totalMultiplier + pet.rebirth
                end
        end
        return totalMultiplier, count
end

-- 一次完整重生：练满 → 换重生装 → 确认+1
-- 目标值=官方公式 calculateRequiredStrength()；附带卡上限检测与失败收敛兜底
local function performPackRebirth()
        local strengthTarget = calculateRequiredStrength()
        while _G.auto_packrebirth do
                -- 阶段1：练力量到目标（或力量停涨=疑似到装备上限，提前尝试）
                local lastStr = strengthStat.Value
                local stallCount = 0
                local stallTimer = 0
                while _G.auto_packrebirth and strengthStat.Value < strengthTarget do
                        pcall(function()
                                local burst = 13  -- 固定:等同快速锻炼原始速度(约1250次/秒;本循环0.01s/轮,50次/0.04s÷4≈13)
                                for _ = 1, burst do
                                        muscleEvent:FireServer("rep")
                                end
                        end)
                        task.wait(0.01)
                        local cur = strengthStat.Value
                        if cur > lastStr then
                                stallCount = 0
                                stallTimer = 0
                                trainRate = math.min(2400, trainRate + 40)
                        else
                                stallCount = stallCount + 1
                                if stallCount >= 3 then
                                        trainRate = math.max(600, trainRate - 80)
                                        stallCount = 0
                                end
                                stallTimer = stallTimer + 0.01
                                if stallTimer >= 8 then break end -- 连续8秒力量无增长：提前去尝试重生
                        end
                        lastStr = cur
                end
                if not _G.auto_packrebirth then return end
                -- 阶段2：换重生倍率装 → 轮换试探重生调用（15秒窗口，命中即锁定）
                equipRebirthPets()
                task.wait(0.25)
                local before = rebirths.Value
                local deadline = tick() + 15
                while _G.auto_packrebirth and tick() < deadline do
                        fireRebirthAttempt()
                        task.wait(0.35)
                        if rebirths.Value > before then
                                lockRebirthVariant()
                                return  -- 重生成功
                        end
                        advanceRebirthVariant()
                end
                if not _G.auto_packrebirth then return end
                -- 阶段3：调用未生效 → 解除锁定下轮重扫,换回练速装,目标上调15%逼近真实门槛
                unlockRebirthVariant()
                equipFarmingPets()
                strengthTarget = math.floor(strengthStat.Value * 1.15) + 1000
                WindUI:Notify({ Title = "换包重生", Content = "重生请求未生效（已轮试全部调用方式），已抬高目标继续", Duration = 4 })
                task.wait(0.25)
        end
end

-- 工作循环
local function autoPackRebirthLoop()
        while _G.auto_packrebirth do
                equipFarmingPets()
                performPackRebirth()
                task.wait(0.5)
        end
end

-- ==================== 功能：快速锻炼（自适应速率） ====================
local function adaptiveTrainLoop()
        local lastStr = (strengthStat and strengthStat.Value) or 0
        local stallCount = 0
        while _G.auto_fasttrain do
                pcall(function()
                        local burst = math.clamp(math.floor(trainRate / 10), 5, 50)
                        for _ = 1, burst do
                                muscleEvent:FireServer("rep")
                        end
                end)
                if strengthStat then
                        local cur = strengthStat.Value
                        if cur > lastStr then
                                stallCount = 0
                                trainRate = math.min(2400, trainRate + 40)
                        else
                                stallCount = stallCount + 1
                                if stallCount >= 3 then
                                        trainRate = math.max(600, trainRate - 80)
                                        stallCount = 0
                                end
                        end
                        lastStr = cur
                end
                task.wait(0.04)
        end
end

-- ==================== 功能：吃蛋 / 送蛋 ====================
-- 找蛋白蛋(角色或背包)
local function findProteinEgg()
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        return (char and char:FindFirstChild("Protein Egg"))
                or (backpack and backpack:FindFirstChild("Protein Egg"))
end

-- 吃一发蛋(双倍力量buff)
local function eatOneEgg()
        local egg = findProteinEgg()
        if egg then
                muscleEvent:FireServer("proteinEgg", egg)
                return true
        end
        return false
end

-- 自动吃蛋循环: 每0.5秒扫一次，找到就10连吃
local function autoEatEggLoop()
        while _G.auto_eategg do
                pcall(function()
                        if findProteinEgg() then
                                for _ = 1, 10 do
                                        eatOneEgg()
                                end
                        end
                end)
                task.wait(0.5)
        end
end

-- 送蛋: 把仓库里的蛋送给目标玩家，返回实送数量
local function giftEggsTo(targetPlayer, amount)
        local sent = 0
        local giftRemote = rEvents and rEvents:FindFirstChild("giftRemote")
        local folder = player:FindFirstChild("consumablesFolder")
        if not (giftRemote and folder and targetPlayer) then
                return sent
        end
        for _ = 1, amount do
                local egg = folder:FindFirstChild("Protein Egg")
                if not egg then break end
                local ok = pcall(function()
                        giftRemote:InvokeServer("giftRequest", targetPlayer, egg)
                end)
                if ok then
                        sent = sent + 1
                end
                task.wait(0.1)
        end
        return sent
end

-- 换包重生页玩家列表(送蛋下拉用)
local function getPackPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                        table.insert(names, p.Name)
                end
        end
        return names
end

-- ==================== 主要页 ====================
MainTab:Input({
        Title = "目标次数",
        Placeholder = "重生目标，0为无限",
        Value = "",
        ClearTextOnFocus = false,
        Callback = function(v)
                rbTarget = tonumber(v) or 0
        end
})

MainTab:Toggle({
        Title = "自动重生",
        Value = false,
        Callback = function(state)
                _G.auto_rebirth = state
                stop(rebirthThread)
                if state then
                        rebirthThread = task.spawn(autoRebirthLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动重生已开启" .. (rbTarget > 0 and ("，目标: " .. rbTarget .. "次") or "，无限"), Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动重生已关闭", Duration = 2 })
                end
        end
})

MainTab:Divider()

MainTab:Toggle({
        Title = "自动锻炼",
        Value = false,
        Callback = function(state)
                _G.auto_train = state
                stop(trainThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_train = false
                                return
                        end
                        trainThread = task.spawn(autoTrainLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动锻炼已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动锻炼已关闭", Duration = 2 })
                end
        end
})

MainTab:Divider()

-- ==================== 自动轮盘 ====================
MainTab:Toggle({
        Title = "自动轮盘",
        Value = false,
        Callback = function(state)
                _G.auto_wheel = state
                stop(wheelThread)
                if state then
                        wheelThread = task.spawn(autoWheelLoop)
                        WindUI:Notify({ Title = "已开启", Content = "自动轮盘已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "自动轮盘已关闭", Duration = 2 })
                end
        end
})

-- ==================== 传送区域 ====================
local TELEPORTS = {
        { name = "大厅", pos = Vector3.new(-0.75, 90.61, 242.78) },
        { name = "小岛", pos = Vector3.new(-32.14, 8.51, 1904.41) },
        { name = "冰霜健身房", pos = Vector3.new(-2623.41, 6.99, -409.34) },
        { name = "神话健身房", pos = Vector3.new(2250.39, 6.99, 1072.77) },
        { name = "永恒健身房", pos = Vector3.new(-6758.39, 6.99, -1284.45) },
        { name = "传奇健身房", pos = Vector3.new(4603.40, 990.99, -3897.44) },
        { name = "肌肉之王健身房", pos = Vector3.new(-8625.40, 16.99, -5730.41) },
        { name = "丛林健身房", pos = Vector3.new(-8685.01, 5.99, 2392.06) },
        { name = "工业健身房", pos = Vector3.new(-5496.68, 59.04, 4927.74) },
        { name = "超载健身房", pos = Vector3.new(-3045.30, 165.41, 4990.69) },
        { name = "无转盘岛", pos = Vector3.new(1952.09, 1, 6179.98) },
        { name = "熔岩争斗", pos = Vector3.new(4472.53, 118.90, -8848.54) },
        { name = "沙漠争斗", pos = Vector3.new(973.62, 15.92, -7277.01) },
        { name = "海滩争斗", pos = Vector3.new(-1880.89, 15.87, -6137.75) },
}

local function teleportTo(pos)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                return true
        end
        return false
end

for _, tp in ipairs(TELEPORTS) do
        TeleportTab:Button({
                Title = tp.name,
                Callback = function()
                        if teleportTo(tp.pos) then
                                WindUI:Notify({ Title = "传送", Content = "已传送到: " .. tp.name, Duration = 2 })
                        else
                                WindUI:Notify({ Title = "传送失败", Content = "未找到角色", Duration = 2 })
                        end
                end
        })
end

-- ==================== 宠物页 ====================
PetTab:Section({ Title = "宠物商店购买" })

local PetDropdown = PetTab:Dropdown({
        Title = "选择宠物/光环",
        Values = getPetShopList(),
        AllowNone = true,
        Callback = function(v)
                selectedPet = v or ""
        end,
})

PetTab:Button({
        Title = "刷新宠物列表",
        Callback = function()
                local list = getPetShopList()
                PetDropdown:Refresh(list, true)
                WindUI:Notify({ Title = "宠物商店", Content = "已刷新，共" .. #list .. "项", Duration = 2 })
        end,
})

PetTab:Button({
        Title = "购买一次",
        Color = Color3.fromHex("#00BFFF"),
        Callback = function()
                local ok, msg = buyPet(selectedPet)
                if ok then
                        WindUI:Notify({ Title = "宠物商店", Content = msg, Duration = 3 })
                else
                        WindUI:Notify({ Title = "宠物商店", Content = msg, Duration = 4 })
                end
        end
})

PetTab:Toggle({
        Title = "自动购买",
        Value = false,
        Callback = function(state)
                _G.auto_petbuy = state
                stop(petbuyThread)
                if state then
                        if selectedPet == "" then
                                WindUI:Notify({ Title = "宠物商店", Content = "请先选择宠物", Duration = 3 })
                                _G.auto_petbuy = false
                                return
                        end
                        petbuyThread = task.spawn(autoPetBuyLoop)
                        WindUI:Notify({ Title = "宠物商店", Content = "自动购买已开启: " .. selectedPet, Duration = 3 })
                else
                        WindUI:Notify({ Title = "宠物商店", Content = "自动购买已关闭", Duration = 2 })
                end
        end
})

-- ==================== Boss页 ====================
BossTab:Toggle({
        Title = "自动打Boss",
        Value = false,
        Color = Color3.fromHex("#FF4040"),
        Callback = function(state)
                _G.auto_boss = state
                if bossHoverConn then
                        pcall(function() bossHoverConn:Disconnect() end)
                        bossHoverConn = nil
                end
                if state then
                        if not getMuscleEvent() then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_boss = false
                                return
                        end
                        if not (rEvents and rEvents:FindFirstChild("changeSpeedSizeRemote")) then
                                WindUI:Notify({ Title = "提示", Content = "未找到changeSpeedSizeRemote，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_boss = false
                                return
                        end
                        destroyPortals()
                        startBossLoop()
                        WindUI:Notify({ Title = "Boss", Content = "自动击杀Boss已开启", Duration = 3 })
                else
                        hitbox = nil
                        local ch = player.Character
                        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                        if hum then hum.PlatformStand = false end
                        WindUI:Notify({ Title = "Boss", Content = "已关闭", Duration = 2 })
                end
        end,
})

-- ==================== 换包重生页 ====================
PackTab:Section({ Title = "换包重生" })

PackTab:Toggle({
        Title = "换包重生",
        Value = false,
        Color = Color3.fromHex("#9B59B6"),
        Callback = function(state)
                _G.auto_packrebirth = state
                stop(packrebirthThread)
                if state then
                        if not (muscleEvent and rebirthRemote and rebirths and strengthStat) then
                                WindUI:Notify({ Title = "提示", Content = "未找到游戏事件，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_packrebirth = false
                                return
                        end
                        packrebirthThread = task.spawn(autoPackRebirthLoop)
                        WindUI:Notify({ Title = "换包重生", Content = "已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "换包重生", Content = "已关闭", Duration = 2 })
                end
        end,
})

PackTab:Divider()

PackTab:Toggle({
        Title = "快速锻炼",
        Value = false,
        Color = Color3.fromHex("#00BFFF"),
        Callback = function(state)
                _G.auto_fasttrain = state
                stop(fasttrainThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_fasttrain = false
                                return
                        end
                        trainRate = 1200
                        fasttrainThread = task.spawn(adaptiveTrainLoop)
                        WindUI:Notify({ Title = "已开启", Content = "快速锻炼已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "已关闭", Content = "快速锻炼已关闭", Duration = 2 })
                end
        end,
})

PackTab:Divider()

PackTab:Section({ Title = "蛋白蛋" })

PackTab:Toggle({
        Title = "自动吃蛋",
        Value = false,
        Color = Color3.fromHex("#F39C12"),
        Callback = function(state)
                _G.auto_eategg = state
                stop(eateggThread)
                if state then
                        if not muscleEvent then
                                WindUI:Notify({ Title = "提示", Content = "未找到muscleEvent，请等待游戏加载后重试", Duration = 4 })
                                _G.auto_eategg = false
                                return
                        end
                        eateggThread = task.spawn(autoEatEggLoop)
                        WindUI:Notify({ Title = "自动吃蛋", Content = "已开启", Duration = 2 })
                else
                        WindUI:Notify({ Title = "自动吃蛋", Content = "已关闭", Duration = 2 })
                end
        end,
})

local selectedEggTarget = ""
local EggPlayerDropdown = PackTab:Dropdown({
        Title = "送蛋目标",
        Values = getPackPlayerNames(),
        AllowNone = true,
        Callback = function(v)
                selectedEggTarget = v or ""
        end,
})

PackTab:Input({
        Title = "送蛋数量",
        Placeholder = "0为全部",
        Value = "",
        ClearTextOnFocus = false,
        Callback = function(v)
                giftAmount = tonumber(v) or 0
        end,
})

PackTab:Button({
        Title = "送蛋",
        Color = Color3.fromHex("#2ECC71"),
        Callback = function()
                local target = Players:FindFirstChild(selectedEggTarget)
                if selectedEggTarget == "" or not target then
                        WindUI:Notify({ Title = "送蛋", Content = "请先选择玩家", Duration = 3 })
                        return
                end
                local folder = player:FindFirstChild("consumablesFolder")
                local have = folder and #folder:GetChildren() or 0
                if have == 0 then
                        WindUI:Notify({ Title = "送蛋", Content = "仓库里没有蛋", Duration = 3 })
                        return
                end
                local amount = giftAmount > 0 and giftAmount or 9999
                task.spawn(function()
                        local sent = giftEggsTo(target, amount)
                        WindUI:Notify({ Title = "送蛋", Content = "已送给 " .. selectedEggTarget .. " " .. sent .. " 个蛋", Duration = 3 })
                        EggPlayerDropdown:Refresh(getPackPlayerNames(), true)
                end)
        end,
})

-- ==================== 启动 ====================
task.wait(0.3)
WindUI:Notify({
        Title = "脚本加载完成",
        Content = (muscleEvent and rebirthRemote) and "欢迎使用JBS 力量传奇 v3.1" or "欢迎使用JBS 力量传奇 v3.1，部分功能不可用",
        Duration = 3,
})

end)
if not okMain then
        notify("JBS 力量传奇", "运行出错: " .. tostring(errMain), 10)
        warn("[JBS] 运行错误: ", errMain)
end

 return okMain,errMain
 end
 local ok,success,err=pcall(runOriginalGame)
 local failure=ok and err or success
 WindUI:FinishGame(ok and success==true,failure)
 if not ok or not success then error("JBS 启动未完成: "..tostring(failure),0) end
 return WindUI
end

end
return loadGame()(loadLibrary())
