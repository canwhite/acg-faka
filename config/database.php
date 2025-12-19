<?php
declare (strict_types=1);

return [
    'driver' => 'sqlite',
    'database' => __DIR__ . '/../database/database.sqlite',
    'prefix' => 'acg_',
    'foreign_key_constraints' => true,
];