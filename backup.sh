#!/system/bin/sh
#微信聊天记录备份脚本
################### 备份模式配置区 ###################


BackupMode="2"
# 切换 增量 / 全量 备份
# 1为 [增量备份] ，2为 [全量备份]


StorageMode="3" 
# 切换 备份数据包存放方式
# 1为上传到 [天翼云盘] ，2为上传到 [阿里云盘] ，3为保存在 [本地]


BackupWechatId="wechatID_1 wechatID_2"
# 请输入需要备份的微信号
# 多个微信号间请用空格分开喔~


################### 网盘配置区 ###################


username='18888888888' # 天翼云盘 账号
password='abc123' # 天翼云盘 密码


AliRefreshToken="32位英文数字"
# 阿里云盘 RefreshToken
# (此项通常不需要填写，在手机上安装并登录阿里云盘app后，脚本便会自动获取此项，用于登录阿里云盘)

DirName="我的备份" 
# 可自定义网盘中存放备份数据包的文件夹名称


################### 本地配置区 ###################


store_path="/storage/emulated/0/WeChat_backup" 
# 可自定义本地备份后数据包的存放路径
# 只有在选择 [本地] 备份模式时才需要设置此处


################### 其他自定义配置区 ###################



MultiPartSize="1024"
# 数据包分卷大小，单位为M
# 若备份数据大于此处所设定的值，脚本将会对数据包进行分卷，避免因数据包太大导致的网盘拒绝上传或上传超时(本地备份不进行分卷操作)
# 仅支持填写0或正整数，0为关闭，其他正整数则为数据包分卷大小


CheckWifiState="0"
# 1为开启，0为关闭
# 开启后，在已连接WiFi且WiFi有网络的情况下脚本才会进行备份


OutputLogMode="2"
# 1为仅输出执行日志到屏幕，2为同时输出执行日志到屏幕与脚本同目录下的BackupLog.txt


taken="PzefqAE8k0NJTfoCX2iNUI0YtAN5"
# 用于识别不是一定会出现的图片验证码
# 如果没有异常提示就不需要改动
# 出现验证码识别异常请尝试更改为自己账号的taken
# 账号注册链接  http://fast.95man.com/login.html
# taken获取链接  http://api.95man.com:8888/api/Http/UserTaken?user=用户名&pwd=密码&isref=0



############################################



# 天翼云盘登陆部分代码参考https://github.com/Aruelius/cloud189
# by:酷安@搓澡君



############################################



# 初始化命令
[[ `whoami` != 'root' ]] && echo -e "\n脚本需要 ROOT权限 才可以正常运行哦~\n" && exit
[[ $0 == *'bin.mt.plus/temp'* ]] && echo -e "\n请不要直接在压缩包内运行脚本，先将压缩包内的所有文件解压到一个文件夹后再执行哦~\n" && exit
cd "`dirname "$0"`"
sh_path=`pwd`
sh_path=`readlink -f "$sh_path"`
sh_path=${sh_path/'/storage/emulated/'/'/data/media/'}

