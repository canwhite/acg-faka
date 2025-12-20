<?php
declare(strict_types=1);

/**
 * SQLite 数据库功能测试
 * 测试数据库连接、基本操作、外键约束和性能优化
 */

require_once __DIR__ . '/../config/database.php';

class SqliteTest
{
    private PDO $pdo;
    private array $config;
    private int $testsPassed = 0;
    private int $testsTotal = 0;

    public function __construct()
    {
        $this->config = require __DIR__ . '/../config/database.php';
        $this->connect();
    }

    /**
     * 连接数据库
     */
    private function connect(): void
    {
        try {
            $this->pdo = new PDO('sqlite:' . $this->config['database']);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            // 应用性能优化配置
            foreach ($this->config['pragma'] as $pragma => $value) {
                $this->pdo->exec("PRAGMA {$pragma} = {$value}");
            }

            echo "✅ SQLite 数据库连接成功\n";
        } catch (PDOException $e) {
            die("❌ 数据库连接失败: " . $e->getMessage() . "\n");
        }
    }

    /**
     * 运行测试
     */
    public function runTests(): void
    {
        echo "\n🚀 开始 SQLite 数据库测试...\n";
        echo str_repeat("=", 50) . "\n";

        $this->testBasicOperations();
        $this->testTableStructure();
        $this->testForeignKeys();
        $this->testDataTypes();
        $this->testPerformance();
        $this->testJsonSupport();
        $this->testIndexes();

        $this->printResults();
    }

    /**
     * 测试基本操作
     */
    private function testBasicOperations(): void
    {
        echo "\n📝 测试 1: 基本数据库操作\n";

        // 测试表查询
        $this->test("查询表数量", function() {
            $stmt = $this->pdo->query("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name LIKE 'acg_%'");
            return $stmt->fetchColumn() >= 22; // 至少22个表
        });

        // 测试配置数据
        $this->test("查询配置数据", function() {
            $stmt = $this->pdo->query("SELECT COUNT(*) FROM acg_config");
            return $stmt->fetchColumn() >= 44; // 实际44个配置项
        });

        // 测试基础业务数据
        $this->test("查询业务等级数据", function() {
            $stmt = $this->pdo->query("SELECT COUNT(*) FROM acg_business_level");
            return $stmt->fetchColumn() >= 3; // 至少3个业务等级
        });

        // 测试核心业务数据完整性
        $this->test("核心业务数据完整性", function() {
            // 验证店铺配置存在
            $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM acg_config WHERE `key` = ?");
            $stmt->execute(['shop_name']);
            $shopConfig = $stmt->fetchColumn() > 0;

            // 验证分类数据存在
            $stmt = $this->pdo->query("SELECT COUNT(*) FROM acg_category");
            $categoryCount = $stmt->fetchColumn();

            // 验证商品数据存在
            $stmt = $this->pdo->query("SELECT COUNT(*) FROM acg_commodity");
            $commodityCount = $stmt->fetchColumn();

            return $shopConfig && $categoryCount > 0 && $commodityCount > 0;
        });
    }

    /**
     * 测试表结构
     */
    private function testTableStructure(): void
    {
        echo "\n🏗️  测试 2: 表结构完整性\n";

        // 测试用户表结构
        $this->test("用户表结构", function() {
            $stmt = $this->pdo->query("PRAGMA table_info(acg_user)");
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $columnNames = array_column($columns, 'name');

            $requiredColumns = ['id', 'username', 'email', 'password', 'balance', 'create_time', 'status'];
            foreach ($requiredColumns as $column) {
                if (!in_array($column, $columnNames)) {
                    return false;
                }
            }
            return true;
        });

        // 测试商品表结构
        $this->test("商品表结构", function() {
            $stmt = $this->pdo->query("PRAGMA table_info(acg_commodity)");
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $columnNames = array_column($columns, 'name');

            $requiredColumns = ['id', 'name', 'price', 'category_id', 'status'];
            foreach ($requiredColumns as $column) {
                if (!in_array($column, $columnNames)) {
                    return false;
                }
            }
            return true;
        });
    }

