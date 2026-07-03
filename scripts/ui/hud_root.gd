extends CanvasLayer

# HUD 组合根：只负责挂载子面板并完成注册，不放具体 UI 逻辑。

const GameHUD := preload("res://scripts/ui/panels/game_hud.gd")
const LevelUpPanel := preload("res://scripts/ui/panels/level_up_panel.gd")
const GameOverPopup := preload("res://scripts/ui/panels/game_over_popup.gd")
const WaveAlert := preload("res://scripts/ui/panels/wave_alert.gd")
const ContractCard := preload("res://scripts/ui/panels/contract_card.gd")
const DamageNumberLayer := preload("res://scripts/ui/panels/damage_number_layer.gd")
const MobileJoystick := preload("res://scripts/ui/panels/mobile_joystick.gd")

@onready var game_hud: GameHUD = $GameHUD
@onready var level_up_panel: LevelUpPanel = $LevelUpOverlay
@onready var game_over_popup: GameOverPopup = $GameOverPopup
@onready var wave_alert: WaveAlert = $WaveAlert
@onready var contract_card: ContractCard = $ContractCard
@onready var damage_number_layer: DamageNumberLayer = $DamageNumberLayer
@onready var mobile_joystick: MobileJoystick = $MobileJoystick
@onready var ui_manager = get_node("/root/UIManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_manager.register_game_hud(game_hud)
	ui_manager.register_level_up_panel(level_up_panel)
	ui_manager.register_game_over_popup(game_over_popup)
	ui_manager.register_wave_alert(wave_alert)
	ui_manager.register_contract_card(contract_card)
	ui_manager.register_damage_number_layer(damage_number_layer)
	ui_manager.register_mobile_joystick(mobile_joystick)