main(){

# 配置busybox / curl / bc 开始
[[ ! -d "${sh_path}/command" ]] && echo -e "\n 找不到脚本运行所需依赖！请尝试前往 https://czj.lanzoux.com/b0evzleqh 重新下载脚本压缩包后，将压缩包内文件解压至同一目录下~\n" && exit
BusyboxTest='mkdir awk sed head rm cp du date ls cat tr md5sum sort uniq seq touch split base64 sha1sum wc mv killall'
for Test in $BusyboxTest ; do ln -fs "${sh_path}/command/bin/busybox" "${sh_path}/command/bin/${Test}" ;done
[[ -n $LD_LIBRARY_PATH ]] && OldLib=":$LD_LIBRARY_PATH"
chmod -R 0777 "${sh_path}/command/" && export LD_LIBRARY_PATH=${sh_path}/command/lib${OldLib} && export PATH=${sh_path}/command/bin:$PATH
# 配置busybox / curl / bc 结束

# 一些方法
source "${sh_path}/command/bin/CloudLocalFunction"
ReadJson(){ echo -ne "$1" | grep -Po '\K[^}]+' | grep -Po '\K[^,]+' | grep -Po '"'$2'"[" :]+\K[^"]+';}
ReadXml(){ echo -ne "$1" | grep -E -o -e '<'$2'>.+</'$2'>' | sed 's/<'$2'>//g' | sed 's/<\/'$2'>//g';}
cut_string(){ str=`echo "$1" | sed s/[[:space:]]//g` ; str=${str#*$2} ; str=${str%%$3*} ; echo "$str";}
RmTmpExit(){ rm -rf /data/media/0/WeChat_tmp/ ; killall -s CONT com.tencent.mm >> /dev/null 2>&1 ; 
cd "${sh_path}/command/bin" && ls -1 -F "${sh_path}/command/bin" | grep -E '[@$]' | awk '{sub(/.{1}$/,"")}1' | xargs rm -rf ; exit;}
EchoYello(){ echo -e "\033[33m${1}\033[0m";}
# 一些方法

# 检测配置区错误 开始
[[ $StorageMode != 1 ]] && [[ $StorageMode != 2 ]] && [[ $StorageMode != 3 ]] && echo -e "\n备份数据包存放方式设置错误，仅支持设置为1或2或3，请修改后重新执行.....\n" && RmTmpExit
CheckNumber(){ [[ $1 != $3 ]] && [[ $1 != $4 ]] && echo -e "\n${2}设置错误，仅支持设置为${3}或${4}，请修改后重新执行.....\n" && RmTmpExit;}
CheckNumber "$CheckWifiState" '检查WiFi状态开关' "0" "1"
CheckNumber "$BackupMode" '备份模式' "1" "2"
CheckNumber "$OutputLogMode" '输出执行日志模式' "1" "2"
CheckNaturalNumbers(){ SetNumberBytes=`echo -n "$1" | wc -c` && [[ -z `echo -n "$1" | grep -E "[0-9]{$SetNumberBytes}"` ]] && echo -e "\n${2}设置错误，仅支持设置为0或正整数，请修改后重新执行.....\n" && RmTmpExit;}
CheckNaturalNumbers "$MultiPartSize" '数据包分卷大小'
# 检测配置区错误 结束

# 检测WiFi状态 开始
if [[ $CheckWifiState == 1 ]];then
while [[ `cat /sys/class/net/wlan0/operstate` == "down" ]];do
echo "未连接WiFi，10分钟后重新检测..." ; sleep 600s
done;fi
# 检测WiFi状态 结束

# 检测网络 开始
if [[ $StorageMode != 3 ]];then
network_state=`curl -k -sIL -w "%{http_code}\n" -o /dev/null "http://www.baidu.com" `
[[ $network_state != "200" ]] && EchoYello "\n连接网络失败！备份中止.....\n" && RmTmpExit;fi
# 检测网络 结束

# 提示语 开始
clear
rm -rf /data/media/0/WeChat_tmp && mkdir -p /data/media/0/WeChat_tmp
dividingLine="\033[36m----------------------------------------\033[0m"
[[ $BackupMode == "1" ]] && modeName='增量' || modeName='全量'
[[ $StorageMode == "1" ]] && CookieOrPwd && echo -e "\n${dividingLine}\n\n [天翼云盘] ${modeName}备份模式\n\n${dividingLine}\n" && uploadMode="TianYiUpload" && uploadMessage="\n正在自动上传备份数据包至天翼云盘....." && uploadSuccessMessage(){ echo -e "全部上传完成！您可以在天翼云盘 /${DirName}/${wxId[$i]}的备份数据/微信聊天记录备份(${modeName}) 中查看您的备份文件～\n\n${dividingLine}\n";}
[[ $StorageMode == "2" ]] && AliLogin && echo -e "\n${dividingLine}\n\n [阿里云盘] ${modeName}备份模式\n\n${dividingLine}\n" && uploadMode="AliUpload" && uploadMessage="\n正在自动上传备份数据包至阿里云盘....." && uploadSuccessMessage(){ echo -e "全部上传完成！您可以在阿里云盘 /${DirName}/${wxId[$i]}的备份数据/微信聊天记录备份(${modeName}) 中查看您的备份文件～\n\n${dividingLine}\n";}
[[ $StorageMode == "3" ]] && echo -e "${dividingLine}\n\n [本地] ${modeName}备份模式\n\n${dividingLine}\n" && uploadMode="LocalMove" && uploadMessage="\n正在移动备份数据包至本地....." && uploadSuccessMessage(){ echo -e "全部移动完成！您可以在本地 ${store_path}/${wxId[$i]}的备份数据/微信聊天记录备份(${modeName}) 中查看您的备份文件～\n\n${dividingLine}\n";}
# 提示语 结束

# 强制停止微信 开始
killall -s STOP com.tencent.mm >> /dev/null 2>&1
backupTime=$(date "+%Y-%m-%d_%H.%M.%S")
# 强制停止微信 结束

# 获取所有 uin 开始
i=0 ; for partition in `ls "/data/user/" `;do 
uinFiles="/data/user/${partition}/com.tencent.mm/shared_prefs/app_brand_global_sp.xml"
if [[ -e "$uinFiles" ]] && uinRead=`ReadXml "$(cat $uinFiles)" 'string'` && [[ -n $uinRead ]];then for uin in $uinRead ;do uinList[$i]="$uin" && wxPartition[$i]=$partition && let i++ ;done;fi;done
[[ -z ${uinList[@]} ]] && echo -e "\n获取微信数据！若您还未登录过微信请先进行登录噢~\n" && RmTmpExit
# 获取所有 uin 结束

# 获取所有微信号 开始
m=0 ; while [[ $m -lt ${#uinList[@]} ]];do
# RC4解密 KeyInfo.bin 开始
KeyFile="/data/user/${wxPartition[$m]}/com.tencent.mm/files/KeyInfo.bin"
if [[ -e "$KeyFile" ]];then
unset imei KeyInfoImei
rc4key=(95 119 69 99 72 65 84 95)
i=0 ; while [[ $i -lt 256 ]];do S[$i]=$i ; let i++ ; done
i=0 ; len=0 ; while [[ $i -lt 256 ]];do T[$i]=${rc4key[$len]} ; let i++ len++ ; [[ $len -gt 7 ]] && len=0 ; done
i=0 ; j=0 ; while [[ $i -lt 256 ]];do let j=$((${j}+${S[$i]}+${T[$i]}))%256 ; tmpi=${S[$i]} ; tmpj=${S[$j]} ; S[$i]=$tmpj ; S[$j]=$tmpi ; let i++; done
KeyInfo16=`xxd -p "$KeyFile" | sed s/[[:space:]]//g `
i=0 ; j=0 ; n=0 ; while [[ -n $KeyInfo16 ]];do 
KeyInfoAscii=$((16#`echo "$KeyInfo16" | head -c2`))
KeyInfo16=`echo -n "$KeyInfo16" | sed 's/..//'`
let i=$(($i+1))%256 ; let j=$((${j}+${S[$i]}))%256
tmpi=${S[$i]} ; tmpj=${S[$j]} ; S[$i]=$tmpj ; S[$j]=$tmpi
let t=$((${S[$i]}+${S[$j]}))%256
let data=${KeyInfoAscii}^${S[$t]}
[[ "$data" == "10" ]] && imei[$n]="-" || imei[$n]=`echo "$data" | awk '{printf("%c", $1)}'` ; let n++ ; done
DeKeyInfo=`echo "${imei[@]}" | sed s/[[:space:]]//g | sed 's/-/ /g'`
KeyInfoImei=($DeKeyInfo)
h=0 ; while [[ $h -lt ${#KeyInfoImei[@]} ]];do
[[ -n `echo "${KeyInfoImei[$h]}" | grep '^123'` ]] && KeyInfoImei[$h]="1234567890ABCDEF" ; let h++ ; done
else KeyInfoImei="1234567890ABCDEF";fi
# RC4解密 KeyInfo.bin 结束

# 获取微信号 开始
for imei in ${KeyInfoImei[@]} ;do
EnDir=`echo -n "mm${uinList[$m]}" | md5sum | awk '{print $1}'`
EnDB="/data/user/${wxPartition[$m]}/com.tencent.mm/MicroMsg/${EnDir}/EnMicroMsg.db"
EnKey=`echo -n "${imei}${uinList[$m]}" | md5sum | awk '{print $1}' | cut -c -7`
getWxId(){
sqlcipher "$EnDB" << EOF
.output /dev/null
PRAGMA key = "$EnKey";
PRAGMA cipher_compatibility = 1;
.output
select value from userinfo where id=$1;
.exit
EOF
}
wxId[$m]=`getWxId '42' 2>/dev/null`
[[ -z ${wxId[$m]} ]] && wxId[$m]=`getWxId '2' 2>/dev/null`
[[ -n ${wxId[$m]} ]] && break 1 ; done
[[ -z ${wxId[$m]} ]] && EchoYello "\n获取微信号失败！备份终止…~\n\n${KeyInfoImei[@]}" && RmTmpExit
# 获取微信号 结束
let m++ ; done
# 获取所有微信号 结束

# 处理重复微信号 (取最新) 开始
reWxId=`echo "${wxId[@]}" | tr ' ' '\n' | sort | uniq -d`
j=0 ; for RwxId in $reWxId ;do
i=0 ; while [[ $i -lt ${#wxId[@]} ]] ;do
[[ "${wxId[$i]}" == "$RwxId" ]] && ReIndex[$j]="${ReIndex[$j]} ${i}"
let i++ ; done ; let j++ ; done
m=0 ;i=0 ; while [[ $i -lt ${#ReIndex[@]} ]] ;do
unset tmpRe
for j in ${ReIndex[$i]} ;do
EnDir=`echo -n "mm${uinList[$j]}" | md5sum | awk '{print $1}'`
tmpRe[$j]="/data/user/${wxPartition[$j]}/com.tencent.mm/MicroMsg/${EnDir}/EnMicroMsg.db"
done
latestEn=`ls -t ${tmpRe[@]} | sed -n '1p' | awk -v FS="/" -v OFS="/" '{print $1,$2,$3,$4}'`
unset grepState ; k=0 ; while [[ $grepState != 1 ]] ;do
[[ `echo "${tmpRe[$k]}" | grep "$latestEn"` ]] && grepState=1 && n="$k"
let k++ ;done
oldReIndex[$m]=`echo "${ReIndex[$i]}" | tr ' ' "\n" | grep -v "$n"`
let m++ i++;done
for i in ${oldReIndex[@]} ;do
unset wxId[$i] ;done
# 处理重复微信号 (取最新) 结束

# 检测配置区微信号是否填写错误 & 匹配数组下标 开始
j=0 ; for BwxId in ${BackupWechatId[@]} ;do
i=0 ; unset getIdState ; while [[ $i -lt ${#wxPartition[@]} ]] ;do
[[ "${wxId[$i]}" == "$BwxId" ]] && getIdState=1 && backupIndex[$j]=$i && let j++
let i++ ; done 
[[ $getIdState != 1 ]] && echo -e "\n在本机上找不到您填写的微信号 ${BwxId} 请检查后重新填写喔~\n在本机上获取到的所有微信号如下：${wxId[@]}\n" && RmTmpExit ; done
# 检测配置区微信号是否填写错误 & 匹配数组下标 结束

# 备份 开始
for i in ${backupIndex[@]} ;do
rm -rf /data/media/0/WeChat_tmp && mkdir -p /data/media/0/WeChat_tmp

# 创建文件夹 & 获取上一次备份时间（增量模式下） 开始
if [[ $StorageMode == "1" ]];then
TYCreateDir "$DirName" '-11' 
UserDirId=`ReadJson "$NewDir" 'id'`
TYCreateDir ''${wxId[$i]}'的备份数据' "$UserDirId"
WxNicknameDir=`ReadJson "$NewDir" 'id'`
TYCreateDir '微信聊天记录备份('$modeName')' "$WxNicknameDir" 
WxRootDirId=`ReadJson "$NewDir" 'id'`
 if [[ $BackupMode == "1" ]];then
 TYCreateDir '文字聊天记录' "$WxRootDirId" 
 StrDirId=`ReadJson "$NewDir" 'id'`
 TYCreateDir '媒体文件' "$WxRootDirId" 
 MediaDirId=`ReadJson "$NewDir" 'id'`
 MediaDirList=`curl -k -b "${sh_path}/cookie/TianYiCookie.txt" -H "accept:application/json;charset=UTF-8" "https://cloud.189.cn/api/open/file/listFiles.action?pageSize=1&pageNum=1&mediaType=0&folderId=${MediaDirId}&iconOption=5&orderBy=createTime&descending=true" -s`
 [[ `ReadJson "$MediaDirList" 'count'` == "0" ]] && fullMode=1 || findTime=`ReadJson "$MediaDirList" 'name' | cut -c -19 | tr '_' ' ' | tr '.' ':'`;fi
elif [[ $StorageMode == "2" ]];then
AliCreateDir "$DirName" 'root' 
UserDirId=`ReadJson "$NewDir" 'file_id'`
AliCreateDir ''${wxId[$i]}'的备份数据' "$UserDirId"
WxNicknameDir=`ReadJson "$NewDir" 'file_id'`
AliCreateDir '微信聊天记录备份('$modeName')' "$WxNicknameDir" 
WxRootDirId=`ReadJson "$NewDir" 'file_id'`
 if [[ $BackupMode == "1" ]];then
 AliCreateDir '文字聊天记录' "$WxRootDirId" 
 StrDirId=`ReadJson "$NewDir" 'file_id'`
 AliCreateDir '媒体文件' "$WxRootDirId" 
 MediaDirId=`ReadJson "$NewDir" 'file_id'`
 MediaDirList=`curl -k -H "content-type:application/json;charset=UTF-8" -H "authorization:${Authorization}" -d '{"drive_id":"'$DriveId'","parent_file_id":"'$MediaDirId'","limit":1,"all":false,"fields":"*","order_by":"created_at","order_direction":"DESC"}' "https://api.aliyundrive.com/adrive/v3/file/list" -s`
 [[ -z `echo "$MediaDirList" | grep 'file_id'` ]] && fullMode=1 || findTime=`ReadJson "$MediaDirList" 'name' | cut -c -19 | tr '_' ' ' | tr '.' ':'`;fi
elif [[ $StorageMode == "3" ]];then
store_path=`readlink -f "$store_path" | sed 's:/storage/emulated/:/data/media/:g'`
WxRootDirId="${store_path}/${wxId[$i]}的备份数据/微信聊天记录备份(${modeName})"
mkdir -p "$WxRootDirId"
 if [[ $BackupMode == "1" ]];then
 StrDirId="${WxRootDirId}/文字聊天记录"
 MediaDirId="${WxRootDirId}/媒体文件"
 mkdir -p "$StrDirId" "$MediaDirId"
  [[ -z `ls "$StrDirId"` ]] && fullMode=1 || findTime=`ls -t "$StrDirId" | sed -n '1p' | cut -c -19 | tr '_' ' ' | tr '.' ':'`;fi
fi
if [[ $BackupMode == "2" ]] || [[ $fullMode == "1" ]];then Backuped="0" ;fi
# 创建文件夹 & 获取上一次备份时间（增量模式下） 结束

#初始化数据与储存目录 开始
StoragePartition="/data/media/${wxPartition[$i]}"
DataPartition="/data/user/${wxPartition[$i]}"
EnDir=`echo -n "mm${uinList[$i]}" | md5sum | awk '{print $1}'`
BackupDir="/data/media/0/WeChat_tmp/${uinList[$i]}"
mkdir -p "$BackupDir"
#初始化数据与储存目录 结束

# 备份 EnMicroMsg.db 开始
unset GetDBState
echo -e "备份${wxId[$i]}的文字聊天记录中....."
EnDB="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/EnMicroMsg.db"
EnDB2="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/EnMicroMsg2.db"
SnsDB="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/SnsMicroMsg.db"
FileDB="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/WxFileIndex.db"
mkdir -p "${BackupDir}/db"
[[ -e "$EnDB" ]] && cp -frs "$EnDB" "${BackupDir}/db" && GetDBState=1
[[ -e "$EnDB2" ]] && cp -frs "$EnDB2" "${BackupDir}/db" && GetDBState=1
[[ -e "$SnsDB" ]] && cp -frs "$SnsDB" "${BackupDir}/db"
[[ -e "$FileDB" ]] && cp -frs "$FileDB" "${BackupDir}/db"
[[ $GetDBState != 1 ]] && EchoYello "获取${wxId[$i]}的聊天记录文件失败！您可以自行查找原因或截图此界面私信 酷安@搓澡君\n${EnDir}" && RmTmpExit || echo "备份文字聊天记录完成！"
#备份 EnMicroMsg.db 结束

# 解密 account.bin 开始
if [[ -e "${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/account.mapping" ]];then
StDir=`cat "${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/account.mapping"`
elif [[ -e "${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/account.bin" ]];then
uin16=`echo -n "${uinList[$i]}" | xxd -p`
AccountBin16=`xxd -p -l 4096 "${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/account.bin"`
AccountBin16="${AccountBin16}${uin16}"
StDir=`echo -n "$AccountBin16" | xxd -p -r | md5sum | awk '{print $1}'`
else StDir="$EnDir" ; EchoYello "若您的微信版本为7.0.5及以下请忽略此提示，否则备份可能已经出现错误....." ;fi
# 解密 account.bin 结束

# 备份媒体文件 开始
echo -e "备份${wxId[$i]}的媒体文件中....."
tencent="tencent" && [[ ! -d ${StoragePartition}/${tencent}  ]] && tencent="Tencent"
DataAvatarDir="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/avatar"
DataImageDir="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/image2"
DataVoiceDir="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/voice2"
DataVideoDir="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/video"
DataAttachmentDir="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/attachment"
StorageAndroidImageDir="${StoragePartition}/Android/data/com.tencent.mm/MicroMsg/${StDir}/image2"
StorageAndroidVoiceDir="${StoragePartition}/Android/data/com.tencent.mm/MicroMsg/${StDir}/voice2"
StorageAndroidVideoDir="${StoragePartition}/Android/data/com.tencent.mm/MicroMsg/${StDir}/video"
StorageTencentImageDir="${StoragePartition}/${tencent}/MicroMsg/${StDir}/image2"
StorageTencentVoiceDir="${StoragePartition}/${tencent}/MicroMsg/${StDir}/voice2"
StorageTencentVideoDir="${StoragePartition}/${tencent}/MicroMsg/${StDir}/video"
StorageAndroidDownloadDir="${StoragePartition}/Android/data/com.tencent.mm/MicroMsg/Download"
StorageTencentDownloadDir="${StoragePartition}/${tencent}/MicroMsg/Download"
# 打包代替复制(加快备份速度)
cpBackup(){
unset newFiles
workPath="${BackupDir}/media/${2}" && mkdir -p "${workPath}"
if [[ -d "$1" ]] && [[ -n `ls "$1"` ]];then
GetFilesState=1 && cd "$1"
 if [[ $Backuped == "0" ]];then
 7za a -tzip -mx0 -mmt -r -l -- "${workPath}/${3}.zip" >> /dev/null
 [[ $? == 2 ]] && EchoYello "\n您的存储空间不足！备份中止.....\n" && RmTmpExit
 else
 find ./ -type f -newermt "$findTime" -print | sed 's/..//' | xargs -r -d "\n" 7za a -tzip -mx0 -mmt -r -l -- "${workPath}/${3}.zip" >> /dev/null
 [[ $? == 2 ]] && EchoYello "\n您的存储空间不足！备份中止.....\n" && RmTmpExit
 fi
fi ;}
echo "备份图片文件..."
unset GetFilesState
cpBackup "$DataAvatarDir" 'avatar' 'DataAvatar'
cpBackup "$DataImageDir" 'image' 'DataImage'
cpBackup "$StorageAndroidImageDir" 'image' 'AndroidImage'
cpBackup "$StorageTencentImageDir" 'image' 'TencentImage'
[[ $GetFilesState != 1 ]] && EchoYello " 获取不到图片文件！"
echo "备份语音文件..."
unset GetFilesState
cpBackup "$DataVoiceDir" 'voice' 'DataVoice'
cpBackup "$StorageAndroidVoiceDir" 'voice' 'AndroidVoice'
cpBackup "$StorageTencentVoiceDir" 'voice' 'TencentVoice'
[[ $GetFilesState != 1 ]] && EchoYello " 获取不到语音文件！"
echo "备份视频文件..."
unset GetFilesState
cpBackup "$DataVideoDir" 'video' 'DataVideo'
cpBackup "$StorageAndroidVideoDir" 'video' 'AndroidVideo'
cpBackup "$StorageTencentVideoDir" 'video' 'TencentVideo'
[[ $GetFilesState != 1 ]] && EchoYello " 获取不到视频文件！"
echo "备份下载文件..."
unset GetFilesState
cpBackup "$DataAttachmentDir" 'download' 'DataAttachment'
cpBackup "$StorageAndroidDownloadDir" 'download' 'AndroidDownload'
cpBackup "$StorageTencentDownloadDir" 'download' 'TencentDownload'
[[ $GetFilesState != 1 ]] && EchoYello " 获取不到下载文件！"
echo "全部媒体文件备份完成！！"
# 备份媒体文件 结束

# 备份跨设备恢复关键文件 开始
mkdir -p "${BackupDir}/auth"
if [[ -e "${DataPartition}/com.tencent.mm/files/KeyInfo.bin" ]];then
cp -frs "${DataPartition}/com.tencent.mm/files/KeyInfo.bin" "${BackupDir}/auth" && echo "获取跨设备恢复关键文件成功！" 
elif [[ -d "${DataPartition}/com.tencent.mm/.auth_cache" ]];then
cp -frs "${DataPartition}/com.tencent.mm/.auth_cache" "${BackupDir}/auth" && echo "获取备用跨设备恢复关键文件成功！"
else EchoYello "获取跨设备恢复关键文件失败！可能会导致数据包在其他设备上无法恢复成功！" ;fi
#备份跨设备恢复关键文件 结束

# 备份登录信息 开始
MmkvPath="${DataPartition}/com.tencent.mm/files/mmkv"
AuthCachePath="${DataPartition}/com.tencent.mm/.auth_cache"
AutoAuthPath="${DataPartition}/com.tencent.mm/MicroMsg/autoauth.cfg"
AccBin="${DataPartition}/com.tencent.mm/MicroMsg/${EnDir}/account.bin"
SystemInfoPath="${DataPartition}/com.tencent.mm/MicroMsg/systemInfo.cfg"
HostRedirectPath="${DataPartition}/com.tencent.mm/files/host/host-redirect.xml"
AuthPrefs="${DataPartition}/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml"
AppSpPath="${DataPartition}/com.tencent.mm/shared_prefs/app_brand_global_sp.xml"
CompatibleInfoPath="${DataPartition}/com.tencent.mm/MicroMsg/CompatibleInfo.cfg"
[[ -e "$AccBin" ]] && cp -frs "$AccBin" "${BackupDir}/auth"
[[ -d "$MmkvPath" ]] && cp -frs "$MmkvPath" "${BackupDir}/auth"
[[ -e "$CompatibleInfoPath" ]] && cp -frs "$CompatibleInfoPath" "${BackupDir}/auth"
[[ -d "$AuthCachePath" ]] && cp -frs "$AuthCachePath" "${BackupDir}/auth"
[[ -e "$AutoAuthPath" ]] && cp -frs "$AutoAuthPath" "${BackupDir}/auth"
[[ -e "$SystemInfoPath" ]] && cp -frs "$SystemInfoPath" "${BackupDir}/auth"
[[ -e "$AuthPrefs" ]] && cp -frs "$AuthPrefs" "${BackupDir}/auth"
[[ -e "$AppSpPath" ]] && cp -frs "$AppSpPath" "${BackupDir}/auth"
[[ -e "$HostRedirectPath" ]] && cp -frs "$HostRedirectPath" "${BackupDir}/auth" && echo -e "备份${wxId[$i]}登录状态成功！" || EchoYello "获取登录信息失败！恢复时请先登录备份的微信账号再进行恢复哦~"
# 备份登录信息 结束

# 分卷 & 打包方法 开始
SFXandZIP(){
unset SFXsize ; cd /data/media/0/WeChat_tmp/
[[ $? != 0 ]] && EchoYello "\n失败！备份中止.....\n" && RmTmpExit
duList=`echo "$1" | awk '{for(i=1;i<=NF;i++){printf "./"$i" "}{print ""}}'`
dirSize=`du -s -m -L $duList | awk '{sum += $1};END{print sum}'`
[[ $MultiPartSize != 0 ]] && [[ $StorageMode != 3 ]] && [[ $dirSize -gt $MultiPartSize ]] && SFXsize="-v${MultiPartSize}m"
7za a -tzip -mx0 -mmt -r -l ${SFXsize} -- "/data/media/0/WeChat_tmp/${backupTime}_${2}.zip" $1 >> /dev/null ; zipState=$?
[[ $zipState == 2 ]] && EchoYello "\n您的存储空间不足！备份中止.....\n" && RmTmpExit
[[ $zipState != 0 ]] && EchoYello "\n失败！备份中止.....\n" && RmTmpExit ;}
# 分卷 & 打包方法 结束

# 分卷 & 打包 & 上传 开始
echo -e "${wxId[$i]}的备份数据打包中....."
if [[ $BackupMode == 1 ]];then
SFXandZIP "${uinList[$i]}/db ${uinList[$i]}/auth" 'db'
SFXandZIP "${uinList[$i]}/media" 'media'
echo "备份数据打包完成！"
echo -e "$uploadMessage"
$uploadMode '_db' "$StrDirId"
$uploadMode '_media' "$MediaDirId"
uploadSuccessMessage
else
SFXandZIP "${uinList[$i]}/db ${uinList[$i]}/auth ${uinList[$i]}/media" 'full'
echo "备份数据打包完成！"
echo -e "$uploadMessage"
$uploadMode '_full' "$WxRootDirId"
uploadSuccessMessage ;fi
# 分卷 & 打包 & 上传 结束

done
# 备份 结束

echo -e "\n备份全部完成啦！！！\n\n"
RmTmpExit
}

[[ $OutputLogMode == 2 ]] && echo "当前备份时间 ：`date "+%Y年%m月%d日%H时%M分%S秒"`" > "${sh_path}/BackupLog.txt" && main | tee -a "${sh_path}/BackupLog.txt" || main