#!/bin/bash

SystemVersion=`uname`

#参考文档：
# http://stackoverflow.com/questions/9497719/how-to-extract-a-public-private-key-from-a-pkcs12-file-with-openssl-for-later-us
# http://stackoverflow.com/questions/6712895/validate-certificate-and-provisioning-profile
# http://stackoverflow.com/questions/21116409/is-it-possible-to-get-data-from-the-certificate-ios-application-was-signed-with
# http://stackoverflow.com/questions/6398364/parsing-mobileprovision-files-in-bash
# https://gist.github.com/neonichu/2147247
# https://github.com/frjtrifork/buildscripts/blob/master/XCode/mobileprovision.sh

# 用户使用说明
# 
# 本脚本支持Linux、Mac os ，在 Kali Linux 和 Mac osx 10.9 下测试成功
#
# 本脚本在Linux 下需要用到 xmlstarlet 这个免费的xml解析命令工具
# 安装xmlstarlet：
# apt-get install xmlstarlet
#
# 使用说明：
# 有三个参数，第一个是p12文件所在的路径；第二个是p12文件的导入密码；第三个是mobileprovision文件所在的路径
# 例子：
# ./ios_verify2.sh ming.p12 mdby2013 ming.mobileprovision


# 从p12文件，获取appid、证书的类型、证书开通的服务、是否有效
#
# 输出信息 1：
# MAC verified OK
# subject= /UID=com.mdby.motan2.testPush/CN=Apple Development IOS Push Services: com.mdby.motan2.testPush/OU=KZV5N634G4/C=CN
#
# 输出信息 2：
# MAC verified OK
# subject= /UID=ALAS2KK6YR/CN=iPhone Developer: xubin xu (X6CPZ4FK2R)/OU=KZV5N634G4/O=Guangzhou Mu Debao far Network Technology Co. Ltd/C=CN
# 
# "Verify failure" 出现类似字样，验证不正确
#
echo ---------------------------
echo ---------------------------
echo ---------------------------
echo "------------------------------------------解析p12证书----------------------------------------------------"
#openssl pkcs12 -in "$1" -nodes -passin pass:"$2" | openssl x509 -noout -subject

#获取UID的值
APPUID=`openssl pkcs12 -in "$1" -nodes -passin pass:"$2" | openssl x509 -noout -subject | sed 's/\(.*\)\/UID=\(.*\)\/CN=\(.*\)/\2/g'`
echo "p12证书UID = $APPUID" 

PushProductionCertification="Apple Production IOS Push Services"
PushDevelopmentCertification="Apple Development IOS Push Services"
IphoneProductionCertification="iPhone Distribution"
IphoneDevelopmentCertification="iPhone Developer"
CertificationName=`openssl pkcs12 -in "$1" -nodes -passin pass:"$2" | openssl x509 -noout -subject | \
sed 's/\(.*\)\/CN=\(.*\)\/O\(.*\)/\2/g'`

if [[ "$CertificationName" =~ ^"$PushProductionCertification" ]] ; then
	echo "该 p12 是发布版本的推送证书。。。"
elif [[ "$CertificationName" == *"$PushDevelopmentCertification"* ]] ; then
	echo "该 p12 是开发者版本的推送证书，不能用来线上推送！！！！"
elif [[ "$CertificationName" =~ ^"$IphoneProductionCertification" ]] ; then
	echo "该 p12 是发布版本的签名证书。。。"
elif [[ "$CertificationName" == *"$IphoneDevelopmentCertification"* ]] ; then
	echo "该 p12 是开发者版本的签名证书，不能用来线上打包！！！！"
fi

#打印证书有效期
EndDate=`openssl pkcs12 -in "$1" -nodes -passin pass:"$2" | openssl x509 -noout -enddate | cut -b 10-`
if [[ "$SystemVersion" == *Darwin* ]]; then
	#mac系统
	LocalEndDateString=`date -jv "$EndDate" +"%Y-%m-%d %T"`
	LocalEndDate=`date -jv "$EndDate" +%s`
	echo "p12证书有效期：$EndDate" 
else
	#linux 系统
	LocalEndDateString=`date -d "$EndDate" +"%Y-%m-%d %T"`
	LocalEndDate=`date -d "$EndDate" +"%s"`
	echo "p12证书有效期：$LocalEndDateString" 
fi

