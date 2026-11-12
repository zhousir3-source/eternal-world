extends Control

#
@onready var characterName : PanelContainer				= $PlayerName
@onready var characterNameLineEdit : LineEdit			= $PlayerName/Fields/Entry
@onready var characterNameDisplay : Label				= $PlayerName/Fields/Name

@onready var display : HBoxContainer					= $Display
@onready var traitsPanel : PanelContainer				= $Display/Traits
@onready var attributesPanel : PanelContainer			= $Display/Attributes
@onready var statsPanel : PanelContainer				= $Display/Stats

var isCharacterCreatorEnabled : bool					= false
var charactersInfo : Array[Dictionary]					= []
var charactersNode : Array[Entity]						= []
var currentCharacterID : int							= ActorCommons.InvalidCharacterSlot
var pendingFocusControl : Control						= null

#
func FillWarningLabel(err : NetworkCommons.CharacterError):
	if isCharacterCreatorEnabled:
		FSM.EnterState(FSM.States.CHAR_SCREEN)
		if err == NetworkCommons.CharacterError.ERR_OK:
			EnableCharacterCreator(false)
		else:
			EnableCharacterCreator(true)

	var warn : String = ""
	match err:
		NetworkCommons.CharacterError.ERR_OK:
			warn = ""
			EnableCharacterCreator(false)
		NetworkCommons.CharacterError.ERR_ALREADY_LOGGED_IN:
			warn = "该角色已在游戏中。"
		NetworkCommons.CharacterError.ERR_TIMEOUT:
			warn = "无法连接服务器（错误代码：%d）。" % err
		NetworkCommons.CharacterError.ERR_MISSING_PARAMS:
			warn = "角色信息不完整，请检查后重试。"
			RequestFocus(characterNameLineEdit)
		NetworkCommons.CharacterError.ERR_NAME_AVAILABLE:
			warn = "该角色名称不可用。"
			RequestFocus(characterNameLineEdit)
		NetworkCommons.CharacterError.ERR_NAME_VALID:
			warn = "名称只能包含字母、数字和允许使用的符号。"
			RequestFocus(characterNameLineEdit)
		NetworkCommons.CharacterError.ERR_NAME_SIZE:
			warn = "角色名称长度必须为%d至%d个字符。" % [NetworkCommons.CharacterNicknameMinSize, NetworkCommons.CharacterNicknameMaxSize]
			RequestFocus(characterNameLineEdit)
		NetworkCommons.CharacterError.ERR_EMPTY_ACCOUNT:
			EnableCharacterCreator(true)
		_:
			warn = "角色操作失败（错误代码：%d）。请保留当前数据并重新启动游戏。" % err

	if not warn.is_empty():
		warn = "[color=#%s]%s[/color]" % [UICommons.WarnTextColor.to_html(false), warn]
	Launcher.GUI.notificationLabel.AddNotification(warn)

func RequestFocus(control : Control):
	pendingFocusControl = control
	if control.is_visible_in_tree():
		ApplyFocus.call_deferred()

func ApplyFocus():
	if pendingFocusControl:
		pendingFocusControl.release_focus()
		pendingFocusControl.grab_focus()
		pendingFocusControl = null

func FillMissingCharacterInfo(info : Dictionary):
	Util.DicCheckOrAdd(info, "nickname", "")
	Util.DicCheckOrAdd(info, "last_timestamp", ActorCommons.MaxStatValue)
	Util.DicCheckOrAdd(info, "created_timestamp", ActorCommons.MaxStatValue)
	Util.DicCheckOrAdd(info, "level", 1)
	Util.DicCheckOrAdd(info, "pos_map", LauncherCommons.DefaultStartMapID)
	Util.DicCheckOrAdd(info, "hairstyle", DB.UnknownHash)
	Util.DicCheckOrAdd(info, "haircolor", DB.UnknownHash)
	Util.DicCheckOrAdd(info, "gender", ActorCommons.Gender.MALE)
	Util.DicCheckOrAdd(info, "race", DB.UnknownHash)
	Util.DicCheckOrAdd(info, "skintone", DB.UnknownHash)

func HasSlot(slotID : int) -> bool:
	return slotID >= 0 and slotID <= ActorCommons.MaxCharacterCount

