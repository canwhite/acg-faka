<?php
declare(strict_types=1);

namespace Kernel\Util;


use Kernel\Exception\JSONException;
use PDO;
use PDOException;

class SQL
{
    /**
     * 导入SQL文件 - 支持MySQL和SQLite
     * @throws \Kernel\Exception\JSONException
     */
    public static function import(string $sql, string $host, string $db, string $username, string $password, string $prefix, string $driver = 'mysql')
    {
        //处理前缀
        $sqlSrc = str_replace('__PREFIX__', $prefix, (string)file_get_contents($sql));
        if ($sqlSrc == "") {
            return;
        }

        if ($driver === 'sqlite') {
            return self::importSqlite($sqlSrc, $db);
        } else {
            return self::importMysql($sql, $sqlSrc, $host, $db, $username, $password, $prefix);
        }
    }

    /**
     * MySQL导入（原逻辑）
     */
    private static function importMysql(string $sql, string $sqlSrc, string $host, string $db, string $username, string $password, string $prefix)
    {
        if (file_put_contents($sql . '.process', $sqlSrc) === false) {
            throw new JSONException("没有写入权限，请检查权限是否足够");
        }

        $tmp = BASE_PATH . '/runtime/tmp';
        if (!is_dir($tmp)) {
            mkdir($tmp, 0777, true);
        }

        try {
            $dump = new \Rah\Danpu\Dump();
            $dump
                ->file($sql . '.process')
                ->dsn('mysql:dbname=' . $db . ';host=' . $host)
                ->user($username)
                ->pass($password)
                ->tmp($tmp);
            new \Rah\Danpu\Import($dump);
            unlink($sql . '.process');
        } catch (\Exception $e) {
            throw new JSONException("数据库出错，原因：" . $e->getMessage());
        }
    }

    /**
     * SQLite导入
     */
    private static function importSqlite(string $sqlSrc, string $dbPath)
    {
        try {
            // 检查文件路径
            if (!file_exists($dbPath)) {
                throw new JSONException("SQLite数据库文件不存在: " . $dbPath);
            }

            // 创建PDO连接
            $pdo = new PDO('sqlite:' . $dbPath);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            // 启用外键约束和性能优化
            $pdo->exec("PRAGMA foreign_keys = ON");
            $pdo->exec("PRAGMA journal_mode = WAL");
            $pdo->exec("PRAGMA cache_size = 10000");
            $pdo->exec("PRAGMA synchronous = NORMAL");

            // 分割SQL语句并执行
            $statements = self::splitSqlStatements($sqlSrc);

            $pdo->beginTransaction();

            foreach ($statements as $statement) {
                $statement = trim($statement);
                if (empty($statement) || preg_match('/^(--|#)/', $statement)) {
                    continue; // 跳过空行和注释
                }

                try {
                    $pdo->exec($statement);
                } catch (PDOException $e) {
                    // 记录错误但继续执行其他语句
                    error_log("SQL执行错误: " . $e->getMessage() . " SQL: " . $statement);
                }
            }

            $pdo->commit();

        } catch (PDOException $e) {
            throw new JSONException("SQLite数据库出错，原因：" . $e->getMessage());
        }
    }

    /**
     * 分割SQL语句
     */
    private static function splitSqlStatements(string $sql): array
    {
        // 移除注释
        $sql = preg_replace('/--.*$/m', '', $sql);
        $sql = preg_replace('/#.*$/m', '', $sql);

        // 分割语句
        $statements = preg_split('/;(?=(?:[^\'"]|["\'][^\'"]*["\'])*$)/', $sql);

        return array_filter($statements, function($stmt) {
            return trim($stmt) !== '';
        });
    }
}