-- Camera Tracking
-- by QSC
-- October 2020

PluginInfo = {
    Name = "Tools~Camera Tracking v0.5",
    Version = "0.5",
    BuildVersion = "0.0.0.188",
    Id = "648260e3-c166-4b00-98ba-b3asg37ba4a63b0",
    Author = "QSC",
    Description = "A Plugin for Camera Tracking in Q-SYS",
}

-- Colors used by Plugin
Plugin = {102,102,102}
White = {255,255,255}
Black = {0,0,0,255}
Clear = {0,0,0,0}
Grey = {230,230,230}
Faders = {110,198,241}
LED = {255,0,0}
Text = {51,51,51}

function GetColor(props)
  return { 102, 102, 102 }
end

function GetPrettyName(props)
  return "Camera Tracking v" .. PluginInfo.Version
end

function GetProperties()
  props = {}
  table.insert(props,{Name = "Debug Print",Type = "enum",Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},Value = "None"})
  table.insert(props,{Name = "Microphones",Type = "integer",Min = 1,Max = 10,Value = 1})
  return props
end

function GetPageNames(props)
  local pagenames = {"Setup"}
  local inputs = props["Microphones"].Value
  
  for i=1,inputs do
    table.insert(pagenames,"Input "..i)
  end
  return pagenames
end

function GetPages(props)
  pages = {}
  for ix,pname in ipairs(GetPageNames(props)) do
    table.insert( pages, { name = pname })
  end
  return pages
end

function RectifyProperties(props)
  if props.plugin_show_debug.Value==false then props["Debug Print"].IsHidden=true end
  return props
end

function GetControls(props)
  ctrls = {}
  local Inputs = props["Microphones"].Value
  
  -- code pin
  table.insert(ctrls,{Name = "code",ControlType = "Text",PinStyle = "Input",Count = 1})
  -- Commenting these out to experiment with automating it
  --table.insert(ctrls,{Name = "CrossTalkThreshold",ControlType = "Knob",ControlUnit = "Integer",Min = 1,Max = 200,UserPin = true,PinStyle = "Both",Value = 100,Count = 1})
  --table.insert(ctrls,{Name = "CrossTalkDelay",ControlType = "Knob",ControlUnit = "Integer",Min = 1,Max = 30,UserPin = true,PinStyle = "Both",Value = 15,Count = 1})
  table.insert(ctrls,{Name = "PTZDelay",ControlType = "Knob",ControlUnit = "Integer",Min = 1, Max = 5000,UserPin = true,PinStyle = "Both",DefaultValue = 2500,Count = 1})
  table.insert(ctrls,{Name = "SpeakerNormalizing",ControlType = "Knob",ControlUnit = "Float",Min = 0,Max = 1,UserPin = true,PinStyle = "Both",DefaultValue = 0.5,Count = 1})
  table.insert(ctrls,{Name = "MicLevelPresent",ControlType = "Indicator",IndicatorType = "Led",UserPin = false,PinStyle = "Input",Count = Inputs})
  table.insert(ctrls,{Name = "SpeakersLevelPresent",ControlType = "Indicator",IndicatorType = "Led",UserPin = false,PinStyle = "Input",Count = 1})
  table.insert(ctrls,{Name = "PositionSaveTotal",ControlType = "Button",ButtonType = "Trigger",UserPin = true,PinStyle = "Both",Count = 1})
  table.insert(ctrls,{Name = "PositionTotal",ControlType = "Text",UserPin = true,PinStyle = "Output",Count = 1})
  table.insert(ctrls,{Name = "Microphone",ControlType = "Text",PinStyle = "Both",UserPin = true,Count = Inputs})
  table.insert(ctrls,{Name = "CurrentAngle",ControlType = "Indicator",IndicatorType = "Text",UserPin = true,PinStyle = "Output",Count = Inputs})
  table.insert(ctrls,{Name = "TrackingOnOff",ControlType = "Button",ButtonType = "Toggle",UserPin = true,PinStyle = "Both",Count = 1})
  table.insert(ctrls,{Name = "Zones",ControlType = "Knob",ControlUnit = "Integer",Min = 1,Max = 21,UserPin = true,PinStyle = "Both",DefaultValue = 5,Count = Inputs})
  table.insert(ctrls,{Name = "CameraRouter",ControlType = "Text",UserPin = true,PinStyle = "Both", Count = 1})
  table.insert(ctrls,{Name = "Camera",ControlType = "Text",UserPin = true,PinStyle = "Both",Count = 10})
  table.insert(ctrls,{Name = "CameraHomePosition",ControlType = "Text",UserPin = true,PinStyle = "Both",Count = 1})
  table.insert(ctrls,{Name = "CrosstalkPreset",ControlType = "Text",UserPin = true,PinStyle = "Both",DefaultValue="slow",Count = 1})
  for i=1,Inputs do
    table.insert(ctrls,{Name = "Input"..i.."ZoneBoundary",ControlType = "Text",UserPin = true,PinStyle = "Both",Count = 21})
    table.insert(ctrls,{Name = "Input"..i.."ActiveZone",ControlType = "Indicator",IndicatorType = "Led",UserPin = true,PinStyle = "Output",Count = 21})
    table.insert(ctrls,{Name = "Input"..i.."Position",ControlType = "Text",UserPin = true,PinStyle = "Output",Count = 21})
    table.insert(ctrls,{Name = "Input"..i.."PositionSave",ControlType = "Button",ButtonType = "Trigger",UserPin = true,PinStyle = "Both",Count = 21})
    table.insert(ctrls,{Name = "Input"..i.."PositionLoad",ControlType = "Button",ButtonType = "Trigger",UserPin = true,PinStyle = "Both",Count = 21})
    table.insert(ctrls,{Name = "Input"..i.."CameraSelect",ControlType = "Text",UserPin = true,PinStyle = "Both",Count = 21})
  end
  return ctrls
