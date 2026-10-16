translate = {}

local Languages = {}
local Translations = {}
local AddingLanguage
local DefaultLanguage = "en"
local CurrentLanguage = DefaultLanguage

local LANG_ALIASES = {
	["zh-cn"] = "zh-cn",
	["zh_cn"] = "zh-cn",
	["zh-CN"] = "zh-cn",
	["zh_CN"] = "zh-cn",
	["zh-tw"] = "zh-tw",
	["zh_tw"] = "zh-tw",
	["zh-TW"] = "zh-tw",
	["zh_TW"] = "zh-tw",
	["es-es"] = "es-es",
	["es_es"] = "es-es",
	["es-ES"] = "es-es",
	["es_ES"] = "es-es",
	["es"]    = "es-es",
	["pt-br"] = "pt-br",
	["pt-BR"] = "pt-br",
	["pt_br"] = "pt-br",
	["pt-pt"] = "pt-pt",
	["pt-PT"] = "pt-pt",
	["sv-se"] = "sv-se",
	["sv-SE"] = "sv-se",
	["en-pt"] = "en-pt",
	["en-PT"] = "en-pt",
}

local function NormalizeLang(code)
	if not code or code == "" then return DefaultLanguage end
	code = string.lower(string.Trim(code))
	return LANG_ALIASES[code] or code
end

if CLIENT then
	CreateClientConVar("gmod_language_rep", "en", false, true)

	local function RefreshLanguage()
		local raw = GetConVar("gmod_language"):GetString()
		CurrentLanguage = NormalizeLang(raw)

		local rep = GetConVar("gmod_language_rep")
		if rep and CurrentLanguage ~= NormalizeLang(rep:GetString()) then
			RunConsoleCommand("gmod_language_rep", CurrentLanguage)
		end
	end

	RefreshLanguage()

	cvars.AddChangeCallback("gmod_language", function(_, _, new)
		CurrentLanguage = NormalizeLang(new)
		RunConsoleCommand("gmod_language_rep", CurrentLanguage)
	end, "Horde_Translate_LanguageChange")

	timer.Simple(0, RefreshLanguage)
	timer.Simple(1, RefreshLanguage)
	timer.Simple(3, RefreshLanguage)
end

function translate.GetLanguages()
	return Languages
end

function translate.GetLanguageName(short)
	return Languages[NormalizeLang(short)]
end

function translate.GetTranslations(short)
	short = NormalizeLang(short)
	return Translations[short] or Translations[DefaultLanguage] or {}
end

function translate.AddLanguage(short, long)
	short = NormalizeLang(short)
	Languages[short] = long
	Translations[short] = Translations[short] or {}
	AddingLanguage = short
end

function translate.AddTranslation(id, text)
	if not AddingLanguage or not Translations[AddingLanguage] then return end
	Translations[AddingLanguage][id] = text
end

function translate.Get(id)
	local t = translate.GetTranslations(CurrentLanguage)
	if t and t[id] ~= nil then return t[id] end
	local def = Translations[DefaultLanguage]
	if def and def[id] ~= nil then return def[id] end
	return nil
end

function translate.Format(id, ...)
	return string.format(translate.Get(id), ...)
end

local NotifTranslations = {}

function translate.AddNotificationTranslations(tbl)
	if not AddingLanguage or type(tbl) ~= "table" then return end
	local dst = NotifTranslations[AddingLanguage]
	if not dst then
		dst = {}
		NotifTranslations[AddingLanguage] = dst
	end
	for _, rule in ipairs(tbl) do
		if type(rule) == "table" and isstring(rule[1]) and isstring(rule[2]) then
			dst[#dst + 1] = { rule[1], rule[2] }
		end
	end
end

function translate.GetNotificationTranslations(short)
	if short == nil then short = CurrentLanguage end
	return NotifTranslations[NormalizeLang(short)] or NotifTranslations[DefaultLanguage] or {}
end

function translate.LocalizeNotification(text)
	if text == nil or text == "" then return text end
	local exact = translate.Get(text)
	if exact ~= nil then return exact end
	for _, rule in ipairs(translate.GetNotificationTranslations()) do
		local out, count = text:gsub(rule[1], rule[2])
		if count > 0 then return out end
	end
	return text
end

function translate.GetFont()
	return translate.Get("Default_Font") or "arial"
end

function translate.GetBoldFont()
	return translate.Get("Default_Font_Bold") or translate.Get("Default_Font") or "arial bold"
end

if SERVER then
	function translate.ClientGet(pl, ...)
		local old = CurrentLanguage
		CurrentLanguage = NormalizeLang(pl:GetInfo("gmod_language_rep"))
		local result = translate.Get(...)
		CurrentLanguage = old
		return result
	end

	function translate.ClientFormat(pl, ...)
		local old = CurrentLanguage
		CurrentLanguage = NormalizeLang(pl:GetInfo("gmod_language_rep"))
		local result = translate.Format(...)
		CurrentLanguage = old
		return result
	end

	function PrintTranslatedMessage(printtype, str, ...)
		for _, pl in pairs(player.GetAll()) do
			pl:PrintMessage(printtype, translate.ClientFormat(pl, str, ...))
		end
	end
end

if CLIENT then
	function translate.ClientGet(_, ...)
		return translate.Get(...)
	end
	function translate.ClientFormat(_, ...)
		return translate.Format(...)
	end
end

local lang_files = file.Find(GM.FolderName .. "/gamemode/modules/languages/*.lua", "LUA")
if lang_files then
	for _, filename in ipairs(lang_files) do
		LANGUAGE = {}
		LANGUAGE_NOTIF = nil
		local lang_full = GM.FolderName .. "/gamemode/modules/languages/" .. filename
		AddCSLuaFile(lang_full)
		include(lang_full)
		if istable(LANGUAGE) then
			for k, v in pairs(LANGUAGE) do
				translate.AddTranslation(k, v)
			end
		end
		if istable(LANGUAGE_NOTIF) then
			translate.AddNotificationTranslations(LANGUAGE_NOTIF)
		end
		LANGUAGE = nil
		LANGUAGE_NOTIF = nil
	end
end

local meta = FindMetaTable("Player")
if not meta then return end

function meta:PrintTranslatedMessage(hudprinttype, translateid, ...)
	if ... ~= nil then
		self:PrintMessage(hudprinttype, translate.ClientFormat(self, translateid, ...))
	else
		self:PrintMessage(hudprinttype, translate.ClientGet(self, translateid))
	end
end
