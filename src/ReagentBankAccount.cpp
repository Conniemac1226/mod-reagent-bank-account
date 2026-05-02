// SPDX-License-Identifier: AGPL-3.0-or-later
/*
 * AzerothCore module: Standalone Reagent Bank Account
 *
 * This version intentionally does not require a spawned banker NPC.
 * Players and addons use the SEC_PLAYER chat command API:
 *
 *   .rbank
 *   .rbank open
 *   .rbank list <categoryId> [page]
 *   .rbank deposit all
 *   .rbank deposit category <categoryId>
 *   .rbank deposit item <itemEntry> <amount>
 *   .rbank deposit items <itemEntry> <amount> [itemEntry amount ...]
 *   .rbank withdraw all
 *   .rbank withdraw category <categoryId>
 *   .rbank withdraw item <itemEntry> <one|stack|all> [categoryId] [page]
 *   .rbank withdraw item <itemEntry> exact <amount> [categoryId] [page]
 *   .rbank withdraw needed <itemEntry> <amount> [itemEntry amount ...]
 *
 * The matching addon listens for hidden RBANK:* system protocol lines.
 */

#include "ReagentBankAccount.h"

#include "Bag.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdlib>
#include <map>
#include <sstream>
#include <string>
#include <vector>

uint32 g_reagentBankMaxItemsPerPage = DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;
bool g_accountWideReagentBank = false;
bool g_reagentBankEnabled = true;
bool g_reagentBankAutoMigrate = true;
bool g_reagentBankEnableNpc = false;

static bool g_reagentBankStorageReady = false;

using Acore::ChatCommands::ChatCommandTable;
using Acore::ChatCommands::Console;

namespace ReagentBank
{
    struct CategoryInfo
    {
        uint32 SubClass;
        char const* Name;
        uint32 SampleItem;
    };

    static constexpr std::array<CategoryInfo, 15> Categories =
    { {
        { ITEM_SUBCLASS_CLOTH,              "Cloth",             2589  },
        { ITEM_SUBCLASS_MEAT,               "Meat",              12208 },
        { ITEM_SUBCLASS_METAL_STONE,        "Metal & Stone",     2772  },
        { ITEM_SUBCLASS_ENCHANTING,         "Enchanting",        10940 },
        { ITEM_SUBCLASS_ELEMENTAL,          "Elemental",         7068  },
        { ITEM_SUBCLASS_PARTS,              "Parts",             4359  },
        { ITEM_SUBCLASS_TRADE_GOODS_OTHER,  "Other Trade Goods", 2604  },
        { ITEM_SUBCLASS_HERB,               "Herb",              2453  },
        { ITEM_SUBCLASS_LEATHER,            "Leather",           2318  },
        { ITEM_SUBCLASS_JEWELCRAFTING,      "Jewelcrafting",     1206  },
        { ITEM_SUBCLASS_EXPLOSIVES,         "Explosives",        4358  },
        { ITEM_SUBCLASS_DEVICES,            "Devices",           4388  },
        { ITEM_SUBCLASS_MATERIAL,           "Nether Material",   23572 },
        { ITEM_SUBCLASS_ARMOR_ENCHANTMENT,  "Armor Vellum",      38682 },
        { ITEM_SUBCLASS_WEAPON_ENCHANTMENT, "Weapon Vellum",     39349 }
    } };

    struct StoredItem
    {
        uint32 ItemEntry = 0;
        uint32 ItemSubclass = 0;
        uint32 Amount = 0;
    };

    enum class WithdrawMode : uint8
    {
        One,
        Stack,
        All
    };

    static std::string ToLower(std::string value)
    {
        for (char& c : value)
            c = char(std::tolower(static_cast<unsigned char>(c)));

        return value;
    }

    static std::vector<std::string> Tokenize(char const* args)
    {
        std::vector<std::string> tokens;

        if (!args)
            return tokens;

        std::istringstream stream(args);
        std::string token;
        while (stream >> token)
            tokens.push_back(token);

        return tokens;
    }

    static bool TryParseUInt32(std::string const& text, uint32& value)
    {
        if (text.empty())
            return false;

        char* end = nullptr;
        unsigned long parsed = std::strtoul(text.c_str(), &end, 10);
        if (!end || *end != '\0')
            return false;

        value = uint32(parsed);
        return true;
    }

    static bool TryParseItemAmountPairs(std::vector<std::string> const& tokens, std::size_t startIndex, std::vector<std::pair<uint32, uint32>>& pairs)
    {
        pairs.clear();

        if (startIndex >= tokens.size())
            return false;

        if (((tokens.size() - startIndex) % 2) != 0)
            return false;

        for (std::size_t index = startIndex; index < tokens.size(); index += 2)
        {
            uint32 itemEntry = 0;
            uint32 amount = 0;

            if (!TryParseUInt32(tokens[index], itemEntry) || !TryParseUInt32(tokens[index + 1], amount))
                return false;

            if (!itemEntry || !amount)
                return false;

            pairs.emplace_back(itemEntry, amount);
        }

        return !pairs.empty();
    }

    static bool IsCategory(uint32 itemSubclass)
    {
        for (CategoryInfo const& category : Categories)
            if (category.SubClass == itemSubclass)
                return true;

        return false;
    }

