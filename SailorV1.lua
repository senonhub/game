                                                                                 local Library=        
                                                                        loadstring(game:HttpGet(                        
                                                                                                                                  
                                                                                                                                        
                                                                                                                                          
                                                                                                                                            
                                                                                                                                              
                                                                                                                                                
                                                                                                                                                  
                                                                                                                                                    
                                                                                                                                                      
                                                                                                                                                        
                                                                                                                                                          
                                                                                                                                                            
                                                                                                                                                            
                                                                                                                                                              
                                                                                                                                                                
                                                                                                                                                                  
                                                                                                                                                                    
                                                                                                                                                                      
                                                                                                                                                                      
                                                                                                                                                                        
                                                                                                              --[[==============================]]                        
                                                                                                    --[[============================================]]                    
                                                                                                --[[======================================================]]                
                                                                                            --[[==========================================================]]                  
                                                                                          --[[==============================================================]]                
                                                                                          --[[================================================================]]                
                                                                                          --[[==================================================================]]              
                                                                                          --[[==================================================================]]                  
                                                                                          --[[====================================================================]]              
                                                                                          --[[====================================================================]]                
                                                                                          --[[======================================================================]]              
                                                                                          --[[======================================================================]]              
                                                                                          --[[======================================================================]]              
                                                                                          --[[======================================================================]]              
                                                                                          --[[======================================================================]]              
                                                                                          --[[======================================================================]]              
                                                                                            --[[==================================================================]]                
                                                                                            --[[================================================================]]                  
                                                                                            --[[==============================================================]]                  
                                                                                              --[[==========================================================]]                    
                                                                                                --[[====================================================]]                        
                                                                                                  --[[==============================================]]                          
                                                                                                      --[[====================================]]                              
                                                                                                          --[[========================]]                                      
    "https://gist.githubusercontent.com/MjContiga1/6e2c779299e9bf3d3f9edb5bff97b2fb/raw/29b9f1cc215ad4e583271d1ad229f34c921553a8/Lib%2520ui%2520test.lua"))();local window= 
  Library:Window("AutoFarm");local mainTab=window:Tab("Main");local settingsTab=window:Tab("SETTINGS");local Players=game:GetService("Players");local ReplicatedStorage=  
  game:GetService("ReplicatedStorage");local VirtualInputManager=game:GetService("VirtualInputManager");local UIS=game:GetService("UserInputService");local CoreGui=    
  game:GetService("CoreGui");local HttpService=game:GetService("HttpService");local player=Players.LocalPlayer;local TeleportService=game:GetService("TeleportService");  
  local teleportRemote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TeleportToPortal");local saveFile="autofarm_config.json";local weaponFarm=false;local      
  farmSpeed=0.5;local isRunning=false;local hideEnabled=false;local selectedIslands={};local weaponName="Strongest In History";local autoRejoin=false;local switchDelay=  
  0.5;local fSpamDelay=0.1;local weapons={"Anos","Strongest Of Today"};local equipRemote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipWeapon");local      
  function saveConfig() if  not writefile then return;end local data={auto=isRunning,hide=hideEnabled,weapon=weaponFarm,rejoin=autoRejoin,farmSpeed=farmSpeed,islands=    
  selectedIslands};writefile(saveFile,HttpService:JSONEncode(data));end local function loadConfig() if ( not readfile or  not isfile or  not isfile(saveFile)) then       
  return;end local data=HttpService:JSONDecode(readfile(saveFile));isRunning=data.auto or false ;hideEnabled=data.hide or false ;weaponFarm=data.weapon or false ;        
  autoRejoin=data.rejoin or false ;farmSpeed=data.farmSpeed or 0.25 ;if data.islands then for k,v in pairs(data.islands) do selectedIslands[k]=v;end end end loadConfig() 
  ;local promptGui=CoreGui:FindFirstChild("RobloxPromptGui");if (promptGui and promptGui:FindFirstChild("promptOverlay")) then promptGui.promptOverlay.ChildAdded:Connect 
  (function(child) if (autoRejoin and (child.Name=="ErrorPrompt")) then task.wait(2);TeleportService:Teleport(game.PlaceId,player);end end);end local hiddenFolder=Instance 
  .new("Folder");hiddenFolder.Parent=ReplicatedStorage;local hidingLoop=false;local function startHide() hidingLoop=true;task.spawn(function() while hidingLoop do local    
  char=player.Character;for _,v in pairs(workspace:GetChildren()) do if ((v~=char) and (v.Name~="Camera") and (v.Name~="Terrain")) then if  not selectedIslands[v.Name]     
  then pcall(function() v.Parent=hiddenFolder;end);end end end task.wait(0.5);end end);end local function stopHide() hidingLoop=false;for _,v in pairs(hiddenFolder:        
  GetChildren()) do v.Parent=workspace;end end task.spawn(function() local index=1;while true do if weaponFarm then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.One, 
  false,game);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.One,false,game);if (equipRemote and weapons[index]) then pcall(function() equipRemote:FireServer("Equip", 
  weapons[index]);end);end index=index + 1 ;if (index> #weapons) then index=1;end task.wait(switchDelay);else task.wait(0.2);end end end);task.spawn(function() while true  
  do if weaponFarm then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.F,false,game);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.F,false,game);task.wait(       
  fSpamDelay);else task.wait(0.2);end end end);local Islands={{name="Starter Island",remoteName="Starter",farmPoints={CFrame.new(177,11, -159)}},{name="Lawless Island",    
  remoteName="Lawless",farmPoints={CFrame.new(63,0,1817)}},{name="Ninja Island",remoteName="Ninja",farmPoints={CFrame.new( -1870,8, -738)}},{name="Judgement Island",       
  remoteName="Judgement",farmPoints={CFrame.new( -1273,1, -1187)}},{name="Academy Island",remoteName="Academy",farmPoints={CFrame.new(1069,1,1273)}},{name="Slime Island",  
  remoteName="Slime",farmPoints={CFrame.new(177,11, -159)}},{name="Shinjuku Island",remoteName="Shinjuku",farmPoints={CFrame.new( -16,1, -1843),CFrame.new(664,1, -1696)}}, 
  {name="Hueco Mundo",remoteName="Hueco",farmPoints={CFrame.new( -368,0,1096)}},{name="Shibuya Station",remoteName="Shibuya",farmPoints={CFrame.new(1399,8,486)}},{name=    
  "Snow Island",remoteName="Snow",farmPoints={CFrame.new( -406, -1, -994)}},{name="Desert Island",remoteName="Desert",farmPoints={CFrame.new( -787, -4, -430)}},{name=    
  "Jungle Island",remoteName="Jungle",farmPoints={CFrame.new( -566,0,402)}}};for _,v in ipairs(Islands) do if (selectedIslands[v.name]==nil) then selectedIslands[v.name] 
  =false;end end task.spawn(function() while true do task.wait(0.3);if isRunning then local char=player.Character;local backpack=player:FindFirstChild("Backpack");if (   
    char and backpack) then for _,tool in pairs(backpack:GetChildren()) do if (tool:IsA("Tool") and (tool.Name:lower()==weaponName:lower())) then tool.Parent=char;end    
    end end end end end);task.spawn(function() while true do task.wait(0.5);if isRunning then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.X,false,game);           
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.X,false,game);end end end);task.spawn(function() while true do task.wait(0.1);if isRunning then for _,island in   
    ipairs(Islands) do if  not isRunning then break;end if  not selectedIslands[island.name] then continue;end teleportRemote:FireServer(island.remoteName);local char=   
      player.Character or player.CharacterAdded:Wait() ;local hrp=char:WaitForChild("HumanoidRootPart");hrp.Anchored=true;task.wait(farmSpeed);for _,point in ipairs(   
      island.farmPoints) do if  not isRunning then break;end hrp.CFrame=point;task.wait(farmSpeed);end end else local char=player.Character;if char then local hrp=char 
      :FindFirstChild("HumanoidRootPart");if hrp then hrp.Anchored=false;end end end end end);local autoFarmToggle,hideToggle,rejoinToggle,weaponToggle,                
        farmSpeedDropdown,islandsDropdown;mainTab:Label("Auto Farm System");autoFarmToggle=mainTab:Toggle("Auto Farm",isRunning,function(state) isRunning=state;        
        saveConfig();if state then local char=player.Character;if char then local hasWeapon=false;for _,v in pairs(char:GetChildren()) do if (v:IsA("Tool") and (v.Name 
        ==weaponName)) then hasWeapon=true;break;end end if  not hasWeapon then pcall(function() equipRemote:FireServer("Equip",weaponName);end);end end if hideEnabled 
           then startHide();end else stopHide();end end);weaponToggle=mainTab:Toggle("Tower/Rush",weaponFarm,function(state) weaponFarm=state;saveConfig();end);local 
             islandNames={};for _,v in ipairs(Islands) do table.insert(islandNames,v.name);end islandsDropdown=mainTab:Dropdown("Select Islands",islandNames,function 
              (selected) for k in pairs(selectedIslands) do selectedIslands[k]=false;end for _,name in pairs(selected) do selectedIslands[name]=true;end saveConfig() 
                ;end,true);mainTab:Toggle("Farm All Islands",false,function(state) for _,island in ipairs(Islands) do selectedIslands[island.name]=state;end          
                  saveConfig();end);local speedOptions={0.25,0.5,0.75,1};farmSpeedDropdown=settingsTab:Dropdown("Farm Speed",speedOptions,function(selected)        
                      farmSpeed=tonumber(selected) or 0.25 ;saveConfig();end);hideToggle=settingsTab:Toggle("Hide World",hideEnabled,function(state) hideEnabled=   
                                  state;saveConfig();if (state and isRunning) then startHide();end if  not state then stopHide();end end);rejoinToggle=settingsTab: 
                                      Toggle("Auto Rejoin",autoRejoin,function(state) autoRejoin=state;saveConfig();end);task.delay(0.5,function() if (             
                                      autoFarmToggle and autoFarmToggle.Set) then autoFarmToggle:           Set(isRunning);end if (hideToggle and hideToggle.Set)   
                                      then hideToggle:Set(hideEnabled);end if (rejoinToggle and             rejoinToggle.Set) then rejoinToggle:Set(autoRejoin);  
                                      end if (weaponToggle and weaponToggle.Set) then weaponToggle:         Set(weaponFarm);end if (farmSpeedDropdown and         
                                      farmSpeedDropdown.Set) then farmSpeedDropdown:Set(farmSpeed);         end local selectedList={};for name,v in pairs(        
                                      selectedIslands) do if v then table.insert(selectedList,name)           ;end end if (islandsDropdown and islandsDropdown.   
                                      Set) then islandsDropdown:Set(selectedList);end end);task.              spawn(function() while true do task.wait(3);        
                                      saveConfig();end end);task.delay(1,function() if (isRunning             and hideEnabled) then startHide();end end);