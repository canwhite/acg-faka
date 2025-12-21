<?php
declare(strict_types=1);

namespace App\Pay\Epusdt\Impl;

use Kernel\Util\Context;

/**
 * Class Signature
 * @package App\Pay\Kvmpay\Impl
 */
class Signature implements \App\Pay\Signature
{

    /**
     * 生成签名
     * @param array $data
     * @param string $key
     * @return string
     */
    public static function generateSignature(array $data, string $key): string
    {
        ksort($data);
        $sign = '';
        foreach ($data as $k => $v) {
            if ($v == '') continue;
            $sign .= $k . '=' . $v . '&';
        }
        $sign = trim($sign, '&');
        return md5($sign . $key);
    }

    /**
     * @inheritDoc
     */
    public function verification(array $data, array $config): bool
    {
        $data = json_decode(file_get_contents('php://input'), true);
        $sign = $data['signature'];
        unset($data['signature']);
        $generateSignature = self::generateSignature($data, $config['key']);
        Context::set(\App\Consts\Pay::DAFA, $data);

        return $sign == $generateSignature;
    }
}