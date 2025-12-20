-- SQLite 版本数据库架构文件
-- 从 MySQL 转换而来

-- 删除已存在的表
DROP TABLE IF EXISTS `acg_bill`;
DROP TABLE IF EXISTS `acg_business`;
DROP TABLE IF EXISTS `acg_business_level`;
DROP TABLE IF EXISTS `acg_card`;
DROP TABLE IF EXISTS `acg_cash`;
DROP TABLE IF EXISTS `acg_category`;
DROP TABLE IF EXISTS `acg_commodity`;
DROP TABLE IF EXISTS `acg_config`;
DROP TABLE IF EXISTS `acg_coupon`;
DROP TABLE IF EXISTS `acg_manage`;
DROP TABLE IF EXISTS `acg_order`;
DROP TABLE IF EXISTS `acg_order_option`;
DROP TABLE IF EXISTS `acg_pay`;
DROP TABLE IF EXISTS `acg_shared`;
DROP TABLE IF EXISTS `acg_user`;
DROP TABLE IF EXISTS `acg_user_category`;
DROP TABLE IF EXISTS `acg_user_commodity`;
DROP TABLE IF EXISTS `acg_user_group`;
DROP TABLE IF EXISTS `acg_user_recharge`;
DROP TABLE IF EXISTS `acg_manage_log`;
DROP TABLE IF EXISTS `acg_commodity_group`;
DROP TABLE IF EXISTS `acg_upload`;

-- 启用外键约束
PRAGMA foreign_keys = ON;

-- 创建表
CREATE TABLE `acg_bill`  (
                                   `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                   `owner` INTEGER NOT NULL,
                                   `amount` NUMERIC(10, 2) NOT NULL,
                                   `balance` NUMERIC(14, 2) NOT NULL,
                                   `type` INTEGER NOT NULL,
                                   `currency` INTEGER NOT NULL DEFAULT 0,
                                   `log` TEXT NOT NULL,
                                   `create_time` DATETIME NOT NULL,
                                   FOREIGN KEY (`owner`) REFERENCES `acg_user` (`id`) ON DELETE CASCADE
);

-- 创建索引
CREATE INDEX `bill_owner` ON `acg_bill`(`owner`);
CREATE INDEX `bill_type` ON `acg_bill`(`type`);

CREATE TABLE `acg_business`  (
                                       `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                       `user_id` INTEGER NOT NULL,
                                       `shop_name` TEXT,
                                       `title` TEXT,
                                       `notice` TEXT,
                                       `service_qq` TEXT,
                                       `service_url` TEXT,
                                       `subdomain` TEXT,
                                       `topdomain` TEXT,
                                       `master_display` INTEGER NOT NULL DEFAULT 0,
                                       `create_time` DATETIME NOT NULL,
                                       UNIQUE (`user_id`),
                                       UNIQUE (`subdomain`),
                                       UNIQUE (`topdomain`)
);

CREATE TABLE `acg_business_level`  (
                                             `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                             `name` TEXT NOT NULL,
                                             `icon` TEXT,
                                             `cost` NUMERIC(4, 2) NOT NULL DEFAULT 0.00,
                                             `accrual` NUMERIC(4, 2) NOT NULL DEFAULT 0.00,
                                             `substation` INTEGER NOT NULL DEFAULT 0,
                                             `top_domain` INTEGER NOT NULL DEFAULT 0,
                                             `price` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                             `supplier` INTEGER NOT NULL DEFAULT 1
);

-- 插入初始数据
INSERT INTO `acg_business_level` VALUES (1, '体验版', '/assets/static/images/business/v1.png', 0.30, 0.10, 1, 0, 188.00, 1);
INSERT INTO `acg_business_level` VALUES (3, '普通版', '/assets/static/images/business/v2.png', 0.25, 0.15, 1, 0, 288.00, 1);
INSERT INTO `acg_business_level` VALUES (4, '专业版', '/assets/static/images/business/v3.png', 0.20, 0.20, 1, 1, 388.00, 1);

CREATE TABLE `acg_card`  (
                                   `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                   `owner` INTEGER NOT NULL DEFAULT 0,
                                   `commodity_id` INTEGER NOT NULL,
                                   `draft` TEXT,
                                   `secret` TEXT NOT NULL,
                                   `create_time` DATETIME NOT NULL,
                                   `purchase_time` DATETIME,
                                   `order_id` INTEGER,
                                   `status` INTEGER NOT NULL DEFAULT 0,
                                   `note` TEXT,
                                   `race` TEXT,
                                   `sku` JSON,
                                   `draft_premium` NUMERIC(10,2) DEFAULT NULL,
                                   FOREIGN KEY (`commodity_id`) REFERENCES `acg_commodity` (`id`) ON DELETE CASCADE
);

