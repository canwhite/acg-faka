# ACG-FAKA 项目启动机制深度分析

## 🚀 用户使用指南 - 简单启动方式

### 💡 你只需要启动nginx！

从表面上看，**你只需要启动nginx就可以了**！

#### ✅ 当前状态
- Nginx已启动 - 监听91端口，处理HTTP请求
- PHP-FPM已运行 - Laravel Herd在后台管理PHP进程
- 项目已就绪 - 代码和数据库都在正确位置

#### 🔄 完整的"自动"流程
当你访问 `http://localhost:91` 时：
1. **Nginx** 接收请求 → 转发给PHP-FPM
2. **PHP-FPM** 自动启动PHP进程 → 执行`index.php`
3. **PHP** 自动加载数据库 → 渲染页面 → 返回结果

#### 💡 日常使用指南
**平时使用时**：
- ✅ 项目会自动启动（通过nginx触发）
- ✅ 数据库自动连接（SQLite文件）
- ✅ 缓存自动生成（runtime目录）

**什么时候需要手动干预**：
- 🔄 重启电脑后 → 启动nginx: `brew services start nginx`
- 🔄 修改配置后 → 重载nginx: `nginx -s reload`
- 🔄 PHP出问题 → 检查Laravel Herd状态

#### 🎉 总结
现在你只需要：
1. **浏览器访问** `http://localhost:91`
2. **开始使用** 项目

所有复杂的技术细节都已经被配置好了，项目会"自动"运行！

---

## 📚 技术深度分析

### 概述
ACG-FAKA使用了自研的PHP 8.0+框架，集成了现代PHP架构模式，包括依赖注入、注解系统、插件化架构等高级特性。

## 启动流程图

```
HTTP请求 → Nginx(91端口) → PHP-FPM → index.php → Kernel.php → 路由解析 → 控制器执行 → 响应输出
```

## 详细启动流程

### 1. 入口点：index.php
```php
<?php
declare(strict_types=1);

/**
 * 开启DEBUG
 */
const DEBUG = false;
require("kernel/Kernel.php");
```

**特点**：
- 极简入口，仅定义DEBUG常量和加载核心
- 使用`declare(strict_types=1)`严格类型模式
- DEBUG=false，生产环境关闭调试

### 2. 核心启动：kernel/Kernel.php

#### 2.1 初始化阶段
```php
// 设置时区
date_default_timezone_set("Asia/Shanghai");

// 关闭错误显示（生产环境）
error_reporting(0);

// 定义基础路径
const BASE_PATH = __DIR__ . "/../";

// 加载Composer依赖和助手函数
require(BASE_PATH . '/vendor/autoload.php');
require("Helper.php");
```

#### 2.2 URL路由解析
```php
// 从$_GET['s']参数获取路由，默认为"/user/index/index"
$routePath = $_GET['s'] = $_GET['s'] ?? "/user/index/index";

// 特殊URL重写规则
preg_match('/\/item\/(\d+)/', $_GET['s'] ?? "/", $_item);
preg_match('/\/cat\/(\d+|recommend)/', $_GET['s'] ?? "/", $_cat);

// 商品详情页重写
if (isset($_item[1]) && is_numeric($_item[1])) {
    $_GET['s'] = "/user/index/item";
    $_GET['mid'] = $_item[1];
}

// 分类页面重写
if (isset($_cat[1]) && (is_numeric($_cat[1]) || $cat[1] == "recommend")) {
    $_GET['s'] = "/user/index/index";
    $_GET['cid'] = $_cat[1];
}

// 后台重定向
if (trim($routePath, "/") == 'admin') {
    header('location:' . "/admin/authentication/login");
}
```

