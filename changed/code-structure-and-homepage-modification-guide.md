# ACG-FAKA 代码结构与首页功能修改指南

## 📁 项目整体架构

ACG-FAKA采用自研的MVC框架，结合PHP 8.0+的现代特性，结构清晰分层：

```
acg-faka/
├── app/                    # 应用核心代码
│   ├── Controller/         # 控制器层 - 处理HTTP请求
│   │   ├── Admin/         # 后台管理控制器
│   │   ├── User/          # 用户控制器 (首页相关)
│   │   ├── Shared/        # 共享控制器
│   │   └── Base/          # 基础控制器
│   ├── Model/             # 数据模型层 - 数据库操作
│   ├── Service/           # 服务层 - 业务逻辑
│   ├── View/              # 视图层 - 模板文件
│   │   ├── User/          # 用户端模板 (首页相关)
│   │   └── Admin/         # 后台管理模板
│   ├── Util/              # 工具类 - 通用功能
│   ├── Interceptor/       # 拦截器 - 中间件
│   ├── Consts/            # 常量定义
│   └── Entity/            # 实体类
├── kernel/                # 框架核心
├── config/                # 配置文件
├── database/              # SQLite数据库
└── assets/                # 静态资源 (CSS/JS/图片)
```

## 🏗️ 各层职责详解

### 1. Controller层 (控制器)
**职责**: 接收HTTP请求，处理用户输入，调用服务层，返回响应

**首页相关控制器**: `app/Controller/User/Index.php`

```php
#[Interceptor([Waf::class, UserVisitor::class])]
class Index extends User {
    #[Inject]
    private Shop $shop;

    public function index(): string {
        // 1. 获取用户信息
        // 2. 获取分类数据
        // 3. 渲染首页模板
        return $this->theme("购物", "INDEX", "Index/Index.html", $data);
    }
}
```

### 2. Model层 (数据模型)
**职责**: 数据库操作，数据验证，数据关系

**首页相关模型**:
- `app/Model/User.php` - 用户数据
- `app/Model/Commodity.php` - 商品数据
- `app/Model/Category.php` - 分类数据

### 3. Service层 (服务层)
**职责**: 业务逻辑处理，复用性高的业务操作

**首页相关服务**:
- `app/Service/Shop.php` - 商品相关业务逻辑
- `app/Service/Bind/User.php` - 用户绑定服务

### 4. View层 (视图层)
**职责**: HTML模板渲染，用户界面展示

**首页相关模板**: `app/View/User/Theme/Cartoon/Index/Index.html`

### 5. Interceptor层 (拦截器)
**职责**: 请求拦截，权限验证，日志记录

**首页拦截器**:
- `Waf::class` - Web应用防火墙
- `UserVisitor::class` - 访客权限检查

## 🎯 请求处理流程

### 首页访问流程图
```
用户访问 http://localhost:91
    ↓
Nginx (91端口) → PHP-FPM
    ↓
index.php → Kernel.php (路由解析)
    ↓
/user/index/index → App\Controller\User\Index->index()
    ↓
拦截器: Waf → UserVisitor
    ↓
依赖注入: Shop服务
    ↓
业务逻辑: 获取分类、商品数据
    ↓
视图渲染: Index/Index.html
    ↓
返回HTML响应
```

## 🔧 首页功能修改指南

### 场景1: 修改首页显示的商品列表

#### 需要修改的层次：

**1. Controller层** - `app/Controller/User/Index.php`
```php
public function index(): string {
    // 获取商品列表的业务逻辑
    $commodities = $this->shop->getCommodities($this->getUserGroup(), $_GET['cid']);

    return $this->theme("购物", "INDEX", "Index/Index.html", [
        'commodities' => $commodities  // 传递给模板
    ]);
}
```

**2. Service层** - `app/Service/Shop.php`
```php
public function getCommodities($userGroup, $categoryId = null): array {
    // 业务逻辑：根据用户组获取商品
    $query = \App\Model\Commodity::where('status', 1);

    if ($categoryId) {
        $query->where('category_id', $categoryId);
    }

    return $query->get()->toArray();
}
```

**3. View层** - `app/View/User/Theme/Cartoon/Index/Index.html`
```html
<!-- 商品列表展示 -->
<div class="commodity-list">
    {foreach $commodities as $item}
        <div class="commodity-item">
            <h3>{$item.name}</h3>
            <p>价格: {$item.price}</p>
        </div>
    {/foreach}
</div>
```

### 场景2: 添加首页推荐功能

#### 修改步骤：

