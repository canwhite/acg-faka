# Kernel层架构分析与Install功能修改指南

## 🏗️ Kernel层架构概览

Kernel是ACG-FAKA框架的核心，包含3869行代码，提供底层基础设施和框架功能。

### 📁 Kernel目录结构

```
kernel/
├── Kernel.php                    # 框架入口和核心启动逻辑 (169行)
├── Component/                   # 框架组件系统
├── Container/                   # 依赖注入容器
├── Context/                     # HTTP请求上下文处理
│   ├── Request.php              # HTTP请求封装
│   └── Abstract/Request.php     # 请求抽象基类
├── Database/                    # 数据库相关组件
├── Annotation/                  # PHP 8.0+ 注解系统 (11个文件)
│   ├── Collector.php           # 注解收集器 (4348行)
│   ├── Inject.php              # 依赖注入注解
│   ├── Interceptor.php         # 拦截器注解
│   └── Hook.php                # 钩子注解
├── Util/                        # 工具类库 (20+个文件)
│   ├── View.php                 # Smarty模板引擎封装
│   ├── SQL.php                  # SQL工具类
│   ├── Plugin.php               # 插件工具
│   ├── Date.php                 # 日期工具
│   └── Context.php              # 上下文工具
├── Waf/                         # Web应用防火墙
│   └── Firewall.php             # WAF核心实现
├── Exception/                   # 异常处理类
├── Consts/                      # 常量定义
├── Install/                     # 安装相关文件
│   ├── Install.sql              # MySQL安装脚本 (52730行)
│   ├── Install_sqlite.sql       # SQLite安装脚本 (31129行)
│   └── Lock                     # 安装锁定文件
├── Plugin/                      # 插件系统
├── Cache/                       # 缓存系统
└── File/                        # 文件处理系统
```

## 🔧 Kernel核心功能详解

### 1. Kernel.php - 框架启动器
**职责**: 框架的入口点，处理应用启动流程

**核心功能**:
```php
// 1. 基础设置
date_default_timezone_set("Asia/Shanghai");
error_reporting(0);
const BASE_PATH = __DIR__ . "/../";

// 2. 依赖加载
require(BASE_PATH . '/vendor/autoload.php');
require("Helper.php");

// 3. 路由解析和URL重写
preg_match('/\/item\/(\d+)/', $_GET['s'] ?? "/", $_item);
if (isset($_item[1]) && is_numeric($_item[1])) {
    $_GET['s'] = "/user/index/item";
    $_GET['mid'] = $_item[1];
}

// 4. 上下文初始化
Context::set(\Kernel\Context\Interface\Request::class, new Request());

// 5. 控制器实例化和方法调用
$controllerInstance = new $controller;
$result = call_user_func_array([$controllerInstance, $action], $parameters);
```

**Install功能影响**:
- 安装程序的URL重写规则在这里处理
- 安装状态检查（Lock文件）
- 错误处理和异常捕获

### 2. Context/Request.php - HTTP请求封装
**职责**: 封装HTTP请求数据，提供统一的请求接口

**核心功能**:
```php
class Request extends Abstract\Request {
    public function __construct() {
        $this->_unsafe_post = $this->post = $_POST;
        $this->method = strtoupper($_SERVER['REQUEST_METHOD']);
        $this->_unsafe_get = $this->get = $_GET;
        $this->header = $this->parseHeader();
        $this->cookie = $_COOKIE;
        $this->raw = (string)file_get_contents("php://input");
        $this->files = $_FILES;

        // URL解析
        $uri = "/" . trim($_GET['s'] ?? "/", "/");
        $this->uri = (string)$uris[0];

        // IP地址获取
        $this->clientIp = $this->getClientIp();
    }
}
```

**Install功能影响**:
- 获取安装程序的POST数据
- 解析安装表单提交
- 处理文件上传（如果有的话）

### 3. Util/View.php - 模板引擎封装
**职责**: 封装Smarty模板引擎，提供视图渲染功能

