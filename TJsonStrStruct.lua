local toJsonStruct = {}

--数据默认值
local DefaultValue = 
{
	["String"] = '"' .. '"',
	["Bool"] = "false",
}
--
local ParamJsonType = 
{
	--json type, value to json type, json to value type
	["int"] = {"Int"},
	["long"] = {"Double","(double)", "(long64_t)"},
	["short"] = {"Int", "(int)", "(short)"},
	["byte"] = {"Int", "(int)", "(byte)"},
	["bool"] = {"Bool"},
	["string"] = {"String"},
	["float"] = {"Double", "(double)", "(float)"},
	["date"] = {"Double","(double)", "(long64_t)"},
	["double"] = {"Double"},
	["SeqBool"] = {"Bool"},
    ["SeqByte"] = {"Int", "(int)", "(byte)"},
    ["SeqShort"] = {"Int", "(int)", "(short)"},
    ["SeqInt"] = {"Int"},
    ["SeqFloat"] = {"Double", "(double)", "(float)"},
    ["SeqDouble"] = {"Double"},
    ["SeqLong"] = {"Double","(double)", "(long64_t)"},
    ["SeqString"] = {"String"},
    ["DictIntInt"] = {{"Int"},{"Int"}},
	["DictIntStr"] = {{"Int"},{"String"}},
	["DictStrInt"] = {{"String"},{"Int"}},
	["DictIntBool"] = {{"Int"},{"Bool"}},
	["DictIntLong"] = {{"Int"},{"Double","(double)", "(long64_t)"}},
	["DictLongInt"] = {{"Double",nil, "(long64_t)"}, {"Int"}},
	["DictLongStr"] = {{"Double","(double)", "(long64_t)"}, {"String"}},
	["DictLongLong"] = {{"Double","(double)", "(long64_t)"}, {"Double","(double)", "(long64_t)"}},
	["DictShortInt"] = {{"Int", "(int)", "(short)"},{"Int"}},
}

local CommonSeqType = 
{
    ["SeqBool"] = true,
    ["SeqByte"] = true,
    ["SeqShort"] = true,
    ["SeqInt"] = true,
    ["SeqFloat"] = true,
    ["SeqDouble"] = true,
    ["SeqLong"] = true,
    ["SeqString"] = true,
}

local ParamCppType = 
{
	["int"] = "int",
	["long"] = "long64_t",
	["string"] = "std::string",
	["date"] = "cdf::CDateTime",
}

local DiyMapKeyType =
{
	["int"] = "int",
	["long"] = "long64_t",
	["string"] = "std::string",
}

local rootDir = "../../../../../Server/GameEngine/Message/Db/JsonStrStructs"

