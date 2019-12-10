说明：
本脚本用于网站的备份与恢复，功能包括：
1. 网站文件的备份
2. 网站数据库的备份
3. 网站文件的恢复
4. 网站数据库的恢复
用法：
1. 填写配置文件config.ini所需参数
2. 网站备份：sh backup_tools.sh 或者sh backup_tools.sh backup
3. 从备份文件恢复文件: sh backup_tools.sh recover 备份路径  或者 sh backup_tools.sh recover 这个根据配置文件备份路径选择最新备份