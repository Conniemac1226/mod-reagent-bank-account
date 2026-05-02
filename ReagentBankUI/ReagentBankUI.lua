-- ReagentBankUI custom skin v12
-- WotLK 3.3.5a-safe: no Retail APIs, no Blizzard button templates in the main window.
local ADDON_NAME = ...
if not ADDON_NAME or ADDON_NAME == "" then
    ADDON_NAME = "ReagentBankUI"
end

local RB = CreateFrame("Frame", "ReagentBankUIController")
_G.ReagentBankUI = RB

local COMMAND_PREFIX = ".rbank"

local CATEGORY_ORDER = {
    { id = 5,  name = "Cloth",             sample = 2589  },
    { id = 8,  name = "Meat",              sample = 12208 },
    { id = 7,  name = "Metal & Stone",     sample = 2772  },
    { id = 12, name = "Enchanting",        sample = 10940 },
    { id = 10, name = "Elemental",         sample = 7068  },
    { id = 1,  name = "Parts",             sample = 4359  },
    { id = 11, name = "Other Trade Goods", sample = 2604  },
    { id = 9,  name = "Herb",              sample = 2453  },
    { id = 6,  name = "Leather",           sample = 2318  },
    { id = 4,  name = "Jewelcrafting",     sample = 1206  },
    { id = 2,  name = "Explosives",        sample = 4358  },
    { id = 3,  name = "Devices",           sample = 4388  },
    { id = 13, name = "Nether Material",   sample = 23572 },
    { id = 14, name = "Armor Vellum",      sample = 38682 },
    { id = 15, name = "Weapon Vellum",     sample = 39349 },
}

local CATEGORY_BY_ID = {}
for _, category in ipairs(CATEGORY_ORDER) do
    CATEGORY_BY_ID[category.id] = category
end

local BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local PANEL_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local BUTTON_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local SKIN = {
    windowBg = { 0.025, 0.028, 0.040, 0.98 },
    windowBorder = { 0.72, 0.52, 0.24, 0.95 },
    panelBg = { 0.045, 0.050, 0.070, 0.86 },
    panelBorder = { 0.23, 0.26, 0.31, 1.00 },
    headerBg = { 0.10, 0.075, 0.035, 0.95 },
    headerLine = { 0.95, 0.72, 0.28, 0.82 },
    buttonBg = { 0.105, 0.085, 0.050, 0.94 },
    buttonBorder = { 0.58, 0.42, 0.18, 0.95 },
    buttonHover = { 1.00, 0.78, 0.28, 0.18 },
    buttonDown = { 0.045, 0.036, 0.025, 0.98 },
    closeBg = { 0.22, 0.045, 0.035, 0.95 },
    closeBorder = { 0.86, 0.30, 0.18, 0.95 },
    rowOdd = { 0.070, 0.075, 0.095, 0.35 },
    rowEven = { 0.030, 0.034, 0.048, 0.18 },
    rowHover = { 1.00, 0.82, 0.32, 0.13 },
    blueText = { 0.62, 0.78, 1.00 },
}

local DEFAULT_SCALE = 0.92
local ROW_COUNT = 15
local ROW_HEIGHT = 24
local ROW_SPACING = 2
local REQUEST_TIMEOUT_SECONDS = 8.0
local MUTATION_REFRESH_DELAY = 0.85
local ITEM_CACHE_REFRESH_INTERVAL = 0.35
local ITEM_CACHE_REFRESH_TIMEOUT = 8.0
local AUTO_DEPOSIT_AFTER_CLOSE_DELAY = 0.80
local AUTO_DEPOSIT_PREP_EXPIRE_SECONDS = 300
local TRADE_SKILL_PREPARE_COUNT_MIN = 1
local TRADE_SKILL_PREPARE_COUNT_MAX = 999

-- Main window top action button placement.
-- Change these to move/resize Deposit All, Withdraw All, and Refresh.
local ROOT_BUTTON_ROW_X = 18
local ROOT_BUTTON_ROW_Y = -60
local ROOT_ACTION_BUTTON_WIDTH = 118
local ROOT_REFRESH_BUTTON_WIDTH = 96
local ROOT_BUTTON_HEIGHT = 24
local ROOT_BUTTON_GAP = 8
local ROOT_HELP_TEXT_GAP = 12

-- Category/detail navigation button placement.
-- Change these to move/resize Categories, Deposit Category, Withdraw Category, Prev, and Next.
local CATEGORY_BUTTON_ROW_X = 18
local CATEGORY_BUTTON_ROW_Y = -90
local CATEGORY_BACK_BUTTON_WIDTH = 96
local CATEGORY_ACTION_BUTTON_WIDTH = 148
local CATEGORY_PAGE_BUTTON_WIDTH = 72
local CATEGORY_BUTTON_HEIGHT = 24
local CATEGORY_BUTTON_GAP = 8
local CATEGORY_PAGE_TEXT_GAP = 10

-- PaperDoll toggle button placement/style.
-- Uses the same round minimap-style art as the PaperDollAHButton example.
-- Primary position: immediately to the right of PaperDollAHButton.
-- Fallback position is used if PaperDollAHButton is not loaded yet.
local PAPERDOLL_BUTTON_ENABLED = true
local PAPERDOLL_BUTTON_PARENT = "PaperDollFrame"
local PAPERDOLL_ANCHOR_BUTTON_NAME = "PaperDollAHButton"
local PAPERDOLL_BUTTON_GAP = 2

-- Fallback: this matches the AH button's sample position and places this button
-- directly to the right of it: AH TOPRIGHT is -324, -474; this TOPLEFT is -322, -474.
local PAPERDOLL_BUTTON_FALLBACK_POINT = "TOPLEFT"
local PAPERDOLL_BUTTON_FALLBACK_RELATIVE_POINT = "TOPRIGHT"
local PAPERDOLL_BUTTON_FALLBACK_X = -322
local PAPERDOLL_BUTTON_FALLBACK_Y = -474

local PAPERDOLL_BUTTON_SIZE = 32
local PAPERDOLL_BUTTON_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local PAPERDOLL_BUTTON_ICON_SIZE = 17
local PAPERDOLL_BUTTON_ICON_CROP = 0.08

local PAPERDOLL_BUTTON_BG_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBackground"
local PAPERDOLL_BUTTON_BG_SIZE = 20
local PAPERDOLL_BUTTON_BG_R = 0.15
local PAPERDOLL_BUTTON_BG_G = 0.15
local PAPERDOLL_BUTTON_BG_B = 0.15
local PAPERDOLL_BUTTON_BG_A = 0.95

local PAPERDOLL_BUTTON_BORDER_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBorder"
local PAPERDOLL_BUTTON_BORDER_SIZE = 54

local PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local PAPERDOLL_BUTTON_HIGHLIGHT_SIZE = 52
local MINIMAP_BUTTON_DEFAULT_ENABLED = false
local MINIMAP_BUTTON_SIZE = 32
local MINIMAP_BUTTON_ICON_SIZE = 17
local MINIMAP_BUTTON_ICON_CROP = 0.08
local MINIMAP_BUTTON_DEFAULT_ANGLE = 220

