--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio                "EskaQuestTracker.Classes.Quest"                       ""
--============================================================================--
namespace "EQT"
--============================================================================--
class "Quest" inherit "Frame" extend "IReusable" "IObjectiveHolder"
  _QuestCache = setmetatable( {}, { __mode = "v" } )
  event "OnDistanceChanged"
  event "IsOnMapChanged"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateProps(self, new, old, prop)
    if prop == "name" then
      Theme.SkinText(self.frame.headerName, new)
    elseif prop == "level" then
      Theme.SkinText(self.frame.headerLevel, new)
    elseif prop == "distance" then
      self.OnDistanceChanged(self, new)
    end
  end
  ------------------------------------------------------------------------------
  --                                   Methods                                --
  ------------------------------------------------------------------------------
  __Arguments__{}
  function GetQuestItem(self)
    if not self.questItem then
      self.questItem = _ObjectManager:GetQuestItem()
      self.questItem:SetParent(self.frame)
      -- self:Show()
    end

    return self.questItem
  end

  __Arguments__{}
  function Draw(self)
    if not self:IsShown() then
      self:Show()
    end

    if self.questItem then
      if not self.questItem:IsShown() then
        self.questItem:Show()
      end

      local obj = self.objectives[1]
      if obj then
        self.questItem:Show()
        self.questItem.frame:SetPoint("TOPLEFT", self.frame.header, "BOTTOMLEFT", 5, -5)

        obj.frame:SetPoint("TOPLEFT", self.questItem.frame, "TOPRIGHT")
        obj.frame:SetPoint("TOPRIGHT", self.frame.header, "BOTTOMRIGHT")

        self:DrawObjectives(self.frame.header, true)
        if self.height < self.questItem.height + self.baseHeight + 10 then
          self.height = self.baseHeight + self.questItem.height + 10
        end
      end
    else
      self:DrawObjectives(self.frame.header)
    end
  end

  function ShowLevel(self)
    self.frame.headerLevel:Show()
  end

  function HideLevel(self)
    self.frame.headerLevel:Hide()
  end


  function Refresh(self)
    Theme.SkinFrame(self.frame)
    Theme.SkinFrame(self.frame.header)

    Theme.SkinText(self.frame.headerName, self.name)
    Theme.SkinText(self.frame.headerLevel, self.level)

    if Quest.showLevel then
      self:ShowLevel()
    else
      self:HideLevel()
    end

  end

  function Reset(self)
    --for _, objective in self.objectives:GetIterator() do
      --objective.isReusable = true
    --end

    self:ClearAllPoints()
    self:SetParent(nil)
    self:Hide()

    -- Reset properties
    self.numObjectives = nil
    self.id = nil
    self.name = nil
    self.level = nil
    self.header = nil
    self.distance = nil
    self.isBounty = nil
    self.isTask = nil
    self.isHidden = nil
    self.isOnMap = nil


    if self.questItem then
      self.questItem.isReusable = true
      self.questItem = nil
    end


    -- Reset variables
    --self.objectives =  ObjectArray(Objective)
    --self:ClearObjectives()

  end

  __Static__() function RefreshAll()
    for obj in pairs(_QuestCache) do
      obj:Refresh()
    end
  end

  --[[
  __Static__() property "showID" {
    GET = function(self) return _DB.Quest.showID end,
    SET = function(self, showID) _DB.Quest.showID = showID ; Quest:RefreshAll() end
  }

  __Static__() property "showLevel" {
    GET = function() return _DB.Quest.showLevel end,
    SET = function(self, showLevel) _DB.Quest.showLevel = showLevel ; Quest:RefreshAll() end
  }

  __Static__() property "showOnlyQuestsInZone" {
    GET = function() return _DB.Quest.showOnlyQuestsInZone end,
    SET = function(self, showInZone) _DB.Quest.showOnlyInQuestsInZone = showInZone end,
  }--]]


  function RegisterFramesForThemeAPI(self)
    local class = System.Reflector.GetObjectClass(self)

    Theme.RegisterFrame(class._THEME_CLASS_ID, self.frame)
    Theme.RegisterFrame(class._THEME_CLASS_ID..".header", self.frame.header)

    Theme.RegisterText(class._THEME_CLASS_ID..".name", self.frame.headerName)
    Theme.RegisterText(class._THEME_CLASS_ID..".level", self.frame.headerLevel)
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "id" { TYPE= Number, DEFAULT = -1 }
  property "name" { TYPE = String, HANDLER = UpdateProps, DEFAULT = ""}
  property "level" { TYPE = Number, DEFAULT = 0, HANDLER = UpdateProps }
  property "header" { TYPE = String, DEFAULT = "Misc"}
  property "distance" { TYPE = Number, DEFAULT = -1, HANDLER = UpdateProps }
  property "isBounty" { TYPE = Boolean, DEFAULT = false }
  property "isTask" { TYPE = Boolean, DEFAULT = false }
  property "isHidden" { TYPE = Boolean, DEFAULT = false }
  property "isOnMap" { TYPE = Boolean, DEFAULT = false, EVENT = "IsOnMapChanged" }
  -- Theme system
  property "tID" { DEFAULT = "quest"}
  __Static__() property "_THEME_CLASS_ID" { DEFAULT = "quest" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function Quest(self)
    Super(self)

    local frame = CreateFrame("Frame")
    frame:SetBackdrop(_Backdrops.Common)

    local headerFrame = CreateFrame("Button", nil, frame)
    headerFrame:SetBackdrop(_Backdrops.Common)
    headerFrame:SetPoint("TOPRIGHT")
    headerFrame:SetPoint("TOPLEFT")
    headerFrame:SetHeight(21) -- 14
    headerFrame:RegisterForClicks("RightButtonUp", "LeftButtonUp")

    -- Script
    headerFrame:SetScript("OnClick", function(_, button, down)
      if not self:MustBeInteractive(headerFrame) then
        return
      end

      if button == "LeftButton" then
        ShowQuestLog();
        QuestMapFrame_ShowQuestDetails(self.id);
      elseif button == "RightButton" then
        if _Addon.MenuContext:IsShown() then
          _Addon.MenuContext:Hide()
        else
          _Addon.MenuContext:Show()
          _Addon.MenuContext:AnchorTo(headerFrame)
          _Addon.MenuContext:Clear()
          _Addon.MenuContext:AddItem("Create a group", nil, function() GroupFinder:CreateGroup(self.id) end)
          _Addon.MenuContext:AddItem("Join a group", nil, function() GroupFinder:JoinGroup(self.id) end)
          _Addon.MenuContext:AddItem(MenuItemSeparator())
          _Addon.MenuContext:AddItem("Leave the group", nil, GroupFinder.LeaveGroup)
          _Addon.MenuContext:AddItem(MenuItemSeparator())
          if not QuestUtils_IsQuestWorldQuest(self.id) then
            if GetSuperTrackedQuestID() == self.id then
              _Addon.MenuContext:AddItem("Stop tracking", nil, function() SetSuperTrackedQuestID(0); QuestSuperTracking_ChooseClosestQuest() end)
            else
              _Addon.MenuContext:AddItem("Track", nil, function() SetSuperTrackedQuestID(self.id) end)
            end
          end
          _Addon.MenuContext:AddItem("Show details", nil, function()
            local questLogIndex = GetQuestLogIndexByID(self.id);
            if ( IsQuestComplete(self.id) and GetQuestLogIsAutoComplete(questLogIndex) ) then
              ShowQuestComplete(questLogIndex);
            else
              QuestLogPopupDetailFrame_Show(questLogIndex)
            end
          end)
          _Addon.MenuContext:AddItem(MenuItemSeparator())
          _Addon.MenuContext:AddItem("Help", nil, function() print("Put a Help handler here !") end).disabled = true
        end
      end
    end)

    local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerText:GetFontObject():SetShadowOffset(0.5, 0)
    headerText:GetFontObject():SetShadowColor(0, 0, 0, 0.4)
    headerText:SetPoint("LEFT", 10, 0)
    headerText:SetPoint("RIGHT")
    headerText:SetPoint("TOP")
    headerText:SetPoint("BOTTOM")

    local headerLevel = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerLevel:GetFontObject():SetShadowOffset(0.5, 0)
    headerLevel:GetFontObject():SetShadowColor(0, 0, 0, 0.4)
    headerLevel:SetPoint("RIGHT", -2)

    frame.headerName = headerText
    frame.headerLevel = headerLevel
    frame.header = headerFrame

    self.frame = frame
    self.height = 21
    self.baseHeight = self.height

    -- Important : Always use 'This' to avoid issues when this class is inherited
    -- by other classes.
    This.RegisterFramesForThemeAPI(self)
    This.Refresh(self)

    _QuestCache[self] = true
  end

  -- Say to option the keyword available
  __Static__()
  function InstallOptions(self, child)
    local class = child or self
    local prefix = class._THEME_CLASS_ID and class._THEME_CLASS_ID or ""
    local superClass = System.Reflector.GetSuperClass(self)
    if superClass.InstallOptions then
      superClass:InstallOptions(class)
    end

    Options.AddAvailableThemeKeywords(
      Options.ThemeKeyword(prefix, Options.ThemeKeywordType.FRAME),
      Options.ThemeKeyword(prefix..".header", Options.ThemeKeywordType.FRAME),
      Options.ThemeKeyword(prefix..".name", Options.ThemeKeywordType.TEXT),
      Options.ThemeKeyword(prefix..".level", Options.ThemeKeywordType.TEXT)
    )
  end

endclass "Quest"
Quest:InstallOptions()
Theme.RegisterRefreshHandler("quest", Quest.RefreshAll)

--============================================================================--
-- OnLoad Handler
--============================================================================--
function OnLoad(self)
  Options:Register("quest-show-id", false)
  Options:Register("quest-show-level", true)

  -- Register this class in the object manager
  _ObjectManager:Register(Quest)
end