#### 2.3 路由到控制器映射
```php
// 路由解析：/user/index/index -> App\Controller\User\Index->index()
$s = explode("/", trim((string)$routePath, '/'));
$count = count($s);
$controller = "App\\Controller"; // 基础命名空间

// 插件路由处理
if (strtolower($s[0]) == "plugin") {
    $controller = "App";
    Plugin::$currentControllerPluginName = ucfirst(trim((string)$s[1]));
}

// 动态构建控制器类名
foreach ($s as $j => $x) {
    if ($j == ($count - 1)) break; // 跳过最后的action名

    if (strtolower($s[0]) == "plugin" && $j == 2) {
        $controller .= "\\Controller"; // 插件控制器路径
    }
    $controller .= '\\' . ucfirst(trim($x)); // 首字母大写
}

// 解析action和参数
$parameter = explode('.', $ends);
$action = array_shift($parameter);
$_GET["_PARAMETER"] = Firewall::inst()->xssKiller($parameter);
```

#### 2.4 上下文初始化
```php
// 设置全局上下文
Context::set(\Kernel\Context\Interface\Request::class, new Request());
Context::set(Base::ROUTE, "/" . implode("/", $s));
Context::set(Base::LOCK, (string)file_get_contents(BASE_PATH . "/kernel/Install/Lock"));
Context::set(Base::IS_INSTALL, file_exists(BASE_PATH . '/kernel/Install/Lock'));
Context::set(Base::OPCACHE, extension_loaded("Zend OPcache") || extension_loaded("opcache"));
Context::set(Base::STORE_STATUS, file_exists(BASE_PATH . "/kernel/Plugin.php"));
```

#### 2.5 数据库初始化
```php
// 使用Laravel Eloquent ORM
$capsule = new Manager();
$db_config = config('database'); // 从config/database.php读取配置
$db_config['options'][PDO::ATTR_PERSISTENT] = true; // 持久连接
$capsule->addConnection($db_config);
$capsule->setAsGlobal();
$capsule->bootEloquent();
```

#### 2.6 插件系统初始化
```php
// 检查并加载插件系统
if (Context::get(Base::STORE_STATUS) && Context::get(Base::IS_INSTALL)) {
    require("Plugin.php");
    Hook::inst()->load(); // 加载钩子
    hook(\App\Consts\Hook::KERNEL_INIT); // 执行内核初始化钩子
}
```

### 3. 控制器执行阶段

#### 3.1 实例化和验证
```php
// 检查控制器类是否存在
if (!class_exists($controller)) {
    throw new NotFoundException("404 Not Found");
}

// 实例化控制器
$controllerInstance = new $controller;

// 检查方法是否存在
if (!method_exists($controllerInstance, $action)) {
    throw new NotFoundException("404 Not Found");
}
```

#### 3.2 注解系统处理
```php
// 解析类注解
Collector::instance()->classParse($controllerInstance, function (\ReflectionAttribute $attribute) {
    $attribute->newInstance();
});

// 解析方法注解
Collector::instance()->methodParse($controllerInstance, $action, function (\ReflectionAttribute $attribute) {
    $attribute->newInstance();
});
```

#### 3.3 依赖注入
```php
// 自动依赖注入
Di::instance()->inject($controllerInstance);

// 参数注入和方法调用
$parameters = Collector::instance()->getMethodParameters($controllerInstance, $action, $_REQUEST);
hook(\App\Consts\Hook::CONTROLLER_CALL_BEFORE, $controllerInstance, $action);
$result = call_user_func_array([$controllerInstance, $action], $parameters);
hook(\App\Consts\Hook::CONTROLLER_CALL_AFTER, $controllerInstance, $action, $result);
```

#### 3.4 响应输出
```php
if ($result === null) {
    return; // 无返回值
}

if (!is_scalar($result)) {
    // 非标量类型，输出JSON
    header('content-type:application/json;charset=utf-8');
    echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} else {
    // 标量类型，输出HTML
    header("Content-type: text/html; charset=utf-8");
    echo $result;
}
```

### 4. 示例：首页访问流程

#### 4.1 访问：http://localhost:91
```
1. Nginx伪静态规则：try_files $uri $uri/ /index.php?s=$uri&$args;
2. $_GET['s'] = "/" → 默认为 "/user/index/index"
3. 路由解析：["user", "index", "index"]
4. 控制器：App\Controller\User\Index
5. 方法：index()
6. 执行流程：
   - Waf拦截器检查
   - UserVisitor拦截器处理
   - 依赖注入Shop服务
   - 执行index()方法
   - 返回渲染后的HTML
```