    static CategoryInfo const* GetCategory(uint32 itemSubclass)
    {
        for (CategoryInfo const& category : Categories)
            if (category.SubClass == itemSubclass)
                return &category;

        return nullptr;
    }

    static uint32 NormalizePage(uint32 page)
    {
        return page > MAX_REAGENT_BANK_PAGE_NUMBER ? MAX_REAGENT_BANK_PAGE_NUMBER : page;
    }

    static uint32 GetPageSize()
    {
        if (g_reagentBankMaxItemsPerPage == 0)
            return DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;

        return std::min<uint32>(g_reagentBankMaxItemsPerPage, 50);
    }

    static void GetStorageKeys(Player const* player, uint32& accountKey, uint32& guidKey)
    {
        if (g_accountWideReagentBank)
        {
            accountKey = player->GetSession()->GetAccountId();
            guidKey = 0;
        }
        else
        {
            accountKey = 0;
            guidKey = uint32(player->GetGUID().GetCounter());
        }
    }

    static char const* GetDesiredStorageModeName()
    {
        return g_accountWideReagentBank ? "account" : "character";
    }

    static void LoadConfig()
    {
        g_reagentBankEnabled = sConfigMgr->GetOption<bool>("ReagentBankAccount.Enable", true);
        g_accountWideReagentBank = sConfigMgr->GetOption<bool>("ReagentBankAccount.AccountWide", true);
        g_reagentBankMaxItemsPerPage = sConfigMgr->GetOption<uint32>("ReagentBankAccount.MaxItemsPerPage", DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE);
        g_reagentBankAutoMigrate = sConfigMgr->GetOption<bool>("ReagentBankAccount.AutoMigrate", true);
        g_reagentBankEnableNpc = sConfigMgr->GetOption<bool>("ReagentBankAccount.EnableNpc", false);

        if (g_reagentBankMaxItemsPerPage == 0)
            g_reagentBankMaxItemsPerPage = DEFAULT_REAGENT_BANK_ITEMS_PER_PAGE;

        if (g_reagentBankMaxItemsPerPage > 50)
            g_reagentBankMaxItemsPerPage = 50;
    }

    static uint64 QueryUInt64(char const* sql)
    {
        QueryResult result = CharacterDatabase.Query(sql);
        if (!result)
            return 0;

        return (*result)[0].Get<uint64>();
    }

    static void EnsureStorageTables()
    {
        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account` ("
            "`account_id` INT UNSIGNED NOT NULL DEFAULT 0,"
            "`guid` INT UNSIGNED NOT NULL DEFAULT 0,"
            "`item_entry` INT UNSIGNED NOT NULL,"
            "`item_subclass` INT UNSIGNED NOT NULL,"
            "`amount` INT UNSIGNED NOT NULL DEFAULT 0,"
            "PRIMARY KEY (`account_id`, `guid`, `item_entry`),"
            "KEY `idx_mod_reagent_bank_owner_subclass` (`account_id`, `guid`, `item_subclass`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account_meta` ("
            "`setting` VARCHAR(64) NOT NULL,"
            "`value` VARCHAR(64) NOT NULL,"
            "`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
            "PRIMARY KEY (`setting`)"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    }

    static std::string GetStoredStorageMode()
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT `value` FROM `mod_reagent_bank_account_meta` WHERE `setting` = 'storage_mode'");

        if (!result)
            return "";

        return (*result)[0].Get<std::string>();
    }

    static void SetStoredStorageMode()
    {
        CharacterDatabase.DirectExecute(
            "INSERT INTO `mod_reagent_bank_account_meta` (`setting`, `value`) "
            "VALUES ('storage_mode', '{}') "
            "ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
            GetDesiredStorageModeName());
    }