local function Trim(text)
    if not text then
        return ""
    end

    text = tostring(text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function SplitColon(text)
    local parts = {}

    for part in string.gmatch(text or "", "([^:]+)") do
        table.insert(parts, part)
    end

    return parts
end

local function FormatCount(value)
    value = tonumber(value) or 0

    if value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    end

    if value >= 10000 then
        return string.format("%.1fk", value / 1000)
    end

    return tostring(value)
end

local function GetItemDisplay(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return "Interface\\Icons\\INV_Misc_QuestionMark", "Unknown item", nil, 1, false
    end

    local name, link, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, icon = GetItemInfo(itemEntry)
    local missingInfo = name == nil or link == nil

    if not icon then
        icon = GetItemIcon(itemEntry)
    end

    if not name then
        name = "Item #" .. tostring(itemEntry)
    end

    stackCount = tonumber(stackCount) or 1
    if stackCount < 1 then
        stackCount = 1
    end

    return icon or "Interface\\Icons\\INV_Misc_QuestionMark", name, link, stackCount, missingInfo
end

local function HideTooltip()
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip:Hide()
    end
end

local function SetTooltipItem(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink("item:" .. tostring(itemEntry) .. ":0:0:0:0:0:0:0")
    GameTooltip:Show()
end

local function ParseItemIdFromLink(link)
    if not link then
        return nil
    end

    local itemId = string.match(link, "item:(%d+):")
    return tonumber(itemId)
end

local function PrintAddon(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r " .. tostring(message or ""))
    end
end

local function SafeDate()
    if date then
        return date("%H:%M:%S")
    end

    return "now"
end

function RB:MakeBackdrop(frame, alpha, panel)
    if panel then
        frame:SetBackdrop(PANEL_BACKDROP)
        frame:SetBackdropColor(SKIN.panelBg[1], SKIN.panelBg[2], SKIN.panelBg[3], alpha or SKIN.panelBg[4])
        frame:SetBackdropBorderColor(SKIN.panelBorder[1], SKIN.panelBorder[2], SKIN.panelBorder[3], SKIN.panelBorder[4])
        return
    end

    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(SKIN.windowBg[1], SKIN.windowBg[2], SKIN.windowBg[3], alpha or SKIN.windowBg[4])
    frame:SetBackdropBorderColor(SKIN.windowBorder[1], SKIN.windowBorder[2], SKIN.windowBorder[3], SKIN.windowBorder[4])
end

function RB:SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
        button:SetAlpha(1.0)
        if button.label then
            button.label:SetTextColor(1.00, 0.86, 0.46)
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
        end
    else
        button:Disable()
        button:SetAlpha(0.48)
        if button.label then
            button.label:SetTextColor(0.55, 0.55, 0.55)
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(0.22, 0.22, 0.24, 0.90)
        end
    end
end

function RB:Status(text, r, g, b)
    self.lastStatus = text

    if self.frame and self.frame.status then
        self.frame.status:SetText(text or "")
        self.frame.status:SetTextColor(r or 0.70, g or 0.70, b or 0.70)
    end
end

function RB:EnsureOnUpdate()
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame:OnUpdate(elapsed)
    end)
end

function RB:BeginBusy(kind, text)
    self.busyKind = kind or "request"
    self.busyText = text or "Working..."
    self.busyStartedAt = GetTime()

    self:Status(self.busyText, 0.82, 0.82, 0.82)
    self:UpdateControls()
    self:EnsureOnUpdate()
end

function RB:ClearBusy(text, r, g, b)
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil

    self:UpdateControls()

    if text then
        self:Status(text, r or 0.45, g or 1.00, b or 0.45)
    end
end

function RB:ScheduleRefresh(delay, view, categoryId, page)
    delay = tonumber(delay) or MUTATION_REFRESH_DELAY

    self.pendingRefresh = {
        at = GetTime() + delay,
        view = view or self.currentView or "root",
        categoryId = categoryId or self.currentCategoryId,
        page = page or self.currentPage or 0,
    }

    self:EnsureOnUpdate()
end

function RB:ScheduleCurrentRefresh(delay)
    if self.currentView == "category" or self.currentView == "detail" then
        if self.currentCategoryId then
            self:ScheduleRefresh(delay, "category", self.currentCategoryId, self.currentPage or 0)
            return
        end
    end

    self:ScheduleRefresh(delay, "root", nil, 0)
end

function RB:QueueItemInfoRefresh()
    local now = GetTime()

    if not self.itemInfoRefreshStartedAt then
        self.itemInfoRefreshStartedAt = now
    end

    self.nextItemInfoRefreshAt = now + ITEM_CACHE_REFRESH_INTERVAL
    self:EnsureOnUpdate()
end

function RB:ClearItemInfoRefresh()
    self.itemInfoRefreshStartedAt = nil
    self.nextItemInfoRefreshAt = nil
end

function RB:RefreshItemInfoIfNeeded()
    self.nextItemInfoRefreshAt = nil

    if not self.frame or not self.frame:IsShown() then
        self:ClearItemInfoRefresh()
        return
    end

    if self.itemInfoRefreshStartedAt and GetTime() - self.itemInfoRefreshStartedAt >= ITEM_CACHE_REFRESH_TIMEOUT then
        self:ClearItemInfoRefresh()
        return
    end

    if self.currentView == "category" and self.currentCategoryId then
        self:RenderCategory(true)
        return
    end

    if self.currentView == "detail" and self.detailItem then
        self:ShowDetail(self.detailItem, true)
        return
    end

    self:ClearItemInfoRefresh()
end

function RB:OnUpdate(elapsed)
    local now = GetTime()

    if self.pendingAutoDepositAt and now >= self.pendingAutoDepositAt then
        self.pendingAutoDepositAt = nil
        self:DepositPreparedLeftovers()
    end

    if self.pendingRefresh and now >= self.pendingRefresh.at then
        local refresh = self.pendingRefresh
        self.pendingRefresh = nil

        if refresh.view == "category" and refresh.categoryId then
            self:RequestCategory(refresh.categoryId, refresh.page or 0)
        else
            self:RequestRoot()
        end

        return
    end

    if self.nextItemInfoRefreshAt and now >= self.nextItemInfoRefreshAt then
        self:RefreshItemInfoIfNeeded()
    end

    if self.busyStartedAt and now - self.busyStartedAt >= REQUEST_TIMEOUT_SECONDS then
        self:ClearBusy("No server data yet. Press Refresh to try again.", 1.00, 0.82, 0.32)
    end

    if not self.pendingRefresh and not self.busyStartedAt and not self.pendingAutoDepositAt and not self.nextItemInfoRefreshAt then
        self:SetScript("OnUpdate", nil)
    end
end

function RB:SendServerCommand(command)
    command = Trim(command or "")

    if command == "" then
        command = "open"
    end

    SendChatMessage(COMMAND_PREFIX .. " " .. command, "SAY")
end

function RB:RequestRoot()
    self.pendingRefresh = nil
    self.awaitingView = "root"

    self:BeginBusy("request", "Refreshing categories...")
    self:SendServerCommand("open")
end

function RB:RequestCategory(categoryId, page)
    categoryId = tonumber(categoryId)
    page = tonumber(page) or 0

    if not categoryId then
        self:RequestRoot()
        return
    end

    self.pendingRefresh = nil
    self.awaitingView = "category"

    local category = CATEGORY_BY_ID[categoryId]
    local categoryName = category and category.name or "category"

    self:BeginBusy("request", "Loading " .. categoryName .. "...")
    self:SendServerCommand("list " .. tostring(categoryId) .. " " .. tostring(page))
end

function RB:DepositAll()
    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Depositing all reagents...")
    self:SendServerCommand("deposit all")
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:WithdrawAll()
    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Withdrawing all reagents...")
    self:SendServerCommand("withdraw all")
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:DepositCategory()
    if not self.currentCategoryId then
        return
    end

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Depositing this category...")
    self:SendServerCommand("deposit category " .. tostring(self.currentCategoryId))
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", self.currentCategoryId, self.currentPage or 0)
end

function RB:WithdrawCategory()
    if not self.currentCategoryId then
        return
    end

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing this category...")
    self:SendServerCommand("withdraw category " .. tostring(self.currentCategoryId))
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", self.currentCategoryId, self.currentPage or 0)
end

function RB:GetOptimisticWithdrawAmount(item, mode, exactAmount)
    if not item then
        return 0
    end

    local stored = tonumber(item.amount) or 0
    if stored <= 0 then
        return 0
    end

    if mode == "one" then
        return math.min(stored, 1)
    end

    if mode == "stack" then
        local icon, name, link, stackCount = GetItemDisplay(item.entry)
        return math.min(stored, stackCount or 1)
    end

    if mode == "all" then
        return stored
    end

    if mode == "exact" then
        return math.min(stored, math.max(tonumber(exactAmount) or 0, 0))
    end

    return 0
end

function RB:ApplyOptimisticWithdraw(itemEntry, amount)
    itemEntry = tonumber(itemEntry)
    amount = tonumber(amount) or 0

    if not itemEntry or amount <= 0 then
        return
    end

    local removedType = false

    if self.items then
        local index = 1
        while index <= #self.items do
            local item = self.items[index]
            if item and tonumber(item.entry) == itemEntry then
                local newAmount = math.max((tonumber(item.amount) or 0) - amount, 0)
                item.amount = newAmount

                if newAmount <= 0 then
                    table.remove(self.items, index)
                    removedType = true
                end

                break
            end

            index = index + 1
        end
    end

    if self.detailItem and tonumber(self.detailItem.entry) == itemEntry then
        self.detailItem.amount = math.max((tonumber(self.detailItem.amount) or 0) - amount, 0)
    end

    if self.currentCategoryId then
        self.categoryAmount = math.max((tonumber(self.categoryAmount) or 0) - amount, 0)

        if removedType then
            self.categoryTypeCount = math.max((tonumber(self.categoryTypeCount) or 0) - 1, 0)
        end

        if self.categories and self.categories[self.currentCategoryId] then
            local category = self.categories[self.currentCategoryId]
            category.amount = math.max((tonumber(category.amount) or 0) - amount, 0)

            if removedType then
                category.types = math.max((tonumber(category.types) or 0) - 1, 0)
            end
        end
    end

    if self.currentView == "detail" then
        if self.detailItem and (tonumber(self.detailItem.amount) or 0) > 0 then
            self:ShowDetail(self.detailItem, true)
        else
            self:RenderCategory(true)
        end
    elseif self.currentView == "category" then
        self:RenderCategory(true)
    end
end

function RB:GetExactWithdrawAmount()
    if not self.frame or not self.frame.exactBox then
        return 0
    end

    local amount = tonumber(self.frame.exactBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:WithdrawItem(mode)
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    mode = mode or "one"

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, mode)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing item...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " " .. tostring(mode) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:WithdrawItemExact()
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    local amount = self:GetExactWithdrawAmount()
    if amount <= 0 then
        self:Status("Enter an exact amount first.", 1.00, 0.82, 0.32)
        return
    end

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, "exact", amount)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing exact amount...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " exact " .. tostring(amount) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Exact withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    if self.frame and self.frame.exactBox then
        self.frame.exactBox:SetText("")
        self.frame.exactBox:ClearFocus()
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:ClampTradeSkillPrepareCount(value)
    value = math.floor(tonumber(value) or 1)

    if value < TRADE_SKILL_PREPARE_COUNT_MIN then
        value = TRADE_SKILL_PREPARE_COUNT_MIN
    end

    if value > TRADE_SKILL_PREPARE_COUNT_MAX then
        value = TRADE_SKILL_PREPARE_COUNT_MAX
    end

    return value
end

function RB:GetNativeTradeSkillRepeatCount()
    local input = _G.TradeSkillInputBox
    if input and input.GetNumber then
        local value = tonumber(input:GetNumber())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    if input and input.GetText then
        local value = tonumber(input:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    return 1
end

function RB:GetTradeSkillRepeatCount()
    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local value = tonumber(self.tradeSkillQuantityBox:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local saved = tonumber(ReagentBankUIDB.tradeSkillPrepareCount)
    if saved and saved > 0 then
        return self:ClampTradeSkillPrepareCount(saved)
    end

    return self:GetNativeTradeSkillRepeatCount()
end

function RB:SetTradeSkillPrepareCount(value, updateNative)
    value = self:ClampTradeSkillPrepareCount(value)

    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.tradeSkillPrepareCount = value

    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local textValue = tostring(value)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if updateNative then
        self:SyncNativeTradeSkillRepeatCount(value)
    end

    self:UpdateTradeSkillControls()
    return value
end

function RB:NormalizeTradeSkillQuantityBox(updateNative)
    return self:SetTradeSkillPrepareCount(self:GetTradeSkillRepeatCount(), updateNative)
end

function RB:SyncNativeTradeSkillRepeatCount(value)
    value = self:ClampTradeSkillPrepareCount(value)

    local input = _G.TradeSkillInputBox
    if not input then
        return
    end

    self.suppressNativeTradeSkillQuantityChanged = true

    if input.SetNumber then
        input:SetNumber(value)
    elseif input.SetText then
        input:SetText(tostring(value))
    end

    self.suppressNativeTradeSkillQuantityChanged = nil
end

function RB:GetSelectedTradeSkillNeeds()
    if not GetTradeSkillSelectionIndex or not GetTradeSkillInfo or not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo then
        return nil, "The trade skill API is not available.", nil, nil
    end

    local index = GetTradeSkillSelectionIndex()
    if not index or index <= 0 then
        return nil, "Select a recipe first.", nil, nil
    end

    local recipeName, recipeType, numAvailable, isExpanded = GetTradeSkillInfo(index)
    if isExpanded or recipeType == "header" then
        return nil, "Select a craftable recipe, not a category header.", nil, nil
    end

    local reagentCount = GetTradeSkillNumReagents(index) or 0
    if reagentCount <= 0 then
        return nil, "Selected recipe has no item reagents.", recipeName, 1
    end

    local repeatCount = self:GetTradeSkillRepeatCount()
    local byItem = {}
    local order = {}

    for reagentIndex = 1, reagentCount do
        local reagentName, reagentTexture, requiredCount, playerCount = GetTradeSkillReagentInfo(index, reagentIndex)
        requiredCount = tonumber(requiredCount) or 0

        local link = nil
        if GetTradeSkillReagentItemLink then
            link = GetTradeSkillReagentItemLink(index, reagentIndex)
        end

        local itemEntry = ParseItemIdFromLink(link)
        if itemEntry and requiredCount > 0 then
            local totalRequired = requiredCount * repeatCount
            local inBags = 0

            if GetItemCount then
                inBags = tonumber(GetItemCount(itemEntry, false)) or 0
            end

            if inBags <= 0 and playerCount then
                inBags = tonumber(playerCount) or 0
            end

            local missing = totalRequired - inBags
            if missing > 0 then
                if not byItem[itemEntry] then
                    byItem[itemEntry] = {
                        itemEntry = itemEntry,
                        amount = 0,
                        name = reagentName or ("Item #" .. tostring(itemEntry)),
                    }
                    table.insert(order, itemEntry)
                end

                byItem[itemEntry].amount = byItem[itemEntry].amount + missing
            end
        end
    end

    local needs = {}
    for _, itemEntry in ipairs(order) do
        local need = byItem[itemEntry]
        if need and need.amount > 0 then
            table.insert(needs, need)
        end
    end

    return needs, nil, recipeName, repeatCount
end

function RB:BuildItemAmountCommand(prefix, items)
    local command = prefix

    for _, item in ipairs(items or {}) do
        local itemEntry = tonumber(item.itemEntry or item.entry)
        local amount = tonumber(item.amount) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            command = command .. " " .. tostring(itemEntry) .. " " .. tostring(math.floor(amount))
        end
    end

    return command
end

function RB:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)
    ReagentBankUIDB = ReagentBankUIDB or {}

    if not ReagentBankUIDB.autoDepositLeftovers then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        return
    end

    if not needs or #needs == 0 then
        return
    end

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        pending = {
            itemsByEntry = {},
            recipeNames = {},
            firstArmedAt = GetTime(),
        }
        self.pendingAutoDepositLeftovers = pending
    end

    pending.expiresAt = GetTime() + AUTO_DEPOSIT_PREP_EXPIRE_SECONDS

    if recipeName and recipeName ~= "" then
        pending.recipeNames[tostring(recipeName)] = true
    end

    for _, need in ipairs(needs) do
        local itemEntry = tonumber(need.itemEntry or need.entry)
        if itemEntry and itemEntry > 0 then
            local key = tostring(itemEntry)
            if not pending.itemsByEntry[key] then
                pending.itemsByEntry[key] = {
                    itemEntry = itemEntry,
                    baseline = GetItemCount(itemEntry, false) or 0,
                }
            end
        end
    end

    PrintAddon(
        "Auto-deposit armed for profession window close" ..
        " (" .. tostring(repeatCount or 1) .. " prepared craft(s))."
    )
end

function RB:BuildPreparedLeftoverItems(pending)
    local items = {}

    if not pending or not pending.itemsByEntry then
        return items
    end

    for _, info in pairs(pending.itemsByEntry) do
        local itemEntry = tonumber(info.itemEntry)
        local baseline = tonumber(info.baseline) or 0

        if itemEntry and itemEntry > 0 then
            local current = GetItemCount(itemEntry, false) or 0
            local leftover = current - baseline

            if leftover > 0 then
                table.insert(items, {
                    entry = itemEntry,
                    amount = math.floor(leftover),
                })
            end
        end
    end

    table.sort(items, function(a, b)
        return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
    end)

    return items
end

function RB:WithdrawNeededForSelectedRecipe()
    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    if errText then
        PrintAddon(errText)
        self:Status(errText, 1.00, 0.82, 0.32)
        return
    end

    self:SetTradeSkillPrepareCount(repeatCount, true)

    if not needs or #needs == 0 then
        local message = "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return
    end

    self:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)

    local command = self:BuildItemAmountCommand("withdraw needed", needs)
    self:SendServerCommand(command)

    local total = 0
    for _, need in ipairs(needs) do
        total = total + (tonumber(need.amount) or 0)
    end

    PrintAddon(
        "Requested " .. tostring(total) .. " reagent(s) for " ..
        tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") .. "."
    )

    self:UpdateTradeSkillControls()
end

function RB:MaybeAutoWithdrawForSelectedRecipe(force)
    ReagentBankUIDB = ReagentBankUIDB or {}
    if not ReagentBankUIDB.autoWithdrawRecipe then
        return
    end

    if self.busyKind then
        return
    end

    local needs, errText, _, repeatCount = self:GetSelectedTradeSkillNeeds()
    if errText or not needs or #needs == 0 then
        return
    end

    local index = GetTradeSkillSelectionIndex and GetTradeSkillSelectionIndex() or 0
    local key = tostring(index) .. ":" .. tostring(repeatCount or 1)
    local now = GetTime()
    if not force and self.lastAutoWithdrawKey == key and self.lastAutoWithdrawAt and (now - self.lastAutoWithdrawAt) < 1.2 then
        return
    end

    self.lastAutoWithdrawKey = key
    self.lastAutoWithdrawAt = now
    self:WithdrawNeededForSelectedRecipe()
end

function RB:DepositPreparedLeftovers()
    local pending = self.pendingAutoDepositLeftovers
    self.pendingAutoDepositLeftovers = nil
    self.pendingAutoDepositAt = nil

    local items = self:BuildPreparedLeftoverItems(pending)
    if not items or #items == 0 then
        if pending then
            PrintAddon("No prepared reagent leftovers to auto-deposit.")
        end
        return
    end

    local command = self:BuildItemAmountCommand("deposit items", items)
    self:SendServerCommand(command)
    PrintAddon("Auto-depositing prepared reagent leftovers after closing the profession window.")
end

function RB:HandleTradeSkillClosed()
    self:UpdateTradeSkillControls()

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        return
    end

    if pending.expiresAt and GetTime() > pending.expiresAt then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        PrintAddon("Prepared reagent auto-deposit expired.")
        return
    end

    self.pendingAutoDepositAt = GetTime() + AUTO_DEPOSIT_AFTER_CLOSE_DELAY
    self:EnsureOnUpdate()
end

function RB:Toggle()
    self:CreateFrame()

    if self.frame:IsShown() then
        self:Close()
        return
    end

    self.frame:Show()
    self:RequestRoot()
end

function RB:PositionMinimapButton()
    if not self.minimapButton or not Minimap then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local angle = tonumber(ReagentBankUIDB.minimapButtonAngle) or MINIMAP_BUTTON_DEFAULT_ANGLE
    local radians = math.rad(angle)
    local radius = 78
    local x = math.cos(radians) * radius
    local y = math.sin(radians) * radius

    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function RB:UpdateMinimapButtonVisibility()
    if not self.minimapButton then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    if ReagentBankUIDB.showMinimapButton then
        self.minimapButton:Show()
    else
        self.minimapButton:Hide()
    end
end

function RB:CreateMinimapButton()
    if self.minimapButton then
        self:UpdateMinimapButtonVisibility()
        self:PositionMinimapButton()
        return
    end

    if not Minimap then
        return
    end

    local button = CreateFrame("Button", "ReagentBankUIMinimapButton", Minimap)
    button:SetWidth(MINIMAP_BUTTON_SIZE)
    button:SetHeight(MINIMAP_BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetClampedToScreen(true)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(PAPERDOLL_BUTTON_ICON)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetWidth(MINIMAP_BUTTON_ICON_SIZE)
    icon:SetHeight(MINIMAP_BUTTON_ICON_SIZE)
    icon:SetTexCoord(MINIMAP_BUTTON_ICON_CROP, 1 - MINIMAP_BUTTON_ICON_CROP, MINIMAP_BUTTON_ICON_CROP, 1 - MINIMAP_BUTTON_ICON_CROP)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(PAPERDOLL_BUTTON_BG_TEXTURE)
    bg:SetPoint("CENTER", 0, 1)
    bg:SetWidth(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetHeight(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetVertexColor(PAPERDOLL_BUTTON_BG_R, PAPERDOLL_BUTTON_BG_G, PAPERDOLL_BUTTON_BG_B, PAPERDOLL_BUTTON_BG_A)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(PAPERDOLL_BUTTON_BORDER_TEXTURE)
    border:SetPoint("CENTER", 0, 1)
    border:SetWidth(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetHeight(PAPERDOLL_BUTTON_BORDER_SIZE)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE)
    highlight:SetBlendMode("ADD")
    highlight:SetPoint("CENTER", 0, 1)
    highlight:SetWidth(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
    highlight:SetHeight(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", function(selfButton, mouseButton)
        if mouseButton == "LeftButton" then
            RB:Toggle()
        else
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.showMinimapButton = not ReagentBankUIDB.showMinimapButton
            RB:UpdateMinimapButtonVisibility()
        end
    end)

    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open or close.", 1, 1, 1)
        GameTooltip:AddLine("Right-click: hide minimap button.", 0.82, 0.82, 0.82)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)

    self.minimapButton = button
    self:PositionMinimapButton()
    self:UpdateMinimapButtonVisibility()
end

function RB:PositionPaperDollButton()
    if not self.paperDollButton then
        return
    end

    local parent = _G[PAPERDOLL_BUTTON_PARENT]
    if not parent then
        return
    end

    local button = self.paperDollButton
    local anchorButton = _G[PAPERDOLL_ANCHOR_BUTTON_NAME]

    button:ClearAllPoints()

    if anchorButton then
        button:SetPoint("LEFT", anchorButton, "RIGHT", PAPERDOLL_BUTTON_GAP, 0)
    else
        button:SetPoint(
            PAPERDOLL_BUTTON_FALLBACK_POINT,
            parent,
            PAPERDOLL_BUTTON_FALLBACK_RELATIVE_POINT,
            PAPERDOLL_BUTTON_FALLBACK_X,
            PAPERDOLL_BUTTON_FALLBACK_Y
        )
    end
end

function RB:CreatePaperDollButton()
    if self.paperDollButton or not PAPERDOLL_BUTTON_ENABLED then
        return
    end

    local parent = _G[PAPERDOLL_BUTTON_PARENT]
    if not parent then
        return
    end

    local button = CreateFrame("Button", "ReagentBankUIPaperDollButton", parent)
    button:SetWidth(PAPERDOLL_BUTTON_SIZE)
    button:SetHeight(PAPERDOLL_BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 12)

    -- Dark circular background, matching the AH button style.
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(PAPERDOLL_BUTTON_BG_TEXTURE)
    bg:SetWidth(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetHeight(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetPoint("CENTER", button, "CENTER", 0, 0)
    bg:SetVertexColor(
        PAPERDOLL_BUTTON_BG_R,
        PAPERDOLL_BUTTON_BG_G,
        PAPERDOLL_BUTTON_BG_B,
        PAPERDOLL_BUTTON_BG_A
    )
    button.bg = bg

    -- Inner icon.
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(PAPERDOLL_BUTTON_ICON)
    icon:SetWidth(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetHeight(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexCoord(
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP,
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP
    )
    button.icon = icon

    -- Circular border ring.
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(PAPERDOLL_BUTTON_BORDER_TEXTURE)
    border:SetWidth(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetHeight(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border = border

    -- Mouseover glow.
    button:SetHighlightTexture(PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE)
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetWidth(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:SetHeight(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
    end

    button:SetScript("OnMouseDown", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 1, -1)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 0, 0)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 0, 0)
    end)

    button:SetScript("OnClick", function(selfButton, mouseButton)
        if mouseButton == "RightButton" then
            RB:CreateFrame()
            RB.frame:Show()
            RB:RequestRoot()
            return
        end

        RB:Toggle()
    end)

    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open or close.", 1, 1, 1)
        GameTooltip:AddLine("Right-click: refresh categories.", 0.82, 0.82, 0.82)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", HideTooltip)

    self.paperDollButton = button
    self:PositionPaperDollButton()

    -- If the AH button addon loads after this addon, retry for a few seconds
    -- and then snap to the right of PaperDollAHButton as soon as it exists.
    button.positionElapsed = 0
    button.positionAttempts = 0
    button:SetScript("OnUpdate", function(selfButton, elapsed)
        selfButton.positionElapsed = (selfButton.positionElapsed or 0) + elapsed
        if selfButton.positionElapsed < 0.25 then
            return
        end

        selfButton.positionElapsed = 0
        selfButton.positionAttempts = (selfButton.positionAttempts or 0) + 1

        RB:PositionPaperDollButton()

        if _G[PAPERDOLL_ANCHOR_BUTTON_NAME] or selfButton.positionAttempts >= 40 then
            selfButton:SetScript("OnUpdate", nil)
        end
    end)

    if parent.HookScript and not parent.ReagentBankUIPositionHooked then
        parent:HookScript("OnShow", function()
            RB:CreatePaperDollButton()
            RB:PositionPaperDollButton()
        end)
        parent.ReagentBankUIPositionHooked = true
    end
end

function RB:UpdateTradeSkillControls()
    if not self.tradeSkillButton then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}

    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    local enabled = errText == nil

    self:SetButtonEnabled(self.tradeSkillButton, enabled)
    self:SetButtonEnabled(self.tradeSkillMinusButton, repeatCount > TRADE_SKILL_PREPARE_COUNT_MIN)
    self:SetButtonEnabled(self.tradeSkillPlusButton, repeatCount < TRADE_SKILL_PREPARE_COUNT_MAX)

    if self.tradeSkillQuantityBox and not self.tradeSkillQuantityBox:HasFocus() then
        local textValue = tostring(repeatCount)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if needs and #needs > 0 then
        local total = 0
        for _, need in ipairs(needs) do
            total = total + (tonumber(need.amount) or 0)
        end

        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Withdraw x" .. tostring(repeatCount))
            self.tradeSkillButton.tooltipText =
                "Prepare " .. tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") ..
                " by withdrawing " .. tostring(total) .. " missing reagent(s)."
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
            self.tradeSkillButton.tooltipText =
                "Withdraw " .. tostring(total) .. " missing reagent(s) for " .. tostring(recipeName or "selected recipe") .. "."
        end
    else
        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Ready x" .. tostring(repeatCount))
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
        end

        if errText then
            self.tradeSkillButton.tooltipText = errText
        else
            self.tradeSkillButton.tooltipText =
                "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        end
    end

    if self.tradeSkillAutoDepositCheck then
        self.tradeSkillAutoDepositCheck:SetChecked(ReagentBankUIDB.autoDepositLeftovers and true or false)
    end
    if self.tradeSkillAutoWithdrawCheck then
        self.tradeSkillAutoWithdrawCheck:SetChecked(ReagentBankUIDB.autoWithdrawRecipe and true or false)
    end
end

function RB:CreateTradeSkillControls()
    if self.tradeSkillButton then
        self:UpdateTradeSkillControls()
        return
    end

    local parent = _G.TradeSkillFrame
    if not parent then
        return
    end

    local button = self:CreateButton(parent, 132, 22, "Withdraw Needed")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)

    local createButton = _G.TradeSkillCreateButton
    if createButton then
        button:SetPoint("LEFT", createButton, "RIGHT", 8, 0)
    else
        button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 80, 40)
    end

    button:SetScript("OnClick", function()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Withdraw missing reagents for the selected recipe.", 1, 1, 1, true)
        GameTooltip:AddLine("Set the count box beside this button to prepare multiple crafts in one click.", 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)

    self.tradeSkillButton = button

    local quantityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    quantityLabel:SetPoint("LEFT", button, "RIGHT", 8, 0)
    quantityLabel:SetText("x")
    quantityLabel:SetTextColor(1.00, 0.86, 0.46)
    self.tradeSkillQuantityLabel = quantityLabel

    local quantityBox = CreateFrame("EditBox", "ReagentBankUIPrepareCountBox", parent)
    quantityBox:SetWidth(42)
    quantityBox:SetHeight(22)
    quantityBox:SetAutoFocus(false)
    quantityBox:SetNumeric(true)
    quantityBox:SetFontObject(ChatFontNormal)
    quantityBox:SetTextInsets(6, 6, 0, 0)
    quantityBox:SetBackdrop(BUTTON_BACKDROP)
    quantityBox:SetBackdropColor(0.035, 0.038, 0.052, 0.96)
    quantityBox:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
    quantityBox:SetTextColor(1.00, 0.92, 0.70)
    quantityBox:SetPoint("LEFT", quantityLabel, "RIGHT", 4, 0)
    quantityBox:SetScript("OnEscapePressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(false)
        selfBox:ClearFocus()
    end)
    quantityBox:SetScript("OnEnterPressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(true)
        selfBox:ClearFocus()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    quantityBox:SetScript("OnEditFocusLost", function()
        RB:NormalizeTradeSkillQuantityBox(false)
    end)
    quantityBox:SetScript("OnTextChanged", function(selfBox)
        if RB.suppressTradeSkillQuantityChanged then
            return
        end

        local value = tonumber(selfBox:GetText())
        if value and value > 0 then
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.tradeSkillPrepareCount = RB:ClampTradeSkillPrepareCount(value)
        end

        RB:UpdateTradeSkillControls()
    end)
    quantityBox:SetScript("OnEnter", function(selfBox)
        GameTooltip:SetOwner(selfBox, "ANCHOR_RIGHT")
        GameTooltip:SetText("Prepare count", 1, 0.82, 0)
        GameTooltip:AddLine("Number of times to prepare the selected recipe's reagents. Press Enter here to withdraw needed reagents.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    quantityBox:SetScript("OnLeave", HideTooltip)

    self.tradeSkillQuantityBox = quantityBox

    ReagentBankUIDB = ReagentBankUIDB or {}
    local initialCount = tonumber(ReagentBankUIDB.tradeSkillPrepareCount) or self:GetNativeTradeSkillRepeatCount() or 1
    self:SetTradeSkillPrepareCount(initialCount, false)

    if hooksecurefunc and TradeSkillFrame_SetSelection and not self.tradeSkillSelectionHooked then
        hooksecurefunc("TradeSkillFrame_SetSelection", function()
            RB:UpdateTradeSkillControls()
            RB:MaybeAutoWithdrawForSelectedRecipe(false)
        end)
        self.tradeSkillSelectionHooked = true
    end

    local nativeInput = _G.TradeSkillInputBox
    if nativeInput and nativeInput.HookScript and not self.tradeSkillNativeInputHooked then
        nativeInput:HookScript("OnTextChanged", function(inputBox)
            if RB.suppressNativeTradeSkillQuantityChanged then
                return
            end

            local value = nil
            if inputBox.GetNumber then
                value = tonumber(inputBox:GetNumber())
            end
            if (not value or value <= 0) and inputBox.GetText then
                value = tonumber(inputBox:GetText())
            end

            if value and value > 0 then
                RB:SetTradeSkillPrepareCount(value, false)
            end
        end)
        self.tradeSkillNativeInputHooked = true
    end

    local minusButton = self:CreateButton(parent, 22, 22, "-")
    minusButton:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    minusButton:SetPoint("LEFT", quantityBox, "RIGHT", 3, 0)
    minusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() - 1, true)
    end)
    minusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Decrease prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    minusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillMinusButton = minusButton

    local plusButton = self:CreateButton(parent, 22, 22, "+")
    plusButton:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    plusButton:SetPoint("LEFT", minusButton, "RIGHT", 3, 0)
    plusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() + 1, true)
    end)
    plusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Increase prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    plusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillPlusButton = plusButton

    local check = CreateFrame("CheckButton", "ReagentBankUIAutoDepositLeftoversCheck", parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    check:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    check:SetPoint("LEFT", plusButton, "RIGHT", 8, 0)
    check:SetScript("OnClick", function(selfCheck)
        ReagentBankUIDB = ReagentBankUIDB or {}
        ReagentBankUIDB.autoDepositLeftovers = selfCheck:GetChecked() and true or false
        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end
        RB:UpdateTradeSkillControls()
    end)
    check:SetScript("OnEnter", function(selfCheck)
        GameTooltip:SetOwner(selfCheck, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-deposit leftovers", 1, 0.82, 0)
        GameTooltip:AddLine("When you close the profession window, deposit prepared reagent leftovers back into the reagent bank. It preserves the bag counts you had before Withdraw Needed.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", HideTooltip)

    local checkText = _G[check:GetName() .. "Text"]
    if checkText then
        checkText:SetText("Auto-deposit leftovers")
        checkText:SetTextColor(1.00, 0.86, 0.46)
    end

    self.tradeSkillAutoDepositCheck = check

    local autoWithdrawCheck = CreateFrame("CheckButton", "ReagentBankUIAutoWithdrawRecipeCheck", parent, "UICheckButtonTemplate")
    autoWithdrawCheck:SetWidth(24)
    autoWithdrawCheck:SetHeight(24)
    autoWithdrawCheck:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    autoWithdrawCheck:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 0, -2)
    autoWithdrawCheck:SetScript("OnClick", function(selfCheck)
        ReagentBankUIDB = ReagentBankUIDB or {}
        ReagentBankUIDB.autoWithdrawRecipe = selfCheck:GetChecked() and true or false
        RB:UpdateTradeSkillControls()
    end)
    autoWithdrawCheck:SetScript("OnEnter", function(selfCheck)
        GameTooltip:SetOwner(selfCheck, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-withdraw on recipe select/craft", 1, 0.82, 0)
        GameTooltip:AddLine("Automatically withdraw missing reagents for the selected recipe when you select or craft.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoWithdrawCheck:SetScript("OnLeave", HideTooltip)

    local autoWithdrawText = _G[autoWithdrawCheck:GetName() .. "Text"]
    if autoWithdrawText then
        autoWithdrawText:SetText("Auto-withdraw recipe")
        autoWithdrawText:SetTextColor(1.00, 0.86, 0.46)
    end

    self.tradeSkillAutoWithdrawCheck = autoWithdrawCheck

    if createButton and createButton.HookScript and not self.tradeSkillCreateHooked then
        createButton:HookScript("OnClick", function()
            RB:MaybeAutoWithdrawForSelectedRecipe(true)
        end)
        self.tradeSkillCreateHooked = true
    end

    self:UpdateTradeSkillControls()
end

function RB:ApplyScale()
    if not self.frame then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local scale = Clamp(ReagentBankUIDB.scale or DEFAULT_SCALE, 0.75, 1.20)

    ReagentBankUIDB.scale = scale
    self.frame:SetScale(scale)
end

function RB:CreateButton(parent, width, height, label)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop(BUTTON_BACKDROP)
    button:SetBackdropColor(SKIN.buttonBg[1], SKIN.buttonBg[2], SKIN.buttonBg[3], SKIN.buttonBg[4])
    button:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])

    button.shine = button:CreateTexture(nil, "BORDER")
    button.shine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    button.shine:SetPoint("TOPLEFT", 2, -2)
    button.shine:SetPoint("TOPRIGHT", -2, -2)
    button.shine:SetHeight(7)
    button.shine:SetVertexColor(1.00, 0.78, 0.32, 0.15)

    button.hover = button:CreateTexture(nil, "HIGHLIGHT")
    button.hover:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    button.hover:SetAllPoints(button)
    button.hover:SetVertexColor(SKIN.buttonHover[1], SKIN.buttonHover[2], SKIN.buttonHover[3], SKIN.buttonHover[4])
    button:SetHighlightTexture(button.hover)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER", 0, 0)
    button.label:SetJustifyH("CENTER")
    button.label:SetTextColor(1.00, 0.86, 0.46)
    button.label:SetText(label or "")
    button:SetFontString(button.label)
    button:SetText(label or "")

    button:SetScript("OnMouseDown", function(selfButton)
        if not selfButton:IsEnabled() then
            return
        end

        selfButton:SetBackdropColor(SKIN.buttonDown[1], SKIN.buttonDown[2], SKIN.buttonDown[3], SKIN.buttonDown[4])
        selfButton.label:ClearAllPoints()
        selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton:SetBackdropColor(SKIN.buttonBg[1], SKIN.buttonBg[2], SKIN.buttonBg[3], SKIN.buttonBg[4])
        selfButton.label:ClearAllPoints()
        selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 0, 0)
    end)

    return button
end

function RB:CreateEditBox(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetWidth(width)
    box:SetHeight(height)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetFontObject(ChatFontNormal)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetBackdrop(BUTTON_BACKDROP)
    box:SetBackdropColor(0.035, 0.038, 0.052, 0.96)
    box:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
    box:SetTextColor(1.00, 0.92, 0.70)
    box:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    box:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:WithdrawItemExact()
    end)
    box:SetScript("OnTextChanged", function()
        RB:UpdateControls()
    end)

    return box
end

function RB:CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(24)
    button:SetHeight(24)
    button:SetBackdrop(BUTTON_BACKDROP)
    button:SetBackdropColor(SKIN.closeBg[1], SKIN.closeBg[2], SKIN.closeBg[3], SKIN.closeBg[4])
    button:SetBackdropBorderColor(SKIN.closeBorder[1], SKIN.closeBorder[2], SKIN.closeBorder[3], SKIN.closeBorder[4])

    button.hover = button:CreateTexture(nil, "HIGHLIGHT")
    button.hover:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    button.hover:SetAllPoints(button)
    button.hover:SetVertexColor(1.00, 0.18, 0.12, 0.25)
    button:SetHighlightTexture(button.hover)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("CENTER", 0, 1)
    button.label:SetText("X")
    button.label:SetTextColor(1.00, 0.76, 0.58)

    button:SetScript("OnMouseDown", function(selfButton)
        selfButton.label:ClearAllPoints()
        selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 1, 0)
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton.label:ClearAllPoints()
        selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 0, 1)
    end)

    return button
end

function RB:CreateLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    return label
end

function RB:CreateFrame()
    if self.frame then
        return
    end

    local f = CreateFrame("Frame", "ReagentBankUIFrame", UIParent)
    f:SetWidth(700)
    f:SetHeight(610)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()

        ReagentBankUIDB = ReagentBankUIDB or {}
        local point, relativeTo, relativePoint, xOfs, yOfs = selfFrame:GetPoint(1)

        ReagentBankUIDB.point = point
        ReagentBankUIDB.relativePoint = relativePoint
        ReagentBankUIDB.xOfs = xOfs
        ReagentBankUIDB.yOfs = yOfs
    end)

    f.shadow = f:CreateTexture(nil, "BACKGROUND")
    f.shadow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.shadow:SetPoint("TOPLEFT", -6, 6)
    f.shadow:SetPoint("BOTTOMRIGHT", 6, -6)
    f.shadow:SetVertexColor(0.00, 0.00, 0.00, 0.50)

    self:MakeBackdrop(f, 0.98)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 8, -8)
    f.header:SetPoint("TOPRIGHT", -8, -8)
    f.header:SetHeight(42)
    f.header:SetBackdrop(PANEL_BACKDROP)
    f.header:SetBackdropColor(SKIN.headerBg[1], SKIN.headerBg[2], SKIN.headerBg[3], SKIN.headerBg[4])
    f.header:SetBackdropBorderColor(SKIN.windowBorder[1], SKIN.windowBorder[2], SKIN.windowBorder[3], SKIN.windowBorder[4])

    f.headerGlow = f.header:CreateTexture(nil, "ARTWORK")
    f.headerGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.headerGlow:SetPoint("TOPLEFT", 2, -2)
    f.headerGlow:SetPoint("TOPRIGHT", -2, -2)
    f.headerGlow:SetHeight(15)
    f.headerGlow:SetVertexColor(1.00, 0.74, 0.22, 0.10)

    f.headerLine = f:CreateTexture(nil, "ARTWORK")
    f.headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.headerLine:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 0, -4)
    f.headerLine:SetPoint("TOPRIGHT", f.header, "BOTTOMRIGHT", 0, -4)
    f.headerLine:SetHeight(1)
    f.headerLine:SetVertexColor(SKIN.headerLine[1], SKIN.headerLine[2], SKIN.headerLine[3], SKIN.headerLine[4])

    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", 12, 1)
    f.title:SetText("Reagent Bank")
    f.title:SetJustifyH("LEFT")
    f.title:SetTextColor(1.00, 0.82, 0.28)

    f.modeText = f.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.modeText:SetPoint("LEFT", f.title, "RIGHT", 14, -1)
    f.modeText:SetPoint("RIGHT", -44, 0)
    f.modeText:SetJustifyH("LEFT")
    f.modeText:SetTextColor(0.78, 0.82, 0.88)
    f.modeText:SetText("")

    f.close = self:CreateCloseButton(f.header)
    f.close:SetPoint("RIGHT", -9, 0)
    f.close:SetScript("OnClick", function()
        RB:Close()
    end)

    f.rootDeposit = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Deposit All")
    f.rootDeposit:SetPoint("TOPLEFT", ROOT_BUTTON_ROW_X, ROOT_BUTTON_ROW_Y)
    f.rootDeposit:SetScript("OnClick", function()
        RB:DepositAll()
    end)

    f.rootWithdraw = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Withdraw All")
    f.rootWithdraw:SetPoint("LEFT", f.rootDeposit, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.rootWithdraw:SetScript("OnClick", function()
        RB:WithdrawAll()
    end)

    f.refresh = self:CreateButton(f, ROOT_REFRESH_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Refresh")
    f.refresh:SetPoint("LEFT", f.rootWithdraw, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.refresh:SetScript("OnClick", function()
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
    end)

    f.helpText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.helpText:SetPoint("LEFT", f.refresh, "RIGHT", ROOT_HELP_TEXT_GAP, 0)
    f.helpText:SetPoint("RIGHT", -18, 0)
    f.helpText:SetJustifyH("LEFT")
    f.helpText:SetTextColor(0.55, 0.58, 0.64)
    f.helpText:SetText("Click a category, then click an item to withdraw.")

    f.back = self:CreateButton(f, CATEGORY_BACK_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Categories")
    f.back:SetPoint("TOPLEFT", CATEGORY_BUTTON_ROW_X, CATEGORY_BUTTON_ROW_Y)
    f.back:SetScript("OnClick", function()
        RB:RequestRoot()
    end)

    f.catDeposit = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Deposit Category")
    f.catDeposit:SetPoint("LEFT", f.back, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catDeposit:SetScript("OnClick", function()
        RB:DepositCategory()
    end)

    f.catWithdraw = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Withdraw Category")
    f.catWithdraw:SetPoint("LEFT", f.catDeposit, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catWithdraw:SetScript("OnClick", function()
        RB:WithdrawCategory()
    end)

    f.prev = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Prev")
    f.prev:SetPoint("LEFT", f.catWithdraw, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.prev:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.currentPage > 0 then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage - 1)
        end
    end)

    f.next = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Next")
    f.next:SetPoint("LEFT", f.prev, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.next:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.totalPages and RB.currentPage + 1 < RB.totalPages then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage + 1)
        end
    end)

    f.pageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.pageText:SetPoint("LEFT", f.next, "RIGHT", CATEGORY_PAGE_TEXT_GAP, 0)
    f.pageText:SetPoint("RIGHT", -18, 0)
    f.pageText:SetJustifyH("RIGHT")
    f.pageText:SetText("")

    f.list = CreateFrame("Frame", nil, f)
    f.list:SetPoint("TOPLEFT", 18, -118)
    f.list:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.list, 0.78, true)

    f.listHeader = CreateFrame("Frame", nil, f.list)
    f.listHeader:SetHeight(24)
    f.listHeader:SetPoint("TOPLEFT", 8, -7)
    f.listHeader:SetPoint("RIGHT", -8, 0)

    f.listHeader.bg = f.listHeader:CreateTexture(nil, "BACKGROUND")
    f.listHeader.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.bg:SetAllPoints(f.listHeader)
    f.listHeader.bg:SetVertexColor(0.11, 0.085, 0.045, 0.72)

    f.listHeader.line = f.listHeader:CreateTexture(nil, "ARTWORK")
    f.listHeader.line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.line:SetPoint("BOTTOMLEFT", 0, 0)
    f.listHeader.line:SetPoint("BOTTOMRIGHT", 0, 0)
    f.listHeader.line:SetHeight(1)
    f.listHeader.line:SetVertexColor(SKIN.headerLine[1], SKIN.headerLine[2], SKIN.headerLine[3], 0.70)

    f.headerName = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetJustifyH("LEFT")
    f.headerName:SetText("Name")

    f.headerCount = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerCount:SetPoint("RIGHT", -8, 0)
    f.headerCount:SetJustifyH("RIGHT")
    f.headerCount:SetText("Stored")

    f.rows = {}
    for i = 1, ROW_COUNT do
        local row = CreateFrame("Button", nil, f.list)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("LEFT", 8, 0)
        row:SetPoint("RIGHT", -8, 0)

        if i == 1 then
            row:SetPoint("TOP", f.listHeader, "BOTTOM", 0, -2)
        else
            row:SetPoint("TOP", f.rows[i - 1], "BOTTOM", 0, -ROW_SPACING)
        end

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        row.bg:SetAllPoints(row)
        if (i % 2) == 0 then
            row.bg:SetVertexColor(SKIN.rowEven[1], SKIN.rowEven[2], SKIN.rowEven[3], SKIN.rowEven[4])
        else
            row.bg:SetVertexColor(SKIN.rowOdd[1], SKIN.rowOdd[2], SKIN.rowOdd[3], SKIN.rowOdd[4])
        end

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22)
        row.icon:SetHeight(22)
        row.icon:SetPoint("LEFT", 4, 0)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetJustifyH("LEFT")

        row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.count:SetWidth(158)
        row.count:SetPoint("RIGHT", -8, 0)
        row.count:SetJustifyH("RIGHT")
        row.count:SetTextColor(SKIN.blueText[1], SKIN.blueText[2], SKIN.blueText[3])

        row.hover = row:CreateTexture(nil, "HIGHLIGHT")
        row.hover:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        row.hover:SetAllPoints(row)
        row.hover:SetVertexColor(SKIN.rowHover[1], SKIN.rowHover[2], SKIN.rowHover[3], SKIN.rowHover[4])
        row:SetHighlightTexture(row.hover)

        row:SetScript("OnClick", function(selfRow)
            if selfRow.kind == "category" and selfRow.categoryId then
                RB:RequestCategory(selfRow.categoryId, 0)
            elseif selfRow.kind == "item" and selfRow.item then
                RB:ShowDetail(selfRow.item)
            end
        end)

        row:SetScript("OnEnter", function(selfRow)
            if selfRow.kind == "item" and selfRow.item and selfRow.item.entry then
                SetTooltipItem(selfRow.item.entry)
            end
        end)

        row:SetScript("OnLeave", HideTooltip)

        f.rows[i] = row
    end

    f.detail = CreateFrame("Frame", nil, f)
    f.detail:SetPoint("TOPLEFT", 18, -118)
    f.detail:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.detail, 0.78, true)

    f.detailIconBorder = CreateFrame("Frame", nil, f.detail)
    f.detailIconBorder:SetWidth(62)
    f.detailIconBorder:SetHeight(62)
    f.detailIconBorder:SetPoint("TOPLEFT", 16, -16)
    f.detailIconBorder:SetBackdrop(BUTTON_BACKDROP)
    f.detailIconBorder:SetBackdropColor(0.02, 0.02, 0.03, 0.90)
    f.detailIconBorder:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])

    f.detailIcon = f.detailIconBorder:CreateTexture(nil, "ARTWORK")
    f.detailIcon:SetWidth(54)
    f.detailIcon:SetHeight(54)
    f.detailIcon:SetPoint("CENTER", 0, 0)

    f.detailName = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.detailName:SetPoint("TOPLEFT", f.detailIconBorder, "TOPRIGHT", 14, -2)
    f.detailName:SetPoint("RIGHT", -18, 0)
    f.detailName:SetJustifyH("LEFT")

    f.detailStored = f.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.detailStored:SetPoint("TOPLEFT", f.detailName, "BOTTOMLEFT", 0, -8)
    f.detailStored:SetJustifyH("LEFT")

    f.detailHint = f.detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.detailHint:SetPoint("TOPLEFT", f.detailStored, "BOTTOMLEFT", 0, -8)
    f.detailHint:SetPoint("RIGHT", -18, 0)
    f.detailHint:SetJustifyH("LEFT")
    f.detailHint:SetText("Withdraw one stack, all, or type an exact amount. Counts refresh from the server after each action.")

    f.withdrawOne = self:CreateButton(f.detail, 132, 28, "Withdraw 1")
    f.withdrawOne:SetPoint("TOPLEFT", 18, -112)
    f.withdrawOne:SetScript("OnClick", function()
        RB:WithdrawItem("one")
    end)

    f.withdrawStack = self:CreateButton(f.detail, 132, 28, "Withdraw Stack")
    f.withdrawStack:SetPoint("LEFT", f.withdrawOne, "RIGHT", 10, 0)
    f.withdrawStack:SetScript("OnClick", function()
        RB:WithdrawItem("stack")
    end)

    f.withdrawItemAll = self:CreateButton(f.detail, 132, 28, "Withdraw All")
    f.withdrawItemAll:SetPoint("LEFT", f.withdrawStack, "RIGHT", 10, 0)
    f.withdrawItemAll:SetScript("OnClick", function()
        RB:WithdrawItem("all")
    end)

    f.exactLabel = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.exactLabel:SetPoint("TOPLEFT", 20, -154)
    f.exactLabel:SetText("Exact amount:")
    f.exactLabel:SetJustifyH("LEFT")

    f.exactBox = self:CreateEditBox(f.detail, 82, 24)
    f.exactBox:SetPoint("LEFT", f.exactLabel, "RIGHT", 10, 0)

    f.withdrawExact = self:CreateButton(f.detail, 132, 28, "Withdraw Exact")
    f.withdrawExact:SetPoint("LEFT", f.exactBox, "RIGHT", 10, 0)
    f.withdrawExact:SetScript("OnClick", function()
        RB:WithdrawItemExact()
    end)

    f.detailBack = self:CreateButton(f.detail, 132, 28, "Back to List")
    f.detailBack:SetPoint("LEFT", f.withdrawItemAll, "RIGHT", 10, 0)
    f.detailBack:SetScript("OnClick", function()
        if RB.currentCategoryId then
            RB:RenderCategory()
        else
            RB:RequestRoot()
        end
    end)

    f.detail:SetScript("OnEnter", function()
        if RB.detailItem and RB.detailItem.entry then
            SetTooltipItem(RB.detailItem.entry)
        end
    end)
    f.detail:SetScript("OnLeave", HideTooltip)

    f.footer = CreateFrame("Frame", nil, f)
    f.footer:SetPoint("BOTTOMLEFT", 18, 18)
    f.footer:SetPoint("BOTTOMRIGHT", -18, 18)
    f.footer:SetHeight(24)
    self:MakeBackdrop(f.footer, 0.58, true)

    f.status = f.footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("LEFT", 8, 0)
    f.status:SetPoint("RIGHT", -8, 0)
    f.status:SetJustifyH("LEFT")
    f.status:SetText("")

    f:Hide()

    self.frame = f
    self:ApplyScale()
    self:UpdateControls()
end

function RB:ApplySavedPosition()
    self:CreateFrame()

    ReagentBankUIDB = ReagentBankUIDB or {}
    if ReagentBankUIDB.point and ReagentBankUIDB.relativePoint and ReagentBankUIDB.xOfs and ReagentBankUIDB.yOfs then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(ReagentBankUIDB.point, UIParent, ReagentBankUIDB.relativePoint, ReagentBankUIDB.xOfs, ReagentBankUIDB.yOfs)
    end
end

function RB:SetCommonVisibility(view)
    self:CreateFrame()

    local f = self.frame
    local rootView = view == "root"
    local categoryView = view == "category"
    local detailView = view == "detail"

    f.rootDeposit:Show()
    f.rootWithdraw:Show()
    f.refresh:Show()

    if categoryView or detailView then
        f.back:Show()
    else
        f.back:Hide()
    end

    if categoryView then
        f.catDeposit:Show()
        f.catWithdraw:Show()
        f.prev:Show()
        f.next:Show()
        f.pageText:Show()
    else
        f.catDeposit:Hide()
        f.catWithdraw:Hide()
        f.prev:Hide()
        f.next:Hide()
        f.pageText:Hide()
    end

    if rootView or categoryView then
        f.list:Show()
    else
        f.list:Hide()
    end

    if detailView then
        f.detail:Show()
    else
        f.detail:Hide()
    end
end

function RB:UpdateControls()
    if not self.frame then
        return
    end

    local f = self.frame
    local busy = self.busyKind ~= nil
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)
    local inCategory = self.currentView == "category"
    local inDetail = self.currentView == "detail"
    local hasCategory = self.currentCategoryId ~= nil

    if self.busyKind == "request" then
        f.refresh:SetText("Refreshing")
    else
        f.refresh:SetText("Refresh")
    end

    self:SetButtonEnabled(f.refresh, not busy)
    self:SetButtonEnabled(f.rootDeposit, not busy)
    self:SetButtonEnabled(f.rootWithdraw, not busy)
    self:SetButtonEnabled(f.back, not busy)
    self:SetButtonEnabled(f.catDeposit, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.catWithdraw, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.prev, not busy and inCategory and page > 0)
    self:SetButtonEnabled(f.next, not busy and inCategory and page + 1 < totalPages)

    local stored = 0
    if self.detailItem then
        stored = tonumber(self.detailItem.amount) or 0
    end

    local exactAmount = self:GetExactWithdrawAmount()

    self:SetButtonEnabled(f.withdrawOne, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawStack, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawItemAll, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawExact, not busy and inDetail and stored >= 1 and exactAmount >= 1)
    self:SetButtonEnabled(f.detailBack, not busy)
end

function RB:ClearRows()
    local f = self.frame

    for _, row in ipairs(f.rows) do
        row.kind = nil
        row.categoryId = nil
        row.item = nil
        row.icon:Show()
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetText("")
        row.count:SetText("")
        row:Hide()
    end
end

function RB:SetEmptyRow(text)
    local f = self.frame
    local row = f.rows[1]

    row.kind = nil
    row.categoryId = nil
    row.item = nil
    row.icon:Show()
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
    row.text:SetPoint("RIGHT", -170, 0)
    row.text:SetText(text or "Nothing to show.")
    row.count:SetText("")
    row:Show()
end

function RB:RenderRoot(preserveStatus)
    self:CreateFrame()

    self.currentView = "root"
    self.currentCategoryId = nil
    self.currentPage = 0
    self.totalPages = 1
    self.detailItem = nil

    local f = self.frame
    f:Show()
    f.title:SetText("Reagent Bank")
    f.modeText:SetText(self.accountWide and "|cff80ff80Account-wide|r" or "|cffffcc80Character-only|r")
    f.pageText:SetText("")
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Category")
    f.headerCount:SetText("Types / Total")

    self:SetCommonVisibility("root")
    self:ClearRows()

    for index, category in ipairs(CATEGORY_ORDER) do
        local row = f.rows[index]
        if row then
            local info = self.categories and self.categories[category.id] or nil
            local types = info and info.types or 0
            local amount = info and info.amount or 0
            local icon = GetItemIcon(category.sample) or "Interface\\Icons\\INV_Misc_QuestionMark"

            row.kind = "category"
            row.categoryId = category.id
            row.item = nil
            row.icon:Show()
            row.icon:SetTexture(icon)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
            row.text:SetPoint("RIGHT", -170, 0)
            row.text:SetText(category.name)
            row.count:SetText(FormatCount(types) .. " types / " .. FormatCount(amount))
            row:Show()
        end
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:RenderCategory(preserveStatus)
    self:CreateFrame()

    self.currentView = "category"
    self.detailItem = nil

    local f = self.frame
    local category = CATEGORY_BY_ID[self.currentCategoryId]
    local categoryName = category and category.name or "Category"
    local typeCount = tonumber(self.categoryTypeCount) or 0
    local amount = tonumber(self.categoryAmount) or 0
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)

    f:Show()
    f.title:SetText(categoryName)
    f.modeText:SetText(FormatCount(typeCount) .. " types / " .. FormatCount(amount) .. " reagents")
    f.pageText:SetText("Page " .. tostring(page + 1) .. "/" .. tostring(totalPages))
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Item")
    f.headerCount:SetText("Stored")

    self:SetCommonVisibility("category")
    self:ClearRows()

    local missingItemInfo = false

    for index, item in ipairs(self.items or {}) do
        local row = f.rows[index]
        if row then
            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)

            if missingInfo then
                missingItemInfo = true
            end

            row.kind = "item"
            row.item = item
            row.icon:Show()
            row.icon:SetTexture(icon)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
            row.text:SetPoint("RIGHT", -170, 0)
            row.text:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount))
            row:Show()
        end
    end

    if not self.items or #self.items == 0 then
        self:SetEmptyRow("No stored reagents in this category.")
        missingItemInfo = false
    end

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:ShowDetail(item, preserveStatus)
    if not item or not item.entry then
        return
    end

    self:CreateFrame()

    self.detailItem = item
    self.currentView = "detail"

    local f = self.frame
    local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
    local stored = tonumber(item.amount) or 0

    f:Show()
    f.title:SetText("Withdraw")
    f.modeText:SetText("")
    self:SetCommonVisibility("detail")

    f.detailIcon:SetTexture(icon)
    f.detailName:SetText(link or name)
    f.detailStored:SetText("Stored: " .. FormatCount(stored))

    if f.exactBox then
        f.exactBox:SetText("")
        f.exactBox:ClearFocus()
    end

    if missingInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Choose a withdraw amount.", 0.82, 0.82, 0.82)
    end
