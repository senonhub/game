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
  Library:Window("AutoFarm");local mainTab=window:Tab("Main");local Players=game:GetService("Players");local ReplicatedStorage=game:GetService("ReplicatedStorage");local 
   VirtualInputManager=game:GetService("VirtualInputManager");local UIS=game:GetService("UserInputService");local CoreGui=game:GetService("CoreGui");local HttpService= 
  game:GetService("HttpService");local player=Players.LocalPlayer;local saveFile="autofarm_config.json";local weaponFarm=false;local isRunning=false;local hideEnabled=   
  false;local selectedIslands={};local weaponName="Strongest In History";local switchDelay=0.5;local fSpamDelay=0.1;local weapons={"Anos","Strongest Of Today"};local     
  equipRemote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipWeapon");local function saveConfig() if  not writefile then return;end local data={auto=       
  isRunning,hide=hideEnabled,weapon=weaponFarm,rejoin=autoRejoin,islands=selectedIslands};writefile(saveFile,HttpService:JSONEncode(data));end local function loadConfig( 
  ) if ( not readfile or  not isfile or  not isfile(saveFile)) then return;end local data=HttpService:JSONDecode(readfile(saveFile));isRunning=data.auto or false ;       
  hideEnabled=data.hide or false ;weaponFarm=data.weapon or false ;autoRejoin=data.rejoin or false ;if data.islands then for k,v in pairs(data.islands) do                
  selectedIslands[k]=v;end end end loadConfig();local teleportRemote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TeleportToPortal");local TeleportService=    
  game:GetService("TeleportService");local autoRejoin=autoRejoin or false ;game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child) if 
   (autoRejoin and (child.Name=="ErrorPrompt")) then task.wait(2);TeleportService:Teleport(game.PlaceId,player);end end);local hiddenFolder=Instance.new("Folder");       
  hiddenFolder.Parent=ReplicatedStorage;local hidingLoop=false;local function startHide() hidingLoop=true;task.spawn(function() while hidingLoop do local char=player.      
  Character;for _,v in pairs(workspace:GetChildren()) do if ((v~=char) and (v.Name~="Camera") and (v.Name~="Terrain")) then if  not selectedIslands[v.Name] then pcall(     
  function() v.Parent=hiddenFolder;end);end end end task.wait(0.2);end end);end local function stopHide() hidingLoop=false;for _,v in pairs(hiddenFolder:GetChildren()) do  
  v.Parent=workspace;end end task.spawn(function() local index=1;while true do if weaponFarm then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.One,false,game);       
  VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.One,false,game);if (equipRemote and weapons[index]) then pcall(function() equipRemote:FireServer("Equip",weapons[     
  index]);end);end index=index + 1 ;if (index> #weapons) then index=1;end task.wait(switchDelay);else task.wait(0.2);end end end);task.spawn(function() while true do if    
  weaponFarm then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.F,false,game);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.F,false,game);task.wait(fSpamDelay); 
  else task.wait(0.2);end end end);local Islands={{name="Starter Island",remoteName="Starter",farmPoints={CFrame.new(177,11, -159)}},{name="Lawless Island",remoteName=     
  "Lawless",farmPoints={CFrame.new(63,0,1817)}},{name="Ninja Island",remoteName="Ninja",farmPoints={CFrame.new( -1870,8, -738)}},{name="Judgement Island",remoteName=       
  "Judgement",farmPoints={CFrame.new( -1273,1, -1187)}},{name="Academy Island",remoteName="Academy",farmPoints={CFrame.new(1069,1,1273)}},{name="Slime Island",remoteName=  
  "Slime",farmPoints={CFrame.new(177,11, -159)}},{name="Shinjuku Island",remoteName="Shinjuku",farmPoints={CFrame.new( -16,1, -1843),CFrame.new(664,1, -1696)}},{name=      
  "Hueco Mundo",remoteName="Hueco",farmPoints={CFrame.new( -368,0,1096)}},{name="Shibuya Station",remoteName="Shibuya",farmPoints={CFrame.new(1399,8,486)}},{name=          
  "Snow Island",remoteName="Snow",farmPoints={CFrame.new( -406, -1, -994)}},{name="Desert Island",remoteName="Desert",farmPoints={CFrame.new( -787, -4, -430)}},{name=      
  "Jungle Island",remoteName="Jungle",farmPoints={CFrame.new( -566,0,402)}}};for _,v in ipairs(Islands) do if (selectedIslands[v.name]==nil) then selectedIslands[v.name] 
  =false;end end task.spawn(function() while true do task.wait(0.3);if isRunning then local char=player.Character;local backpack=player:FindFirstChild("Backpack");if (   
  char and backpack) then for _,tool in pairs(backpack:GetChildren()) do if (tool:IsA("Tool") and (tool.Name:lower()==weaponName:lower())) then tool.Parent=char;end end  
    end end end end);task.spawn(function() while true do task.wait(0.5);if isRunning then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.X,false,game);               
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.X,false,game);end end end);task.spawn(function() while true do task.wait(0.1);if isRunning then for _,island in   
    ipairs(Islands) do if  not isRunning then break;end if  not selectedIslands[island.name] then continue;end teleportRemote:FireServer(island.remoteName);local char=   
    player.Character or player.CharacterAdded:Wait() ;local hrp=char:WaitForChild("HumanoidRootPart");hrp.Anchored=true;task.wait(1.25);for _,point in ipairs(island.     
      farmPoints) do if  not isRunning then break;end hrp.CFrame=point;task.wait(1.25);end end else local char=player.Character;if char then local hrp=char:            
      FindFirstChild("HumanoidRootPart");if hrp then hrp.Anchored=false;end end end end end);mainTab:Label("Auto Farm System");mainTab:Toggle("Auto Farm",isRunning,    
      function(state) isRunning=state;saveConfig();if state then local char=player.Character;if char then local hasWeapon=false;for _,v in pairs(char:GetChildren()) do 
         if (v:IsA("Tool") and (v.Name==weaponName)) then hasWeapon=true;break;end end if  not hasWeapon then pcall(function() equipRemote:FireServer("Equip",          
        weaponName);end);end end if hideEnabled then startHide();end else stopHide();end end);mainTab:Toggle("Hide World",hideEnabled,function(state) hideEnabled=state 
        ;saveConfig();if (state and isRunning) then startHide();end if  not state then stopHide();end end);mainTab:Toggle("Auto Rejoin",autoRejoin,function(state)      
          autoRejoin=state;saveConfig();end);mainTab:Toggle("Tower/Rush",weaponFarm,function(state) weaponFarm=state;saveConfig();end);local islandNames={};for _,v   
            in ipairs(Islands) do table.insert(islandNames,v.name);end mainTab:Dropdown("Select Islands",islandNames,function(selected) for k in pairs(               
              selectedIslands) do selectedIslands[k]=false;end for _,name in pairs(selected) do selectedIslands[name]=true;end saveConfig();end,true);mainTab:Toggle( 
                "Farm All Islands",false,function(state) for _,island in ipairs(Islands) do selectedIslands[island.name]=state;end saveConfig();end);local mainUI=    
                  window.gui or window.Gui or window.ScreenGui ;if  not mainUI then for _,v in pairs(CoreGui:GetDescendants()) do if v:IsA("ScreenGui") then mainUI 
                      =v;break;end end end local minimized=false;local floatingBtn=Instance.new("TextButton");floatingBtn.Size=UDim2.new(0,80,0,40);floatingBtn.    
                                  Position=UDim2.new(0,20,0.5,0);floatingBtn.Text="OPEN";floatingBtn.BackgroundColor3=Color3.fromRGB(0,150,0);floatingBtn.          
                                      TextColor3=Color3.new(1,1,1);floatingBtn.Parent=CoreGui;floatingBtn.Visible=false;local function toggleUI() minimized= not    
                                      minimized;if mainUI then mainUI.Enabled= not minimized;end            floatingBtn.Visible=minimized;end UIS.InputBegan:       
                                      Connect(function(input,gpe) if gpe then return;end if (input.         KeyCode==Enum.KeyCode.RightShift) then toggleUI();end 
                                       end);floatingBtn.MouseButton1Click:Connect(toggleUI);task.           spawn(function() while true do task.wait(3);          
                                      saveConfig();end end);task.delay(1,function() if (isRunning           and hideEnabled) then startHide();end end);