**核心功能**:
```php
class View {
    public static function render(string $template, array $data = [], string $dir = BASE_PATH . '/app/View'): string {
        $engine = new \Smarty();
        $engine->setTemplateDir($dir);
        $engine->setCacheDir(BASE_PATH . '/runtime/view/cache');
        $engine->setCompileDir(BASE_PATH . '/runtime/view/compile');
        $engine->left_delimiter = '#{';
        $engine->right_delimiter = '}';

        foreach ($data as $key => $item) {
            $engine->assign($key, $item);
        }

        return $engine->fetch($template);
    }
}
```

**Install功能影响**:
- 渲染安装程序模板
- 处理安装程序的数据传递
- 管理模板缓存

### 4. Annotation系统 - PHP 8.0注解支持
**职责**: 实现代码注解的解析和执行

**核心注解**:
- `#[Inject]` - 依赖注入
- `#[Interceptor]` - 拦截器
- `#[Hook]` - 钩子函数

**Install功能影响**:
- 安装控制器可能使用注解
- 拦截器验证安装状态

### 5. Waf/Firewall.php - Web应用防火墙
**职责**: 提供安全防护，过滤恶意请求

**核心功能**:
```php
class Firewall {
    private ?\HTMLPurifier $HTMLPurifier = null;
    private Cache $cache;

    public function xssKiller($parameter): array {
        // XSS过滤
        return $this->HTMLPurifier->purify($parameter);
    }
}
```

**Install功能影响**:
- 过滤安装程序的恶意输入
- 防止SQL注入攻击
- 生成WAF缓存文件

## 🔧 Install功能修改指南

### 当前Install功能的实现流程

```
访问 /install/step
    ↓
Kernel.php 路由解析 → App\Controller\Install->step()
    ↓
渲染安装模板 → 用户填写信息
    ↓
提交表单 → App\Controller\Install->submit()
    ↓
创建管理员 → 创建Lock文件
    ↓
安装完成
```

### 修改Install功能时需要涉及的Kernel层

#### 1. 修改安装程序的路由规则
**文件**: `kernel/Kernel.php`

**当前路由处理**:
```php
preg_match('/\/item\/(\d+)/', $_GET['s'] ?? "/", $_item);
preg_match('/\/cat\/(\d+|recommend)/', $_GET['s'] ?? "/", $_cat);

if (isset($_item[1]) && is_numeric($_item[1])) {
    $_GET['s'] = "/user/index/item";
    $_GET['mid'] = $_item[1];
}
```

**如果要修改安装URL**:
```php
// 将 /install 改为 /setup
if (str_starts_with($_GET['s'], '/install')) {
    $_GET['s'] = str_replace('/install', '/setup', $_GET['s']);
}
```

#### 2. 修改安装程序的模板引擎配置
**文件**: `kernel/Util/View.php`

**如果要修改模板引擎**:
```php
public static function render(string $template, array $data = [], string $dir = BASE_PATH . '/app/View'): string {
    $engine = new \Smarty();
    $engine->setTemplateDir($dir);
    $engine->setCacheDir(BASE_PATH . '/runtime/view/cache');
    $engine->setCompileDir(BASE_PATH . '/runtime/view/compile');

    // 安装程序特殊配置
    if (str_contains($template, 'Install')) {
        $engine->caching = false;  // 安装时禁用缓存
        $engine->force_compile = true;
    }

    return $engine->fetch($template);
}
```

#### 3. 修改HTTP请求处理
**文件**: `kernel/Context/Request.php`

**如果要添加安装专用的请求处理**:
```php
public function isInstallation(): bool {
    return str_contains($this->uri, '/install');
}

public function getInstallationData(): array {
    return [
        'php_version' => phpversion(),
        'extensions' => $this->getLoadedExtensions(),
        'server_info' => $this->getServerInfo()
    ];
}
```

#### 4. 修改安全防护规则
**文件**: `kernel/Waf/Firewall.php`

**如果要为安装程序添加特殊安全规则**:
```php
public function validateInstallation(array $data): bool {
    // 安装程序特殊验证
    $allowedFields = ['email', 'nickname', 'login_password'];

    foreach ($data as $key => $value) {
        if (!in_array($key, $allowedFields)) {
            return false;
        }
    }

    return true;
}
```

