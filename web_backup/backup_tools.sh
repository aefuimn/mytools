# !/bin/bash
# 初始化获取配置信息全局变量
config_key="" 

# 读取config.ini文件中的配置信息函数
# 根据第一个参数查找是否有对应键
function read_config(){
    key=$1 # 查找键
    res=`awk -F "[ =]" '$1~/'$key'/{print $2}' config.ini`
    # 判断是否有结果没有结果，报错并退出
    if [ -z "$res" ];
    then
        echo "The key of "$key" is null, make sure you fill out" $key"!!!"
        exit 0
    fi
    config_key=$res 
}


# 备份
function backup(){
    # 备份网站目录
    read_config web_path  # 读取web网站目录到config_key
    web_path=$config_key
    read_config backup_root_path # 读取备份文件存放路径到config_key
    backup_root_path=$config_key
    backup_dir_name=`date +%Y-%m-%d`  # 获取当前日期当做备份文件夹名称
    backup_path=$backup_root_path"/"$backup_dir_name  # 拼接字符串获取备份绝对路径
    `mkdir -p $backup_path`  # 创建备份目录
    
    # 备份网站文件
    `cp -r $web_path $backup_path`
    
    # 读取数据库名称和数据库账户密码
    read_config mysql_database_name
    mysql_database_name=$config_key
    read_config mysql_user
    mysql_user=$config_key
    read_config mysql_password
    mysql_password=$config_key

    # 备份数据库
    `mysqldump -u$mysql_user -p$mysql_password  --databases $mysql_database_name | gzip > $backup_path"/mysql.sql.gz"`

    manage_backup_file  $backup_root_path # 调用管理备份文件目录
}


# 管理备份文件函数，最多只能拥有5个备份文件，如果多余5个就删除最旧的一个
# 需要传入备份文件根目录
function manage_backup_file(){
    # 检测备份数量
    backup_count=`ls -l $1|wc -l`
    if [ $backup_count -gt 6 ];then
        backup_file_name=`ls -ltr $1|awk '$9~/[0-9]+-[0-9]+-[0-9]+/ {print $9;exit}'` # 找到最早的一个备份文件名称
        backup_file_path=$1"/"$backup_file_name  # 拼接最早一个文件的绝对路径

        # 对路径进行检测，以免删除错误
        if [ $backup_file_path != "/" ];then
            `rm -rf $backup_file_path`  # 删除备份
        fi
    fi
}


# 从网站备份文件中恢复网站
# 需要传入恢复备份文件所在路径，否则默认恢复备份路径中最新的一个备份
function recover(){
    backup_file_path=$1  # 获取传入的参数
    # 如果参数为空，选择最新的备份
    if [ -z "$backup_file_path" ];then
        read_config backup_root_path
        backup_root_path=$config_key
        backup_file_name=`ls $backup_root_path -lt|awk '$9~/[0-9]+-[0-9]+-[0-9]+/ {print $9;exit}'`
        backup_file_path=$backup_root_path"/"$backup_file_name
    fi
    echo Recover web from $backup_file_path
    # 恢复网站文件
    web_file_path=$backup_file_path"/html"  # 这里的html请根据实际情况进行配置
    read_config web_path
    web_path=$config_key
    # 删除存在的网站文件
    if [ $web_path != "/" ];then
        `rm -rf $web_path`
    fi
    `cp -r $web_file_path $web_path`  # 从备份文件中恢复网站文件
    `chown -R nginx:nginx $web_path`  # 更改文件夹的权限，nginx:nginx需要根据实际情况进行配置

    # 恢复数据库文件
    sql_gzfile_path=$backup_file_path"/mysql.sql.gz"  # 这里的mysql.sql.gz请根据实际情况进行配置
    `gzip -d $sql_gzfile_path`  # 解压mysql.sql
    sql_file_path=$backup_file_path"/mysql.sql"
    read_config mysql_user
    mysql_user=$config_key
    read_config mysql_password
    mysql_password=$config_key
    `mysql -u$mysql_user -p$mysql_password < $sql_file_path`  # 恢复数据库
    gzip $sql_file_path  # 压缩mysql
}

if [ -z "$1" ]||[[ "$1" = "backup" ]];then
    backup
elif [[ "$1" = "recover" ]];then
    recover $2
else
    echo parameter error
fi