func GetDefaultSlot(slotID : int) -> int:
	return slotID if HasSlot(slotID) else 0

func NextAvailableSlot() -> int:
	var availableSlot : int = ActorCommons.InvalidCharacterSlot
	for charID in ActorCommons.MaxCharacterCount:
		if charactersInfo[charID].is_empty():
			availableSlot = charID
			break
	return availableSlot

func MoreRecentThan(firstChar : Dictionary, secondChar : Dictionary) -> bool:
	var firstVal : int = firstChar["created_timestamp"] if firstChar["last_timestamp"] == ActorCommons.MaxStatValue else firstChar["last_timestamp"]
	var secondVal : int = secondChar["created_timestamp"] if secondChar["last_timestamp"] == ActorCommons.MaxStatValue else secondChar["last_timestamp"]
	return firstVal > secondVal

func AddCharacter(info : Dictionary, equipment : Dictionary, slotID : int = ActorCommons.InvalidCharacterSlot):
	FillMissingCharacterInfo(info)

	var availableSlot : int = NextAvailableSlot() if slotID == ActorCommons.InvalidCharacterSlot else slotID
	if availableSlot == ActorCommons.InvalidCharacterSlot:
		assert(false, "No free available placement")
		return

	var entityData : EntityData = DB.EntitiesDB.get("Player".hash(), null)
	if not entityData:
		assert(false, "Could not retrieve the default entity database entry")
		return

	var entity : Entity = Instantiate.CreateEntity(ActorCommons.Type.PLAYER, entityData, info["nickname"], false)
	if not entity:
		assert(false, "Could not create character preview")
		return

	entity.inventory.ImportEquipment(equipment)

	entity.stat.hairstyle	= info["hairstyle"]
	entity.stat.haircolor	= info["haircolor"]
	entity.stat.gender		= info["gender"]
	entity.stat.race		= info["race"]
	entity.stat.skintone	= info["skintone"]

	RemoveCharacter(availableSlot)
	charactersInfo[availableSlot] = info
	charactersNode[availableSlot] = entity
	# Character preview visuals are initialized when the entity enters the scene tree.
	# Defer the first update until ready so the body, face and hair are not left blank.
	entity.ready.connect(_on_character_preview_ready.bind(entity, availableSlot), CONNECT_ONE_SHOT)
	Launcher.Map.AddChild(entity)

	if not HasSlot(currentCharacterID) or MoreRecentThan(info, charactersInfo[currentCharacterID]) or info["nickname"].is_empty():
		UpdateSelectedCharacter(info, availableSlot)

	RefreshCharacterList()

func _on_character_preview_ready(entity : Entity, slotID : int):
	if not is_instance_valid(entity) or not HasSlot(slotID):
		return
	if entity.visual:
		entity.visual.SetBody()
		entity.visual.SetFace()
		entity.visual.SetHair()
	var randDir : Vector2 = Vector2(randf_range(-0.8, 0.8), 1.0)
	var randState : ActorCommons.State = ActorCommons.State.IDLE if isCharacterCreatorEnabled or randi() % 2 == 1 else ActorCommons.State.SIT
	entity.Update(Vector2.ZERO, ActorCommons.CharacterScreenLocations[slotID], randDir, randState, -1, true)

func RemoveCharacter(slotID : int):
	if HasSlot(slotID):
		if charactersNode[slotID] != null:
			Launcher.Map.RemoveChild(charactersNode[slotID])
			charactersNode[slotID] = null
		if not charactersInfo[slotID].is_empty():
			charactersInfo[slotID] = {}

		if currentCharacterID == slotID:
			var mostRecentTimestamp : int = -1
			var mostRecentCharacterID : int = ActorCommons.InvalidCharacterSlot
			for characterID in ActorCommons.MaxCharacterCount:
				if not charactersInfo[characterID].is_empty():
					if mostRecentCharacterID == ActorCommons.InvalidCharacterSlot:
						mostRecentCharacterID = characterID
					elif "last_timestamp" in charactersInfo[characterID] and charactersInfo[characterID]["last_timestamp"] != null and mostRecentTimestamp < charactersInfo[characterID]["last_timestamp"]:
						mostRecentTimestamp = charactersInfo[characterID]["last_timestamp"]
						mostRecentCharacterID = characterID
			UpdateSelectedCharacter(charactersInfo[mostRecentCharacterID] if HasSlot(mostRecentCharacterID) else {}, mostRecentCharacterID)

		RefreshCharacterList()