end

function RB:Close()
    self.awaitingView = nil
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil
    self.pendingRefresh = nil
    self.mutationNeedsRefresh = nil
    self:ClearItemInfoRefresh()

    HideTooltip()

    if self.frame then
        self:UpdateControls()
        self.frame:Hide()
    end
end

function RB:HandleOK(okText)
    okText = Trim(okText or "")

    local lowerText = string.lower(okText)
    if string.find(lowerText, "refresh") then
        okText = "Refresh acknowledged. Waiting for server data..."
    end

    if okText == "" then
        okText = "Server acknowledged."
    end

    self:ClearBusy(okText, 0.45, 1.00, 0.45)

    if self.mutationNeedsRefresh then
        local refreshTarget = self.mutationNeedsRefresh
        self.mutationNeedsRefresh = nil

        if refreshTarget == "category" and self.currentCategoryId then
            self:ScheduleRefresh(0.25, "category", self.currentCategoryId, self.currentPage or 0)
        else
            self:ScheduleRefresh(0.25, "root", nil, 0)
        end
    end
end

function RB:HandleError(errText)
    errText = Trim(errText or "Server error.")

    self.mutationNeedsRefresh = nil
    self:CreateFrame()
    self.frame:Show()
    self:ClearBusy(errText, 1.00, 0.35, 0.35)
