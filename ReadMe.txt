���ݽṹ����json��ת����
1������TJsonStrStruct.cdl��������
2��MakeJsonStr_Struct.bat ���� cpp�ļ���Ŀǰ��Ŀ�����ļ�Ŀ¼GameEngine\Message\Db\JsonStrStructs��

�ӿڣ�
3��structToString ���ݽṹ�� -> json -> string
4��stringToStruct string -> json -> �ṹ��
5��toJson fromJson ���ڴ��ھɷ�ʽjson���ݣ�������Json::Value

�������ͣ�CdlPublic.cdl
6��sequence�ݲ�֧����Ƕsequence
7���ֵ�ֵҲ�ݲ�֧��sequence��Ƕ��
8���������ʱǰ�����������tojson fromjsonʱ�ֶ���Ϊ�����������ֶ���Ϊ������
9������sequence���͵ģ��ṹ��������Struct������json����ͨ���ṹ����ȡֵ��ֱ������ȡֵ
10���Զ���map keyֻ֧��[int,long,stirng] ��ʽstd::map<int,defineClassInfo> xxx