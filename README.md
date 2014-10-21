
## 背景说明

有时候，你可能需要用到别人的证书来帮助他们签名和打包生成一个ipa文件，我们在拿到别人导出的p12证书还有一个mobileProvision文件时，很有可能这个mobileprovision文件里面关联的签名证书信息与所给的p12证书不对应，导致编译不了，或者你可能想要拿到这个mobileProvision文件对应的App Bundle Indentifier等等，我们固然可以直接打开Xcode，导入mobileProvision，导入证书，然后修改Xcode里面的相关配置，最后build，通过build的结果来识别这两个文件是否对应，但是太麻烦了。

使用这个shell 脚本可以立刻知道所有的文件信息，以及是否对应上了。

## shell脚本的作用：

1. 可以用来对指定的p12证书和MobileProvision文件进行验证，可以知道MobileProvsion文件对应的签名证书或者推送证书是否与这个给定的证书一样。

2. 可以解析p12证书和MobileProvision配置文件的有效期，appid，team name，证书名称等基本信息。

3. 可以验证p12证书和MobileProvision文件是什么类型的？是开发者版本证书，还是release版本证书，还是签名或者推送证书。

## 依赖

这个shell 需要用到 xmlstarlet 这个免费的xml解析命令行工具，使用之前需要安装：

    apt-get install xmlstarlet

## 快速使用

直接在命令行下输入：

    ./verify.sh ming.p12 password ming.mobileprovision

## 参考文档

如果没有网络上无私的分享，这个shell脚本也不会出现，感谢所有分享者，是他们的劳动促成了这个小小的shell工具脚本

<http://stackoverflow.com/questions/9497719/how-to-extract-a-public-private-key-from-a-pkcs12-file-with-openssl-for-later-us>

<http://stackoverflow.com/questions/6712895/validate-certificate-and-provisioning-profile>

<http://stackoverflow.com/questions/21116409/is-it-possible-to-get-data-from-the-certificate-ios-application-was-signed-with>

<http://stackoverflow.com/questions/6398364/parsing-mobileprovision-files-in-bash>

<https://gist.github.com/neonichu/2147247>

<https://github.com/frjtrifork/buildscripts/blob/master/XCode/mobileprovision.sh>