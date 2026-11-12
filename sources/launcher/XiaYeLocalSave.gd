extends RefCounted
class_name XiaYeLocalSave

# Independent single-player persistence primitive. This does not create an account,
# contact a server, or alter the legacy Source of Mana database.
const SAVE_DIRECTORY := "user://xiaoye"
const SAVE_PATH := SAVE_DIRECTORY + "/slot_1.json"
const TEMP_PATH := SAVE_DIRECTORY + "/slot_1.pending"
const FORMAT_VERSION := 1

static func HasSave() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func ReadSave() -> Dictionary:
	if not HasSave():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("无法打开本地存档：" + str(FileAccess.get_open_error()))
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("本地存档 JSON 格式错误，原文件已保留。")
		return {}
	var value: Variant = json.data
	if not value is Dictionary or value.get("format_version", -1) != FORMAT_VERSION:
		push_error("本地存档版本不受支持，原文件已保留。")
		return {}
	if not value.has("character") or not value["character"] is Dictionary:
		push_error("本地存档缺少角色数据，原文件已保留。")
		return {}
	if not IsValidCharacter(value["character"]):
		push_error("本地存档角色数据不合法，原文件已保留。")
		return {}
	return value

static func IsValidCharacter(character: Dictionary) -> bool:
	var nickname: Variant = character.get("nickname", null)
	var gender: Variant = character.get("gender", null)
	if not nickname is String or nickname.strip_edges().is_empty():
		return false
	if nickname.length() > 30:
		return false
	# Keep gender values compatible with the engine enum, without accepting
	# arbitrary serialized objects or strings as gender.
	if not gender is int or gender not in [0, 1]:
		return false
	return true

static func WriteNewSave(character: Dictionary, world: Dictionary = {}) -> bool:
	# Fail closed: never overwrite an existing save until migration/backup
	# and full world-state serialization have been implemented and tested.
	if HasSave() or FileAccess.file_exists(TEMP_PATH):
		push_error("已有存档或未完成的临时存档，拒绝覆盖。")
		return false
	if not IsValidCharacter(character):
		push_error("角色数据不完整，未写入存档。")
		return false
	var directory := ProjectSettings.globalize_path(SAVE_DIRECTORY)
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("无法创建本地存档目录。")
		return false
	var payload := {
		"format_version": FORMAT_VERSION,
		"character": character,
		"world": world
	}
	var json_text := JSON.stringify(payload)
	if json_text.is_empty():
		push_error("本地存档序列化失败。")
		return false
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法创建本地临时存档。")
		return false
	file.store_string(json_text)
	file.flush()
	file.close()
	var verify := FileAccess.open(TEMP_PATH, FileAccess.READ)
	if verify == null or verify.get_as_text() != json_text:
		push_error("本地存档写入校验失败，临时文件已保留。")
		return false
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if error != OK:
		push_error("本地存档提交失败，临时文件已保留：" + str(error))
		return false
	return true