    static void MigrateCharacterRowsToAccountRows()
    {
        uint64 const sourceRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` = 0 AND `guid` <> 0");

        if (!sourceRows)
            return;

        uint64 const orphanRows = QueryUInt64(
            "SELECT COUNT(*) "
            "FROM `mod_reagent_bank_account` r "
            "LEFT JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0 AND c.`guid` IS NULL");

        auto trans = CharacterDatabase.BeginTransaction();

        // Merge every character-scoped row into its owning account, preserving total amounts.
        trans->Append(
            "INSERT INTO `mod_reagent_bank_account` (`account_id`, `guid`, `item_entry`, `item_subclass`, `amount`) "
            "SELECT c.`account`, 0, r.`item_entry`, MIN(r.`item_subclass`), SUM(r.`amount`) "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0 "
            "GROUP BY c.`account`, r.`item_entry` "
            "ON DUPLICATE KEY UPDATE "
            "`amount` = `amount` + VALUES(`amount`), "
            "`item_subclass` = VALUES(`item_subclass`)");

        trans->Append(
            "DELETE r "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN `characters` c ON c.`guid` = r.`guid` "
            "WHERE r.`account_id` = 0 AND r.`guid` <> 0");

        CharacterDatabase.CommitTransaction(trans);

        LOG_INFO("module", "ReagentBankAccount: migrated {} character-scoped reagent bank row(s) into account-scoped storage.", sourceRows - orphanRows);

        if (orphanRows)
        {
            LOG_ERROR("module", "ReagentBankAccount: {} character-scoped reagent bank row(s) had no matching characters.guid and were left untouched.", orphanRows);
        }
    }

    static void MigrateAccountRowsToCharacterRows()
    {
        uint64 const sourceRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` <> 0 AND `guid` = 0");

        if (!sourceRows)
            return;

        uint64 const orphanRows = QueryUInt64(
            "SELECT COUNT(*) "
            "FROM `mod_reagent_bank_account` r "
            "LEFT JOIN (SELECT `account`, MIN(`guid`) AS `owner_guid` FROM `characters` GROUP BY `account`) c "
            "ON c.`account` = r.`account_id` "
            "WHERE r.`account_id` <> 0 AND r.`guid` = 0 AND c.`owner_guid` IS NULL");

        auto trans = CharacterDatabase.BeginTransaction();

        // There is no safe way to reconstruct the original character ownership once rows were merged
        // account-wide. Preserve item totals by assigning each account bank to the account's lowest GUID.
        trans->Append(
            "INSERT INTO `mod_reagent_bank_account` (`account_id`, `guid`, `item_entry`, `item_subclass`, `amount`) "
            "SELECT 0, owner.`owner_guid`, r.`item_entry`, r.`item_subclass`, r.`amount` "
            "FROM `mod_reagent_bank_account` r "
            "INNER JOIN (SELECT `account`, MIN(`guid`) AS `owner_guid` FROM `characters` GROUP BY `account`) owner "
            "ON owner.`account` = r.`account_id` "
            "WHERE r.`account_id` <> 0 AND r.`guid` = 0 "
            "ON DUPLICATE KEY UPDATE "
            "`amount` = `amount` + VALUES(`amount`), "
            "`item_subclass` = VALUES(`item_subclass`)");

        trans->Append(
            "DELETE FROM `mod_reagent_bank_account` "
            "WHERE `account_id` <> 0 AND `guid` = 0 "
            "AND `account_id` IN (SELECT DISTINCT `account` FROM `characters`)");

        CharacterDatabase.CommitTransaction(trans);

        LOG_INFO("module", "ReagentBankAccount: migrated {} account-scoped reagent bank row(s) into character-scoped storage.", sourceRows - orphanRows);

        if (orphanRows)
        {
            LOG_ERROR("module", "ReagentBankAccount: {} account-scoped reagent bank row(s) had no matching characters.account and were left untouched.", orphanRows);
        }
    }

