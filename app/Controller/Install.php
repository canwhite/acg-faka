<?php
declare(strict_types=1);

namespace App\Controller;


use App\Controller\Base\API\User;
use App\Service\App;
use App\Util\Client;
use App\Util\Opcache;
use App\Util\Str;
use App\Util\Validation;
use Kernel\Annotation\Inject;
use Kernel\Exception\JSONException;
use Kernel\Util\SQL;
use Kernel\Util\View;

class Install extends User
{

    #[Inject]
    private App $app;

    /**
     * 伪静态探测
     * @return array
     */
    public function rewrite(): array
    {
        return $this->json(200, "success");
    }


    /**
     * @return string
     */
    public function step(): string
    {
        if (file_exists(BASE_PATH . '/kernel/Install/Lock')) {
            Client::redirect("/", "どうして?", 3);
        }
        $data = [];
        $data['version'] = config("app")['version'];
        $data['php_version'] = phpversion();

        $data['ext']['gd'] = extension_loaded("gd");
        $data['ext']['curl'] = extension_loaded("curl");
        $data['ext']['pdo'] = extension_loaded("PDO");
        $data['ext']['pdo_mysql'] = extension_loaded("pdo_mysql");
        $data['ext']['pdo_sqlite'] = extension_loaded("pdo_sqlite");
        $data['ext']['date'] = extension_loaded("date");
        $data['ext']['json'] = extension_loaded("json");
        $data['ext']['session'] = extension_loaded("session");
        $data['ext']['zip'] = extension_loaded("zip");


        $data['install'] = true;
        if ($data['php_version'] < 8) {
            $data['install'] = false;
        } else {
            foreach ($data['ext'] as $ext) {
                if (!$ext) {
                    $data['install'] = false;
                }
            }
        }

        return View::render("Install.html", $data);
    }


    /**
     * @return array
     * @throws \Kernel\Exception\JSONException
     */
    public function submit(): array
    {
        if (file_exists(BASE_PATH . '/kernel/Install/Lock')) {
            throw new JSONException("您已经安装过了，如果想重新安装，请删除" . '/kernel/Install/Lock' . '文件，即可重新安装!');
        }
        $map = $_POST;

        foreach ($map as $k => $v) {
            $map[$k] = trim((string)$v);
        }

        $email = $map['email'];
        $nickname = $map['nickname'];
        $login_password = $map['login_password'];

        if (!Validation::email($email)) {
            throw new JSONException("管理员邮箱格式不正确");
        }

        if (!Validation::password($login_password)) {
            throw new JSONException("您设置的登录密码过于简单");
        }

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
                    'status' => 1,
                    'type' => 1,
                    'create_time' => date('Y-m-d H:i:s')
                ]);
            } else {
                // 更新现有管理员密码
                $manage->password = $pw;
                $manage->nickname = $nickname;
                $manage->salt = $salt;
                $manage->status = 1;
                $manage->save();
            }
        } catch (\Exception $e) {
            throw new JSONException("创建管理员账号失败: " . $e->getMessage());
        }
        file_put_contents(BASE_PATH . '/kernel/Install/Lock', "");

        try {
            $this->app->install();
        } catch (\Exception|\Error $e) {
        }

        return $this->json(200, '安装完成');
    }
}