<?php
declare (strict_types=1);

return [
    'driver' => 'sqlite',
    'database' => __DIR__ . '/../database/database.sqlite',
    'prefix' => 'acg_',
    'foreign_key_constraints' => true,
    'options' => [
        \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
    ],
    'pragma' => [
        'journal_mode' => 'WAL',
        'cache_size' => 10000,
        'synchronous' => 'NORMAL',
        'foreign_keys' => 'ON',
        'temp_store' => 'MEMORY',
        'mmap_size' => 268435456, // 256MB
    ],
];