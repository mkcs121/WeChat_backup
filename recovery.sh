#!/system/bin/sh
#微信聊天记录恢复脚本
################### 恢复模式配置区 ###################


RecoveryMode=""
#切换 数据包的获取方式
# 1为从 [天翼云盘] 中获取，2为从 [阿里云盘] 中获取，3为从 [本地] 中获取


# 其他配置需进入交互模式后自行选择
# MT文件管理器 执行脚本后，点一下右下角的 Im 即可弹出键盘进行输入


################### 网盘配置区 ###################


username='18888888888' # 天翼云盘 账号
password='abc123' # 天翼云盘 密码


AliRefreshToken="32位英文数字"
# 阿里云盘 RefreshToken
# (此项通常不需要填写，在手机上安装并登录阿里云盘app后，脚本便会自动获取此项，用于登录阿里云盘)


DirName="我的备份" 
# 网盘中存放有数据包的文件夹名称


################### 本地配置区 ###################


recovery_path="/storage/emulated/0/WeChat_backup"
# 本地中存放有数据包的路径
# 只有在选择 [本地] 恢复模式时才需要设置此处


################### 其他自定义配置区 ###################


taken="PzefqAE8k0NJTfoCX2iNUI0YtAN5"
# 用于识别不是一定会出现的图片验证码
# 如果没有异常提示就不需要改动
# 出现验证码识别异常请尝试更改为自己账号的taken
# 账号注册链接  http://fast.95man.com/login.html
# taken获取链接  http://api.95man.com:8888/api/Http/UserTaken?user=用户名&pwd=密码&isref=0


############################################



#天翼云盘登陆部分代码参考https://github.com/Aruelius/cloud189
#by:酷安@搓澡君



############################################



# 初始化命令
[[ `whoami` != 'root' ]] && echo -e "\n脚本需要 ROOT权限 才可以正常运行哦~\n" && exit
[[ $0 == *'bin.mt.plus/temp'* ]] && echo -e "\n请不要直接在压缩包内运行脚本，先将压缩包内的所有文件解压到一个文件夹后再执行哦~\n" && exit
cd "`dirname "$0"`"
sh_path=`pwd`
sh_path=`readlink -f "$sh_path"`
sh_path=${sh_path/'/storage/emulated/'/'/data/media/'}


# 配置busybox / curl / bc 开始
[[ ! -d "${sh_path}/command" ]] && echo -e "\n 找不到脚本运行所需依赖！请尝试前往 https://czj.lanzoux.com/b0evzleqh 重新下载脚本压缩包后，将压缩包内文件解压至同一目录下~\n" && exit
BusyboxTest='mkdir awk sed head rm cp date ls cat tr md5sum sort uniq seq touch split base64 sha1sum wc mv killall'
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

# 提示用户选择 RecoveryMode 开始
rm -rf /data/media/0/WeChat_tmp && mkdir /data/media/0/WeChat_tmp && clear
[[ $RecoveryMode == "" ]] && echo -e "请选择从何网盘下载数据...\n\n1. 天翼云盘\n2. 阿里云盘\n3. 本地" && echo -e "\n请输入序号后回车进行选择....." && read RecoveryMode
while [[ $RecoveryMode != 1 ]] && [[ $RecoveryMode != 2 ]] && [[ $RecoveryMode != 3 ]];do echo -e "\033[33m\n输入错误！请重新输入！\033[0m" && read RecoveryMode ;done ;clear
# 提示用户选择 RecoveryMode 结束

# 检测错误 开始
if [[ $RecoveryMode != "3" ]];then
network_state=`curl -k -sIL -w "%{http_code}\n" -o /dev/null "http://www.baidu.com" `
[[ $network_state != "200" ]] && EchoYello "\n连接网络失败！备份中止.....\n" && RmTmpExit ;fi
checkEmpty(){ [[ $1 == "" ]] && echo -e "\n请先编辑 recovery.sh 中的 ${1} 项后再进行恢复噢~\n" && RmTmpExit ;}
[[ $RecoveryMode == "1" ]] && checkEmpty 'username' && checkEmpty 'password' ;clear
# 检测错误 结束