end

function GetPosition(index, rowlen, base, offset)
  -- base and offset are x,y position values passed as a table
  local row,col = (index-1)//(rowlen),(index-1)%rowlen
  return { base.x + col*offset.x, base.y + row*offset.y }
end

function GetControlLayout(props)
  layout   = {}
  graphics = {}
  local Inputs = props["Microphones"].Value
  local CurrentPage = GetPageNames(props)[props["page_index"].Value]
  
  -- code pin
  layout["code"] = {PrettyName = "Code",Style = "None"}
  -- Control pins only
  --layout["MicLevelPresent"] = {PrettyName = "Input Level Present",Style = "None"}
  -- layout["ChaosReset"] = {PrettyName = "Chaos Reset",Style = "None"}
  if CurrentPage == "Setup" then
    -- Graphics
    table.insert(graphics,{Type = "GroupBox",Fill = White,CornerRadius = 0,Position = {0,0},Size = {309,570}})
    table.insert(graphics,{Type = "GroupBox",Fill = Grey,CornerRadius = 0,Position = {6,23},Size = {296,540}})
    table.insert(graphics,{Type = "Label",Text = "Tracking On/Off",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Left",Position = {70,35},Size = {120,18}})
    table.insert(graphics,{Type = "Label",Text = "Settings",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 18,FontStyle = "Bold",HTextAlign = "Left",Position = {6,0},Size = {204,22}})
    table.insert(graphics,{Type = "Label",Text = "Version "..PluginInfo.Version,Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 9,HTextAlign = "Right",Position = {228,550},Size = {73,12}})
    table.insert(graphics,{Type = "Header",Text = "Cameras",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,69},Size = {274,11}})
    table.insert(graphics,{Type = "Header",Text = "Global Home Position",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,180},Size = {274,11}})
    table.insert(graphics,{Type = "Header",Text = "Crosstalk Detection",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,500},Size = {274,11}})
    table.insert(graphics,{Type = "Header",Text = "PTZ Switch Delay",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,279},Size = {274,11}})
    table.insert(graphics,{Type = "Header",Text = "Speaker Normalizing",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,355},Size = {274,11}})
    table.insert(graphics,{Type = "Header",Text = "Camera Router",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlignment = "Center",Position = {17,431},Size = {274,11}})
    for i=1,10 do
      table.insert(graphics,{Type = "Label",Text = "Cam "..i,Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 12,HTextAlign = "Center",Position = GetPosition(i,5,{x=14,y=88},{x=56,y=42}),Size = {55,18}})
      layout["Camera "..i] = {PrettyName = "Settings~Camera "..i,Style = "ComboBox",Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black,Position = GetPosition(i,5,{x=14,y=107},{x=56,y=42}),Size = {55,18}}
      --layout["Camera "..t+5] = {PrettyName = "Settings~Cam "..t+5 ,Style = "ComboBox",Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black, Position = {14+56*(t-1),149}, Size = {55,18}}  
    end
    -- Controls
    layout["TrackingOnOff"] = {PrettyName = "Settings~Tracking",Style = "Button",ButtonStyle = "Toggle",CornerRadius = 2,Margin = 2,Position = {190,35},Size = {50,18}}
    layout["PositionTotal"] = {PrettyName = "Settings~Global Home Position",Style = "Text",TextBoxStyle = "Normal",Color = White,Position = {79,201},Size = {153,16}}
    layout["PositionSaveTotal"] = {PrettyName = "Settings~Global Home Save",Style = "Button",ButtonStyle = "Trigger",Legend = "SAVE",CornerRadius = 0,Margin = 1,Position = {99,245},Size = {113,19}}
    layout["CameraHomePosition"] = {PrettyName = "Settings~Global Home Camera", Style = "ComboBox", Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black, Position = {99,223},Size = {113,18}}
    layout["CameraRouter"] = {PrettyName = "Settings~Camera Router", Style = "ComboBox", Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black, Position = {99,460},Size = {113,18}}    
    layout["CrosstalkPreset"] = {PrettyName = "Settings~Crosstalk Preset", Style = "ComboBox", Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black, Position = {99,529},Size = {113,18}}    
    layout["PTZDelay"] = {PrettyName = "Settings~PTZ Delay",Style = "Fader",Color = Faders,Position = {17,304},Size = {274,36}}
    layout["SpeakerNormalizing"] = {PrettyName = "Settings~Speaker Normalizing",Style = "Fader",Color = Faders,Position = {17,380},Size = {274,36}}
  elseif CurrentPage:find("Input") then
    local Index = CurrentPage:match("%d+")
    -- Graphics
    table.insert(graphics,{Type = "GroupBox",Fill = White,CornerRadius = 0,Position = {0,0},Size = {547,593}})
    table.insert(graphics,{Type = "GroupBox",Fill = Grey,CornerRadius = 0,Position = {6,23},Size = {534,563}})
    table.insert(graphics,{Type = "Label",Text = "Input "..Index,Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 18,FontStyle = "Bold",HTextAlign = "Left",Position = {6,0},Size = {204,22}})
    table.insert(graphics,{Type = "Label",Text = "Version "..PluginInfo.Version,Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 9,HTextAlign = "Right",Position = {467,573},Size = {73,12}})
    table.insert(graphics,{Type = "Header",Text = "Setup",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlign = "Center",Position = {90,34},Size = {365,11}})
    table.insert(graphics,{Type = "Header",Text = "Zone Boundaries",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlign = "Center",Position = {90,146},Size = {365,11}})
    table.insert(graphics,{Type = "Header",Text = "Camera Presets",Fill = Text,Font = "Roboto",FontSize = 16,HTextAlign = "Center",Position = {90,284},Size = {365,11}})
    table.insert(graphics,{Type = "Label",Text = "Microphone",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Right",Position = {105,55},Size = {103,18}})
    table.insert(graphics,{Type = "Label",Text = "Current Angle",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Right",Position = {90,73},Size = {118,18}})
    table.insert(graphics,{Type = "Label",Text = "Zones",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Right",Position = {151,91},Size = {57,18}})
    table.insert(graphics,{Type = "Label",Text = "Microphone Signal",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Right",Position = {65,113},Size = {143,18}})
    table.insert(graphics,{Type = "Label",Text = "Speaker Signal",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 14,HTextAlign = "Right",Position = {271,113},Size = {98,18}})
    -- Setup Controls
    for i=1,Inputs do
      local string = tostring(Inputs==1 and "" or " "..i)
      if CurrentPage == "Input "..i then
        layout["Microphone"..string] = {PrettyName = "Input "..i.."~Microphone",Style = "ComboBox",Fill = White,Font = "Roboto",FontSize = 12,FontColor = Black,Position = {222,55},Size = {189,18}}
        layout["CurrentAngle"..string] = {PrettyName = "Input "..i.."~Current Angle",Style = "Text",TextBoxStyle = "Normal",Position = {222,73},Size = {189,18}}
        layout["Zones"..string] = {PrettyName = "Input "..i.."~Zones",Style = "Text",TextBoxStyle = "Normal",Color = Faders,Position = {222,91},Size = {73,16}}
        layout["MicLevelPresent"..string] = {PrettyName = "Input "..i.."~Microphone Signal",Style = "Led",Color = LED,UnlinkOffColor = false,Position = {236,112},Size = {20,20}}
        layout["SpeakersLevelPresent"] = {PrettyName = "Speaker Signal",Style = "Led",Color = LED,UnlinkOffColor = false,Position = {379,112},Size = {20,20}}
      end
    end
    for i=1,21 do
      -- Position Labels
      table.insert(graphics,{Type = "Label",Text = "Position "..i,Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 12,HTextAlign = "Center",Position = GetPosition(i,7,{x=17,y=303},{x=73,y=91}),Size = {73,15}})
      table.insert(graphics,{Type = "Label",Text = "Camera",Fill = Clear,Font = "Roboto",FontColor = Text,FontSize = 12,HTextAlign = "Center",Position = GetPosition(i,7,{x=17,y=354},{x=73,y=91}),Size = {73,15}})
      -- Zone Boundary and Position Controls
      layout["Input"..Index.."ActiveZone "..i] = {PrettyName = "Input "..Index.."~Zone "..i.."~Active",Style = "Led",Color = LED,UnlinkOffColor = false,Position = GetPosition(i,7,{x=45,y=160},{x=73,y=40}),Size = {17,17}}
      layout["Input"..Index.."ZoneBoundary "..i] = {PrettyName = "Input "..Index.."~Zone "..i.."~Boundary",Style = "Text",TextBoxStyle = "Normal",Color = Faders,Position = GetPosition(i,7,{x=17,y=177},{x=73,y=40}),Size = {73,16}}
      layout["Input"..Index.."Position "..i] = {PrettyName = "Input "..Index.."~Position "..i.."~String",Style = "Text",TextBoxStyle = "Normal",Margin = 1,Fill = White,Position = GetPosition(i,7,{x=17,y=318},{x=73,y=91}),Size = {73,16}}
      layout["Input"..Index.."PositionSave "..i] = {PrettyName = "Input "..Index.."~Position "..i.."~Save",Style = "Button",ButtonStyle = "Trigger",Legend = "SAVE",CornerRadius = 0,Margin = 1,Position = GetPosition(i,7,{x=17,y=334},{x=73,y=91}),Size = {37,19}}
      layout["Input"..Index.."PositionLoad "..i] = {PrettyName = "Input "..Index.."~Position "..i.."~Load",Style = "Button",ButtonStyle = "Trigger",Legend = "LOAD",CornerRadius = 0,Margin = 1,Position = GetPosition(i,7,{x=53,y=334},{x=73,y=91}),Size = {37,19}}
      layout["Input"..Index.."CameraSelect "..i] = {PrettyName = "Input "..Index.."~Position "..i.."~Camera",Style = "ComboBox",CornerRadius = 0,Margin = 1,Position = GetPosition(i,7,{x=17,y=370},{x=73,y=91}),Size = {73,19}}
    end
  end
  return layout, graphics
end

--Start event based logic
if Controls then

  --Variables
  Microphones = Properties["Microphones"].Value


  --Tables
  TCC,Camselect,CamselectUnsorted,Cam,CamUnsorted,CameraMoving,CameraPosition = {},{},{},{},{},{},{}
  Borders = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
  Zones = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
  CamZone = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
  --Timers
  Polltimer=Timer.New()
  Polltimer:Start(0.5)
  ControlsTimer=Timer.New()
  ControlsTimer:Start(0.1)
  
  function AddMics() print("AddMics")--Adding the Components for the Mics 
    if Microphones == 1 then
      if Controls.Microphone.String ~= "" then
        TCC1=Component.New(Controls.Microphone.String)["SourceHorizontalValue"] 
        TCC[1]=TCC1 
        Controls.CurrentAngle.String = TCC[1].Value
      end
    else 
      for i=1,Microphones do
        if Controls.Microphone[i].String ~= "" then
          TCC[i]=Component.New(Controls.Microphone[i].String)["SourceHorizontalValue"]
          Controls.CurrentAngle[i].String = TCC[i].Value
        end
      end
    end
  end
  function MicAngle() print("MicAngle")
    if Microphones == 1 then
      if Controls.Microphone.String ~= "" then
        Controls.CurrentAngle.String = TCC[1].Value
      end  
      else
      for i=1,Microphones do
        if Controls.Microphone[i].String ~= "" then
          Controls.CurrentAngle[i].String = TCC[i].Value
        end
      end
    end
  end
  -- find the Named Components in Design
  local CameraComponents = {}
  local CameraRouterComponents = {}
  local PluginComponents = {}
  local MicrophoneComponents = {}
  local Components = Component.GetComponents()

  
  if #Components>0 then --checking if there are named components present
  for i,v in pairs(Components) do
    --print(v.Name, v.Type)
    if      string.find(v.Type,"camera") then table.insert(CameraComponents, v.Name) --Checks if the component is a camera 
    elseif  string.find(v.Type,"video_router") then table.insert(CameraRouterComponents, v.Name) --Checks if the component is a camera router
    elseif  string.find(v.Type,"PLUGIN") then table.insert(PluginComponents, v.Name) --Checks if the component is a plugin
    end
  end
  for n,t in pairs(PluginComponents) do
    for _,b_element in ipairs(Component.GetControls(Component.New(PluginComponents[n]))) do    --checks if the plugin is the sennheiser plugin
    if string.find(b_element.Name, "SourceHorizontalValue") then table.insert(MicrophoneComponents,n,t) end
    end
  end 
  table.sort(CameraComponents) --Sorts Cameras alphabetical
  table.sort(CameraRouterComponents) --Sorts CameraRouters alphabetical
  table.sort(MicrophoneComponents)  --Sorts Microphones alphabetical
    Controls["CameraRouter"].Choices = CameraRouterComponents
    for i=1,10 do
      Controls["Camera"][i].Choices = CameraComponents
    end
    if Microphones == 1 then 
      Controls.Microphone.Choices = MicrophoneComponents 
    else
      for i=1,Microphones do 
        Controls.Microphone[i].Choices = MicrophoneComponents
      end
    end
  end
  
    function CameraRouterSelect() print("CameraRouterSelect")--Assigning Camera Router
  CameraRouter = Component.New(Controls["CameraRouter"].String)["select.1"]
  end
  
  -- Filling Cam Arrays 
  function CamTable()print("CamTable")
    for i=1,10 do
      if Controls["Camera"][i].String ~= "" then --Adding the 10 selected cameras to an array
        Camselect[i] = Controls["Camera"][i].String
        CamselectUnsorted[i] = Controls["Camera"][i].String
      end
    end
   table.sort(Camselect) --sorting alphabetically
    Controls["CameraHomePosition"].Choices = Camselect
    for i=1,Microphones do
      if Microphones == 1 then
        for j=1,Controls.Zones.Value do Controls["Input1CameraSelect"][j].Choices = Camselect end
      else
        for j=1,Controls.Zones[i].Value do Controls["Input"..i.."CameraSelect"][j].Choices = Camselect end
      end
    end
  end

function AddCamComponents() print("AddCamComponents")--Adding the Components from the before defined arrays
    for i=1,10 do CamTable()  --executing CamTable so the Array gets filled before defining component
      if Controls["Camera"][i].String ~= "" 
        then Cam[i] = Component.New(Camselect[i])["ptz.preset"] --adding the controls for later to be selected
             CamUnsorted[i] = Component.New(CamselectUnsorted[i])["ptz.preset"]  --adding the same controls unsorted for the movement tracking
      end      
    end  
end
  
  -- Saving Home Position
  Controls.PositionSaveTotal.EventHandler=function() 
    for i=1,10 do if Controls.CameraHomePosition.String==CamselectUnsorted[i] then Controls.PositionTotal.String = Cam[i].String end
  end end
  
  --Saving Camera Positions
  function CamPositionSaveHandler() print("CamPositionSaveHandler")
  if Microphones == 1 then 
    for j=1,21 do
      Controls.Input1PositionSave[j].EventHandler = function()
        for c=1,10 do if Controls["Input1CameraSelect"][j].String==CamselectUnsorted[c] then Controls.Input1Position[j].String = Cam[c].String end end
      end
    end
  else 
      for i=1,Microphones do
        for j=1,21 do
          Controls["Input"..i.."PositionSave"][j].EventHandler = function()
            for c=1,10 do if Controls["Input"..i.."CameraSelect"][j].String == CamselectUnsorted[c] then Controls["Input"..i.."Position"][j].String = Cam[c].String end end
          end
        end
      end
    end
  end
  
  --Changing CameraRouter
  function CameraRouterSwitch(i,j) print("CameraRouterSwitch")
    if Controls["CameraRouter"].String ~="" then --print(CameraMoving[1])
      for c=1,10 do
        if Controls["Input"..i.."CameraSelect"][j].String == CamselectUnsorted[c] then
          Timer.CallAfter(function() 
            if CameraMoving[c] == false then CameraRouter.Value = c 
            else  Timer.CallAfter(function() 
                    if CameraMoving[c] == false then 
                          CameraRouter.Value = c 
                    else  Timer.CallAfter(function()
                          CameraRouter.Value = c end,0.5) 
                          
                    end 
                  end,0.5) 
            end
          end,0.1)
        end  
      end
    end
  end

  --checking if Cameras are moving
  function CameraMovement() print("CameraMovement")
    for i,v in ipairs(CamUnsorted) do
      if CameraPosition[i]==CamUnsorted[i].String then CameraMoving[i] = false 
      else CameraMoving[i] = true 
      CameraPosition[i]=CamUnsorted[i].String
      end
    end    
  end
  --Loading Camera Positions
  function CamPositionLoadHandler() print("CamPositionLoadHandler")
    if Microphones == 1 then 
      for j=1,21 do
        Controls.Input1PositionLoad[j].EventHandler = function()
          for c=1,10 do 
            if Controls["Input1CameraSelect"][j].String == CamselectUnsorted[c] 
            then Cam[c].String = Controls.Input1Position[j].String CameraRouterSwitch(1,j) SetCamZone(1,j)
            end 
          end 
        end
      end
    else
      for i=1,Microphones do
        for j=1,21 do
          Controls["Input"..i.."PositionLoad"][j].EventHandler = function()
            for c=1,10 do 
              if Controls["Input"..i.."CameraSelect"][j].String == CamselectUnsorted[c] 
              then Cam[c].String = Controls["Input"..i.."Position"][j].String CameraRouterSwitch(i,j)   SetCamZone(i,j)
              end 
            end
          end
        end
      end
    end
  end
  --Home Position Recall
  function RecallHomePosition() print("RecallHomePosition")
    for c=1,10 do 
      if Controls["CameraHomePosition"].String == CamselectUnsorted[c] then 
        Cam[c].String = Controls["PositionTotal"].String 
          if Controls["CameraRouter"].String ~="" then 
            Timer.CallAfter(function() 
              if CameraMoving[c] == false then CameraRouter.Value = c 
              else  Timer.CallAfter(function() 
                      if CameraMoving[c] == false then 
                            CameraRouter.Value = c 
                      else  Timer.CallAfter(function()
                            CameraRouter.Value = c 
                            end,0.5)                           
                      end 
                    end,0.5) 
              end
            end,0.1)
          end  
      end
    end
  end

        
  --Silence Home Position Recall
  Silence = 0
  SilenceTime = 40
  function SilenceHomePositionRecall() print("SilenceHomePositionRecall")
    if Microphones == 1 then
      if Silence < SilenceTime then Silence = Silence+1 elseif Silence == SilenceTime then Silence = Silence+1 RecallHomePosition() end   
      else if Silence < SilenceTime*Microphones then Silence = Silence+1 elseif Silence == SilenceTime*Microphones then Silence = Silence+1 RecallHomePosition()  end   
    end 
  end

  --Disabling not used Controls
  ZoneControls = {"ZoneBoundary","ActiveZone","Position","PositionSave","PositionLoad","CameraSelect"}
  
  function Disable(i,l) print("Disable")
    for k,v in pairs(ZoneControls) do
      if Microphones==1 then
        if l > Controls.Zones.Value then
          Controls["Input"..i..v][l].IsDisabled = true
        else
          Controls["Input"..i..v][l].IsDisabled = false
        end
      else
        if l > Controls.Zones[i].Value then
          Controls["Input"..i..v][l].IsDisabled = true
        else
          Controls["Input"..i..v][l].IsDisabled = false
        end
      end
    end
  end
  
  --Borders Selecting
  function SetBorders() print("SetBorders")
    if Microphones == 1 then 
      for j=1,Controls.Zones.Value do Borders[1][j] = Controls.Input1ZoneBoundary[j].String
      end
    else
      for i=1,Microphones do 
        for j=1,Controls.Zones[i].Value do Borders[i][j] = Controls["Input"..i.."ZoneBoundary"][j].String end
      end  
    end
  end
  
  function ZonesHandler()  print("ZonesHandler")
    for i=1,Microphones do
      for l=1,21 do
        Disable(i,l)
      end
    end
  end
  
  ZonesHandler()
  
  --Setting the Switch Delaytime
  function SetDelay() print("SetDelay") -- time in ms how long a zone needs to be present before switch
    Delay=Controls.PTZDelay.Value*0.001
  end
  SetDelay() 
  
  --checks if the zone kept steady for time "Delay"
  function Presetswitch(i,j) print("PresetSwitch")
  SpeakerNormalizingValue = 0.5
    if Microphones == 1 then
          Timer.CallAfter(function()  
            if Zones[i][j] == "true" and cv == 0 and Controls.MicLevelPresent.Boolean==true 
              then for c=1,10 
                do 
                  if Controls["Input"..i.."CameraSelect"][j].String == Camselect[c] 
                    then Cam[c].String = Controls.Input1Position[j].String CameraRouterSwitch(i,j) SetCamZone(i,j) --print(c)
                  end 
                end 
            end 
          end,Delay+N*SpeakerNormalizingValue) 
    else  Timer.CallAfter(function()  
            if Zones[i][j] == "true" and cv == 0 and Controls.MicLevelPresent[i].Boolean==true 
              then for c=1,10 do 
                if Controls["Input"..i.."CameraSelect"][j].String == Camselect[c] 
                  then Cam[c].String = Controls["Input"..i.."Position"][j].String CameraRouterSwitch(i,j) SetCamZone(i,j) 
                end 
              end 
            end 
          end,Delay+N*SpeakerNormalizingValue) 
    end
  end
  
  --Defines which camera is currently select with corresponding preset
  function SetCamZone(p,q) print("SetCamZone")
  if CamZone[p][q]==Zones[p][q] then else  N=0 end  
  if Microphones == 1 then
    for j=1,Controls.Zones.Value do
        if j==q then Controls["Input1PositionLoad"][j].Color = "white" CamZone[1][j] = "true"
        else Controls["Input1PositionLoad"][j].Color = "#FF7C7C7C" CamZone[1][j] = "false"
        end
      end
  else 
    for i=1,Microphones do
      for j=1,Controls.Zones[i].Value do
        if i==p and j==q then Controls["Input"..i.."PositionLoad"][j].Color = "white" CamZone[i][j] = "true"
        else Controls["Input"..i.."PositionLoad"][j].Color = "#FF7C7C7C" CamZone[i][j] = "false"
        end
      end
    end
  end
  end
  
  --LED feedback for current speaker
  function ZoneFeedback(p,q) print("ZoneFeedback")
    if Microphones == 1 then
        for j=1,Controls.Zones.Value do
          if q == j then Controls["Input1ActiveZone"][j].Boolean = true else Controls["Input1ActiveZone"][j].Boolean = false end
        end
    else
      for i=1,Microphones do
        for j=1,Controls.Zones[i].Value do
          if p == i and q == j then Controls["Input"..i.."ActiveZone"][j].Boolean = true else Controls["Input"..i.."ActiveZone"][j].Boolean = false end
          end
        end     
      end
   end
  
   --increases Switching Delay the longer the current zone is active
  N=0
   function Normalizing(p,q) print("Normalizing")
    if Microphones == 1 then 
      if q == oldj then if N<10 then N=N+0.1 end
      else if N>0 then N=N-0.5 end
      end
    else
      if p== oldi and q == oldj then if N<10 then N=N+0.1 end
      else if N>0 then N=N-0.5 end
    end
    oldj = q oldi = p
    end
   end

   --Settings for Crosstalk
   Controls.CrosstalkPreset.Choices = {"none","slow","medium","fast"}
   ChaosTablei = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
   ChaosTablej = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
   xi = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
   xj = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
   cv=0
   function ChaosCalc(i,j)  print("ChaosCalc")
   --print(cv)
    isum = 0
    jsum = 0
    table.insert(ChaosTablei, 1, i) table.remove(ChaosTablei,22)
    table.insert(ChaosTablej, 1, j) table.remove(ChaosTablej,22)
      for i=1,20 do
        if math.abs(ChaosTablej[i]-ChaosTablej[i+1]) >1 then xj[i] =1 else xj[i]=0 end 
        if math.abs(ChaosTablei[i]-ChaosTablei[i+1]) >1 then xi[i] =1 else xi[i]=0 end  
        jsum = jsum + xj[i] 
        isum = isum + xi[i]    
      end 
     --print("jsum "..jsum) 
     --print("isum "..isum)
     if Controls.CrosstalkPreset.String == "none" then        m=100   z=100   r=0 --setting the markers way higher so it never gets triggered
     elseif Controls.CrosstalkPreset.String == "slow" then    m=0.4   z=0.2   r=20 
     elseif Controls.CrosstalkPreset.String == "medium" then  m=0.3   z=0.1   r=15 
     elseif Controls.CrosstalkPreset.String == "fast" then    m=0.2   z=0.03  r=10 
     end 
    -- print("test"..m)
    if isum > 21*m or jsum > 21*z 
    then cv=1 print("CHAOS") RecallHomePosition() Timer.CallAfter(function() if isum < Microphones*m and jsum < 21*z and cv == 1 then cv=0 end  end, r)
    end
   end 
  
  --Function that checks if active TCC Angle is between Zone Borders 
  Polltimer.EventHandler = function() 
    if Controls.TrackingOnOff.Boolean == true and Controls.SpeakersLevelPresent.Boolean == false then farendspeaking=0 
      if Microphones == 1 then 
        if Controls.MicLevelPresent.Boolean == true then Silence = 0
          for j=1,Controls.Zones.Value do 
            if Controls["Input1ZoneBoundary"][j].String ~= "" and TCC[1]~= nil then
              if TCC[1].Value >= tonumber(string.sub(Controls["Input1ZoneBoundary"][j].String, 1, string.sub(string.find(Controls["Input1ZoneBoundary"][j].String, "%D"),1,2))) and
                TCC[1].Value <  tonumber(string.sub(Controls["Input1ZoneBoundary"][j].String, string.sub(string.find(Controls["Input1ZoneBoundary"][j].String, "%D"),1,2))) and
                1==1 
                then Zones[1][j] = "true" Presetswitch(1,j) ZoneFeedback(1,j) Normalizing(1,j) ChaosCalc(1,j)
                else Zones[1][j] = "false"
              end
            end
          end
        elseif Controls.MicLevelPresent.Boolean == false then SilenceHomePositionRecall()
        end 
      else 
        for i=1,Microphones do 
          if Controls.MicLevelPresent[i].Boolean == true then Silence = 0 
            for j=1,Controls.Zones[i].Value do 
              if Controls["Input"..i.."ZoneBoundary"][j].String ~= "" and TCC[i]~= nil then
                if TCC[i].Value >= tonumber(string.sub(Controls["Input"..i.."ZoneBoundary"][j].String, 1, string.sub(string.find(Controls["Input"..i.."ZoneBoundary"][j].String, "%D"),1,2))) and
                  TCC[i].Value <  tonumber(string.sub(Controls["Input"..i.."ZoneBoundary"][j].String, string.sub(string.find(Controls["Input"..i.."ZoneBoundary"][j].String, "%D"),1,2))) and
                  1==1
                  then Zones[i][j] = "true" Presetswitch(i,j) ZoneFeedback(i,j) Normalizing(i,j) ChaosCalc(i,j) 
                  else Zones[i][j] = "false"
                end
              end
            end 
          elseif Controls.MicLevelPresent[i].Boolean == false then SilenceHomePositionRecall()
          end
        end
      end  
    elseif Controls.TrackingOnOff.Boolean == true and Controls.SpeakersLevelPresent.Boolean == true then
      if farendspeaking < 10 then farendspeaking=farendspeaking+1 elseif farendspeaking>=10 then RecallHomePosition() end
    end  --10 times half a second until total position gets triggered. change both 10 against other value for shorter/longer treshhold  
  end
  
  --Updates the Controls
  ControlsTimer.EventHandler=function()
    SetBorders() 
    --CamPositionSaveHandler() 
    --CamPositionLoadHandler() 
    --BorderHandler()
    CamTable()
    SetDelay()
    CameraMovement()
    MicAngle()
  end
  
  function EventHandlers()
    for i=1,10 do 
      Controls["Camera"][i].EventHandler = AddCamComponents --Adding Camera Components on Change of Camera entries at Setup
    end      
    if Microphones == 1 then        -- Adding Microphone Components when changing microphone on microphone pages                           
      Controls.Microphone.EventHandler = AddMics
      Controls.Zones.EventHandler = ZonesHandler
      for j=1,21 do 
        Controls.Input1ZoneBoundary[j].EventHandler=SetBorders 
      end
    else 
      for i=1,Microphones do
        Controls.Microphone[i].EventHandler = AddMics
        Controls.Zones[i].EventHandler = ZonesHandler
        for j=1,21 do 
          Controls.Input1ZoneBoundary[j].EventHandler=SetBorders 
        end
      end
    end
    Controls["CameraRouter"].EventHandler = CameraRouterSelect
  end
  EventHandlers()
  
  function Initialize()
    SetBorders() 
    CamPositionSaveHandler() 
    CamPositionLoadHandler() 
    ZonesHandler()
    CamTable()
    SetDelay()
    CameraMovement()
    AddCamComponents()
    AddMics()
    CameraRouterSelect()
  end
  Initialize()
 
end