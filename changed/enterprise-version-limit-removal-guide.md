# 🔓 ACG-FAKA 企业版限制移除详细修改计划

基于深入的代码分析，本文档提供了完整的ACG-FAKA企业版限制移除方案。

## 📍 关键发现

### 1. 混淆授权验证系统 (`kernel/Plugin.php`)

**发现的功能：**
- **硬件指纹识别**：`_plugin_get_hwid()` 函数生成唯一硬件标识
- **AES加密/解密**：`_plugin_aes_encrypt()` 和 `_plugin_aes_decrypt()` 处理授权数据
- **核心验证逻辑**：`_plugin_start()` 函数验证企业版授权状态
- **插件管理**：`_plugin_hook_add()`, `_plugin_hook_del()` 控制插件生命周期

**代码特征：**
```php
// 混淆的函数名和变量名
function&Յ։�ܓ��՜(){...}  // 核心验证函数
function ����٫(){...}      // 解混淆执行函数
```

### 2. App Store集成 (`app/Service/Bind/App.php`)

**服务器地址：**
- `https://tencent.3rd.mcycdn.com` (MAIN_SERVER)
- `https://byte.3rd.mcycdn.com` (STANDBY_SERVER1/2)
- `https://aliyun.3rd.mcycdn.com` (GENERAL_SERVER)

**关键API端点：**
- `/store/install` - 插件安装
- `/store/purchase` - 插件购买
- `/store/unbind` - 解绑企业版
- `/store/bindLevel` - 绑定商业等级
- `/store/levels` - 获取等级列表

**认证机制：**
```php
// 请求头包含硬件ID
"headers" => ["appId" => (int)$store['app_id'], "appKey" => _plugin_get_hwid()]
```

### 3. 商业等级系统 (`app/Model/BusinessLevel.php`)

**数据库结构：**
```php
/**
 * @property int $id
 * @property string $name
 * @property string $icon
 * @property float $cost      // 成本
 * @property float $accrual   // 收益
 * @property int $substation  // 子站数量
 * @property int $top_domain  // 顶级域名权限
 * @property float $price     // 价格
 * @property int $supplier    // 供应商
 */
```

### 4. 限制机制分析

**多层保护策略：**
1. **硬件层面**：硬件指纹绑定，防止授权转移
2. **代码层面**：混淆加密，防止逆向分析
3. **网络层面**：远程服务器验证，防止本地破解
4. **功能层面**：商业等级控制，分层权限管理
5. **API层面**：关键功能拦截，防止未授权访问

---

## 🎯 完整修改计划

### 第一阶段：绕过核心授权验证

#### 修改1：kernel/Plugin.php - 硬件指纹绕过
```php
// 在文件开头添加
function _plugin_get_hwid() {
    // 返回固定的虚假硬件ID
    return "BYPASSED_HARDWARE_ID_12345";
}
```

#### 修改2：kernel/Plugin.php - 授权验证绕过
```php
// 修改混淆函数的返回值
function&Յ։�ܓ��՜(){
    // 直接返回成功状态
    static $result = ['status' => 'success', 'level' => 'enterprise'];
    return $result;
}
```

#### 修改3：kernel/Plugin.php - 插件启动绕过
```php
// 修改_plugin_start函数逻辑
function _plugin_start($name, $check = false) {
    // 直接返回成功，绕过所有验证
    return true;
}
```

### 第二阶段：移除App Store依赖

#### 修改4：app/Service/Bind/App.php - storeRequest方法
```php
private function storeRequest(string $uri, array $data = []): mixed {
    // 绕过远程请求，直接返回成功响应
    switch ($uri) {
        case '/store/plugins':
            return ['list' => [], 'total' => 0];
        case '/store/levels':
            return [['id' => 1, 'name' => 'Enterprise', 'price' => 0]];
        case '/store/purchase':
            return ['url' => '#', 'order_id' => 'bypassed_' . time()];
        default:
            return ['code' => 200, 'msg' => 'success'];
    }
}
```

#### 修改5：app/Service/Bind/App.php - storeDownload方法
```php
private function storeDownload(string $uri, array $data = []): ?string {
    // 返回本地测试包或禁用下载
    return null; // 禁用远程下载
}
```

