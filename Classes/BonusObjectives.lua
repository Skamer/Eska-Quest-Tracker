--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio             "EskaQuestTracker.Classes.BonusObjective"                 ""
--============================================================================--
namespace "EQT"                                                               --                                                           --
--============================================================================--
class "BonusQuest" inherit "Quest"
  _BonusQuestCache = setmetatable( {}, { __mode = "k" })
  ------------------------------------------------------------------------------
  --                                   Methods                                --
  ------------------------------------------------------------------------------
  __Arguments__{}
  function Draw(self)
    super.Draw(self)
  end

  __Arguments__ { Variable.Optional(Theme.SkinInfo, Theme.SKIN_INFO_ALL_FLAGS) }
  __Static__() function RefreshAll(skinInfo)
    for obj in pairs(_BonusQuestCache) do
      obj:Refresh(skinInfo)
    end
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  __Static__() property "_prefix" { DEFAULT = "bonusQuest" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function BonusQuest(self)
    super(self)

    -- Keep it in the cache for later.
    _BonusQuestCache[self] = true
  end
endclass "BonusQuest"

class "BonusObjectives" inherit "Block"
  _BonusObjectivesCache = setmetatable( {}, { __mode = "k" } )
  ------------------------------------------------------------------------------
  --                                   Methods                                --
  ------------------------------------------------------------------------------
  __Arguments__ { BonusQuest }
  function AddBonusQuest(self, bonusQuest)
    if not self.bonusQuests:Contains(bonusQuest) then
      self.bonusQuests:Insert(bonusQuest)
      bonusQuest:SetParent(self.frame)

      bonusQuest.OnHeightChanged = function(bq, new, old)
        self.height = self.height + (new - old)
      end

      self:OnDrawRequest()
    end
  end

  __Arguments__ { Number }
  function RemoveBonusQuest(self, bonusQuestID)
    local bonusQuest = self:GetBonusQuest(bonusQuestID)
    if bonusQuest then
      self:RemoveBonusQuest(bonusQuest)
    end
  end

  __Arguments__ { BonusQuest }
  function RemoveBonusQuest(self, bonusQuest)
    local found = self.bonusQuests:Remove(bonusQuest)
    if found then
      bonusQuest.OnHeightChanged = nil
      bonusQuest.isReusable = true

      self:OnDrawRequest()
    end
  end

  __Arguments__ { Number }
  function GetBonusQuest(self, bonusQuestID)
    for _, bonusQuest in self.bonusQuests:GetIterator() do
      if bonusQuest.id == bonusQuestID then
        return bonusQuest
      end
    end
  end

  __Arguments__()
  function Draw(self)
    local previousFrame
    local height = 0

    for index, bonusQuest in self.bonusQuests:GetIterator() do
      bonusQuest:ClearAllPoints()
      bonusQuest:Show()
      bonusQuest:Draw()

      if index == 1 then
        bonusQuest.frame:SetPoint("TOPLEFT", 0, -40)
        bonusQuest.frame:SetPoint("TOPRIGHT", 20, -40)
      else
        bonusQuest.frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
        bonusQuest.frame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
      end

      height = height + bonusQuest.height
      previousFrame = bonusQuest.frame
    end

    self.height = self.baseHeight + height
  end

  __Arguments__ { Variable.Optional(Theme.SkinInfo, Theme.SKIN_INFO_ALL_FLAGS) }
  __Static__() function RefreshAll(skinInfo)
    for obj in pairs(_BonusObjectivesCache) do
      obj:Refresh(skinInfo)
    end
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  __Static__() property "_prefix" { DEFAULT = "block.bonusObjectives" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function BonusObjectives(self)
    super(self, "bonusObjectives", 12)
    self.text = "Bonus Objectives"

    self.bonusQuests = Array[BonusQuest]()

    -- Keep it in the cache for later.
    _BonusObjectivesCache[self] = true
  end

endclass "BonusObjectives"


function OnLoad(self)
  _ObjectManager:Register(BonusQuest)

  -- Register the refresher
  CallbackHandlers:Register("bonusQuest/refresher", CallbackHandler(BonusQuest.RefreshAll))
  CallbackHandlers:Register("bonusObjectives/refresher", CallbackHandler(BonusObjectives.RefreshAll))
end