#### 5. 修改安装锁定机制
**文件**: `kernel/Kernel.php`

**当前锁定检查**:
```php
Context::set(Base::IS_INSTALL, file_exists(BASE_PATH . '/kernel/Install/Lock'));
```

**如果要修改锁定逻辑**:
```php
// 添加多种锁定方式
$lockMethods = [
    'file' => file_exists(BASE_PATH . '/kernel/Install/Lock'),
    'config' => config('app')['installed'] ?? false,
    'database' => $this->checkDatabaseInstallation()
];

Context::set(Base::IS_INSTALL, !in_array(true, $lockMethods));
```

## 🔄 具体修改示例

### 示例1: 添加安装程序的环境检测

#### 1. 在Kernel.php中添加环境检测
```php
// 在启动前添加环境检测
if (str_contains($_GET['s'] ?? '', '/install')) {
    $this->checkEnvironment();
}

private function checkEnvironment(): void {
    $requirements = [
        'php_version' => version_compare(phpversion(), '8.0.0', '>='),
        'extensions' => [
            'pdo_sqlite' => extension_loaded('pdo_sqlite'),
            'curl' => extension_loaded('curl'),
            'json' => extension_loaded('json'),
        ]
    ];

    Context::set(Base::INSTALL_ENVIRONMENT, $requirements);
}
```

#### 2. 在Controller中获取环境数据
```php
public function step(): string {
    $data['environment'] = Context::get(\Kernel\Consts\Base::INSTALL_ENVIRONMENT);
    return View::render("Install.html", $data);
}
```

### 示例2: 修改安装程序的缓存策略

#### 在View.php中添加安装模式
```php
public static function render(string $template, array $data = [], string $dir = BASE_PATH . '/app/View', bool $controller = true): string {
    $engine = new \Smarty();

    // 安装程序特殊处理
    if ($this->isInstallationMode($template, $data)) {
        $engine->caching = false;
        $engine->force_compile = true;
        $engine->compile_check = true;
    }

    return $engine->fetch($template);
}

private static function isInstallationMode(string $template, array $data): bool {
    return str_contains($template, 'Install') ||
           isset($data['is_installation']) ||
           str_contains($_GET['s'] ?? '', '/install');
}
```

## 📋 Install功能修改清单

### 必须修改的Kernel文件
- [ ] **kernel/Kernel.php** - 路由处理、启动流程
- [ ] **kernel/Install/** - 安装脚本和锁定文件

### 可能需要修改的Kernel文件
- [ ] **kernel/Context/Request.php** - 如果需要特殊的请求处理
- [ ] **kernel/Util/View.php** - 如果需要修改模板引擎配置
- [ ] **kernel/Waf/Firewall.php** - 如果需要修改安全规则
- [ ] **kernel/Annotation/** - 如果需要添加安装专用注解

### App层文件
- [ ] **app/Controller/Install.php** - 主要安装逻辑
- [ ] **app/View/Install.html** - 安装界面
- [ ] **app/Model/** - 如果涉及数据库模型

## 🛠️ 开发建议

### 1. 保持Kernel层稳定
- Kernel是框架核心，修改时要格外小心
- 优先在App层实现功能，避免修改Kernel
- 如果必须修改，要充分测试

### 2. 向后兼容性
- 保持原有API不变
- 使用配置开关控制新功能
- 渐进式修改，避免破坏性变更

### 3. 测试策略
- 单独测试Kernel层修改
- 集成测试整个安装流程
- 测试各种边界情况

## 🎯 总结

Kernel层是ACG-FAKA框架的基础，提供了路由、请求处理、模板渲染、安全防护等核心功能。修改Install功能时：

**主要影响**: 主要是`app/Controller/Install.php`和`kernel/Install/`目录

**可能的Kernel修改**:
- 路由规则（Kernel.php）
- 请求处理（Context/Request.php）
- 模板渲染（Util/View.php）
- 安全防护（Waf/Firewall.php）

**建议**: 尽量在App层实现功能，必要时才修改Kernel，确保框架稳定性。