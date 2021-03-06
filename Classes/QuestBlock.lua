--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio               "EskaQuestTracker.Classes.QuestBlock"                   ""
--============================================================================--
namespace "EQT"
--============================================================================--
class "QuestBlock" inherit "Block"
  _QuestBlockCache = setmetatable( {}, { __mode = "k" } )
  ------------------------------------------------------------------------------
  --                                   Methods                                --
  ------------------------------------------------------------------------------
  __Arguments__{ Quest }
  function AddQuest(self, quest)
    if not self.quests:Contains(quest) then
      if Options:Get("quest-categories-enabled") then
        local header = self:GetHeader(quest.header)
        if not header then
          header = self:NewHeader(quest.header)
        end
        header:AddQuest(quest)
      else
        quest:SetParent(self.frame)
        quest.OnHeightChanged = function(_, new, old)
          self.height = self.height + (new - old)
        end
        quest.OnDistanceChanged = function() self:OnDrawRequest() end
      end
      self.quests:Insert(quest)
      self:OnDrawRequest()
      Scorpio.FireSystemEvent("EQT_QUESTBLOCK_QUEST_ADDED", quest)
    end
  end

  __Arguments__ { Quest }
  function RemoveQuestFromHeader(self, quest)
    local header = self:GetHeader(quest.header)
    if header then
      header:RemoveQuest(quest)
      if header:GetQuestNum() == 0 then
        header.OnHeightChanged = nil
        header.OnDrawRequest = nil
        self:RemoveHeader(quest.header)
        header.isReusable = true
      end
    end
  end

  __Arguments__ { Number }
  function RemoveQuest(self, questID)
    local quest = self:GetQuest(questID)
    if quest then
      self:RemoveQuest(quest)
    end
  end

  __Arguments__ { Quest }
  function RemoveQuest(self, quest)
    self.quests:Remove(quest)

    if Options:Get("quest-categories-enabled") then
      self:RemoveQuestFromHeader(quest)
    end
    self:OnDrawRequest()

    Scorpio.FireSystemEvent("EQT_QUESTBLOCK_QUEST_REMOVED", quest)
    quest.isReusable = true
  end

  __Arguments__ { Number }
  function GetQuest(self, questID)
    for _, quest in self.quests:GetIterator() do
      if quest.id == questID then
        return quest
      end
    end
  end

  __Arguments__ { String }
  function GetHeader(self, name)
    return self.headers[name]
  end

  __Arguments__ { String }
  function NewHeader(self, name)
    local header = _ObjectManager:GetQuestHeader()
    header.name = name
    header._sortIndex = nil
    header:SetParent(self.frame)

    header.OnHeightChanged = function(h, new, old)
      self.height = self.height + (new - old)
    end

    header.OnQuestDistanceChanged = function(h)
      self:OnDrawRequest()
    end

    self.headers[name] = header

    return header
  end

  __Arguments__ { String }
  function RemoveHeader(self, name)
    self.headers[name] = nil
  end

  -- This function is called when the frame needs to update the anchors of its children.
  -- You should avoid to call it directly, except if you know you're doing.
  -- It's prefered to use self.OnDrawRequest instead, that is a safe way to call indirectly Draw().
  __Arguments__()
  function Draw(self)
    local enableCategories = Options:Get("quest-categories-enabled")

    local previousFrame
    local height = 0

    if enableCategories then
      -- Header compare function
      local function HeaderSortMethod(a, b)
        if a.nearestQuestDistance ~= b.nearestQuestDistance then
          return a.nearestQuestDistance < b.nearestQuestDistance
        end
        return a.name < b.name
      end

      for index, header in self.headers.Values:ToList():Sort(HeaderSortMethod):GetIterator() do
        if not header:IsShown() then
          header:Show()
        end

        header:ClearAllPoints()

        if index == 1 then
          header.frame:SetPoint("TOPLEFT", 0, -35)
          header.frame:SetPoint("TOPRIGHT", 0, -35)
        else
          header.frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -2)
          header.frame:SetPoint("RIGHT", previousFrame, "BOTTOMRIGHT")
        end

        previousFrame = header.frame
      end
    else
      -- Quest compare function (Priorty : Distance > ID > Name)
      local function QuestSortMethod(a, b)
        if a.distance ~= b.distance then
          return a.distance < b.distance
        end

        if a.id ~= b.id then
          return a.id < b.id
        end
        return a.name < b.name
      end

      for index, quest in self.quests:Sort(QuestSortMethod):GetIterator() do
        if not quest:IsShown() then
          quest:Show()
        end
        quest:ClearAllPoints()
        if index == 1 then
          --quest.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -36) -- -36
          --quest.frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT")
          quest:SetPoint("TOP", 0, -36)
          quest:SetPoint("LEFT")
          quest:SetPoint("RIGHT")
        else
          quest:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -10)
          quest:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
        end

        previousFrame = quest.frame

      end
    end

    self:CalculateHeight()
  end

  function CalculateHeight(self)
    local height = self.baseHeight
    if Options:Get("quest-categories-enabled") then
      for index, header in self.headers.Values:ToList():GetIterator() do
        local offset = 2

        height = height + header.height + offset
      end
    else
      for index, quest in self.quests:GetIterator() do
        local offset = 10

        height = height + quest.height + offset
      end
    end

    self.height = height
  end

  function EnableCategories(self)
    for index, quest in self.quests:GetIterator() do
      local header = self:GetHeader(quest.header)

      -- Remove event register by the block
      quest.OnHeightChanged = nil
      quest.OnDistanceChanged = nil

      if not header then
        header = self:NewHeader(quest.header)
      end
      -- The quest header handles everything (anchor, register event, ...)
      header:AddQuest(quest)
    end
    -- Request a draw to displaying changes
    self:OnDrawRequest()
  end

  function DisableCategories(self)
    for index, quest in self.quests:GetIterator() do
      self:RemoveQuestFromHeader(quest)

      -- Don't forget to change the parent
      quest:SetParent(self.frame)

      -- Register events
      quest.OnHeightChanged = function(_, new, old)
        self.height = self.height + (new - old )
      end
      quest.OnDistanceChanged = function() self:OnDrawRequest() end
    end
    -- Request a draw to displaying changes
    self:OnDrawRequest()
  end


  __Static__() function SetCategoriesEnabled(enabled)
    for obj in pairs(_QuestBlockCache) do
      if enabled then
        obj:EnableCategories()
      else
        obj:DisableCategories()
      end
    end
  end


  __Arguments__ { Variable.Optional(Theme.SkinInfo, Theme.SKIN_INFO_ALL_FLAGS) }
  __Static__() function RefreshAll(skinInfo)
    for obj in pairs(_QuestBlockCache) do
      obj:Refresh(skinInfo)
    end
  end

  __Static__() property "showOnlyQuestsInZone" {
    TYPE = Boolean,
    SET = function(self, filteringByZone)
      _DB.Quests.filteringByZone = filteringByZone
      Scorpio.FireSystemEvent("EQT_SHOW_ONLY_QUESTS_IN_ZONE", filteringByZone)
    end,
    GET = function(self) return _DB.Quests.filteringByZone end
  }
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  __Static__() property "_prefix" { DEFAULT = "block.quests" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function QuestBlock(self)
    super(self, "quests", 20)
    self.text = "Quests"


    self.quests = Array[Quest]()
    self.headers = Dictionary()

    -- Keep it in the cache for later.
    _QuestBlockCache[self] = true
  end
endclass "QuestBlock"

-- /run EQT.Options:Set("quest-categories-enabled", true)
function OnLoad(self)
  Options:Register("quest-categories-enabled", true, "quests/setCategoriesEnabled")

  CallbackHandlers:Register("quests/refresher", CallbackHandler(QuestBlock.RefreshAll))
  CallbackHandlers:Register("quests/setCategoriesEnabled", CallbackHandler(QuestBlock.SetCategoriesEnabled))
end
