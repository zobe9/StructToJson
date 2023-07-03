数据结构体与json互转工具
1、先在TJsonStrStruct.cdl定义数据
2、MakeJsonStr_Struct.bat 生成 cpp文件（目前项目生成文件目录GameEngine\Message\Db\JsonStrStructs）

接口：
3、structToString 数据结构体 -> json -> string
4、stringToStruct string -> json -> 结构体
5、toJson fromJson 用于存在旧方式json数据，参数是Json::Value

数据类型：CdlPublic.cdl
6、sequence暂不支持内嵌sequence
7、字典值也暂不支持sequence和嵌套
8、定义变量时前面添加索引，tojson fromjson时字段名为索引，否则字段名为变量名
9、用于sequence类型的，结构体名不加Struct，这样json不用通过结构体名取值，直接索引取值
10、自定义map key只支持[int,long,stirng] 格式std::map<int,defineClassInfo> xxx