func RandomizeCharacter():
	attributesPanel.Randomize()
	traitsPanel.Randomize()

func RefreshCharacterList():
	var characterCount : int = 0
	for character in charactersNode:
		if character != null:
			characterCount += 1
	statsPanel.selection.set_visible(characterCount >= 2)
	RefreshSuggestedButton()

func RefreshSuggestedButton():
	if not Launcher.GUI or not Launcher.GUI.buttonBoxes or not FSM.IsCharacterState():
		return

	if isCharacterCreatorEnabled or currentCharacterID != ActorCommons.InvalidCharacterSlot:
		Launcher.GUI.buttonBoxes.Suggest(UICommons.ButtonBox.PRIMARY)
	else:
		Launcher.GUI.buttonBoxes.Suggest(UICommons.ButtonBox.SECONDARY)

func CreateCharacter():
	if isCharacterCreatorEnabled:
		# Normalize accidental surrounding whitespace before local/name validation.
		var nickname : String = characterNameLineEdit.get_text().strip_edges()
		characterNameLineEdit.text = nickname
		var err : NetworkCommons.CharacterError = NetworkCommons.CheckCharacterInformation(nickname)
		if err != NetworkCommons.CharacterError.ERR_OK:
			FillWarningLabel(err)
		else:
			var appearance : Dictionary = traitsPanel.GetValues()
			if appearance.is_empty():
				Launcher.GUI.notificationLabel.AddNotification("[color=#ff7777]角色外观资源未加载完整，请检查游戏资源后重试。[/color]")
				return
			# Android single-player character creation must not call the account/RPC path.
			# This saves the initial character only; world-state loading and entering
			# the playable map still require a separate offline implementation.
			if OS.get_name() == "Android":
				var character_data : Dictionary = appearance.duplicate(true)
				character_data["nickname"] = nickname
				character_data["attributes"] = attributesPanel.GetValues()
				if not XiaYeLocalSave.WriteNewSave(character_data):
					Launcher.GUI.notificationLabel.AddNotification("[color=#ff7777]本地角色保存失败，已有存档不会被覆盖。[/color]")
					return
				EnableCharacterCreator(false)
				AddCharacter(character_data, {})
				Launcher.GUI.notificationLabel.AddNotification("角色已保存在本机。")
			elif Network.CreateCharacter(nickname, appearance, attributesPanel.GetValues()):
				FSM.EnterState(FSM.States.CHAR_PROGRESS)

func SelectCharacter():
	if Network.ConnectCharacter(characterNameDisplay.get_text()):
		FSM.EnterState(FSM.States.CHAR_PROGRESS)

func DeleteCharacter():
	UICommons.MessageBox("""确定要删除这个角色吗？
此操作不可撤销，删除后将无法恢复或继续使用该角色。
""",
		Callback.Empty, "取消",
		ConfirmDeleteCharacter, "确认")

func ConfirmDeleteCharacter():
	if Network.DeleteCharacter(characterNameDisplay.get_text()):
		RemoveCharacter(currentCharacterID)

func GetSelectedEntity() -> Entity:
	return charactersNode[currentCharacterID] if currentCharacterID != ActorCommons.InvalidCharacterSlot else null

func UpdateSelectedCharacter(info : Dictionary, slotID : int):
	var displayInformation : bool = not info.is_empty() or isCharacterCreatorEnabled
	characterName.set_visible(displayInformation)
	display.set_visible(displayInformation)
	# Keep the nickname editor explicitly visible during creation; the display label is only for existing characters.
	characterNameLineEdit.set_visible(isCharacterCreatorEnabled)
	characterNameDisplay.set_visible(not isCharacterCreatorEnabled and not info.is_empty())

	if not isCharacterCreatorEnabled and not info.is_empty():
		statsPanel.SetInfo(info)
		characterNameDisplay.set_text(info["nickname"])

	if HasSlot(slotID) and charactersNode[slotID] != null:
		if HasSlot(currentCharacterID) and charactersNode[currentCharacterID]:
			EnableCharacterSelectionFx(false, currentCharacterID)
		EnableCharacterSelectionFx(true, slotID)

	if FSM.IsCharacterState():
		Launcher.Camera.LookAt(ActorCommons.CharacterScreenLocations[GetDefaultSlot(slotID)])

	currentCharacterID = slotID