**1. Model层** - `app/Model/Commodity.php`
```php
// 添加推荐商品的查询方法
public function scopeRecommend($query) {
    return $query->where('is_recommend', 1);
}
```

**2. Service层** - `app/Service/Shop.php`
```php
public function getRecommendCommodities(): array {
    return \App\Model\Commodity::recommend()
        ->where('status', 1)
        ->limit(10)
        ->get()
        ->toArray();
}
```

**3. Controller层** - `app/Controller/User/Index.php`
```php
public function index(): string {
    // 获取推荐商品
    $recommendCommodities = $this->shop->getRecommendCommodities();

    return $this->theme("购物", "INDEX", "Index/Index.html", [
        'recommendCommodities' => $recommendCommodities
    ]);
}
```

**4. View层** - 添加推荐商品展示区域
```html
<div class="recommend-section">
    <h2>推荐商品</h2>
    {foreach $recommendCommodities as $item}
        <!-- 推荐商品展示 -->
    {/foreach}
</div>
```

### 场景3: 修改首页样式

#### 修改层次：

**1. CSS文件** - `assets/user/css/index.css`
```css
/* 首页样式修改 */
.commodity-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
}
```

**2. JavaScript文件** - `assets/user/controller/index/index.js`
```javascript
// 首页交互逻辑
$(document).ready(function() {
    // 商品点击事件
    $('.commodity-item').click(function() {
        // 处理商品点击
    });
});
```

## 🔄 完整的修改流程

### 第一步：确定需求
- 明确要修改的首页功能
- 确定需要的数据和逻辑

### 第二步：修改Model层（如需要）
- 添加新的查询方法
- 修改数据验证规则

### 第三步：修改Service层
- 实现新的业务逻辑
- 处理数据转换和计算

### 第四步：修改Controller层
- 调用Service层方法
- 处理HTTP请求参数
- 准备模板数据

### 第五步：修改View层
- 更新HTML模板
- 添加新的展示区域
- 修改CSS样式

### 第六步：修改静态资源
- 更新CSS/JavaScript文件
- 添加新的图片资源

## 📝 具体示例：修改首页标题和描述

### 1. 修改配置
**文件**: `database` (SQLite中的config表)
```sql
UPDATE acg_config SET value = '我的店铺名称' WHERE name = 'shop_name';
UPDATE acg_config SET value = '我的店铺描述' WHERE name = 'description';
```

### 2. 修改模板（可选）
**文件**: `app/View/User/Theme/Cartoon/Index/Index.html`
```html
<title>{$shop_name} - {$title}</title>
<meta name="description" content="{$description}">
```

### 3. 修改Controller
**文件**: `app/Controller/User/Index.php`
```php
public function index(): string {
    // 获取店铺配置
    $shopName = \App\Model\Config::get('shop_name');
    $description = \App\Model\Config::get('description');

    return $this->theme($shopName, "INDEX", "Index/Index.html", [
        'shop_name' => $shopName,
        'description' => $description
    ]);
}
```

## 🛠️ 开发调试技巧

### 1. 开启调试模式
```php
// index.php
const DEBUG = true;  // 开启调试
```

### 2. 查看调试日志
```bash
tail -f /Users/zack/Desktop/acg-faka/runtime.log
```

### 3. 使用debug函数
```php
// 在Controller中添加调试信息
debug("用户访问首页，参数: " . json_encode($_GET));
```

### 4. 使用dd()函数
```php
// 调试变量内容
dd($commodities);
```

## 📋 修改清单

修改首页功能时，通常需要考虑：

### 必需修改
- [ ] **Controller** - 处理业务逻辑和数据传递
- [ ] **View** - 更新用户界面展示

### 可能需要修改
- [ ] **Model** - 如果需要新的数据查询方法
- [ ] **Service** - 如果需要复杂的业务逻辑
- [ ] **CSS/JS** - 如果需要样式或交互修改
- [ ] **Config** - 如果需要新的配置项

### 注意事项
- [ ] 保持代码风格一致
- [ ] 添加适当的注释
- [ ] 测试各种边界情况
- [ ] 检查权限控制
- [ ] 验证数据安全性

## 🎯 总结

ACG-FAKA的代码结构清晰，分层合理：
- **Controller**: 处理HTTP请求和响应
- **Model**: 数据库操作和数据模型
- **Service**: 业务逻辑和数据处理
- **View**: 用户界面和模板渲染
- **Interceptor**: 请求拦截和权限控制

修改首页功能时，通常遵循：**需求分析 → Model → Service → Controller → View** 的顺序，确保各层职责清晰，代码可维护性高。