<?php
declare (strict_types = 1);

return [
    'version'     => '1.0.0',
    'name'        => 'Epusdt',
    'author'      => '荔枝',
    'website'     => '#',
    'description' => 'Epusdt',
    'options'     => [
        'tron.trx'     => 'TRON・TRX',
        'usdt.trc20'   => 'USDT・TRC20',
        'usdt.polygon' => 'USDT・Polygon',
        'usdt.erc20'   => 'USDT・ERC20',
        'usdt.bep20'   => 'USDT・BEP20',
        'usdt.xlayer'   => 'USDT・X-Layer'
    ],
    'callback'    => [
        \App\Consts\Pay::IS_SIGN            => true,
        \App\Consts\Pay::IS_STATUS          => true,
        \App\Consts\Pay::FIELD_STATUS_KEY   => 'status',
        \App\Consts\Pay::FIELD_STATUS_VALUE => 2,
        \App\Consts\Pay::FIELD_ORDER_KEY    => 'order_id',
        \App\Consts\Pay::FIELD_AMOUNT_KEY   => 'amount',
        \App\Consts\Pay::FIELD_RESPONSE     => 'ok'
    ]
];