end

function RB:HandleProtocol(message)
    if type(message) ~= "string" or string.sub(message, 1, 6) ~= "RBANK:" then
        return false
    end

    local okText = string.match(message, "^RBANK:OK:(.*)$")
    if okText then
        self:HandleOK(okText)
        return true
    end

    local errText = string.match(message, "^RBANK:ERR:(.*)$")
    if errText then
        self:HandleError(errText)
        return true
    end

    local parts = SplitColon(message)
    local recordType = parts[2]

    if recordType == "BEGIN" then
        local view = parts[3]

        if view == "ROOT" then
            self.pendingView = "root"
            self.pendingCategories = {}
            self.accountWide = tonumber(parts[4]) == 1
        elseif view == "CATEGORY" then
            self.pendingView = "category"
            self.pendingItems = {}
            self.pendingCategoryId = tonumber(parts[4])
            self.pendingPage = tonumber(parts[5]) or 0
            self.pendingTotalPages = tonumber(parts[6]) or 1
            self.pendingTypeCount = tonumber(parts[7]) or 0
            self.pendingAmount = tonumber(parts[8]) or 0
        end

        return true
    end

    if recordType == "CAT" and self.pendingView == "root" then
        local categoryId = tonumber(parts[3])

        if categoryId then
            self.pendingCategories[categoryId] = {
                sample = tonumber(parts[4]) or 0,
                types = tonumber(parts[5]) or 0,
                amount = tonumber(parts[6]) or 0,
            }
        end

        return true
    end

    if recordType == "ITEM" and self.pendingView == "category" then
        table.insert(self.pendingItems, {
            entry = tonumber(parts[3]) or 0,
            amount = tonumber(parts[4]) or 0,
        })

        return true
    end

    if recordType == "END" then
        local view = parts[3]

        if view == "ROOT" and self.pendingView == "root" then
            self.categories = self.pendingCategories or {}
            self.pendingCategories = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()
            self:RenderRoot(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        elseif view == "CATEGORY" and self.pendingView == "category" then
            self.currentCategoryId = self.pendingCategoryId
            self.currentPage = self.pendingPage or 0
            self.totalPages = self.pendingTotalPages or 1
            self.categoryTypeCount = self.pendingTypeCount or 0
            self.categoryAmount = self.pendingAmount or 0
            self.items = self.pendingItems or {}
            self.pendingItems = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()
            self:RenderCategory(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        end

        return true
    end

    return true
end

local function SystemMessageFilter(chatFrame, event, message, ...)
    if RB:HandleProtocol(message) then
        return true
    end

    return false
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
else
    RB:RegisterEvent("CHAT_MSG_SYSTEM")
end

SLASH_REAGENTBANKUI1 = "/rbank"
SLASH_REAGENTBANKUI2 = "/reagentbank"
SLASH_REAGENTBANKUI3 = "/rbankui"
SLASH_REAGENTBANKUI4 = "/craftbag"
SlashCmdList["REAGENTBANKUI"] = function(msg)
    msg = Trim(msg or "")

    local command, value = string.match(msg, "^(%S+)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "open" or command == "show" then
        RB:CreateFrame()
        RB.frame:Show()
        RB:RequestRoot()
        return
    end

    if command == "hide" or command == "close" then
        RB:Close()
        return
    end

    if command == "refresh" then
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
        return
    end

    if command == "autodeposit" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" then
            ReagentBankUIDB.autoDepositLeftovers = true
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            ReagentBankUIDB.autoDepositLeftovers = false
        else
            ReagentBankUIDB.autoDepositLeftovers = not ReagentBankUIDB.autoDepositLeftovers
        end

        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end

        RB:UpdateTradeSkillControls()
        PrintAddon("auto-deposit leftovers on profession close " .. (ReagentBankUIDB.autoDepositLeftovers and "enabled." or "disabled."))
        return
    end

    if command == "autowithdraw" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" then
            ReagentBankUIDB.autoWithdrawRecipe = true
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            ReagentBankUIDB.autoWithdrawRecipe = false
        else
            ReagentBankUIDB.autoWithdrawRecipe = not ReagentBankUIDB.autoWithdrawRecipe
        end

        RB:UpdateTradeSkillControls()
        PrintAddon("auto-withdraw on recipe select/craft " .. (ReagentBankUIDB.autoWithdrawRecipe and "enabled." or "disabled."))
        return
    end

    if command == "minimap" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" then
            ReagentBankUIDB.showMinimapButton = true
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            ReagentBankUIDB.showMinimapButton = false
        else
            ReagentBankUIDB.showMinimapButton = not ReagentBankUIDB.showMinimapButton
        end

        RB:CreateMinimapButton()
        RB:UpdateMinimapButtonVisibility()
        PrintAddon("minimap button " .. (ReagentBankUIDB.showMinimapButton and "enabled." or "disabled."))
        return
    end

    if command == "scale" then
        local numberValue = tonumber(value)

        if numberValue then
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.scale = Clamp(numberValue, 0.75, 1.20)
            RB:ApplyScale()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99ReagentBankUI|r scale set to %.2f", ReagentBankUIDB.scale))
            return
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r usage: /rbank scale 0.90")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank refresh")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank hide")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank scale 0.75 - 1.20")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank autodeposit on|off")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank autowithdraw on|off")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank minimap on|off")
    DEFAULT_CHAT_FRAME:AddMessage("  /craftbag")