    static void EnsureStorageModeMatchesConfig()
    {
        EnsureStorageTables();

        if (!g_reagentBankAutoMigrate)
        {
            LOG_INFO("module", "ReagentBankAccount: automatic storage migration is disabled. Active storage mode: {}.", GetDesiredStorageModeName());
            return;
        }

        std::string storedMode = GetStoredStorageMode();
        std::string desiredMode = GetDesiredStorageModeName();

        bool const hasCharacterRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` = 0 AND `guid` <> 0") != 0;
        bool const hasAccountRows = QueryUInt64(
            "SELECT COUNT(*) FROM `mod_reagent_bank_account` WHERE `account_id` <> 0 AND `guid` = 0") != 0;

        if (storedMode.empty())
        {
            if (desiredMode == "account" && hasCharacterRows)
                MigrateCharacterRowsToAccountRows();
            else if (desiredMode == "character" && hasAccountRows)
                MigrateAccountRowsToCharacterRows();

            SetStoredStorageMode();
            LOG_INFO("module", "ReagentBankAccount: initialized storage mode metadata as '{}'.", desiredMode);
            return;
        }

        if (storedMode == desiredMode)
        {
            // Also heal mixed tables from older/manual edits if the active mode is clear.
            if (desiredMode == "account" && hasCharacterRows)
                MigrateCharacterRowsToAccountRows();
            else if (desiredMode == "character" && hasAccountRows)
                MigrateAccountRowsToCharacterRows();

            return;
        }

        LOG_INFO("module", "ReagentBankAccount: storage mode changed from '{}' to '{}'; migrating stored rows.", storedMode, desiredMode);

        if (desiredMode == "account")
            MigrateCharacterRowsToAccountRows();
        else
            MigrateAccountRowsToCharacterRows();

        SetStoredStorageMode();
    }

    static void SendProtocol(ChatHandler* handler, std::string const& line)
    {
        if (!handler)
            return;

        handler->SendSysMessage(line.c_str());
    }

    static void SendOk(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:OK:{}", message));
    }

    static void SendError(ChatHandler* handler, std::string const& message)
    {
        SendProtocol(handler, Acore::StringFormat("RBANK:ERR:{}", message));
    }

    static bool IsStorableReagent(ItemTemplate const* proto, uint32& itemEntry, uint32& itemSubclass)
    {
        if (!proto)
            return false;

        if (!(proto->Class == ITEM_CLASS_TRADE_GOODS || proto->Class == ITEM_CLASS_GEM || proto->Class == ITEM_CLASS_REAGENT))
            return false;

        if (proto->GetMaxStackSize() <= 1)
            return false;

        itemEntry = proto->ItemId;
        if (proto->Class == ITEM_CLASS_GEM)
            itemSubclass = ITEM_SUBCLASS_JEWELCRAFTING;
        else if (proto->Class == ITEM_CLASS_REAGENT)
            itemSubclass = ITEM_SUBCLASS_TRADE_GOODS_OTHER;
        else
            itemSubclass = proto->SubClass;

        return IsCategory(itemSubclass);
    }

    static void LoadStoredItems(Player const* player, std::map<uint32, StoredItem>& items)
    {
        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {}",
            accountKey, guidKey);

        if (!result)
            return;

        do
        {
            StoredItem item;
            item.ItemEntry = (*result)[0].Get<uint32>();
            item.ItemSubclass = (*result)[1].Get<uint32>();
            item.Amount = (*result)[2].Get<uint32>();

            if (item.ItemEntry && item.Amount && IsCategory(item.ItemSubclass))
                items[item.ItemEntry] = item;
        } while (result->NextRow());
    }

    static void SaveStoredItems(Player const* player, std::map<uint32, StoredItem> const& changedItems)
    {
        if (changedItems.empty())
            return;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        auto trans = CharacterDatabase.BeginTransaction();

        for (std::pair<uint32 const, StoredItem> const& pair : changedItems)
        {
            StoredItem const& item = pair.second;

            trans->Append(
                "DELETE FROM mod_reagent_bank_account "
                "WHERE account_id = {} AND guid = {} AND item_entry = {}",
                accountKey, guidKey, item.ItemEntry);

            if (item.Amount)
            {
                trans->Append(
                    "INSERT INTO mod_reagent_bank_account "
                    "(account_id, guid, item_entry, item_subclass, amount) "
                    "VALUES ({}, {}, {}, {}, {})",
                    accountKey, guidKey, item.ItemEntry, item.ItemSubclass, item.Amount);
            }
        }

        CharacterDatabase.CommitTransaction(trans);
    }

    static void QueryCategoryTotals(Player const* player, uint32 category, uint32& typeCount, uint32& totalAmount)
    {
        typeCount = 0;
        totalAmount = 0;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT COUNT(*), COALESCE(SUM(amount), 0) "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {}",
            accountKey, guidKey, category);

        if (!result)
            return;

        typeCount = uint32((*result)[0].Get<uint64>());
        totalAmount = uint32((*result)[1].Get<uint64>());
    }

    static void SendRoot(ChatHandler* handler, Player const* player)
    {
        if (!handler || !player)
            return;

        SendProtocol(handler, Acore::StringFormat("RBANK:BEGIN:ROOT:{}", g_accountWideReagentBank ? 1 : 0));

        for (CategoryInfo const& category : Categories)
        {
            uint32 typeCount = 0;
            uint32 totalAmount = 0;
            QueryCategoryTotals(player, category.SubClass, typeCount, totalAmount);

            SendProtocol(handler, Acore::StringFormat(
                "RBANK:CAT:{}:{}:{}:{}",
                category.SubClass,
                category.SampleItem,
                typeCount,
                totalAmount));
        }

        SendProtocol(handler, "RBANK:END:ROOT");
    }

    static void SendCategory(ChatHandler* handler, Player const* player, uint32 category, uint32 requestedPage)
    {
        if (!handler || !player)
            return;

        CategoryInfo const* categoryInfo = GetCategory(category);
        if (!categoryInfo)
        {
            SendError(handler, "Unknown reagent category.");
            SendRoot(handler, player);
            return;
        }

        uint32 typeCount = 0;
        uint32 totalAmount = 0;
        QueryCategoryTotals(player, category, typeCount, totalAmount);

        uint32 const pageSize = GetPageSize();
        uint32 totalPages = typeCount == 0 ? 1 : ((typeCount + pageSize - 1) / pageSize);
        uint32 page = NormalizePage(requestedPage);
        if (page >= totalPages)
            page = totalPages - 1;

        uint32 offset = page * pageSize;

        SendProtocol(handler, Acore::StringFormat(
            "RBANK:BEGIN:CATEGORY:{}:{}:{}:{}:{}",
            category,
            page,
            totalPages,
            typeCount,
            totalAmount));

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {} "
            "ORDER BY item_entry ASC "
            "LIMIT {} OFFSET {}",
            accountKey, guidKey, category, pageSize, offset);

        if (result)
        {
            do
            {
                uint32 itemEntry = (*result)[0].Get<uint32>();
                uint32 amount = (*result)[1].Get<uint32>();

                SendProtocol(handler, Acore::StringFormat("RBANK:ITEM:{}:{}", itemEntry, amount));
            } while (result->NextRow());
        }

        SendProtocol(handler, "RBANK:END:CATEGORY");
    }

    static uint32 DepositFromSlot(Player* player, uint8 bagSlot, uint8 itemSlot, uint32 onlyCategory, std::map<uint32, StoredItem>& storedItems, std::map<uint32, uint32>& deposited)
    {
        Item* item = player->GetItemByPos(bagSlot, itemSlot);
        if (!item)
            return 0;

        uint32 itemEntry = 0;
        uint32 itemSubclass = 0;
        if (!IsStorableReagent(item->GetTemplate(), itemEntry, itemSubclass))
            return 0;

        if (onlyCategory && itemSubclass != onlyCategory)
            return 0;

        uint32 count = item->GetCount();
        if (!count)
            return 0;

        StoredItem& stored = storedItems[itemEntry];
        stored.ItemEntry = itemEntry;
        stored.ItemSubclass = itemSubclass;
        stored.Amount += count;

        deposited[itemEntry] += count;

        player->DestroyItem(bagSlot, itemSlot, true);
        return count;
    }

    static uint32 Deposit(Player* player, uint32 onlyCategory, std::map<uint32, uint32>& deposited)
    {
        if (!player)
            return 0;

        std::map<uint32, StoredItem> storedItems;
        LoadStoredItems(player, storedItems);

        uint32 totalDeposited = 0;

        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            totalDeposited += DepositFromSlot(player, INVENTORY_SLOT_BAG_0, slot, onlyCategory, storedItems, deposited);

        for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
        {
            Bag* bag = player->GetBagByPos(bagSlot);
            if (!bag)
                continue;

            for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
                totalDeposited += DepositFromSlot(player, bagSlot, uint8(slot), onlyCategory, storedItems, deposited);
        }

        std::map<uint32, StoredItem> changedItems;
        for (std::pair<uint32 const, uint32> const& pair : deposited)
        {
            std::map<uint32, StoredItem>::const_iterator storedItr = storedItems.find(pair.first);
            if (storedItr != storedItems.end())
                changedItems[pair.first] = storedItr->second;
        }

        SaveStoredItems(player, changedItems);
        return totalDeposited;
    }

    static uint32 DepositSpecificItems(Player* player, std::vector<std::pair<uint32, uint32>> const& requestedItems, std::map<uint32, uint32>& deposited)
    {
        deposited.clear();

        if (!player || requestedItems.empty())
            return 0;

        std::map<uint32, StoredItem> storedItems;
        LoadStoredItems(player, storedItems);

        uint32 totalDeposited = 0;

        for (std::pair<uint32, uint32> const& requested : requestedItems)
        {
            uint32 const requestedItemEntry = requested.first;
            uint32 const requestedAmount = requested.second;

            if (!requestedItemEntry || !requestedAmount)
                continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(requestedItemEntry);
            uint32 itemEntry = 0;
            uint32 itemSubclass = 0;
            if (!IsStorableReagent(proto, itemEntry, itemSubclass))
                continue;

            uint32 const availableInBags = player->GetItemCount(itemEntry, false);
            uint32 const amountToDeposit = std::min<uint32>(requestedAmount, availableInBags);
            if (!amountToDeposit)
                continue;

            // Match the existing deposit behavior: remove bag items, then persist the virtual balance.
            player->DestroyItemCount(itemEntry, amountToDeposit, true);

            StoredItem& stored = storedItems[itemEntry];
            stored.ItemEntry = itemEntry;
            stored.ItemSubclass = itemSubclass;
            stored.Amount += amountToDeposit;

            deposited[itemEntry] += amountToDeposit;
            totalDeposited += amountToDeposit;
        }

        std::map<uint32, StoredItem> changedItems;
        for (std::pair<uint32 const, uint32> const& pair : deposited)
        {
            std::map<uint32, StoredItem>::const_iterator storedItr = storedItems.find(pair.first);
            if (storedItr != storedItems.end())
                changedItems[pair.first] = storedItr->second;
        }

        SaveStoredItems(player, changedItems);
        return totalDeposited;
    }

    static bool LoadStoredItem(Player const* player, uint32 itemEntry, StoredItem& item)
    {
        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_entry = {}",
            accountKey, guidKey, itemEntry);

        if (!result)
            return false;

        item.ItemEntry = (*result)[0].Get<uint32>();
        item.ItemSubclass = (*result)[1].Get<uint32>();
        item.Amount = (*result)[2].Get<uint32>();

        return item.ItemEntry && item.Amount && IsCategory(item.ItemSubclass);
    }

    static uint32 WithdrawExact(Player* player, StoredItem& stored, uint32 requestedAmount, bool& stoppedForBagSpace)
    {
        stoppedForBagSpace = false;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(stored.ItemEntry);
        if (!proto)
            return 0;

        uint32 remainingRequest = std::min<uint32>(requestedAmount, stored.Amount);
        uint32 withdrawn = 0;
        uint32 stackSize = std::max<uint32>(1, proto->GetMaxStackSize());

        while (remainingRequest)
        {
            uint32 toGive = std::min<uint32>(stackSize, remainingRequest);

            ItemPosCountVec dest;
            InventoryResult msg = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, stored.ItemEntry, toGive);
            if (msg != EQUIP_ERR_OK)
            {
                player->SendEquipError(msg, nullptr, nullptr, stored.ItemEntry);
                stoppedForBagSpace = true;
                break;
            }

            Item* item = player->StoreNewItem(dest, stored.ItemEntry, true);
            player->SendNewItem(item, toGive, true, false);

            withdrawn += toGive;
            remainingRequest -= toGive;
            stored.Amount -= toGive;
        }

        std::map<uint32, StoredItem> changed;
        changed[stored.ItemEntry] = stored;
        SaveStoredItems(player, changed);

        return withdrawn;
    }

    static uint32 WithdrawItem(Player* player, uint32 itemEntry, WithdrawMode mode, bool& stoppedForBagSpace)
    {
        stoppedForBagSpace = false;

        StoredItem stored;
        if (!LoadStoredItem(player, itemEntry, stored))
            return 0;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemEntry);
        if (!proto)
            return 0;

        uint32 requested = 0;
        switch (mode)
        {
        case WithdrawMode::One:
            requested = 1;
            break;
        case WithdrawMode::Stack:
            requested = std::max<uint32>(1, proto->GetMaxStackSize());
            break;
        case WithdrawMode::All:
            requested = stored.Amount;
            break;
        }

        return WithdrawExact(player, stored, requested, stoppedForBagSpace);
    }

    static uint32 WithdrawItemAmount(Player* player, uint32 itemEntry, uint32 requestedAmount, bool& stoppedForBagSpace)
    {
        stoppedForBagSpace = false;

        if (!requestedAmount)
            return 0;

        StoredItem stored;
        if (!LoadStoredItem(player, itemEntry, stored))
            return 0;

        return WithdrawExact(player, stored, requestedAmount, stoppedForBagSpace);
    }

    static uint32 WithdrawSpecificItems(Player* player, std::vector<std::pair<uint32, uint32>> const& requestedItems, bool& stoppedForBagSpace, uint32& incompleteItems)
    {
        stoppedForBagSpace = false;
        incompleteItems = 0;

        if (!player || requestedItems.empty())
            return 0;

        uint32 totalWithdrawn = 0;

        for (std::pair<uint32, uint32> const& requested : requestedItems)
        {
            uint32 const itemEntry = requested.first;
            uint32 const requestedAmount = requested.second;

            if (!itemEntry || !requestedAmount)
                continue;

            bool full = false;
            uint32 withdrawn = WithdrawItemAmount(player, itemEntry, requestedAmount, full);
            totalWithdrawn += withdrawn;

            if (withdrawn < requestedAmount)
                ++incompleteItems;

            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        }

        return totalWithdrawn;
    }

    static uint32 WithdrawCategory(Player* player, uint32 category, bool& stoppedForBagSpace)
    {
        stoppedForBagSpace = false;

        if (!IsCategory(category))
            return 0;

        uint32 accountKey = 0;
        uint32 guidKey = 0;
        GetStorageKeys(player, accountKey, guidKey);

        QueryResult result = CharacterDatabase.Query(
            "SELECT item_entry, item_subclass, amount "
            "FROM mod_reagent_bank_account "
            "WHERE account_id = {} AND guid = {} AND item_subclass = {} "
            "ORDER BY item_entry ASC",
            accountKey, guidKey, category);

        if (!result)
            return 0;

        uint32 totalWithdrawn = 0;

        do
        {
            StoredItem stored;
            stored.ItemEntry = (*result)[0].Get<uint32>();
            stored.ItemSubclass = (*result)[1].Get<uint32>();
            stored.Amount = (*result)[2].Get<uint32>();

            bool full = false;
            totalWithdrawn += WithdrawExact(player, stored, stored.Amount, full);
            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        } while (result->NextRow());

        return totalWithdrawn;
    }

    static uint32 WithdrawAll(Player* player, bool& stoppedForBagSpace)
    {
        stoppedForBagSpace = false;

        uint32 totalWithdrawn = 0;
        for (CategoryInfo const& category : Categories)
        {
            bool full = false;
            totalWithdrawn += WithdrawCategory(player, category.SubClass, full);
            if (full)
            {
                stoppedForBagSpace = true;
                break;
            }
        }

        return totalWithdrawn;
    }

    static bool ParseWithdrawMode(std::string const& text, WithdrawMode& mode)
    {
        std::string lower = ToLower(text);

        if (lower == "one" || lower == "1")
        {
            mode = WithdrawMode::One;
            return true;
        }

        if (lower == "stack")
        {
            mode = WithdrawMode::Stack;
            return true;
        }

        if (lower == "all")
        {
            mode = WithdrawMode::All;
            return true;
        }

        return false;
    }

    static void SendUsage(ChatHandler* handler)
    {
        SendProtocol(handler, "RBANK:ERR:Usage: .rbank open | list <categoryId> [page] | deposit all|category <categoryId>|item <itemEntry> <amount>|items <itemEntry> <amount> [...] | withdraw all|category <categoryId>|item <itemEntry> <one|stack|all|exact <amount>>|needed <itemEntry> <amount> [...]");
    }
}

class mod_reagent_bank_account_commandscript : public CommandScript
{
public:
    mod_reagent_bank_account_commandscript() : CommandScript("mod_reagent_bank_account_commandscript") {}

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "rbank", HandleRBankCommand, SEC_PLAYER, Console::No }
        };

        return commandTable;
    }

private:
    static bool HandleRBankCommand(ChatHandler* handler, char const* args)
    {
        Player* player = handler && handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        if (!player)
            return false;

        if (!g_reagentBankStorageReady)
        {
            ReagentBank::SendError(handler, "Reagent bank storage is not initialized yet.");
            return true;
        }

        if (!g_reagentBankEnabled)
        {
            ReagentBank::SendError(handler, "The reagent bank is disabled.");
            return true;
        }

        std::vector<std::string> tokens = ReagentBank::Tokenize(args);

        if (tokens.empty() || ReagentBank::ToLower(tokens[0]) == "open" || ReagentBank::ToLower(tokens[0]) == "root")
        {
            ReagentBank::SendRoot(handler, player);
            return true;
        }

        std::string command = ReagentBank::ToLower(tokens[0]);

        if (command == "list")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendRoot(handler, player);
                return true;
            }

            uint32 category = 0;
            if (!ReagentBank::TryParseUInt32(tokens[1], category) || !ReagentBank::IsCategory(category))
            {
                ReagentBank::SendError(handler, "Unknown reagent category.");
                ReagentBank::SendRoot(handler, player);
                return true;
            }

            uint32 page = 0;
            if (tokens.size() >= 3)
                ReagentBank::TryParseUInt32(tokens[2], page);

            ReagentBank::SendCategory(handler, player, category, page);
            return true;
        }

        if (command == "deposit")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendUsage(handler);
                return true;
            }

            std::string scope = ReagentBank::ToLower(tokens[1]);

            if (scope == "all")
            {
                std::map<uint32, uint32> deposited;
                uint32 total = ReagentBank::Deposit(player, 0, deposited);

                if (total)
                    ReagentBank::SendOk(handler, Acore::StringFormat("Deposited {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                ReagentBank::SendRoot(handler, player);
                return true;
            }

            if (scope == "category")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 category = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], category) || !ReagentBank::IsCategory(category))
                {
                    ReagentBank::SendError(handler, "Unknown reagent category.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                std::map<uint32, uint32> deposited;
                uint32 total = ReagentBank::Deposit(player, category, deposited);

                if (total)
                    ReagentBank::SendOk(handler, Acore::StringFormat("Deposited {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                ReagentBank::SendCategory(handler, player, category, 0);
                return true;
            }

            if (scope == "item")
            {
                if (tokens.size() < 4)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 itemEntry = 0;
                uint32 amount = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], itemEntry) || !ReagentBank::TryParseUInt32(tokens[3], amount) || !itemEntry || !amount)
                {
                    ReagentBank::SendError(handler, "Usage: .rbank deposit item <itemEntry> <amount>");
                    return true;
                }

                std::vector<std::pair<uint32, uint32>> requestedItems;
                requestedItems.emplace_back(itemEntry, amount);

                std::map<uint32, uint32> deposited;
                uint32 total = ReagentBank::DepositSpecificItems(player, requestedItems, deposited);

                if (total)
                    ReagentBank::SendOk(handler, Acore::StringFormat("Deposited {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No matching reagents were found in your bags.");

                return true;
            }

            if (scope == "items")
            {
                std::vector<std::pair<uint32, uint32>> requestedItems;
                if (!ReagentBank::TryParseItemAmountPairs(tokens, 2, requestedItems))
                {
                    ReagentBank::SendError(handler, "Usage: .rbank deposit items <itemEntry> <amount> [itemEntry amount ...]");
                    return true;
                }

                std::map<uint32, uint32> deposited;
                uint32 total = ReagentBank::DepositSpecificItems(player, requestedItems, deposited);

                if (total)
                    ReagentBank::SendOk(handler, Acore::StringFormat("Deposited {} reagent leftover(s).", total));
                else
                    ReagentBank::SendOk(handler, "No matching leftover reagents were found in your bags.");

                return true;
            }

            ReagentBank::SendUsage(handler);
            return true;
        }

        if (command == "withdraw")
        {
            if (tokens.size() < 2)
            {
                ReagentBank::SendUsage(handler);
                return true;
            }

            std::string scope = ReagentBank::ToLower(tokens[1]);

            if (scope == "all")
            {
                bool stoppedForBagSpace = false;
                uint32 total = ReagentBank::WithdrawAll(player, stoppedForBagSpace);

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} reagent(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No reagents were withdrawn.");

                ReagentBank::SendRoot(handler, player);
                return true;
            }

            if (scope == "category")
            {
                if (tokens.size() < 3)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 category = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], category) || !ReagentBank::IsCategory(category))
                {
                    ReagentBank::SendError(handler, "Unknown reagent category.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                bool stoppedForBagSpace = false;
                uint32 total = ReagentBank::WithdrawCategory(player, category, stoppedForBagSpace);

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} reagent(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} reagent(s).", total));
                else
                    ReagentBank::SendOk(handler, "No reagents were withdrawn.");

                ReagentBank::SendCategory(handler, player, category, 0);
                return true;
            }

            if (scope == "item")
            {
                if (tokens.size() < 4)
                {
                    ReagentBank::SendUsage(handler);
                    return true;
                }

                uint32 itemEntry = 0;
                if (!ReagentBank::TryParseUInt32(tokens[2], itemEntry))
                {
                    ReagentBank::SendError(handler, "Invalid item entry.");
                    ReagentBank::SendRoot(handler, player);
                    return true;
                }

                uint32 returnCategory = 0;
                uint32 returnPage = 0;
                bool stoppedForBagSpace = false;
                uint32 total = 0;

                std::string modeText = ReagentBank::ToLower(tokens[3]);
                if (modeText == "exact")
                {
                    if (tokens.size() < 5)
                    {
                        ReagentBank::SendUsage(handler);
                        return true;
                    }

                    uint32 amount = 0;
                    if (!ReagentBank::TryParseUInt32(tokens[4], amount) || !amount)
                    {
                        ReagentBank::SendError(handler, "Invalid exact withdraw amount.");
                        return true;
                    }

                    if (tokens.size() >= 6)
                        ReagentBank::TryParseUInt32(tokens[5], returnCategory);
                    if (tokens.size() >= 7)
                        ReagentBank::TryParseUInt32(tokens[6], returnPage);

                    total = ReagentBank::WithdrawItemAmount(player, itemEntry, amount, stoppedForBagSpace);
                }
                else
                {
                    ReagentBank::WithdrawMode mode;
                    if (!ReagentBank::ParseWithdrawMode(modeText, mode))
                    {
                        ReagentBank::SendError(handler, "Invalid withdraw mode.");
                        ReagentBank::SendRoot(handler, player);
                        return true;
                    }

                    if (tokens.size() >= 5)
                        ReagentBank::TryParseUInt32(tokens[4], returnCategory);
                    if (tokens.size() >= 6)
                        ReagentBank::TryParseUInt32(tokens[5], returnPage);

                    total = ReagentBank::WithdrawItem(player, itemEntry, mode, stoppedForBagSpace);
                }

                if (total)
                    ReagentBank::SendOk(handler, stoppedForBagSpace
                        ? Acore::StringFormat("Withdrew {} item(s). Your bags are now full.", total)
                        : Acore::StringFormat("Withdrew {} item(s).", total));
                else
                    ReagentBank::SendOk(handler, "No item was withdrawn.");

                if (returnCategory && ReagentBank::IsCategory(returnCategory))
                    ReagentBank::SendCategory(handler, player, returnCategory, returnPage);
                else
                    ReagentBank::SendRoot(handler, player);

                return true;
            }

            if (scope == "needed")
            {
                std::vector<std::pair<uint32, uint32>> requestedItems;
                if (!ReagentBank::TryParseItemAmountPairs(tokens, 2, requestedItems))
                {
                    ReagentBank::SendError(handler, "Usage: .rbank withdraw needed <itemEntry> <amount> [itemEntry amount ...]");
                    return true;
                }

                bool stoppedForBagSpace = false;
                uint32 incompleteItems = 0;
                uint32 total = ReagentBank::WithdrawSpecificItems(player, requestedItems, stoppedForBagSpace, incompleteItems);

                if (total)
                {
                    if (stoppedForBagSpace)
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s). Your bags are now full.", total));
                    else if (incompleteItems)
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s). Some requested reagents were not fully available.", total));
                    else
                        ReagentBank::SendOk(handler, Acore::StringFormat("Withdrew {} needed reagent(s).", total));
                }
                else
                    ReagentBank::SendOk(handler, "No needed reagents were withdrawn.");

                return true;
            }

            ReagentBank::SendUsage(handler);
            return true;
        }

        if (command == "help")
        {
            ReagentBank::SendUsage(handler);
            ReagentBank::SendRoot(handler, player);
            return true;
        }

        ReagentBank::SendUsage(handler);
        return true;
    }
};

class mod_reagent_bank_account_worldscript : public WorldScript
{
public:
    mod_reagent_bank_account_worldscript() : WorldScript("mod_reagent_bank_account_worldscript") {}

    void OnAfterConfigLoad(bool reload) override
    {
        ReagentBank::LoadConfig();

        if (reload)
        {
            ReagentBank::EnsureStorageModeMatchesConfig();
            g_reagentBankStorageReady = true;

            LOG_INFO("module", "Standalone Reagent Bank config reloaded. Enabled: {}, AccountWide: {}, AutoMigrate: {}, EnableNpc: {}, MaxItemsPerPage: {}",
                g_reagentBankEnabled ? "yes" : "no",
                g_accountWideReagentBank ? "yes" : "no",
                g_reagentBankAutoMigrate ? "yes" : "no",
                g_reagentBankEnableNpc ? "yes" : "no",
                g_reagentBankMaxItemsPerPage);
        }
    }

    void OnStartup() override
    {
        ReagentBank::LoadConfig();
        ReagentBank::EnsureStorageModeMatchesConfig();
        g_reagentBankStorageReady = true;

        LOG_INFO("module", "Standalone Reagent Bank command module loaded. Enabled: {}, AccountWide: {}, AutoMigrate: {}, EnableNpc: {}, MaxItemsPerPage: {}",
            g_reagentBankEnabled ? "yes" : "no",
            g_accountWideReagentBank ? "yes" : "no",
            g_reagentBankAutoMigrate ? "yes" : "no",
            g_reagentBankEnableNpc ? "yes" : "no",
            g_reagentBankMaxItemsPerPage);
    }
};

void AddSC_mod_reagent_bank_account()
{
    new mod_reagent_bank_account_worldscript();
    new mod_reagent_bank_account_commandscript();
}
