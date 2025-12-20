# 安装程序SQLite支持修改

## 修改概述

为了支持现有的SQLite数据库，我们修改了安装程序，使其跳过数据库配置步骤，只保留管理员账号配置和其他必要的安装步骤。

## 修改内容

### 1. 前端界面修改 (`app/View/Install.html`)

#### 数据库配置步骤修改
**原界面**: MySQL数据库配置表单
```html
<input type="text" name="host" placeholder="数据库地址" value="127.0.0.1">
<input type="text" name="database" placeholder="数据库名称">
<input type="text" name="username" placeholder="数据库账号">
<input type="text" name="password" placeholder="数据库密码">
<input type="text" name="prefix" placeholder="数据库前缀" value="acg_">
```

**新界面**: SQLite状态显示
```html
<div style="padding: 20px; background: #e8f5e8; border-radius: 5px; margin-bottom: 20px;">
    <p style="margin: 0; color: #2e7d2e;">
        ✅ SQLite数据库已配置完成，无需额外设置<br>
        📁 数据库位置: /database/database.sqlite<br>
        🔧 数据库类型: SQLite (WAL模式)
    </p>
</div>
```

#### JavaScript验证逻辑修改
**原验证**: 检查数据库字段
```javascript
if (database == '') {
    layer.msg("请填写数据库名称");
    return;
}
if (username == '') {
    layer.msg("请填写数据库账号");
    return;
}
if (password == '') {
    layer.msg("请填写数据库密码");
    return;
}
```

**新验证**: 直接跳过，SQLite已配置
```javascript
// SQLite数据库已配置，直接跳过验证
currentSection.removeClass("is-active").next().addClass("is-active");
headerSection.removeClass("is-active").next().addClass("is-active");
```

### 2. 后端逻辑修改 (`app/Controller/Install.php`)

#### 管理员创建逻辑
**原逻辑**: 通过SQL导入创建管理员
```php
$sqlFile = BASE_PATH . '/kernel/Install/Install.sql';
$sqlSrc = (string)file_get_contents($sqlFile);
$sqlSrc = str_replace('__MANAGE_EMAIL__', $email, $sqlSrc);
$sqlSrc = str_replace('__MANAGE_PASSWORD__', $pw, $sqlSrc);
$sqlSrc = str_replace('__MANAGE_SALT__', $salt, $sqlSrc);
$sqlSrc = str_replace('__MANAGE_NICKNAME__', $nickname, $sqlSrc);
SQL::import($sqlFile . ".tmp", $host, $map['database'], $map['username'], $map['password'], $map['prefix']);
```

**新逻辑**: 使用Eloquent直接创建管理员
```php
//SQLite数据库已存在，只需要创建管理员账号
$salt = Str::generateRandStr(32);
$pw = Str::generatePassword($login_password, $salt);

// 使用Eloquent直接创建管理员账号
try {
    // 检查是否已存在管理员
    $manage = \App\Model\Manage::where('email', $email)->first();
    if (!$manage) {
        // 创建新管理员
        \App\Model\Manage::create([
            'email' => $email,
            'password' => $pw,
            'nickname' => $nickname,
            'salt' => $salt,
            'avatar' => '/favicon.ico',
            'state' => 1,
            'is_initialize' => 0,
            'initialize_time' => date('Y-m-d H:i:s')
        ]);
    } else {
        // 更新现有管理员密码
        $manage->password = $pw;
        $manage->nickname = $nickname;
        $manage->salt = $salt;
        $manage->save();
    }
} catch (\Exception $e) {
    throw new JSONException("创建管理员账号失败: " . $e->getMessage());
}
```

## 安装流程

### 修改后的安装步骤

1. **环境检测** ✅
   - 检查PHP版本和必要扩展
   - 显示环境检测结果

2. **数据库配置** ✅ (修改)
   - 显示SQLite状态信息
   - 无需用户输入，直接进入下一步

3. **管理员配置** ✅ (保持不变)
   - 输入管理员邮箱、昵称、密码
   - 验证输入信息

4. **安装完成** ✅
   - 创建管理员账号
   - 创建安装锁定文件
   - 显示安装成功页面

### 安装程序特点

- ✅ **保留完整安装流程**: 环境检测 → 数据库状态 → 管理员配置 → 安装完成
- ✅ **跳过数据库配置**: SQLite已配置，无需额外设置
- ✅ **智能管理员创建**: 如果管理员已存在则更新，不存在则创建
- ✅ **保持原有UI设计**: 只修改数据库配置部分，其他保持不变
- ✅ **错误处理完整**: 包含详细的异常捕获和用户提示

## 使用方法

1. **访问安装程序**: http://localhost:91/install/step
2. **环境检测**: 确认所有扩展都支持
3. **数据库步骤**: 直接点击"下一步"（SQLite已配置）
4. **管理员配置**: 输入管理员邮箱、昵称、密码
5. **完成安装**: 点击"立即安装"

## 安全考虑

- ✅ **SQL注入防护**: 使用Eloquent ORM，自动防护SQL注入
- ✅ **密码安全**: 使用盐值加密存储密码
- ✅ **输入验证**: 邮箱格式验证和密码强度检查
- ✅ **安装锁定**: 安装完成后创建Lock文件，防止重复安装

## 兼容性

- ✅ **向后兼容**: 如果需要MySQL安装，只需恢复原始文件即可
- ✅ **SQLite优化**: 充分利用SQLite的WAL模式和性能优化
- ✅ **数据完整性**: 保持现有数据和表结构不变

## 文件修改清单

1. `app/View/Install.html` - 前端界面和JavaScript逻辑
2. `app/Controller/Install.php` - 后端安装逻辑
3. 无需修改数据库配置文件（保持SQLite配置）

---

**修改完成时间**: 2025-12-20
**测试状态**: ✅ 通过
**部署状态**: ✅ 可用