# 检测是否安装 双开/多开微信 开始
clear
i=0 ; for partition in `ls "/data/user/"`;do [[ -d "/data/user/${partition}/com.tencent.mm" ]] && wxPartition[$i]="$partition" && let i++ ;done
[[ -z ${wxPartition[@]} ]] && echo -e "\n您还未安装微信，请先进行安装噢~\n" && RmTmpExit
if [[ ${#wxPartition[@]} -gt 1 ]];then
echo -e "当前设备安装了 双开/多开微信 ，请选择数据的恢复位置 ：\n"
i=0 ;while [[ $i -lt ${#wxPartition[@]} ]] ;do echo "${i}. 恢复到本机 ${wxPartition[$i]}分区 的微信" ;let i++ ;done
getChoose(){
echo -e "\n请输入序号后回车进行选择.....";read choose
if [[ -z `echo $choose | grep -E '[0-9]'` ]] || [[ -z ${wxPartition[$choose]} ]];then echo "\033[33m输入错误，请重新输入！\033[0m" && getChoose;fi
}
getChoose
chosePartition=${wxPartition[$choose]}
partitionMessage="\033[36m您选择的是 ${chosePartition}分区\033[0m"
clear
else chosePartition="${wxPartition[@]}";fi
# 检测是否安装 双开/多开微信 结束

# 设置参数 开始
setParameter(){
createType="$1" ; rootDirId="$2" ; jointListType="$3" ; jsonId="$4" ; jsonName="$5" ; downloadType="$6"
}
# 设置参数 结束

# 天翼filename、fileid拼接 开始
TYjointList(){
unset $4
DirList=`curl -k -b "${sh_path}/cookie/TianYiCookie.txt" -H "accept:application/json;charset=UTF-8" "https://cloud.189.cn/api/open/file/listFiles.action?pageSize=99999999&pageNum=1&mediaType=0&folderId=${1}&iconOption=5&orderBy=createTime&descending=true" -s`
[[ $5 != 'stop' ]] && [[ `ReadJson "$DirList" 'count'` == "0" ]] && EchoYello "\n找不到恢复所需数据包！恢复中止.....\n" && RmTmpExit
tmpA=(`ReadJson "$DirList" "$2"`) ; tmpB=(`ReadJson "$DirList" "$3"`)
i=0 ;while [[ $i -lt ${#tmpA[@]} ]];do eval $4[$i]='"${tmpA[$i]} ${tmpB[$i]}"' ;let i++ ;done
}
# 天翼filename、fileid拼接 结束

# 天翼文件下载 开始
TYDownloadFiles(){
fileName=`echo "$1" | awk '{print $1}'`
fileId=`echo "$1" | awk '{print $2}'`
echo "正在下载 ${fileName} ....."
getUrl=`curl -k -b "${sh_path}/cookie/TianYiCookie.txt" -H "accept:application/json;charset=UTF-8" "https://cloud.189.cn/api/open/file/getFileDownloadUrl.action?fileId=${fileId}" -s`
downloadUrl=`ReadJson "$getUrl" 'fileDownloadUrl'`
saveFile=`curl -k -L "$downloadUrl" -o "/data/media/0/WeChat_tmp/${fileName}" --progress-bar` && State=1 || State=0
[[ $State == 0 ]] && EchoYello "\n下载失败！恢复中止.....\n\n错误返回信息如下 ： ${saveFile}" && RmTmpExit || echo "下载完成！"
}
# 天翼文件下载 结束

# 阿里filename、fileid拼接 开始
AliJointList(){
isFirst=1 ;i=0 ;unset $4 ;while [[ -n $marker ]] || [[ $isFirst == 1 ]];do
DirList=`curl -k -H "content-type:application/json;charset=UTF-8" -H "authorization:${Authorization}" -d '{"drive_id":"'$DriveId'","parent_file_id":"'$1'","limit":200,"marker":"'$marker'","all":false,"fields":"*","order_by":"created_at","order_direction":"DESC"}' "https://api.aliyundrive.com/adrive/v3/file/list" -s`
marker=`ReadJson "$DirList" 'next_marker'` ; isFirst=0
[[ $5 != 'stop' ]] && [[ -z `echo "$DirList" | grep 'file_id'` ]] && EchoYello "\n找不到恢复所需数据包！恢复中止.....\n" && echo "$DirList" && RmTmpExit
tmpA=(`ReadJson "$DirList" "$2"`) ; tmpB=(`ReadJson "$DirList" "$3"`) ; j=0
while [[ $j -lt ${#tmpA[@]} ]];do eval $4[$i]='"${tmpA[$j]} ${tmpB[$j]}"' ;let i++ j++ ;done ;done
}
# 阿里filename、fileid拼接 结束

# 阿里文件下载 开始
AliDownloadFiles(){
fileName=`echo "$1" | awk '{print $1}'`
fileId=`echo "$1" | awk '{print $2}'`
echo "正在下载 ${fileName} ....."
getUrl=`curl -k -s -H "accept:application/json, text/plain, */*" -H "content-type:application/json;charset=UTF-8" -H "authorization:${Authorization}" -d '{"drive_id":"'$DriveId'","file_id":"'$fileId'"}' "https://api.aliyundrive.com/v2/file/get_download_url"`
downloadUrl=`ReadJson "$getUrl" 'url'`
saveFile=`curl -k -H "Referer:https://www.aliyundrive.com/" "$downloadUrl" -o "/data/media/0/WeChat_tmp/${fileName}" --progress-bar` && State=1 || State=0
[[ $State == 0 ]] && EchoYello "\n下载失败！恢复中止.....\n\n错误返回信息如下 ： ${saveFile}" && RmTmpExit || echo "下载完成！"
}
# 阿里文件下载 结束

# 本地数据包名获取 开始
LocalJointList(){
unset $2 ; DirList=(`ls -t "$1"`)
[[ $5 != 'stop' ]] && [[ -z ${DirList[@]} ]] && EchoYello "\n找不到恢复所需数据包！恢复中止.....\n" && RmTmpExit
i=0 ;while [[ $i -lt ${#DirList[@]} ]];do eval $2[$i]='"${DirList[$i]}"' ;let i++ ;done
}
# 本地数据包名获取 结束

# 本地数据包获取 开始
LocalLn(){
if [[ $zipType == 0 ]];then
[[ -n `echo "$1" | grep 'db'` ]] && localDirType="文字聊天记录" || localDirType="媒体文件"
ln -fs "${recovery_path}/${WxNickname}/微信聊天记录备份(增量)/${localDirType}/${1}" "/data/media/0/WeChat_tmp/" && State=1 || State=0
[[ $State == 0 ]] && EchoYello "\n获取失败！恢复中止....." && RmTmpExit || echo "获取成功！"
else ln -fs "${recovery_path}/${WxNickname}/微信聊天记录备份(全量)/${1}" "/data/media/0/WeChat_tmp/" && State=1 || State=0
[[ $State == 0 ]] && EchoYello "\n获取失败！恢复中止....." && RmTmpExit || echo "获取成功！" ;fi
}
# 本地数据包获取 结束

# 选择恢复包类型 开始
ZipType(){
unset zipType ;clear ;echo -e "${1}\n请选择恢复模式 ：\n\n0. 从 增量数据包 中恢复微信数据\n1. 从 全量数据包 中恢复微信数据\nq. 返回"
getChoose(){
echo -e "\n请输入序号后回车进行选择.....";read zipType
if [[ $zipType == "0" ]];then ZipDate "\033[36m您选择的是 增量数据包\033[0m"
elif [[ $zipType == "1" ]];then FullMode "\033[36m您选择的是 全量数据包\033[0m"
elif [[ $zipType == "q" ]];then Nickname
else echo "\033[33m输入错误，请重新输入！\033[0m" && getChoose ;fi ;}
getChoose
}
# 选择恢复包类型 结束

# 选择需要恢复的微信号 开始
Nickname(){
unset choose ;clear ;echo -e "${partitionMessage}\n您所有账号的备份如下 ：\n"
if [[ $RecoveryMode == "1" ]] || [[ $RecoveryMode == "2" ]];then
$createType "$DirName" "$rootDirId"
UserDirId=`ReadJson "$NewDir" "$jsonId"`
$jointListType "$UserDirId" "$jsonName" "$jsonId" 'UserListArray'
else $jointListType "$recovery_path" 'UserListArray' ;fi
i=0 ;while [[ $i -lt ${#UserListArray[@]} ]];do echo "${i}. `echo "${UserListArray[$i]}" | awk '{print $1}'`" ;let i++ ;done ;echo "q. 退出"
getChoose(){
echo -e "\n请输入序号后回车进行选择.....";read choose
if [[ $choose == 'q' ]];then RmTmpExit
elif [[ -n `echo $choose | grep -E '[0-9]'` ]] && [[ -n ${UserListArray[$choose]} ]];then
WxNickname=`echo "${UserListArray[$choose]}" | awk '{print $1}'`
 if [[ $RecoveryMode == "1" ]] || [[ $RecoveryMode == "2" ]];then
 WxNicknameDir=`echo "${UserListArray[$choose]}" | awk '{print $2}'`
 $jointListType "$WxNicknameDir" "$jsonName" "$jsonId" 'NicknameListArray';fi 
ZipType "\033[36m您选择的是 ${WxNickname}\033[0m"
else echo "\033[33m输入错误，请重新输入！\033[0m" && getChoose ;fi ;}
getChoose
}
# 选择需要恢复的微信号 结束

# 从全量包中恢复 开始
FullMode(){
unset choose ;clear ;unset dbFileDate ;echo -e "${1}\n加载数据包中......\n"
if [[ $RecoveryMode == "1" ]] || [[ $RecoveryMode == "2" ]];then
$createType '微信聊天记录备份(全量)' "$WxNicknameDir" 
WxRootDirId=`ReadJson "$NewDir" "$jsonId"`
$jointListType "$WxRootDirId" "$jsonName" "$jsonId" 'WxRootDirListArray'
else $jointListType "${recovery_path}/${WxNickname}/微信聊天记录备份(全量)" 'WxRootDirListArray' ;fi
i=0 ;j=0 ;while [[ $i -lt ${#WxRootDirListArray[@]} ]];do
tmpFileDate=`echo "${WxRootDirListArray[$i]}" | awk '{print $1}' | cut -c -19 | tr '.' ':' | tr '_' ' '`
[[ -z `echo "${dbFileDate[@]}" | grep "$tmpFileDate"` ]] && dbFileDate[$j]="$tmpFileDate" && echo -e "${j}. 恢复 ${dbFileDate[$j]} 及之前的数据" && let j++ ;let i++ ;done ;echo "q. 返回"
getChoose(){
echo -e "\n请输入序号后回车进行选择.....";read choose
if [[ $choose == 'q' ]];then ZipType
elif [[ -n `echo $choose | grep -E '[0-9]'` ]] && [[ -n ${WxRootDirListArray[$choose]} ]];then
echo "开始下载数据包....."
choseTimestamp=`date -d "${dbFileDate[$choose]}" +%s`
i=0 ;while [[ $i -lt ${#WxRootDirListArray[@]} ]];do
downloadFileDate=`echo "${WxRootDirListArray[$i]}" | awk '{print $1}' | cut -c -19 | tr '.' ':' | tr '_' ' '`
fileTimestamp=`date -d "$downloadFileDate" +%s`
[[ $fileTimestamp -eq $choseTimestamp ]] && $downloadType "${WxRootDirListArray[$i]}" ;let i++ ;done
else echo "\033[33m输入错误，请重新输入！\033[0m" && getChoose ;fi ;}
getChoose
}
# 从全量包中恢复 结束

# 从增量包中恢复 开始
ZipDate(){
unset choose ;clear ;unset dbFileDate ;echo -e "${1}\n加载数据包中......\n"
if [[ $RecoveryMode == "1" ]] || [[ $RecoveryMode == "2" ]];then
$createType '微信聊天记录备份(增量)' "$WxNicknameDir" 
WxRootDirId=`ReadJson "$NewDir" "$jsonId"`
$createType '文字聊天记录' "$WxRootDirId" 
StrDirId=`ReadJson "$NewDir" "$jsonId"`
$createType '媒体文件' "$WxRootDirId" 
MediaDirId=`ReadJson "$NewDir" "$jsonId"`
$jointListType "$StrDirId" "$jsonName" "$jsonId" 'StrDirListArray'
$jointListType "$MediaDirId" "$jsonName" "$jsonId" 'MediaDirListArray' 'stop'
else $jointListType "${recovery_path}/${WxNickname}/微信聊天记录备份(增量)/文字聊天记录" 'StrDirListArray'
$jointListType "${recovery_path}/${WxNickname}/微信聊天记录备份(增量)/媒体文件" 'MediaDirListArray' ;fi
i=0 ;j=0 ;while [[ $i -lt ${#StrDirListArray[@]} ]];do
tmpFileDate=`echo "${StrDirListArray[$i]}" | awk '{print $1}' | cut -c -19 | tr '.' ':' | tr '_' ' '`
[[ -z `echo "${dbFileDate[@]}" | grep "$tmpFileDate"` ]] && dbFileDate[$j]="$tmpFileDate" && echo -e "${j}. 恢复 ${dbFileDate[$j]} 及之前的数据" && let j++ ;let i++ ;done ;echo "q. 返回"
getChoose(){
echo -e "\n请输入序号后回车进行选择.....";read choose
if [[ $choose == 'q' ]];then ZipType
elif [[ -n `echo $choose | grep -E '[0-9]'` ]] && [[ -n ${dbFileDate[$choose]} ]];then DownloadChoseZip
else echo "\033[33m输入错误，请重新输入！\033[0m" && getChoose ;fi ;}
getChoose
}
# 从增量包中恢复 结束

# 下载选择的增量包 开始
DownloadChoseZip(){
echo "开始获取数据包....."
choseTimestamp=`date -d "${dbFileDate[$choose]}" +%s`
# 获取选择的时间戳
i=0 ;while [[ $i -lt ${#StrDirListArray[@]} ]];do
downloadFileDate=`echo "${StrDirListArray[$i]}" | awk '{print $1}' | cut -c -19 | tr '.' ':' | tr '_' ' '`
fileTimestamp=`date -d "$downloadFileDate" +%s`
[[ $fileTimestamp -eq $choseTimestamp ]] && $downloadType "${StrDirListArray[$i]}" ;let i++ ;done
# 下载 db 数据包
if [[ -n ${MediaDirListArray[@]} ]];then
i=0 ;while [[ $i -lt ${#MediaDirListArray[@]} ]];do
downloadFileDate=`echo "${MediaDirListArray[$i]}" | awk '{print $1}' | cut -c -19 | tr '.' ':' | tr '_' ' '`
fileTimestamp=`date -d "$downloadFileDate" +%s`
[[ $fileTimestamp -le $choseTimestamp ]] && $downloadType "${MediaDirListArray[$i]}" ;let i++ ;done
else EchoYello "\n媒体数据包不存在！可能会导致聊天记录中的图片、语音、视频和下载文件恢复失败！\n";fi
#下载 media 数据包
}
# 下载选择的增量包 结束

# 解压 开始
unZip(){
zipFiles=`ls /data/media/0/WeChat_tmp/ | grep -E 'zip$|.001'`
if [[ -n $zipFiles ]];then echo -e "\n解压数据包中....."
for zipFile in $zipFiles ;do
cd /data/media/0/WeChat_tmp/ && 7za x -mmt -aou -r $zipFile >> /dev/null
[[ $? != 0 ]] && EchoYello "\n解压失败！恢复中止.....\n" && RmTmpExit ;done
echo "解压完成！"
cd /data/media/0/WeChat_tmp/ && ls /data/media/0/WeChat_tmp/ | grep '.zip' | xargs rm -rf
else EchoYello "\n找不到可以恢复的数据包文件！恢复中止.....\n" && RmTmpExit ;fi
}
# 解压 结束

# 传参 开始
if [[ $RecoveryMode == "1" ]];then
CookieOrPwd
setParameter 'TYCreateDir' '-11' 'TYjointList' 'id' 'name' 'TYDownloadFiles'
elif [[ ${RecoveryMode} == "2" ]];then
AliLogin
setParameter 'AliCreateDir' 'root' 'AliJointList' 'file_id' 'name' 'AliDownloadFiles'
elif [[ ${RecoveryMode} == "3" ]];then
recovery_path=`readlink -f "$recovery_path" | sed 's:/storage/emulated/:/data/media/:g'`
setParameter '' '' 'LocalJointList' '' '' 'LocalLn'
fi
# 传参 结束

# 获取数据包 开始
Nickname
# 获取数据包 结束

if [[ $zipType != "q" ]] && [[ $choose != 'q' ]];then

# 解压 开始
clear
dividingLine="\033[36m----------------------------------------\033[0m"
echo -e "\n${dividingLine}\n\n [ 恢复模式 ] \n\n${dividingLine}\n"
unZip
# 解压 结束

# 强制停止微信 开始
echo -e "\n开始恢复....."
am force-stop --user $chosePartition com.tencent.mm >> /dev/null 2>&1
backupTime=$(date "+%Y-%m-%d_%H:%M:%S")
# 强制停止微信 结束

# 获取微信版本号 开始
wechat_versioncode=`pm dump com.tencent.mm | grep "versionCode" | awk '{print $1}' | awk -F "=" '{print $2}'`
GetWechatV(){
if [[ -z `echo $wechat_versioncode | grep -E '[0-9]{4}'` ]];then
EchoYello "\n获取微信版本号失败，请尝试手动输入.....\n(微信版本小于或等于7.0.15请输入数字7后回车，大于7.0.15请输入数字8后回车)"
read InputWechatV
[[ $InputWechatV == 7 ]] && wechat_versioncode=1600
[[ $InputWechatV == 8 ]] && wechat_versioncode=1800
[[ $InputWechatV != 7 ]] && [[ $InputWechatV != 8 ]] && echo "\033[33m输入错误，请重新输入！\033[0m" && GetWechatV ;fi ;}
GetWechatV
# 获取微信版本号 结束

# 初始化路径 开始
bakUin=`ls -1 -t -F "/data/media/0/WeChat_tmp" | grep -E '[@/]' | sed -n '1p' | awk '{sub(/.{1}$/,"")}1'`
bakDBDir="/data/media/0/WeChat_tmp/${bakUin}/db"
bakAuthDir="/data/media/0/WeChat_tmp/${bakUin}/auth"
bakMediaDir="/data/media/0/WeChat_tmp/${bakUin}/media"
SnsFile="${bakDBDir}/SnsMicroMsg.db"
IndexFile="${bakDBDir}/WxFileIndex.db"
EnDir=`echo -n "mm${bakUin}" | md5sum | awk '{print $1}'`
wxDataPath="/data/user/${chosePartition}/com.tencent.mm"
wxFilesDir="${wxDataPath}/files"
DataMicroMsgDir="${wxDataPath}/MicroMsg"
DataEnPath="${DataMicroMsgDir}/${EnDir}"
DataAccBin="${DataEnPath}/account.bin"
tencent="tencent" && [[ ! -d "/data/media/${chosePartition}/${tencent}"  ]] && tencent="Tencent"
[[ $wechat_versioncode -gt 1681 ]] && StMicroMsgDir="/data/media/${chosePartition}/Android/data/com.tencent.mm/MicroMsg" || StMicroMsgDir="/data/media/${chosePartition}/${tencent}/MicroMsg"
[[ ! -d "$StMicroMsgDir" ]] && mkdir -p "$StMicroMsgDir"
# 初始化路径 结束

# 恢复 DB 开始
echo "恢复文字聊天记录中....."
[[ ! -d "$DataEnPath" ]] && mkdir -p "$DataEnPath" && chmod 0777 "/data/user/${chosePartition}/com.tencent.mm/MicroMsg" "$DataEnPath"
[[ -e "$SnsFile" ]] && rm -rf ${DataEnPath}/SnsMicroMsg* && cp -rf "$SnsFile" "$DataEnPath" && chmod 0777 "${DataEnPath}/SnsMicroMsg.db"
[[ -e "$IndexFile" ]] && rm -rf ${DataEnPath}/WxFileIndex* && cp -rf "$DocFile" "$DataEnPath" && chmod 0777 "${DataEnPath}/WxFileIndex.db"
rm -rf ${DataEnPath}/EnMicroMsg* && cp -rf ${bakDBDir}/EnMicroMsg* "$DataEnPath" && chmod 0777 ${DataEnPath}/EnMicroMsg* && State=1 || State=0
[[ $State == 0 ]] && EchoYello "\n失败！恢复中止.....\n" && RmTmpExit || echo "恢复文字聊天记录完成！"
# 恢复 DB 结束

# 获取 微信媒体文件夹名 开始
if [[ $wechat_versioncode -gt 1445 ]];then
 if [[ -e "${DataEnPath}/account.mapping" ]];then
 StDir=`cat "${DataEnPath}/account.mapping"`
 elif [[ -e "$DataAccBin" ]];then
 uin16=`echo -n "$bakUin" | xxd -p`
 AccountBin16=`xxd -p -l 4096 "$DataAccBin"`
 AccountBin16="${AccountBin16}${uin16}"
 StDir=`echo -n "$AccountBin16" | xxd -p -r | md5sum | awk '{print $1}'`
 else
  if [[ -e "${bakAuthDir}/account.bin" ]];then
  cp -rf "${bakAuthDir}/account.bin" "$DataEnPath"
  chmod 0777 "$DataAccBin"
  uin16=`echo -n "$bakUin" | xxd -p`
  AccountBin16=`xxd -p -l 4096 "$DataAccBin"`
  AccountBin16="${AccountBin16}${uin16}"
  StDir=`echo -n "$AccountBin16" | xxd -p -r | md5sum | awk '{print $1}'`
  else touch "$DataAccBin" && chmod 0777 "$DataAccBin" && StDir="$EnDir" ;fi;fi
else StDir="$EnDir" ;fi
wxStDir="${StMicroMsgDir}/${StDir}"
# 获取 微信媒体文件夹名 结束

# 恢复 媒体文件 开始
echo "恢复媒体文件中....."
reMediaFiles(){
unset State
[[ $3 != '' ]] && echo "恢复${3}文件中..."
bakWorkPath="${bakMediaDir}/${1}"
allBakZip=`ls "$bakWorkPath" | grep '.zip'`
if [[ -n "$allBakZip" ]];then
[[ ! -d "$2" ]] && mkdir -p "$2"
for bakZip in $allBakZip ;do
cd "$bakWorkPath" && 7za x -mmt -aoa -r $bakZip -o"$2" >> /dev/null || State=0 ;done ;fi
[[ $3 == '' ]] && chmod -R 0777 "$2"
[[ $3 != '' ]] && [[ $State == 0 ]] && EchoYello "恢复${3}文件失败！"
}
reMediaFiles 'avatar' "${DataEnPath}/avatar" '头像'
if [[ $wechat_versioncode -ge 2240 ]];then
reMediaFiles 'image' "${DataEnPath}/image2" '图片'
reMediaFiles 'voice' "${DataEnPath}/voice2" '语音'
reMediaFiles 'video' "${DataEnPath}/video" '视频'
reMediaFiles 'download' "${DataEnPath}/attachment" '附件(下载)'
chmod -R 0777 "${DataEnPath%/*}"
else
reMediaFiles 'image' "${StMicroMsgDir}/${StDir}/image2" '图片'
reMediaFiles 'voice' "${StMicroMsgDir}/${StDir}/voice2" '语音'
reMediaFiles 'video' "${StMicroMsgDir}/${StDir}/video" '视频'
reMediaFiles 'download' "${StMicroMsgDir}/Download" '下载'
chmod -R 0777 "${StMicroMsgDir%/*}";fi
echo "媒体文件恢复完成！！"
# 恢复 媒体文件 结束

# 恢复 跨设备恢复关键文件 开始
if [[ -e "${bakAuthDir}/KeyInfo.bin" ]];then
[[ ! -d "$wxFilesDir" ]] && mkdir -p "$wxFilesDir" && chmod 0777 "$wxFilesDir"
cp -rf "${bakAuthDir}/KeyInfo.bin" "$wxFilesDir" && chmod 0777 "${wxFilesDir}/KeyInfo.bin" && State=1 || State=0
elif [[ -d "${bakAuthDir}/.auth_cache" ]];then
cp -rf "${bakAuthDir}/.auth_cache" "$wxDataPath" && chmod -R 0777 "${wxDataPath}/.auth_cache" && State=1 || State=0 ;fi
[[ $State == 0 ]] && EchoYello "失败！若当前是在非原备份设备上恢复，有可能会导致恢复失败！" || echo "恢复跨设备恢复关键文件成功！"
# 恢复 跨设备恢复关键文件 结束

# 恢复 登录信息 开始
if [[ -d "${bakAuthDir}/.auth_cache" ]] && [[ -e "${bakAuthDir}/host-redirect.xml" ]] && [[ -e "${bakAuthDir}/systemInfo.cfg" ]] && [[ -e "${bakAuthDir}/autoauth.cfg" ]] && [[ -e "${bakAuthDir}/auth_info_key_prefs.xml" ]];then
unset State
cpAuth(){
rm -rf "${2}/${1}"
[[ ! -d "$2" ]] && mkdir -p "$2" && chmod 0777 "$2"
cp -rf "${bakAuthDir}/${1}" "$2" && chmod -R $3 "${2}/${1}" || State=0 ;}
cpAuth 'mmkv' "$wxFilesDir" '0777'
cpAuth '.auth_cache' "$wxDataPath" '0777'
cpAuth 'host-redirect.xml' "${wxFilesDir}/host" '0777'
cpAuth 'systemInfo.cfg' "$DataMicroMsgDir" '0777'
cpAuth 'autoauth.cfg' "$DataMicroMsgDir" '0777'
cpAuth 'auth_info_key_prefs.xml' "${wxDataPath}/shared_prefs" '0777'
[[ -e "${bakAuthDir}/CompatibleInfo.cfg" ]] && cpAuth 'CompatibleInfo.cfg' "$DataMicroMsgDir" '0777'
[[ $State == 0 ]] && EchoYello "失败！恢复完成后若微信未登录请自行登录噢~" || echo "恢复此微信账号登录状态成功！" ;fi
# 恢复 登录信息 结束

# 设置安全上下文 开始
SecurityContext=`/system/bin/ls -dZ "$wxDataPath" | awk '{print $1}'`
chcon -R $SecurityContext "$wxDataPath"
[[ $? != 0 ]] && EchoYello "设置安全上下文失败！可能会导致微信无法正常运行......"
# 设置安全上下文 结束

# 设置权限 开始
pm grant --user $chosePartition com.tencent.mm android.permission.READ_EXTERNAL_STORAGE android.permission.WRITE_EXTERNAL_STORAGE android.permission.READ_PHONE_STATE
# 设置权限 结束

echo -e "\n\n${dividingLine}\n\n\n恢复全部完成啦！！！\n\n" ;fi
RmTmpExit