function toJsonStruct.loadFile()
	local file = io.open("./TJsonStrStruct.cdl", "r+")
	io.input(file)
	
	local structEntitys = {}
	local structIndexs = {}
	local line = file:read()
	local curStructName = nil
	local checkParamNames = {}
	local checkParamIndex = {}
	while line do
		local ret = false
		if string.match(line, "{") or string.match(line, "}") or string.len(string.gsub(line, "%s", "")) == 0 then
			ret = true
		end
		if not ret then
			string.gsub(line, "struct (%w+)", function(p) 
				ret = true
				curStructName = p
				structEntitys[p] = {}
				checkParamNames = {}
				checkParamIndex = {}
				table.insert(structIndexs, p)
			end)
		end
		if curStructName then
			if not ret then
				string.gsub(line, "(%d+) (%w+) (%w+);", function(idx, t, p) 
					if checkParamIndex[idx] then
						error(string.format("struct:[%s] index:[%s] is exist", curStructName, idx))
					end
					if checkParamNames[p] then
						error(string.format("struct:[%s] param:[%s] is exist", curStructName, p))
					end
					checkParamIndex[idx] = idx
					checkParamNames[p] = p
					ret = true
					local isDict = string.sub(t, 1, 4) == "Dict"
					table.insert(structEntitys[curStructName], {index = idx, type = t, param = p, commonSeq = CommonSeqType[t], isDict = isDict})
				end)
			end

			if not ret then
				string.gsub(line, "(%w+) (%w+);", function(t, p) 
					if checkParamNames[p] then
						error(string.format("struct:[%s] param:[%s] is exist", curStructName, p))
					end
					checkParamNames[p] = p
					ret = true
					local isDict = string.sub(t, 1, 4) == "Dict"
					table.insert(structEntitys[curStructName], {index = nil, type = t, param = p, commonSeq = CommonSeqType[t], isDict = isDict})
				end)
			end

			if not ret then
				string.gsub(line, "(%d+) sequence%<(%w+)%> (%w+);", function(idx, t, p) 
					if checkParamIndex[idx] then
						error(string.format("struct:[%s] index:[%s] is exist", curStructName, idx))
					end
					if checkParamNames[p] then
						error(string.format("struct:[%s] param:[%s] is exist", curStructName, p))
					end

					if not ParamJsonType[t] and not structEntitys[t] then
						error(string.format("struct:%s no define", t))
					end

					checkParamIndex[idx] = idx
					checkParamNames[p] = p
					ret = true
					table.insert(structEntitys[curStructName], {index = idx, type = t, param = p, sequence = true})
				end)
			end

			if not ret then
				string.gsub(line, "sequence%<(%w+)%> (%w+);", function(t, p) 
					if checkParamNames[p] then
						error(string.format("param:%s is exist", p))
					end

					if not ParamJsonType[t] and not structEntitys[t] then
						error(string.format("struct:%s no define", t))
					end

					checkParamNames[p] = p
					ret = true
					table.insert(structEntitys[curStructName], {index = nil, type = t, param = p, sequence = true})
				end)
			end

			if not ret then
				string.gsub(line, "(%d+) std::map%<(%w+),(%w+)%> (%w+);", function(idx, k, v, p) 
					if checkParamIndex[idx] then
						error(string.format("struct:[%s] index:[%s] is exist", curStructName, idx))
					end
					if checkParamNames[p] then
						error(string.format("struct:[%s] param:[%s] is exist", curStructName, p))
					end

					if not DiyMapKeyType[k] then
						error(string.format("map key only [int,long,string], not include: %s", k))
					end

					if not ParamJsonType[v] and not structEntitys[v] then
						error(string.format("struct:%s no define", v))
					end

					checkParamIndex[idx] = idx
					checkParamNames[p] = p
					ret = true
					table.insert(structEntitys[curStructName], {index = idx, key = k, value = v, param = p, diyMap = true})
				end)
			end

			if not ret then
				string.gsub(line, "std::map%<(%w+),(%w+)%> (%w+);", function(k, v, p) 
					if checkParamNames[p] then
						error(string.format("param:%s is exist", p))
					end

					if not ParamJsonType[v] and not structEntitys[v] then
						error(string.format("struct:%s no define", v))
					end

					if not DiyMapKeyType[k] then
						error(string.format("map key only [int,long,string], not include: %s", k))
					end

					checkParamNames[p] = p
					ret = true
					table.insert(structEntitys[curStructName], {index = nil, key = k, value = v, param = p, diyMap = true})
				end)
			end

			if not ret then
				error(string.format("syntax error: %s", line))
			end
		end
		line = file:read()
	end
	io.close(file)
	return structIndexs, structEntitys
end