CREATE INDEX `card_owner` ON `acg_card`(`owner`);
CREATE INDEX `card_commodity_id` ON `acg_card`(`commodity_id`);
CREATE INDEX `card_order_id` ON `acg_card`(`order_id`);
CREATE INDEX `card_secret` ON `acg_card`(`secret`);
CREATE INDEX `card_status` ON `acg_card`(`status`);
CREATE INDEX `card_note` ON `acg_card`(`note`);
CREATE INDEX `card_race` ON `acg_card`(`race`);

CREATE TABLE `acg_cash`  (
                                   `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                   `user_id` INTEGER NOT NULL,
                                   `amount` NUMERIC(14, 2) NOT NULL,
                                   `type` INTEGER NOT NULL DEFAULT 0,
                                   `card` INTEGER NOT NULL,
                                   `create_time` DATETIME NOT NULL,
                                   `arrive_time` DATETIME,
                                   `cost` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                   `status` INTEGER NOT NULL,
                                   `message` TEXT,
                                   FOREIGN KEY (`user_id`) REFERENCES `acg_user` (`id`) ON DELETE CASCADE
);

CREATE INDEX `cash_user_id` ON `acg_cash`(`user_id`);
CREATE INDEX `cash_type` ON `acg_cash`(`type`);
CREATE INDEX `cash_message` ON `acg_cash`(`message`);

CREATE TABLE `acg_category`  (
                                       `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                       `name` TEXT NOT NULL,
                                       `sort` INTEGER NOT NULL DEFAULT 0,
                                       `create_time` DATETIME NOT NULL,
                                       `owner` INTEGER NOT NULL DEFAULT 0,
                                       `icon` TEXT,
                                       `status` INTEGER NOT NULL DEFAULT 0,
                                       `hide` INTEGER NOT NULL DEFAULT 0,
                                       `user_level_config` TEXT,
                                       `pid` INTEGER,
                                       FOREIGN KEY (`pid`) REFERENCES `acg_category`(`id`) ON DELETE CASCADE
);

CREATE INDEX `category_owner` ON `acg_category`(`owner`);
CREATE INDEX `category_pid` ON `acg_category`(`pid`);
CREATE INDEX `category_sort` ON `acg_category`(`sort`);

INSERT INTO `acg_category` VALUES (1, 'DEMO', 1, '2021-11-26 17:59:45', 0, '/favicon.ico', 1, 0, NULL , NULL);

