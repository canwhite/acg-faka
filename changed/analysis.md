# ACG-FAKA 项目分析报告

## 项目概述

这是一个基于 **PHP 8.0+** 的虚拟发卡系统（ACG-FAKA），以下是详细分析：

### 项目类型
- **虚拟发卡/电商系统**：用于销售虚拟商品、卡密、数字产品
- **版本**：3.2.5
- **架构**：MVC架构，使用自定义PHP框架

## 运行环境要求

### 1. 基础环境
- **PHP >= 8.0** （必须，使用了大量PHP8特性和注解）
- **MySQL >= 5.6** （推荐5.7或8.0）
- **Web服务器**：Apache/Nginx/IIS

### 2. PHP扩展要求
- `ext-json` - JSON处理
- `ext-openssl` - 加密功能
- `ext-pdo` - 数据库连接
- `ext-pdo_mysql` - MySQL数据库
- `ext-gd` - 图像处理
- `ext-zip` - 压缩文件处理
- `ext-curl` - HTTP请求

### 3. Composer依赖

主要依赖包：
- `smarty/smarty` - 模板引擎
- `illuminate/database` - Laravel数据库组件
- `illuminate/pagination` - 分页组件
- `phpmailer/phpmailer` - 邮件发送
- `guzzlehttp/guzzle` - HTTP客户端
- `firebase/php-jwt` - JWT令牌
- `mrgoon/aliyun-sms` - 阿里云短信
- `khanamiryan/qrcode-detector-decoder` - 二维码

## 数据库结构

系统包含13个主要数据表：
- `user` - 用户表
- `manage` - 管理员表
- `order` - 订单表
- `commodity` - 商品表
- `card` - 卡密表
- `pay` - 支付方式表
- `category` - 商品分类表
- `config` - 系统配置表
- `bill` - 账单流水表
- `coupon` - 优惠券表
- `cash` - 提现记录表
- `business_level` - 商户等级表
- `user_group` - 用户等级表

## API接口结构

### 管理端API (`/admin/api/`)
- 订单管理：`/admin/api/order/`
- 商品管理：`/admin/api/commodity/`
- 用户管理：`/admin/api/user/`
- 卡密管理：`/admin/api/card/`
- 支付配置：`/admin/api/pay/`
- 配置管理：`/admin/api/config/`

### 用户端API (`/user/api/`)
- 订单操作：`/user/api/order/trade`
- 充值接口：`/user/api/recharge/`
- 用户认证：`/user/api/authentication/`
- 账户管理：`/user/api/bill/`

## 系统功能特性

1. **商品管理**：支持商品分类、会员价、游客价、限时秒杀
2. **支付系统**：支持多种支付渠道（支付宝、微信等）
3. **会员系统**：用户等级、商户等级、积分系统
4. **分站系统**：用户可开通子分站
5. **代理推广**：三级分销返佣
6. **卡密发货**：自动发卡、手动发货
7. **共享店铺**：对接其他平台进货
8. **插件系统**：支持功能扩展

## 运行所需组件

### 必需组件
1. **Web服务器**（Apache/Nginx/IIS）+ 伪静态规则
2. **PHP 8.0+** + 必需扩展
3. **MySQL 5.6+** 数据库
4. **Composer** 依赖管理

### 可选组件
1. **Redis**（缓存优化）
2. **阿里云短信服务**（短信验证）
3. **SMTP服务器**（邮件通知）
4. **支付接口**（支付宝、微信等）

## 部署步骤

1. 下载源码或使用 `composer create-project lizhipay/acg-faka:dev-main`
2. 配置Web服务器伪静态
3. 创建MySQL数据库
4. 访问首页进行安装向导
5. 配置支付接口和基本信息
6. 后台地址：`/admin`

## 项目文件结构

```
acg-faka/
├── app/                    # 应用目录
│   ├── Controller/         # 控制器
│   │   ├── Admin/         # 管理端
│   │   ├── User/          # 用户端
│   │   └── Base/          # 基础控制器
│   ├── Consts/            # 常量定义
│   └── Model/             # 数据模型
├── config/                # 配置文件
├── kernel/                # 框架核心
│   ├── Annotation/        # 注解系统
│   ├── Component/         # 组件
│   ├── Context/           # 上下文
│   ├── Database/          # 数据库
│   ├── Exception/         # 异常处理
│   ├── Plugin/            # 插件系统
│   └── Util/              # 工具类
├── vendor/                # Composer依赖
├── assets/                # 静态资源
├── templates/             # 模板文件
└── index.php              # 入口文件
```

## 核心技术栈

- **后端框架**：自研PHP8框架
- **模板引擎**：Smarty
- **数据库ORM**：Illuminate Database (Laravel组件)
- **依赖注入**：自研DI容器
- **注解系统**：PHP8 Attributes
- **插件系统**：Hook机制
- **安全防护**：WAF防火墙

## 特色功能

### 1. 多商户支持
- 主站管理员可开通分站
- 分站可独立运营
- 支持子域名绑定

### 2. 智能卡密管理
- 支持批量导入卡密
- 自动发货和手动发货
- 卡密预选功能

### 3. 灵活的价格体系
- 游客价和会员价
- 等级折扣
- 批发优惠

### 4. 完善的推广系统
- 三级分销返佣
- 优惠券系统
- 推广链接追踪

### 5. 强大的支付系统
- 支持多种支付方式
- 插件化支付接口
- 自动回调处理

## 系统特点

1. **高性能**：使用PHP8新特性，优化数据库查询
2. **易扩展**：插件化架构，支持自定义开发
3. **安全可靠**：内置WAF防护，防SQL注入
4. **用户友好**：响应式设计，支持移动端
5. **功能完整**：涵盖电商系统各项核心功能

这个系统是一个功能完整的电商发卡平台，适合销售虚拟商品和数字产品，具有良好的扩展性和安全性。