func EnableCharacterSelectionFx(isEnabled : bool, slotID : int):
	if charactersNode[slotID].interactive:
		charactersNode[slotID].interactive.DisplayTarget(ActorCommons.Target.ALLY if isEnabled else ActorCommons.Target.NONE)
	else:
		Callback.PlugCallback(charactersNode[slotID].ready, EnableCharacterSelectionFx, [isEnabled, slotID])

func ChangeSelectedCharacter(changeClockwise : bool = true):
	if not HasSlot(currentCharacterID):
		currentCharacterID = 0
	var operationValue : int = 1 if changeClockwise else -1

	for slotID in range(1, ActorCommons.MaxCharacterCount):
		var lookupID : int = (currentCharacterID + (slotID * operationValue) + ActorCommons.MaxCharacterCount) % ActorCommons.MaxCharacterCount
		var info : Dictionary = charactersInfo[lookupID]
		if not info.is_empty():
			UpdateSelectedCharacter(info, lookupID)
			break

func EnableCharacterCreator(enable : bool):
	if isCharacterCreatorEnabled != enable:
		isCharacterCreatorEnabled = enable
		if enable:
			if Launcher.Camera.IsZooming(ActorCommons.CameraZoomDefault):
				Launcher.Camera.ZoomAt(ActorCommons.CameraZoomDouble)
			RandomizeCharacter()
			var previewAppearance : Dictionary = traitsPanel.GetValues()
			if not previewAppearance.is_empty():
				AddCharacter(previewAppearance, {}, ActorCommons.MaxCharacterCount)
			else:
				Launcher.GUI.notificationLabel.AddNotification("[color=#ff7777]角色外观资源缺失，暂时无法显示角色预览。[/color]")
		else:
			if Launcher.Camera.IsZooming(ActorCommons.CameraZoomDouble):
				Launcher.Camera.ZoomAt(ActorCommons.CameraZoomDefault)
			if not enable and HasSlot(currentCharacterID) and charactersNode[currentCharacterID] != null:
				RemoveCharacter(ActorCommons.MaxCharacterCount)

	statsPanel.set_visible(not enable and visible)
	characterNameDisplay.set_visible(not enable and visible)
	characterNameLineEdit.set_visible(enable)
	characterName.set_visible(enable or (not enable and visible and not characterNameDisplay.text.is_empty()))
	traitsPanel.set_visible(enable)
	attributesPanel.set_visible(enable)

	if enable:
		# Offer an editable offline-friendly default without overwriting a typed name.
		if characterNameLineEdit.text.strip_edges().is_empty():
			characterNameLineEdit.text = "夏叶"
		RequestFocus(characterNameLineEdit)
	else:
		pendingFocusControl = null

	if Launcher.GUI.buttonBoxes:
		Launcher.GUI.buttonBoxes.ClearAll()
		if enable:
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "创建角色", CreateCharacter)
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "随机外观", RandomizeCharacter)
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "取消", EnableCharacterCreator.bind(false))
			RefreshSuggestedButton()
		else:
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.PRIMARY, "进入游戏", SelectCharacter)
			if NextAvailableSlot() != ActorCommons.InvalidCharacterSlot:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.SECONDARY, "新建角色", EnableCharacterCreator.bind(true))
			if currentCharacterID != ActorCommons.InvalidCharacterSlot:
				Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.TERTIARY, "删除角色", DeleteCharacter.bind())
			Launcher.GUI.buttonBoxes.Bind(UICommons.ButtonBox.CANCEL, "取消", Leave)
			RefreshSuggestedButton()

func UpdateCharacterCreatorBody():
	if isCharacterCreatorEnabled and charactersNode[ActorCommons.MaxCharacterCount]:
		# Use the same validated appearance snapshot as character creation.
		# Avoid direct array indexing while Android resources are still loading.
		var appearance : Dictionary = traitsPanel.GetValues()
		if appearance.is_empty():
			return
		var preview : Entity = charactersNode[ActorCommons.MaxCharacterCount]
		preview.stat.race = appearance["race"]
		preview.stat.skintone = appearance["skintone"]
		preview.stat.gender = appearance["gender"]
		if preview.visual:
			preview.visual.SetBody()
			preview.visual.SetFace()

