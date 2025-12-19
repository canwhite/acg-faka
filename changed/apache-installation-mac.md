# Mac 上安装 Apache 指南

## 方法一：使用 Homebrew（推荐）

1. **安装 Homebrew**（如果没有）：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **安装 Apache**：
```bash
brew install httpd
```

3. **找到 Apache 配置文件**：
```bash
# 通常位于 /usr/local/etc/httpd/httpd.conf 或 /opt/homebrew/etc/httpd/httpd.conf
brew --prefix httpd
```

4. **修改配置文件**：
```bash
# 编辑配置文件
sudo nano /usr/local/etc/httpd/httpd.conf
# 或
sudo nano /opt/homebrew/etc/httpd/httpd.conf
```

5. **修改以下设置**：
```apache
# 找到 Listen 80，改为：
Listen 91

# 找到 ServerName，添加或修改为：
ServerName localhost:91

# 确保模块启用
LoadModule rewrite_module lib/httpd/modules/mod_rewrite.so

# 设置 DocumentRoot 指向你的项目目录
DocumentRoot "/Users/zack/Desktop/acg-faka"
<Directory "/Users/zack/Desktop/acg-faka">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

6. **启动 Apache**：
```bash
# 启动服务
brew services start httpd

# 或手动启动
sudo /usr/local/sbin/apachectl start
# 或
sudo /opt/homebrew/sbin/apachectl start
```

## 方法二：使用 Mac 自带 Apache

Mac 系统自带 Apache，但版本可能较旧：

1. **启动自带 Apache**：
```bash
sudo apachectl start
```

2. **配置文件位置**：
```bash
# 主配置文件
/etc/apache2/httpd.conf

# 用户配置文件
/etc/apache2/extra/httpd-userdir.conf
```

3. **修改端口**：
```bash
sudo nano /etc/apache2/httpd.conf
# 修改 Listen 80 为 Listen 91
```

## 安装 PHP（Apache 需要）

1. **安装 PHP**：
```bash
brew install php
```

2. **在 Apache 中启用 PHP**：
```apache
# 在 httpd.conf 中添加
LoadModule php_module /usr/local/opt/php/lib/httpd/modules/libphp.so
# 或 Apple Silicon Mac
LoadModule php_module /opt/homebrew/opt/php/lib/httpd/modules/libphp.so

# 添加 PHP 文件处理
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>
```

## 验证安装

1. **检查 Apache 状态**：
```bash
brew services list | grep httpd
```

2. **测试访问**：
打开浏览器访问 `http://localhost:91`

## 推荐使用 Homebrew

因为：
- 版本更新及时
- 配置简单
- 不影响系统自带服务
- 容易管理和卸载

安装完成后，记得将项目的 `.htaccess` 文件放在正确的位置，确保 Apache 的 `AllowOverride All` 设置已启用。