function toJsonStruct.makeHead()
	local structIndexs, structEntitys = toJsonStruct.loadFile()
	local file = io.open(rootDir .. "/TJsonStrStruct.h", "w+")
	io.output(file)
	file:write("#ifndef __TJsonStrStruct_h__")
	file:write("\n")
	file:write("#define __TJsonStrStruct_h__")
	file:write("\n")

	file:write(string.format("#include %sframework/json/json.h%s", '"', '"'))
	file:write("\n")
	file:write(string.format("#include %sMessage/Public/CdlPublic.h%s", '"', '"'))
	file:write("\n")
	file:write("\n")

	file:write("namespace Message")
	file:write("\n")
	file:write("{")
	file:write("\n")
	file:write("	namespace Db")
	file:write("\n")
	file:write("	{")
	file:write("\n")
	file:write("		namespace JsonStructTables")
	file:write("\n")
	file:write("		{")
	file:write("\n")
	for _, structName in ipairs(structIndexs) do
		local structEntity = structEntitys[structName]
		file:write(string.format("			struct %s", structName))
		file:write("\n")
		file:write("			{")
		file:write("\n")
		for _, info in ipairs(structEntity) do
			if not info.sequence then
				if info.commonSeq or info.isDict then
					file:write(string.format("				Message::Public::%s %s;", ParamCppType[info.type] or info.type, info.param))
				elseif info.diyMap then
					file:write(string.format("				std::map<%s,%s> %s;", DiyMapKeyType[info.key], info.value, info.param))
				else
					file:write(string.format("				%s %s;", ParamCppType[info.type] or info.type, info.param))
				end
			else
				file:write(string.format("				std::vector<%s> %s;", ParamCppType[info.type] or info.type, info.param))
			end
			file:write("\n")
		end

		file:write("\n")
		file:write(string.format("				%s();", structName))
		file:write("\n")
		file:write("				void stringToStruct(const std::string& jsonStr);")
		file:write("\n")
		file:write("				void structToString(std::string& jsonStr);")
		file:write("\n")
		file:write("				void toJson(Json::Value& _js) const;")
		file:write("\n")
		file:write("				void fromJson(const Json::Value& _js);")
		file:write("\n")
		file:write("\n")
		file:write("			private:")
		file:write("\n")
		file:write("				void _toJson(Json::Value& _js) const;")
		file:write("\n")
		file:write("				void _fromJson(const Json::Value& _js);")
		file:write("\n")

		file:write("			};")
		file:write("\n")
		file:write("\n")
	end

	file:write("		}")
	file:write("\n")
	file:write("	}")
	file:write("\n")
	file:write("}")
	file:write("\n")
	

	file:write("#endif")
	file:write("\n")
	io.close(file)
end

function toJsonStruct.includeHeadFile(file, headName)
	file:write(string.format("#include %s%s.h%s", '"', headName, '"'))
	file:write("\n")
end