CREATE TABLE `acg_commodity`  (
                                        `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                        `category_id` INTEGER NOT NULL,
                                        `name` TEXT NOT NULL,
                                        `description` TEXT,
                                        `cover` TEXT,
                                        `factory_price` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                        `price` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                        `user_price` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                        `status` INTEGER NOT NULL DEFAULT 0,
                                        `owner` INTEGER NOT NULL DEFAULT 0,
                                        `create_time` DATETIME NOT NULL,
                                        `api_status` INTEGER NOT NULL DEFAULT 0,
                                        `code` TEXT NOT NULL,
                                        `delivery_way` INTEGER NOT NULL DEFAULT 0,
                                        `delivery_auto_mode` INTEGER NOT NULL DEFAULT 0,
                                        `delivery_message` TEXT,
                                        `contact_type` INTEGER NOT NULL DEFAULT 0,
                                        `password_status` INTEGER NOT NULL DEFAULT 0,
                                        `sort` INTEGER NOT NULL DEFAULT 0,
                                        `coupon` INTEGER NOT NULL DEFAULT 0,
                                        `shared_id` INTEGER,
                                        `shared_code` TEXT,
                                        `shared_premium` REAL DEFAULT 0.00,
                                        `shared_stock` JSON,
                                        `stock` INTEGER DEFAULT NULL,
                                        `shared_premium_type` INTEGER DEFAULT 0,
                                        `seckill_status` INTEGER NOT NULL DEFAULT 0,
                                        `seckill_start_time` DATETIME,
                                        `seckill_end_time` DATETIME,
                                        `draft_status` INTEGER NOT NULL DEFAULT 0,
                                        `draft_premium` NUMERIC(10, 2) DEFAULT 0.00,
                                        `inventory_hidden` INTEGER NOT NULL DEFAULT 0,
                                        `leave_message` TEXT,
                                        `recommend` INTEGER DEFAULT 0,
                                        `send_email` INTEGER NOT NULL DEFAULT 0,
                                        `only_user` INTEGER NOT NULL DEFAULT 0,
                                        `purchase_count` INTEGER NOT NULL DEFAULT 0,
                                        `widget` TEXT,
                                        `level_price` TEXT,
                                        `level_disable` INTEGER NOT NULL DEFAULT 0,
                                        `minimum` INTEGER NOT NULL DEFAULT 0,
                                        `maximum` INTEGER NOT NULL DEFAULT 0,
                                        `shared_sync` INTEGER NOT NULL DEFAULT 0,
                                        `config` TEXT,
                                        `hide` INTEGER NOT NULL DEFAULT 0,
                                        `inventory_sync` INTEGER NOT NULL DEFAULT 0,
                                        UNIQUE (`code`)
);

CREATE INDEX `commodity_owner` ON `acg_commodity`(`owner`);
CREATE INDEX `commodity_status` ON `acg_commodity`(`status`);
CREATE INDEX `commodity_sort` ON `acg_commodity`(`sort`);
CREATE INDEX `commodity_category_id` ON `acg_commodity`(`category_id`);
CREATE INDEX `commodity_shared_id` ON `acg_commodity`(`shared_id`);
CREATE INDEX `commodity_seckill_status` ON `acg_commodity`(`seckill_status`);
CREATE INDEX `commodity_api_status` ON `acg_commodity`(`api_status`);
CREATE INDEX `commodity_recommend` ON `acg_commodity`(`recommend`);

INSERT INTO `acg_commodity` VALUES (1, 1, 'DEMO', '<p>该商品是演示商品</p>', '/favicon.ico', 0.00, 1.00, 0.90, 1, 0, '2021-11-26 18:01:30', 1, '8AE80574F3CA98BE', 1, 0, '', 0, 0, 1, 1, NULL, '', 0.00 , NULL,999999, 0, 0, NULL, NULL, 0, 0.00, 0, NULL, 0, 0, 0, 0, NULL, NULL, 0, 0, 0, 0, NULL, 0, 0);

CREATE TABLE `acg_config`  (
                                     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                     `key` TEXT NOT NULL UNIQUE,
                                     `value` TEXT NOT NULL
);

INSERT INTO `acg_config` VALUES (1, 'shop_name', '异次元店铺');
INSERT INTO `acg_config` VALUES (2, 'title', '异次元店铺 - 最适合你的个人店铺系统！');
INSERT INTO `acg_config` VALUES (3, 'description', '');
INSERT INTO `acg_config` VALUES (4, 'keywords', '');
INSERT INTO `acg_config` VALUES (14, 'user_theme', 'Cartoon');
INSERT INTO `acg_config` VALUES (5, 'registered_state', '1');
INSERT INTO `acg_config` VALUES (6, 'registered_type', '0');
INSERT INTO `acg_config` VALUES (7, 'registered_verification', '1');
INSERT INTO `acg_config` VALUES (8, 'registered_phone_verification', '0');
INSERT INTO `acg_config` VALUES (9, 'registered_email_verification', '0');
INSERT INTO `acg_config` VALUES (10, 'sms_config', '{"accessKeyId":"","accessKeySecret":"","signName":"","templateCode":""}');
INSERT INTO `acg_config` VALUES (11, 'email_config', '{"smtp":"","port":"","username":"","password":""}');
INSERT INTO `acg_config` VALUES (12, 'login_verification', '1');
INSERT INTO `acg_config` VALUES (13, 'forget_type', '0');
INSERT INTO `acg_config` VALUES (15, 'notice', '<p><b><font color="#f9963b">本程序为开源程序，使用者造成的一切法律后果与作者无关。</font></b></p>');
INSERT INTO `acg_config` VALUES (16, 'trade_verification', '1');
INSERT INTO `acg_config` VALUES (17, 'recharge_welfare', '0');
INSERT INTO `acg_config` VALUES (18, 'recharge_welfare_config', '');
INSERT INTO `acg_config` VALUES (19, 'promote_rebate_v1', '0.1');
INSERT INTO `acg_config` VALUES (20, 'promote_rebate_v2', '0.2');
INSERT INTO `acg_config` VALUES (21, 'promote_rebate_v3', '0.3');
INSERT INTO `acg_config` VALUES (22, 'substation_display', '1');
INSERT INTO `acg_config` VALUES (24, 'domain', '');
INSERT INTO `acg_config` VALUES (25, 'service_qq', '');
INSERT INTO `acg_config` VALUES (26, 'service_url', '');
INSERT INTO `acg_config` VALUES (27, 'cash_type_alipay', '1');
INSERT INTO `acg_config` VALUES (28, 'cash_type_wechat', '1');
INSERT INTO `acg_config` VALUES (29, 'cash_cost', '5');
INSERT INTO `acg_config` VALUES (30, 'cash_min', '100');
INSERT INTO `acg_config` VALUES (31, 'cname', '');
INSERT INTO `acg_config` VALUES (32, 'background_url', '/assets/admin/images/login/bg.jpg');
INSERT INTO `acg_config` VALUES (33, 'default_category', '0');
INSERT INTO `acg_config` VALUES (34, 'substation_display_list', '[]');
INSERT INTO `acg_config` VALUES (35, 'closed', '0');
INSERT INTO `acg_config` VALUES (36, 'closed_message', '我们正在升级，请耐心等待完成。');
INSERT INTO `acg_config` VALUES (37, 'recharge_min', '10');
INSERT INTO `acg_config` VALUES (38, 'recharge_max', '1000');
INSERT INTO `acg_config` VALUES (39, 'user_mobile_theme', '0');
INSERT INTO `acg_config` VALUES (40, 'commodity_recommend', '0');
INSERT INTO `acg_config` VALUES (41, 'commodity_name', '推荐');
INSERT INTO `acg_config` VALUES (42, 'background_mobile_url', '');
INSERT INTO `acg_config` VALUES (43, 'username_len', '6');
INSERT INTO `acg_config` VALUES (44, 'cash_type_balance', '0');
INSERT INTO `acg_config` VALUES (45, 'callback_domain', '');

CREATE TABLE `acg_coupon`  (
                                     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                     `code` TEXT NOT NULL UNIQUE,
                                     `commodity_id` INTEGER NOT NULL,
                                     `owner` INTEGER NOT NULL DEFAULT 0,
                                     `create_time` DATETIME NOT NULL,
                                     `expire_time` DATETIME,
                                     `service_time` DATETIME,
                                     `money` NUMERIC(10, 2) NOT NULL,
                                     `status` INTEGER NOT NULL DEFAULT 0,
                                     `trade_no` TEXT,
                                     `note` TEXT,
                                     `mode` INTEGER DEFAULT 0,
                                     `category_id` INTEGER DEFAULT 0,
                                     `life` INTEGER NOT NULL DEFAULT 1,
                                     `use_life` INTEGER NOT NULL DEFAULT 0,
                                     `race` TEXT,
                                     `sku` JSON
);

CREATE INDEX `coupon_commodity_id` ON `acg_coupon`(`commodity_id`);
CREATE INDEX `coupon_owner` ON `acg_coupon`(`owner`);
CREATE INDEX `coupon_create_time` ON `acg_coupon`(`create_time`);
CREATE INDEX `coupon_money` ON `acg_coupon`(`money`);
CREATE INDEX `coupon_status` ON `acg_coupon`(`status`);
CREATE INDEX `coupon_trade_no` ON `acg_coupon`(`trade_no`);
CREATE INDEX `coupon_note` ON `acg_coupon`(`note`);
CREATE INDEX `coupon_race` ON `acg_coupon`(`race`);

CREATE TABLE `acg_manage`  (
                                     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                     `email` TEXT NOT NULL UNIQUE,
                                     `password` TEXT NOT NULL,
                                     `security_password` TEXT,
                                     `nickname` TEXT,
                                     `salt` TEXT NOT NULL,
                                     `avatar` TEXT,
                                     `status` INTEGER NOT NULL DEFAULT 0,
                                     `type` INTEGER NOT NULL DEFAULT 0,
                                     `create_time` DATETIME NOT NULL,
                                     `login_time` DATETIME,
                                     `last_login_time` DATETIME,
                                     `login_ip` TEXT,
                                     `last_login_ip` TEXT,
                                     `note` TEXT
);

INSERT INTO `acg_manage` VALUES (1, '__MANAGE_EMAIL__', '__MANAGE_PASSWORD__', NULL, '__MANAGE_NICKNAME__', '__MANAGE_SALT__', '/favicon.ico', 1, 0, '1997-01-01 00:00:00', NULL , NULL, NULL, NULL, NULL);

CREATE TABLE `acg_order`  (
                                    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                    `owner` INTEGER NOT NULL DEFAULT 0,
                                    `user_id` INTEGER NOT NULL DEFAULT 0,
                                    `trade_no` TEXT NOT NULL UNIQUE,
                                    `amount` NUMERIC(10, 2) NOT NULL,
                                    `commodity_id` INTEGER NOT NULL,
                                    `card_id` INTEGER DEFAULT NULL,
                                    `card_num` INTEGER NOT NULL DEFAULT 0,
                                    `pay_id` INTEGER NOT NULL,
                                    `create_time` DATETIME NOT NULL,
                                    `create_ip` TEXT NOT NULL,
                                    `create_device` INTEGER NOT NULL,
                                    `pay_time` DATETIME,
                                    `status` INTEGER NOT NULL DEFAULT 0,
                                    `secret` TEXT,
                                    `password` TEXT,
                                    `contact` TEXT,
                                    `delivery_status` INTEGER NOT NULL DEFAULT 0,
                                    `pay_url` TEXT,
                                    `coupon_id` INTEGER DEFAULT NULL,
                                    `cost` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                    `from` INTEGER DEFAULT NULL,
                                    `premium` NUMERIC(10, 2) DEFAULT 0.00,
                                    `widget` TEXT,
                                    `rent` NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
                                    `race` TEXT,
                                    `rebate` NUMERIC(10, 2) DEFAULT 0.00,
                                    `pay_cost` NUMERIC(10, 2) DEFAULT 0.00,
                                    `sku` JSON,
                                    `divide_amount` NUMERIC(10,2) DEFAULT NULL,
                                    `substation_user_id` INTEGER DEFAULT NULL,
                                    `request_no` TEXT UNIQUE
);

CREATE INDEX `order_commodity_id` ON `acg_order`(`commodity_id`);
CREATE INDEX `order_pay_id` ON `acg_order`(`pay_id`);
CREATE INDEX `order_contact` ON `acg_order`(`contact`);
CREATE INDEX `order_create_ip` ON `acg_order`(`create_ip`);
CREATE INDEX `order_owner` ON `acg_order`(`owner`);
CREATE INDEX `order_from` ON `acg_order`(`from`);
CREATE INDEX `order_user_id` ON `acg_order`(`user_id`);
CREATE INDEX `order_card_id` ON `acg_order`(`card_id`);
CREATE INDEX `order_create_time` ON `acg_order`(`create_time`);
CREATE INDEX `order_delivery_status` ON `acg_order`(`delivery_status`);
CREATE INDEX `order_substation_user_id` ON `acg_order`(`substation_user_id`);
CREATE INDEX `order_coupon_id` ON `acg_order`(`coupon_id`);

CREATE TABLE `acg_order_option`  (
                                           `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                           `order_id` INTEGER NOT NULL UNIQUE,
                                           `option` TEXT,
                                           FOREIGN KEY (`order_id`) REFERENCES `acg_order` (`id`) ON DELETE CASCADE
);

