--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio                   "EskaQuestTracker.Block"                            ""
--============================================================================--
namespace "EQT"
--============================================================================--
class "Block" inherit "Frame"
  event "OnActiveChanged"
  _BlockCache = setmetatable( {}, { __mode = "k"})
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  function SetText(self, new)
    Theme:SkinText(self.frame.header.text, new)
  end
  ------------------------------------------------------------------------------
  --                                   Methods                                --
  ------------------------------------------------------------------------------
  __Arguments__ {}
  function Refresh(self)
    Theme:SkinFrame(self.frame)
    Theme:SkinFrame(self.frame.header, self.text)
    Theme:SkinTexture(self.frame.header.stripe)
  end


  __Arguments__ {}
  function RegisterFramesForThemeAPI(self, child)
    local class = System.Reflector.GetObjectClass(self)

    Theme:RegisterFrame(class._THEME_CLASS_ID, self.frame, "block")
    Theme:RegisterFrame(class._THEME_CLASS_ID..".header", self.frame.header, "block.header")
    Theme:RegisterTexture(class._THEME_CLASS_ID..".stripe", self.frame.header.stripe, "block.stripe")
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
      Options.ThemeKeyword(prefix..".header", Options.ThemeKeywordType.FRAME + Options.ThemeKeywordType.TEXT),
      Options.ThemeKeyword(prefix..".stripe", Options.ThemeKeywordType.TEXTURE)
    )
  end

  __Static__() function RefreshAll()
    for obj in pairs(_BlockCache) do
      obj:Refresh()
    end
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "id" { TYPE = String }
  property "text" { TYPE = String, DEFAULT = "Default Header Text", HANDLER = SetText}
  property "isActive" { TYPE = Boolean, DEFAULT = true, EVENT = "OnActiveChanged" }
  property "priority" { TYPE = Number, DEFAULT = 100 }

  __Static__() property "_THEME_CLASS_ID" { DEFAULT = "block" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { }
  function Block(self)
    Super(self)

    local frame = CreateFrame("Frame")
    frame:SetBackdrop(_Backdrops.CommonWithBiggerBorder)

    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetPoint("TOPLEFT")
    headerFrame:SetPoint("TOPRIGHT", 2, 0)
    headerFrame:SetFrameStrata("HIGH")
    headerFrame:SetHeight(34) -- 24
    headerFrame:SetBackdrop(_Backdrops.CommonWithBiggerBorder)
    frame.header = headerFrame

    local stripe = headerFrame:CreateTexture()
    stripe:SetAllPoints()
    stripe:SetTexture([[Interface\AddOns\EskaQuestTracker\Media\Textures\Stripe]])
    stripe:SetDrawLayer("ARTWORK", 2)
    stripe:SetBlendMode("ALPHAKEY")
    stripe:SetVertexColor(0, 0, 0, 0.5)
    headerFrame.stripe = stripe

    local headerText = headerFrame:CreateFontString(nil, "OVERLAY")
    headerText:SetAllPoints()
    --headerText:SetPoint("CENTER", -10, 20)
    headerText:SetShadowColor(0, 0, 0, 0.25)
    headerText:SetShadowOffset(1, -1)
    headerFrame.text = headerText

    self.frame = frame
    self.height = 34
    self.baseHeight = self.height

    -- Important : Always use 'This' to avoid issues when this class is inherited
    -- by other classes.
    This.RegisterFramesForThemeAPI(self)
    This.Refresh(self)

    _BlockCache[self] = true
  end

  __Arguments__{ String, Number }
  function Block(self, id, priority)
    self.id = id
    self.priority = priority

    This(self)
  end
endclass "Block"
Block:InstallOptions()
--Theme.RegisterRefreshHandler("block", Block.RefreshAll)
-- ========================================================================== --
-- == OnLoad Handler
-- ========================================================================== --
function OnLoad(self)
  CallbackHandlers:Register("block/refresher", CallbackHandler(Block.RefreshAll), "refresher")
end