function toJsonStruct.makeCpp()
	local structIndexs, structEntitys = toJsonStruct.loadFile()
	local file = io.open(rootDir .. "/TJsonStrStruct.cpp", "w+")
	io.output(file)
	-- file:write(string.format("#include %sstdafx.h%s", '"', '"'))
	-- file:write("\n")
	toJsonStruct.includeHeadFile(file, "TJsonStrStruct")
	toJsonStruct.includeHeadFile(file, "framework/util/typetransform")
	toJsonStruct.includeHeadFile(file, "framework/util/stringfun")
	toJsonStruct.includeHeadFile(file, "Common/Public/Util")
	file:write("\n")
	file:write("using namespace Message::Public;")
	file:write("\n")
	file:write("using namespace Message::Db::JsonStructTables;")
	file:write("\n")
	file:write("\n")

	for _, structName in ipairs(structIndexs) do
		local structEntity = structEntitys[structName]
		file:write("\n")
		file:write(string.format("%s::%s()", structName, structName))
		file:write("\n")
		local isFirst = true
		for _, info in ipairs(structEntity) do
			if isFirst then
				file:write(string.format(":%s()", info.param))
				isFirst = false
			else
				file:write(string.format(",%s()", info.param))
			end
			file:write("\n")
		end
		file:write("{")
		file:write("\n")
		file:write("\n")
		file:write("}")
		file:write("\n")


		file:write("\n")
		file:write(string.format("void %s::stringToStruct(const std::string& jsonStr)", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		file:write("	Json::Value js;")
		file:write("\n")
		file:write("	js.parse(jsonStr);")
		file:write("\n")
		file:write("	_fromJson(js);")
		file:write("\n")
		file:write("}")
		file:write("\n")

		file:write("\n")
		file:write(string.format("void %s::structToString(std::string& jsonStr)", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		file:write("	Json::Value js;")
		file:write("\n")
		file:write("	_toJson(js);")
		file:write("\n")
		file:write("	Json::Value tmpJs;")
		file:write("\n")
		file:write("	Common::CUtil::cutJson(js, tmpJs);")
		file:write("\n")
		file:write("	jsonStr = tmpJs.toFastString();")
		file:write("\n")
		file:write("}")
		file:write("\n")

		file:write(string.format("void %s::toJson(Json::Value& _js) const", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		file:write("	_toJson(_js);")
		file:write("\n")
		file:write("}")
		file:write("\n")
		file:write("\n")

		file:write(string.format("void %s::fromJson(const Json::Value& _js)", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		file:write("	_fromJson(_js);")
		file:write("\n")
		file:write("}")
		file:write("\n")
		file:write("\n")

		file:write(string.format("void %s::_toJson(Json::Value& _js) const", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		if string.match(structName, "Struct") then
			file:write(string.format("	Json::Value &tmpJs = _js[%s%s%s];", '"', structName, '"'))
		else
			file:write("	Json::Value &tmpJs = _js;")
		end
		file:write("\n")
		local key
		for _, info in ipairs(structEntity) do
			key = info.index or info.param
			local pjt = ParamJsonType[info.type]
			local valueJsonType = nil
			local valueToJsonType = nil
			local jsonToValueType = nil
			local keyJsonType = nil
			local keyToJsonType = nil
			local jsonTokeyType = nil

			if pjt then
				if not info.isDict then
					valueJsonType = pjt[1] or ""
					valueToJsonType = pjt[2] or ""
					jsonToValueType = pjt[3] or ""
				else
					keyJsonType = pjt[1][1] or ""
					keyToJsonType = pjt[1][2] or ""
					jsonTokeyType = pjt[1][3] or ""

					valueJsonType = pjt[2][1] or ""
					valueToJsonType = pjt[2][2] or ""
					jsonToValueType = pjt[2][3] or ""
				end
			end

			if info.diyMap then
				file:write(string.format("	for(const auto& elem : %s)", info.param))
				file:write("\n")
				file:write("	{")
				file:write("\n")
				if info.key == "string" then
					file:write(string.format("		 elem.second.toJson(tmpJs[%s%s%s][elem.first]);", '"', key, '"'))
				else
					file:write("		std::string key = ToStr(elem.first);")
					file:write("\n")
					file:write(string.format("		 elem.second.toJson(tmpJs[%s%s%s][key]);", '"', key, '"'))
				end
				file:write("\n")
				file:write("	}")
			elseif not info.sequence and not info.commonSeq and not info.isDict then
				file:write(string.format("	if(%s != %s)", DefaultValue[valueJsonType] or 0, info.param))
				file:write("\n")
				file:write("	{")
				file:write("\n")
				if info.type == "date" then
					file:write(string.format("		tmpJs[%s%s%s] = Json::Value(%s%s.getTotalMill());", '"', key, '"', valueToJsonType, info.param))
				else
					file:write(string.format("		tmpJs[%s%s%s] = Json::Value(%s%s);", '"', key, '"', valueToJsonType, info.param))
				end
				file:write("\n")
				file:write("	}")
			else
				file:write("	{")
				file:write("\n")
				-- file:write(string.format("		int size = (int)%s.size();", info.param))
				-- file:write("\n")
				-- file:write(string.format("		tmpJs[%s%s%s] = Json::Value(size);", '"', key .. "_sz", '"'))
				-- file:write("\n")
				file:write(string.format("		for(const auto& elem : %s)", info.param))
				file:write("\n")
				file:write("		{")
				file:write("\n")
				if ParamCppType[info.type] or info.commonSeq then
					file:write(string.format("			tmpJs[%s%s%s].append(Json::Value(%selem));", '"', key, '"', valueToJsonType))
				elseif info.isDict then
					if keyJsonType == "String" then
						file:write(string.format("			tmpJs[%s%s%s][elem.first] = Json::Value(%selem.second);", '"', key, '"', keyToJsonType))
					else
						file:write("			std::string key = ToStr(elem.first);")
						file:write("\n")
						file:write(string.format("			tmpJs[%s%s%s][key] = Json::Value(%selem.second);", '"', key, '"', keyToJsonType))
					end
				else
					file:write("			Json::Value jv;")
					file:write("\n")
					file:write("			elem.toJson(jv);")
					file:write("\n")
					file:write(string.format("			tmpJs[%s%s%s].append(jv);", '"', key, '"'))
				end
				file:write("\n")
				file:write("		}")
				file:write("\n")
				file:write("	}")
			end
			file:write("\n")
		end
		file:write("}")
		file:write("\n")
		file:write("\n")

		------------------------------------fromJson------------------------------------

		file:write(string.format("void %s::_fromJson(const Json::Value& _js)", structName))
		file:write("\n")
		file:write("{")
		file:write("\n")
		if string.match(structName, "Struct") then
			file:write(string.format("	const Json::Value &tmpJs = _js[%s%s%s];", '"', structName, '"'))
		else
			file:write("	const Json::Value &tmpJs = _js;")
		end
		file:write("\n")
		local key
		for _, info in ipairs(structEntity) do
			key = info.index or info.param
			local pjt = ParamJsonType[info.type]
			local valueJsonType = ""
			local valueToJsonType = ""
			local jsonToValueType = ""
			local keyJsonType = ""
			local keyToJsonType = ""
			local jsonTokeyType = ""
			if pjt then
				if not info.isDict then
					valueJsonType = pjt[1] or ""
					valueToJsonType = pjt[2] or ""
					jsonToValueType = pjt[3] or ""
				else
					keyJsonType = pjt[1][1] or ""
					keyToJsonType = pjt[1][2] or ""
					jsonTokeyType = pjt[1][3] or ""

					valueJsonType = pjt[2][1] or ""
					valueToJsonType = pjt[2][2] or ""
					jsonToValueType = pjt[2][3] or ""
				end
			end

			local defaultV = DefaultValue[valueJsonType] or 0
			
			-- assert(valueJsonType ~= nil, string.format("%s is not found in valueJsonType!", info.type))
			if info.diyMap then
				file:write("	{")
				file:write("\n")
				file:write(string.format("		%s.clear();", info.param))
				file:write("\n")
				file:write(string.format("		Json::Value::Members members = tmpJs[%s%s%s].getMemberNames();", '"', key, '"'))
				file:write("\n")
				file:write("		for (Json::Value::Members::iterator it = members.begin(); it != members.end(); ++it)")
				file:write("\n")
				file:write("		{")
				file:write("\n")
				file:write("			const std::string& codeStr = *it;")
				file:write("\n")
				file:write(string.format("			if(tmpJs[%s%s%s][codeStr].isNull())", '"', key, '"'));
				file:write("\n")
				file:write(string.format("			{"));
				file:write("\n")
				file:write("				continue;")
				file:write("\n")
				file:write("			}")
				file:write("\n")
				if info.key == "string" then
					file:write(string.format("			%s[codeStr].fromJson(tmpJs[%s%s%s][codeStr]);", info.param, '"', key, '"'))
				else
					if info.key == "long" then
						file:write("			long64_t code = cdf::CStrFun::str_to_int64(codeStr.c_str());")
					else
						file:write("			int code = cdf::CStrFun::str_to_int32(codeStr.c_str());")
					end
					file:write("\n")
					file:write(string.format("			%s[code].fromJson(tmpJs[%s%s%s][codeStr]);", info.param, '"', key, '"'))
				end
				file:write("\n")
				file:write("		}")
				file:write("\n")
				file:write("	}")
			elseif not info.sequence and not info.commonSeq and not info.isDict then
				if info.type == "date" then
					file:write(string.format("	if(!tmpJs[%s%s%s].isNull())", '"', key, '"'))
					file:write("\n")
					file:write("	{")
					file:write("\n")
					file:write(string.format("		%s = cdf::CDateTime(%stmpJs[%s%s%s].as%s());", info.param, jsonToValueType, '"', key, '"',  valueJsonType))
					file:write("\n")
					file:write("	}")
				else
					file:write(string.format("	%s = tmpJs[%s%s%s].isNull() ? %s : %stmpJs[%s%s%s].as%s();", info.param, '"', key, '"', defaultV, jsonToValueType, '"', key, '"',  valueJsonType))
				end
			elseif info.isDict then
				file:write("	{")
				file:write("\n")
				file:write(string.format("		%s.clear();", info.param))
				file:write("\n")
				file:write(string.format("		Json::Value::Members members = tmpJs[%s%s%s].getMemberNames();", '"', key, '"'))
				file:write("\n")
				file:write("		for (Json::Value::Members::iterator it = members.begin(); it != members.end(); ++it)")
				file:write("\n")
				file:write("		{")
				file:write("\n")
				file:write("			const std::string& codeStr = *it;")
				file:write("\n")
				if keyJsonType == "String" then
					file:write(string.format("			%s[codeStr] = tmpJs[%s%s%s][codeStr].isNull() ? %s : %stmpJs[%s%s%s][codeStr].as%s();", info.param, '"', key, '"', defaultV, jsonToValueType, '"', key, '"',valueJsonType))
				else
					if keyJsonType == "Double" then
						file:write("			long64_t code = cdf::CStrFun::str_to_int64(codeStr.c_str());")
					else
						file:write("			int code = cdf::CStrFun::str_to_int32(codeStr.c_str());")
					end
					file:write("\n")
					file:write(string.format("			%s[code] = tmpJs[%s%s%s][codeStr].isNull() ? %s : %stmpJs[%s%s%s][codeStr].as%s();", info.param, '"', key, '"', defaultV, jsonToValueType, '"', key, '"',valueJsonType))
				end
				file:write("\n")
				file:write("		}")
				file:write("\n")
				file:write("	}")
			else
				file:write("	{")
				file:write("\n")
				file:write(string.format("		%s.clear();", info.param))
				file:write("\n")
				file:write(string.format("		int size = (int)tmpJs[%s%s%s].size();", '"', key, '"'))
				file:write("\n")
				file:write(string.format("		if(size > 0) { %s.resize(size); }", info.param))
				file:write("\n")
				file:write(string.format("		for(int i = 0; i < size; ++i)"))
				file:write("\n")
				file:write("		{")
				file:write("\n")
				if ParamCppType[info.type] or info.commonSeq then
					file:write(string.format("			%s.push_back(tmpJs[%s%s%s][i].isNull() ? %s : %stmpJs[%s%s%s][i].as%s());", info.param, '"', key, '"', defaultV, jsonToValueType, '"', key, '"', valueJsonType))
				else
					file:write(string.format("			%s[i].fromJson(tmpJs[%s%s%s][i]);", info.param, '"', key, '"'))
				end
				file:write("\n")
				file:write("		}")
				file:write("\n")
				file:write("	}")
			end
			file:write("\n")
		end
		file:write("}")
		file:write("\n")
		file:write("\n")
	end
	io.close(file)
end
toJsonStruct.makeHead()
toJsonStruct.makeCpp()
print("make success!")