CREATE TABLE `acg_pay`  (
                                  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                  `name` TEXT NOT NULL,
                                  `icon` TEXT,
                                  `code` TEXT NOT NULL,
                                  `commodity` INTEGER NOT NULL DEFAULT 0,
                                  `recharge` INTEGER NOT NULL DEFAULT 0,
                                  `create_time` DATETIME NOT NULL,
                                  `handle` TEXT NOT NULL,
                                  `sort` INTEGER NOT NULL DEFAULT 0,
                                  `equipment` INTEGER NOT NULL DEFAULT 0,
                                  `cost` NUMERIC(10, 3) DEFAULT 0.000,
                                  `cost_type` INTEGER DEFAULT 0
);

CREATE INDEX `pay_commodity` ON `acg_pay`(`commodity`);
CREATE INDEX `pay_recharge` ON `acg_pay`(`recharge`);
CREATE INDEX `pay_sort` ON `acg_pay`(`sort`);
CREATE INDEX `pay_equipment` ON `acg_pay`(`equipment`);

INSERT INTO `acg_pay` VALUES (1, '余额', '/assets/static/images/wallet.png', '#system', 1, 0, '1997-01-01 00:00:00', '#system', 999, 0, 0.000, 0);
INSERT INTO `acg_pay` VALUES (2, '支付宝', '/assets/user/images/cash/alipay.png', 'alipay', 1, 1, '1997-01-01 00:00:00', 'Epay', 1, 0, 0.000, 0);