#### 4.2 控制器代码分析（App\Controller\User\Index）
```php
#[Interceptor([Waf::class, UserVisitor::class])] // 注解：拦截器
class Index extends User {
    #[Inject] // 注解：依赖注入
    private Shop $shop;

    public function index(): string {
        // 检查店铺关闭状态
        if ((int)Config::get("closed") == 1) {
            return $this->theme("店铺正在维护", "CLOSED", "Index/Closed.html");
        }

        // 获取分类数据
        $category = $this->shop->getCategory($this->getUserGroup());
        hook(Hook::USER_API_INDEX_CATEGORY_LIST, $category);

        // 渲染主题模板
        return $this->theme("购物", "INDEX", "Index/Index.html", [
            'user' => $this->getUser(),
            'from' => $from,
            "categoryId" => $_GET['cid'],
            "category" => $category
        ]);
    }
}
```

## 核心技术特性

### 1. 现代PHP特性
- **严格类型**: `declare(strict_types=1)`
- **PHP 8.0+ 注解**: 使用反射属性实现AOP
- **命名空间**: 完整的PSR-4自动加载
- **依赖注入**: 自动属性注入

### 2. 框架架构
- **自研MVC框架**: 轻量级但功能完整
- **Laravel Eloquent**: 数据库ORM集成
- **Smarty模板引擎**: 视图层渲染
- **插件化架构**: Hook系统实现扩展

### 3. 安全特性
- **WAF防火墙**: XSS过滤和请求验证
- **拦截器模式**: 拦截器注解实现
- **SQL注入防护**: Eloquent ORM防护
- **CSRF保护**: 表单令牌机制

### 4. 性能优化
- **OPcache支持**: PHP字节码缓存
- **持久数据库连接**: PDO持久连接
- **模板编译缓存**: Smarty编译缓存
- **配置缓存**: Context缓存机制

### 5. 开发友好
- **调试模式**: DEBUG常量控制
- **错误处理**: 异常机制统一处理
- **日志系统**: debug()函数记录
- **助手函数**: 丰富的工具函数库

## 与传统框架对比

| 特性 | ACG-FAKA框架 | Laravel | ThinkPHP |
|------|-------------|---------|----------|
| **入口复杂度** | 极简(8行) | 较复杂 | 中等 |
| **启动速度** | 快(轻量级) | 中等 | 快 |
| **注解支持** | 原生PHP8注解 | 较弱 | 较弱 |
| **插件系统** | Hook系统 | Package | 模块化 |
| **数据库ORM** | Laravel Eloquent | Eloquent | 自研 |
| **模板引擎** | Smarty | Blade | 自研 |

## 运行时文件生成

### 1. runtime/view/compile/
- **作用**: Smarty模板编译缓存
- **示例**: `ad3441bc2b4ed7429fe29987d5fb5f80dac4d3aa_0.file.Install.html.php`
- **生成**: 首次访问模板时自动编译

### 2. runtime/waf/
- **作用**: Web应用防火墙缓存
- **HTML/*.ser**: HTMLPurifier过滤器缓存
- **URI/*.ser**: URI过滤器缓存
- **PACKET/**: WAF数据包缓存

### 3. 缓存策略
- **HTMLPurifier**: 版本化缓存`4.18.0,哈希值.ser`
- **模板编译**: MD5哈希文件名
- **自动清理**: 通过WAF类管理

## 总结

ACG-FAKA的启动机制体现了现代PHP开发的最佳实践：

1. **架构清晰**: 分层设计，职责明确
2. **性能优秀**: 轻量级核心，优化到位
3. **扩展性强**: 插件化架构，Hook机制
4. **安全可靠**: 多层安全防护
5. **开发友好**: 丰富的工具和调试支持

这是一个设计精良的自研框架，既保持了高性能，又提供了现代化的开发体验。