end

RB:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName == ADDON_NAME then
            ReagentBankUIDB = ReagentBankUIDB or {}
            if ReagentBankUIDB.autoDepositLeftovers == nil then
                ReagentBankUIDB.autoDepositLeftovers = false
            end
            if ReagentBankUIDB.autoWithdrawRecipe == nil then
                ReagentBankUIDB.autoWithdrawRecipe = false
            end
            if ReagentBankUIDB.showMinimapButton == nil then
                ReagentBankUIDB.showMinimapButton = MINIMAP_BUTTON_DEFAULT_ENABLED
            end
            if ReagentBankUIDB.minimapButtonAngle == nil then
                ReagentBankUIDB.minimapButtonAngle = MINIMAP_BUTTON_DEFAULT_ANGLE
            end
            if ReagentBankUIDB.tradeSkillPrepareCount == nil then
                ReagentBankUIDB.tradeSkillPrepareCount = 1
            else
                ReagentBankUIDB.tradeSkillPrepareCount = self:ClampTradeSkillPrepareCount(ReagentBankUIDB.tradeSkillPrepareCount)
            end
            self:ApplySavedPosition()
            self:ApplyScale()
            self:CreatePaperDollButton()
            self:CreateMinimapButton()
            self:CreateTradeSkillControls()
        elseif addonName == "Blizzard_TradeSkillUI" then
            self:CreateTradeSkillControls()
        end
    elseif event == "PLAYER_LOGIN" then
        self:CreatePaperDollButton()
        self:CreateMinimapButton()
        self:CreateTradeSkillControls()
    elseif event == "TRADE_SKILL_SHOW" then
        self:CreateTradeSkillControls()
        self:UpdateTradeSkillControls()
        self:MaybeAutoWithdrawForSelectedRecipe(false)
    elseif event == "TRADE_SKILL_UPDATE" then
        self:CreateTradeSkillControls()
        self:UpdateTradeSkillControls()
        self:MaybeAutoWithdrawForSelectedRecipe(false)
    elseif event == "TRADE_SKILL_CLOSE" then
        self:HandleTradeSkillClosed()
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        self:HandleProtocol(message)
    end
end)

RB:RegisterEvent("ADDON_LOADED")
RB:RegisterEvent("PLAYER_LOGIN")
RB:RegisterEvent("TRADE_SKILL_SHOW")
RB:RegisterEvent("TRADE_SKILL_UPDATE")
RB:RegisterEvent("TRADE_SKILL_CLOSE")