NowDate=`date +"%s"`
if [[ $NowDate -gt $LocalEndDate ]]; then
	echo "！！！！！！警告！！！！！！"
	echo "该p12证书已经过期"
fi

echo ---------------------------
echo ---------------------------
echo ---------------------------
echo "------------------------------解析mobileprovision配置文件---------------------------------------------"

if [[ "$SystemVersion" == *Darwin* ]]; then
	#mac系统
	ProvisionedDevices=`/usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices:0' /dev/stdin <<< $(security cms -D -i "$3")`
	ProvisionUUID=`/usr/libexec/PlistBuddy -c 'Print :UUID:' /dev/stdin <<< $(security cms -D -i "$3")`
	ApplicationIdentifier=`/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< $(security cms -D -i "$3")`
	ProvisionExpirationDate=`/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' /dev/stdin <<< $(security cms -D -i "$3")`
else
	#linux 系统
	#判断证书是什么类型的
	ProvisionedDevices=`openssl smime -inform der -verify -noverify -in "$3" | \
	xmlstarlet sel -t -v "/plist/dict/key[. = 'ProvisionedDevices']/following-sibling::array[1]/string[1]"`
	ProvisionUUID=`openssl smime -inform der -verify -noverify -in "$3" | \
	xmlstarlet sel -t -v "/plist/dict/key[. = 'UUID']/following-sibling::string[1]"`
	ApplicationIdentifier=`openssl smime -inform der -verify -noverify -in "$3" | \
	xmlstarlet sel -t -v "/plist/dict/key[. = 'Entitlements']/following-sibling::dict[1]/key[. = 'application-identifier']/following-sibling::string[1]"`
	ProvisionExpirationDate=`openssl smime -inform der -verify -noverify -in "$3" | \
	xmlstarlet sel -t -v "/plist/dict/key[. = 'ExpirationDate']/following-sibling::date[1]"`
fi

if [ "$ProvisionedDevices" = "" ] ; then
	echo "该 mobileprovision 是 发布版应用。。。。"
else
	echo "该 mobileprovision 是 Ad Hud 应用 或者是 开发者版应用！！！！！"
fi
echo "MobileProvision UUID =  $ProvisionUUID"
echo "AID 是 $ApplicationIdentifier"
echo "MobileProvision 过期时间： $ProvisionExpirationDate"


echo ---------------------------
echo ---------------------------
echo ---------------------------
echo "------------------------------判断p12, mobileprovision 是否对应-------------------------------------"

if [[ "$SystemVersion" == *Darwin* ]]; then
	#mac系统
	#end=`grep -n --binary-files=text '</plist>' "$3"|cut -d: -f-1`
 
	#MobileProvisionCertificateName=`sed -n "2, ${end}p" "$3"|xpath '//data' 2>/dev/null|sed -e '1d' -e '$d'|base64 -D| \
	#openssl x509 -subject -inform der|head -n 1 | sed 's/\(.*\)\/CN=\(.*\)\/OU=\(.*\)/\2/g'`

	#使用xml
	MobileProvisionCertificateName=`security cms -D -i "$3" | \
	xml sel -t -v "/plist/dict/key[. = 'DeveloperCertificates']/following-sibling::array[1]/data[1]" | \
	awk '{print $1}' | sed '/^$/d' | base64 -D | openssl x509 -subject -inform der | head -n 1 | sed 's/\(.*\)\/CN=\(.*\)\/O\(.*\)/\2/g'`
else
	#linux 系统
	MobileProvisionCertificateName=`openssl smime -inform der -verify -noverify -in "$3" | \
	xmlstarlet sel -t -v "/plist/dict/key[. = 'DeveloperCertificates']/following-sibling::array[1]/data[1]" | \
	awk '{print $1}' | sed '/^$/d' | base64 -d | openssl x509 -subject -inform der | head -n 1 | \
	sed 's/\(.*\)\/CN=\(.*\)\/OU=\(.*\)/\2/g'`

fi

#注意，echo 变量中不支持多个空格，需要把变量用””包围
echo "p12证书名称为 = $CertificationName" 
echo "mp证书名称为  = $MobileProvisionCertificateName" 

if [ "$CertificationName" = "$MobileProvisionCertificateName" ] ; then 
	echo "恭喜。。。"
	echo "p12证书和mobileprovision对应的证书一致。。。。。"
else
	echo "错误！！！"
	echo "p12证书和mobileprovision对应的证书不一致！！！！！"
fi