    /**
     * 测试外键约束
     */
    private function testForeignKeys(): void
    {
        echo "\n🔗 测试 3: 外键约束功能\n";

        // 测试外键是否启用
        $this->test("外键约束已启用", function() {
            $stmt = $this->pdo->query("PRAGMA foreign_keys");
            return $stmt->fetchColumn() === 1;
        });

        // 测试账单表外键
        $this->test("账单表外键约束", function() {
            $stmt = $this->pdo->query("PRAGMA foreign_key_list(acg_bill)");
            $foreignKeys = $stmt->fetchAll(PDO::FETCH_ASSOC);
            return !empty($foreignKeys) && $foreignKeys[0]['table'] === 'acg_user';
        });

        // 测试外键级联删除
        $this->test("级联删除功能", function() {
            // 开启事务
            $this->pdo->beginTransaction();

            try {
                // 插入测试用户（包含所有必需字段）
                $testUsername = 'test_user_' . time();
                $stmt = $this->pdo->prepare("INSERT INTO acg_user (username, password, salt, app_key, balance, coin, integral, create_time, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute([$testUsername, 'hashed_password', 'salt123', 'appkey123', 100.00, 50.00, 0, date('Y-m-d H:i:s'), 1]);
                $userId = $this->pdo->lastInsertId();

                // 插入测试账单
                $stmt = $this->pdo->prepare("INSERT INTO acg_bill (owner, amount, balance, type, currency, log, create_time) VALUES (?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute([$userId, 50.00, 150.00, 1, 0, 'test log', date('Y-m-d H:i:s')]);
                $billId = $this->pdo->lastInsertId();

                // 验证账单存在
                $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM acg_bill WHERE id = ?");
                $stmt->execute([$billId]);
                $billExists = $stmt->fetchColumn() > 0;

                // 删除用户（应该级联删除账单）
                $stmt = $this->pdo->prepare("DELETE FROM acg_user WHERE id = ?");
                $stmt->execute([$userId]);

                // 验证账单被级联删除
                $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM acg_bill WHERE id = ?");
                $stmt->execute([$billId]);
                $billDeleted = $stmt->fetchColumn() == 0;

                $this->pdo->rollBack();
                return $billExists && $billDeleted;

            } catch (Exception $e) {
                $this->pdo->rollBack();
                return false;
            }
        });
    }

    /**
     * 测试数据类型
     */
    private function testDataTypes(): void
    {
        echo "\n🔢 测试 4: 数据类型支持\n";

        // 测试 INTEGER 自增
        $this->test("INTEGER 自增主键", function() {
            $stmt = $this->pdo->query("SELECT seq FROM sqlite_sequence WHERE name='acg_config'");
            return $stmt->fetchColumn() > 0;
        });

        // 测试 NUMERIC 精度
        $this->test("NUMERIC 数值精度", function() {
            $this->pdo->beginTransaction();

            try {
                // 插入精确的小数值（包含所有必需字段）
                $testValue = 123456789.12;
                $stmt = $this->pdo->prepare("INSERT INTO acg_user (username, password, salt, app_key, balance, coin, integral, create_time, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute(['precision_test_' . time(), 'hashed_password', 'salt123', 'appkey123', $testValue, 50.00, 0, date('Y-m-d H:i:s'), 1]);
                $userId = $this->pdo->lastInsertId();

                // 查询并验证精度
                $stmt = $this->pdo->prepare("SELECT balance FROM acg_user WHERE id = ?");
                $stmt->execute([$userId]);
                $balance = $stmt->fetchColumn();

                $this->pdo->rollBack();
                return abs($balance - $testValue) < 0.01;
            } catch (Exception $e) {
                $this->pdo->rollBack();
                return false;
            }
        });

        // 测试 TEXT 类型
        $this->test("TEXT 文本类型", function() {
            $stmt = $this->pdo->query("SELECT value FROM acg_config WHERE `key` = 'shop_name' LIMIT 1");
            $result = $stmt->fetchColumn();
            return !empty($result) && is_string($result);
        });
    }

    /**
     * 测试性能优化
     */
    private function testPerformance(): void
    {
        echo "\n⚡ 测试 5: 性能优化配置\n";

        // 测试 WAL 模式
        $this->test("WAL 日志模式", function() {
            $stmt = $this->pdo->query("PRAGMA journal_mode");
            return $stmt->fetchColumn() === 'wal';
        });

        // 测试缓存大小
        $this->test("缓存大小设置", function() {
            $stmt = $this->pdo->query("PRAGMA cache_size");
            $cacheSize = $stmt->fetchColumn();
            return $cacheSize >= 10000;
        });

        // 测试同步模式
        $this->test("同步模式设置", function() {
            $stmt = $this->pdo->query("PRAGMA synchronous");
            return $stmt->fetchColumn() === 1; // NORMAL mode
        });

        // 测试内存映射
        $this->test("内存映射大小", function() {
            $stmt = $this->pdo->query("PRAGMA mmap_size");
            $mmapSize = $stmt->fetchColumn();
            return $mmapSize >= 268435456; // 256MB
        });
    }

    /**
     * 测试 JSON 支持
     */
    private function testJsonSupport(): void
    {
        echo "\n📄 测试 6: JSON 数据支持\n";

        // 检查表中是否有 JSON 字段
        $this->test("JSON 字段存在", function() {
            $stmt = $this->pdo->query("PRAGMA table_info(acg_card)");
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $columnNames = array_column($columns, 'name');
            return in_array('sku', $columnNames);
        });

        // 测试 JSON 数据类型
        $this->test("JSON 数据类型", function() {
            $stmt = $this->pdo->query("PRAGMA table_info(acg_card)");
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($columns as $column) {
                if ($column['name'] === 'sku') {
                    return stripos($column['type'], 'json') !== false;
                }
            }
            return false;
        });
    }

    /**
     * 测试索引
     */
    private function testIndexes(): void
    {
        echo "\n🔍 测试 7: 索引性能\n";

        // 测试主要索引存在
        $this->test("主要索引存在", function() {
            $expectedIndexes = [
                'bill_owner' => 'acg_bill',
                'commodity_status' => 'acg_commodity',
                'card_owner' => 'acg_card',
            ];

            foreach ($expectedIndexes as $indexName => $tableName) {
                $stmt = $this->pdo->query("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='{$indexName}' AND tbl_name='{$tableName}'");
                if ($stmt->fetchColumn() == 0) {
                    return false;
                }
            }
            return true;
        });

        // 测试索引查询性能
        $this->test("索引查询性能", function() {
            $start = microtime(true);

            // 执行索引查询
            for ($i = 0; $i < 100; $i++) {
                $stmt = $this->pdo->query("SELECT COUNT(*) FROM acg_config");
                $stmt->fetchColumn();
            }

            $end = microtime(true);
            $executionTime = ($end - $start) * 1000; // 转换为毫秒

            echo "   ⏱️  100次查询耗时: " . number_format($executionTime, 2) . "ms\n";
            return $executionTime < 100; // 应该在100ms内完成
        });
    }

    /**
     * 执行单个测试
     */
    private function test(string $description, callable $test): void
    {
        $this->testsTotal++;

        try {
            $result = $test();
            if ($result) {
                echo "   ✅ {$description}\n";
                $this->testsPassed++;
            } else {
                echo "   ❌ {$description}\n";
            }
        } catch (Exception $e) {
            echo "   ❌ {$description} - 错误: " . $e->getMessage() . "\n";
        }
    }

    /**
     * 打印测试结果
     */
    private function printResults(): void
    {
        echo "\n" . str_repeat("=", 50) . "\n";
        echo "📊 测试结果统计\n";
        echo str_repeat("-", 50) . "\n";
        echo "总测试数: {$this->testsTotal}\n";
        echo "通过测试: {$this->testsPassed}\n";
        echo "失败测试: " . ($this->testsTotal - $this->testsPassed) . "\n";
        echo "成功率: " . number_format(($this->testsPassed / $this->testsTotal) * 100, 1) . "%\n";

        if ($this->testsPassed === $this->testsTotal) {
            echo "\n🎉 所有测试通过！SQLite 数据库迁移完全成功！\n";
        } else {
            echo "\n⚠️  部分测试失败，请检查相关配置和数据。\n";
        }

        // 显示数据库信息
        echo "\n📋 数据库信息:\n";
        echo "   数据库文件: " . $this->config['database'] . "\n";

        // 获取文件大小
        if (file_exists($this->config['database'])) {
            $fileSize = filesize($this->config['database']);
            echo "   文件大小: " . number_format($fileSize / 1024, 2) . " KB\n";
        }
    }
}

// 运行测试
if (php_sapi_name() === 'cli') {
    $test = new SqliteTest();
    $test->runTests();
} else {
    echo "请在命令行中运行此测试文件: php sqlite_test.php\n";
}