func UpdateCharacterCreatorHair():
	if isCharacterCreatorEnabled and charactersNode[ActorCommons.MaxCharacterCount]:
		var appearance : Dictionary = traitsPanel.GetValues()
		if appearance.is_empty():
			return
		var preview : Entity = charactersNode[ActorCommons.MaxCharacterCount]
		preview.stat.hairstyle = appearance["hairstyle"]
		preview.stat.haircolor = appearance["haircolor"]
		if preview.visual:
			preview.visual.SetHair()

func RefreshOnce():
	if isCharacterCreatorEnabled:
		EnableCharacterCreator(isCharacterCreatorEnabled)
		return

	Clear()

	Launcher.Map.EmplaceMapNode(ActorCommons.CharacterScreenMapID)
	currentCharacterID = ActorCommons.InvalidCharacterSlot
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)

	EnableCharacterCreator(isCharacterCreatorEnabled)
	UpdateSelectedCharacter({}, currentCharacterID)
	if OS.get_name() == "Android":
		# Read the independent on-device save; do not request a server character list.
		var saved : Dictionary = XiaYeLocalSave.ReadSave()
		if not saved.is_empty():
			var character_data : Dictionary = saved["character"]
			AddCharacter(character_data, {})
			return
		if XiaYeLocalSave.HasSave() or FileAccess.file_exists(XiaYeLocalSave.TEMP_PATH):
			# A corrupt or unsupported save must never be replaced by a new one.
			Launcher.GUI.notificationLabel.AddNotification("[color=#ff7777]本地存档无法读取，原文件已保留。请先备份存档。[/color]")
			return
		EnableCharacterCreator(true)
		return
	Network.CharacterListing()

func Clear():
	for slotID in charactersInfo.size():
		RemoveCharacter(slotID)
	Launcher.GUI.buttonBoxes.ClearAll()
	currentCharacterID = ActorCommons.InvalidCharacterSlot

func Leave():
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	Network.DisconnectAccount()
	Clear()

func Close():
	if isCharacterCreatorEnabled:
		EnableCharacterCreator(false)
	else:
		Leave()

#
func _ready():
	assert(ActorCommons.MaxCharacterCount + 1 == ActorCommons.CharacterScreenLocations.size(), "Character screen locations count mismatch with the max character count")
	charactersInfo.resize(ActorCommons.MaxCharacterCount + 1)
	charactersNode.resize(ActorCommons.MaxCharacterCount + 1)
	statsPanel.previousButton.pressed.connect(ChangeSelectedCharacter.bind(false))
	statsPanel.nextButton.pressed.connect(ChangeSelectedCharacter.bind(true))
	traitsPanel.bodyUpdate.connect(UpdateCharacterCreatorBody)
	traitsPanel.hairUpdate.connect(UpdateCharacterCreatorHair)
	FSM.enter_game.connect(Clear)

func _physics_process(_delta: float):
	var entity : Entity = GetSelectedEntity()
	if entity:
		var move : Vector2 = Launcher.Action.GetMove()
		if move != Vector2.ZERO:
			entity.entityOrientation = move
			if entity.visual:
				entity.visual.Refresh()

func _unhandled_input(event : InputEvent):
	if not visible:
		return

	var entity : Entity = GetSelectedEntity()
	if entity and Launcher.Action.TryJustPressed(event, "gp_sit"):
		entity.state = ActorCommons.State.IDLE if entity.state == ActorCommons.State.SIT else ActorCommons.State.SIT
		if entity.visual:
			entity.visual.Refresh()

func _on_visibility_changed():
	if visible:
		if pendingFocusControl and pendingFocusControl.is_visible_in_tree():
			ApplyFocus.call_deferred()
	else:
		if statsPanel:
			statsPanel.set_visible(false)
		if traitsPanel:
			traitsPanel.set_visible(false)
		if attributesPanel:
			attributesPanel.set_visible(false)

func _on_text_focus_entered():
	if Launcher.Action:
		Launcher.Action.Enable(false)

func _on_text_focus_exited():
	if Launcher.Action:
		Launcher.Action.Enable(true)
