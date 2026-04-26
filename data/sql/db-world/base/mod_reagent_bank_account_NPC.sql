CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account` (
    `account_id` INT UNSIGNED NOT NULL DEFAULT 0,
    `guid` INT UNSIGNED NOT NULL DEFAULT 0,
    `item_entry` INT UNSIGNED NOT NULL,
    `item_subclass` INT UNSIGNED NOT NULL,
    `amount` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account_id`, `guid`, `item_entry`),
    KEY `idx_mod_reagent_bank_owner_subclass` (`account_id`, `guid`, `item_subclass`),
    KEY `idx_mod_reagent_bank_guid` (`guid`),
    KEY `idx_mod_reagent_bank_item_entry` (`item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account_meta` (
    `setting` VARCHAR(64) NOT NULL,
    `value` VARCHAR(64) NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `mod_reagent_bank_account_meta` (`setting`, `value`)
VALUES ('storage_mode', 'character')
ON DUPLICATE KEY UPDATE
    `value` = VALUES(`value`);