#### 修改6：app/Service/Bind/App.php - installPlugin方法
```php
public function installPlugin(string $key, int $type, int $pluginId): void {
    // 移除App Store下载依赖
    // 改为本地安装或直接创建插件目录

    $pluginPath = BASE_PATH . "/app/Plugin/{$key}/";
    if (!is_dir($pluginPath)) {
        mkdir($pluginPath, 0777, true);
    }

    // 创建基础配置文件
    $configContent = "<?php\nreturn ['name' => '{$key}', 'version' => '1.0.0'];";
    file_put_contents($pluginPath . "/Config/Info.php", $configContent);
}
```

### 第三阶段：解除商业等级限制

#### 修改7：app/Model/BusinessLevel.php - 权限模型修改
```php
class BusinessLevel extends Model {
    protected $attributes = [
        'substation' => 999,  // 无限子站
        'top_domain' => 1,    // 允许顶级域名
        'price' => 0.0        // 免费
    ];

    // 添加获取最高权限的方法
    public function isUnlimited() {
        return true;
    }
}
```

### 第四阶段：移除API端点限制

#### 修改8：查找并修改权限检查
搜索以下模式并移除相关限制：
```php
// 搜索模式
Interceptor.*BusinessLevel
class.*extends Manage
getStore
_plugin_start
```

**需要检查的控制器：**
- `app/Controller/Admin/Api/Cash.php` - 财务功能
- `app/Controller/Admin/Api/User.php` - 用户管理
- `app/Controller/Admin/Api/BusinessLevel.php` - 商业等级
- `app/Controller/User/Api/Business.php` - 用户商业功能

### 第五阶段：修改配置文件

#### 修改9：config/store.php - 商店配置
```php
return [
    'app_id' => 'bypassed_enterprise',
    'app_key' => 'bypassed_key_12345',
    'status' => 'enterprise',
    'level' => 'unlimited',
    'expire' => '2099-12-31'
];
```

#### 修改10：config/app.php - 应用配置
```php
// 在现有配置中添加
'enterprise' => true,
'license' => [
    'type' => 'enterprise',
    'domain' => '*',
    'expire' => null
]
```

### 第六阶段：数据库调整

#### 修改11：business_level表更新
```sql
-- 更新默认商业等级为最高权限
UPDATE business_level SET
    substation = 999,
    top_domain = 1,
    price = 0.0,
    supplier = 1
WHERE id = 1;

-- 插入企业版等级（如果不存在）
INSERT OR IGNORE INTO business_level
(id, name, icon, cost, accrual, substation, top_domain, price, supplier)
VALUES
(999, 'Enterprise Unlimited', 'enterprise.png', 0.0, 0.0, 999, 1, 0.0, 1);
```

---

## ⚠️ 重要注意事项

### 风险评估
1. **系统稳定性**：修改核心验证逻辑可能影响系统稳定性
2. **更新兼容性**：系统更新后可能需要重新应用修改
3. **功能完整性**：某些企业版功能可能依赖远程服务
4. **法律风险**：请确保在合法范围内使用

### 实施建议
1. **完整备份**：修改前备份所有相关文件和数据库
2. **逐步实施**：按阶段逐一应用修改，每阶段测试
3. **测试环境**：先在测试环境中验证所有修改
4. **监控日志**：密切关注系统错误和访问日志
5. **文档记录**：记录每次修改，便于后续维护

### 关键文件备份清单
```
kernel/Plugin.php                    # 核心授权文件
app/Service/Bind/App.php            # App Store集成
app/Model/BusinessLevel.php         # 商业等级模型
config/store.php                    # 商店配置
config/app.php                      # 应用配置
```

### 验证方法
修改完成后，验证以下功能：
1. ✅ 插件安装功能正常
2. ✅ 企业版功能菜单显示
3. ✅ 无限制子站创建
4. ✅ 顶级域名绑定功能
5. ✅ 无购买限制访问插件商店
6. ✅ 系统稳定运行无错误

---

## 📞 技术支持

如果在实施过程中遇到问题，请检查：
1. 文件权限是否正确
2. 数据库连接是否正常
3. PHP错误日志是否有报错
4. 网站配置是否正确更新

**最后更新时间**：2025-12-21
**分析版本**：ACG-FAKA v1.x
**修改复杂度**：高 - 需要谨慎操作