CREATE TABLE `acg_shared`  (
                                     `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                     `type` INTEGER NOT NULL DEFAULT 0,
                                     `name` TEXT NOT NULL,
                                     `domain` TEXT NOT NULL UNIQUE,
                                     `app_id` TEXT NOT NULL,
                                     `app_key` TEXT NOT NULL,
                                     `create_time` DATETIME NOT NULL,
                                     `balance` NUMERIC(14, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE `acg_user`  (
                                   `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                   `username` TEXT NOT NULL UNIQUE,
                                   `email` TEXT UNIQUE,
                                   `phone` TEXT UNIQUE,
                                   `qq` TEXT,
                                   `password` TEXT NOT NULL,
                                   `salt` TEXT NOT NULL,
                                   `app_key` TEXT NOT NULL,
                                   `avatar` TEXT,
                                   `balance` NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
                                   `coin` NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
                                   `integral` INTEGER NOT NULL DEFAULT 0,
                                   `create_time` DATETIME NOT NULL,
                                   `login_time` DATETIME,
                                   `last_login_time` DATETIME,
                                   `login_ip` TEXT,
                                   `last_login_ip` TEXT,
                                   `pid` INTEGER DEFAULT 0,
                                   `recharge` NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
                                   `total_coin` NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
                                   `status` INTEGER NOT NULL DEFAULT 0,
                                   `business_level` INTEGER DEFAULT NULL,
                                   `nicename` TEXT,
                                   `alipay` TEXT,
                                   `wechat` TEXT,
                                   `settlement` INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX `user_pid` ON `acg_user`(`pid`);
CREATE INDEX `user_business_level` ON `acg_user`(`business_level`);
CREATE INDEX `user_coin` ON `acg_user`(`coin`);

CREATE TABLE `acg_user_category`  (
                                            `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                            `user_id` INTEGER NOT NULL,
                                            `category_id` INTEGER NOT NULL,
                                            `name` TEXT,
                                            `status` INTEGER NOT NULL DEFAULT 0,
                                            UNIQUE (`user_id`, `category_id`),
                                            FOREIGN KEY (`user_id`) REFERENCES `acg_user` (`id`) ON DELETE CASCADE,
                                            FOREIGN KEY (`category_id`) REFERENCES `acg_category` (`id`) ON DELETE CASCADE
);

CREATE INDEX `user_category_status` ON `acg_user_category`(`status`);
CREATE INDEX `user_category_category_id` ON `acg_user_category`(`category_id`);
CREATE INDEX `user_category_user_id_2` ON `acg_user_category`(`user_id`);

CREATE TABLE `acg_user_commodity`  (
                                             `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                             `user_id` INTEGER NOT NULL,
                                             `commodity_id` INTEGER NOT NULL,
                                             `premium` REAL DEFAULT 0.00,
                                             `name` TEXT,
                                             `status` INTEGER NOT NULL DEFAULT 0,
                                             UNIQUE (`user_id`, `commodity_id`),
                                             FOREIGN KEY (`user_id`) REFERENCES `acg_user` (`id`) ON DELETE CASCADE,
                                             FOREIGN KEY (`commodity_id`) REFERENCES `acg_commodity` (`id`) ON DELETE CASCADE
);

CREATE INDEX `user_commodity_commodity_id` ON `acg_user_commodity`(`commodity_id`);
CREATE INDEX `user_commodity_user_id_2` ON `acg_user_commodity`(`user_id`);
CREATE INDEX `user_commodity_status` ON `acg_user_commodity`(`status`);

CREATE TABLE `acg_user_group`  (
                                         `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                         `name` TEXT NOT NULL,
                                         `icon` TEXT,
                                         `discount_config` TEXT DEFAULT NULL,
                                         `cost` NUMERIC(4, 2) NOT NULL DEFAULT 0.00,
                                         `recharge` NUMERIC(14, 2) NOT NULL,
                                         UNIQUE (`recharge`)
);

INSERT INTO `acg_user_group` VALUES (1, '一贫如洗', '/assets/static/images/group/ic_user level_1.png', null, 0.30, 0.00);
INSERT INTO `acg_user_group` VALUES (2, '小康之家', '/assets/static/images/group/ic_user level_2.png', null, 0.25, 50.00);
INSERT INTO `acg_user_group` VALUES (3, '腰缠万贯', '/assets/static/images/group/ic_user level_3.png', null, 0.20, 100.00);
INSERT INTO `acg_user_group` VALUES (4, '富甲一方', '/assets/static/images/group/ic_user level_4.png', null, 0.15, 200.00);
INSERT INTO `acg_user_group` VALUES (5, '富可敌国', '/assets/static/images/group/ic_user level_5.png', null, 0.10, 300.00);
INSERT INTO `acg_user_group` VALUES (6, '至尊', '/assets/static/images/group/ic_user level_6.png', null, 0.05, 500.00);

CREATE TABLE `acg_user_recharge`  (
                                            `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                            `trade_no` TEXT NOT NULL UNIQUE,
                                            `user_id` INTEGER NOT NULL,
                                            `amount` NUMERIC(10, 2) NOT NULL,
                                            `pay_id` INTEGER NOT NULL,
                                            `status` INTEGER NOT NULL DEFAULT 0,
                                            `create_time` DATETIME NOT NULL,
                                            `create_ip` TEXT NOT NULL,
                                            `pay_url` TEXT,
                                            `pay_time` DATETIME,
                                            `option` TEXT,
                                            FOREIGN KEY (`user_id`) REFERENCES `acg_user` (`id`) ON DELETE CASCADE
);

CREATE INDEX `user_recharge_user_id` ON `acg_user_recharge`(`user_id`);
CREATE INDEX `user_recharge_pay_id` ON `acg_user_recharge`(`pay_id`);
CREATE INDEX `user_recharge_status` ON `acg_user_recharge`(`status`);

CREATE TABLE `acg_manage_log`  (
                                         `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                         `email` TEXT NOT NULL,
                                         `nickname` TEXT NOT NULL,
                                         `content` TEXT NOT NULL,
                                         `create_time` DATETIME NOT NULL,
                                         `create_ip` TEXT NOT NULL,
                                         `ua` TEXT,
                                         `risk` INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX `manage_log_create_ip` ON `acg_manage_log`(`create_ip`);
CREATE INDEX `manage_log_create_time` ON `acg_manage_log`(`create_time`);
CREATE INDEX `manage_log_risk` ON `acg_manage_log`(`risk`);
CREATE INDEX `manage_log_email` ON `acg_manage_log`(`email`);
CREATE INDEX `manage_log_nickname` ON `acg_manage_log`(`nickname`);
CREATE INDEX `manage_log_content` ON `acg_manage_log`(`content`);

CREATE TABLE `acg_commodity_group` (
                                                           `id` INTEGER PRIMARY KEY AUTOINCREMENT,
    `name` TEXT NOT NULL,
    `commodity_list` JSON DEFAULT NULL
);

CREATE TABLE `acg_upload` (
                                    `id` INTEGER PRIMARY KEY AUTOINCREMENT,
                                    `user_id` INTEGER DEFAULT NULL,
                                    `hash` TEXT NOT NULL UNIQUE,
                                    `type` TEXT NOT NULL,
                                    `path` TEXT NOT NULL,
                                    `create_time` DATETIME NOT NULL,
                                    `note` TEXT DEFAULT NULL
);

CREATE INDEX `upload_user_id` ON `acg_upload`(`user_id`);
CREATE INDEX `upload_type` ON `acg_upload`(`type`);
CREATE INDEX `upload_create_time` ON `acg_upload`(`create_time`);
CREATE INDEX `upload_note` ON `acg_upload`(`note`);