extends Control

const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const BootstrapUIHelpers := preload("res://scripts/ui/bootstrap/bootstrap_ui_helpers.gd")
const LoadingPageScene := preload("res://scenes/bootstrap/pages/loading_page.tscn")
const HeroSelectPageScene := preload("res://scenes/bootstrap/pages/hero_select_page.tscn")

@onready var page_host: Control = $PageHost

var preload_paths: Array[String] = []
var preload_index := 0
var loading_page: LoadingPage
var hero_select_page: HeroSelectPage
var selected_hero_id := "blood_knight"
var progress_bar: ProgressBar
var status_label: Label
var loading_panel: Control
var select_panel: Control
var hero_buttons: Array[Button] = []
var detail_label: Label
var hero_preview: AnimatedSprite2D
var hero_detail_icon: AnimatedSprite2D
var menu_pixel_frame: TextureRect
var talent_pixel_frame: TextureRect
var hero_tab_button: Button
var talent_tab_button: Button
var codex_tab_button: Button
var hero_content: Control
var talent_panel: TalentPage
var codex_panel: CodexPage
var crystal_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_preload_queue()
	_show_loading_page()

func _process(_delta: float) -> void:
	if hero_select_page != null:
		return
	if preload_index >= preload_paths.size():
		_show_hero_select_page()
		return
	var path := preload_paths[preload_index]
	if ResourceLoader.exists(path):
		load(path)
	preload_index += 1
	if loading_page != null:
		loading_page.set_progress(preload_index)
		loading_page.set_status("加载资源 %d / %d" % [preload_index, preload_paths.size()])

func _build_preload_queue() -> void:
	preload_paths = BootstrapUIHelpers.unique_paths(HeroCatalog.asset_paths() + DuelystTheme.preload_asset_paths() + [
		CJKFontTheme.FONT_PATH,
		"res://scenes/main/Main.tscn",
		"res://scenes/enemy/Enemy.tscn",
		"res://scenes/projectile/Projectile.tscn",
		"res://scenes/projectile/EnemyProjectile.tscn",
		"res://scenes/effects/WeaponZone.tscn",
		"res://scenes/effects/ParticleBurst.tscn",
		"res://scenes/xp/XPGem.tscn",
		"res://scenes/pickups/PickupItem.tscn"
	])

func _show_loading_page() -> void:
	_clear_host()
	loading_page = LoadingPageScene.instantiate() as LoadingPage
	page_host.add_child(loading_page)
	loading_panel = loading_page
	progress_bar = loading_page.progress_bar
	status_label = loading_page.status_label
	loading_page.configure(max(1, preload_paths.size()), "正在预加载角色、怪物、武器特效...")
	loading_page.set_progress(preload_index)
	loading_page.set_status("正在预加载角色、怪物、武器特效...")

func _show_hero_select_page() -> void:
	if loading_page != null:
		loading_page.finish()
		loading_page.hide()
	hero_select_page = HeroSelectPageScene.instantiate() as HeroSelectPage
	page_host.add_child(hero_select_page)
	hero_select_page.start_requested.connect(_on_start_requested)
	selected_hero_id = hero_select_page.selected_hero_id
	select_panel = hero_select_page
	hero_buttons = hero_select_page.hero_buttons
	detail_label = hero_select_page.detail_label
	hero_preview = hero_select_page.hero_preview
	hero_detail_icon = hero_select_page.hero_detail_icon
	menu_pixel_frame = hero_select_page.menu_pixel_frame
	talent_pixel_frame = hero_select_page.talent_pixel_frame
	hero_tab_button = hero_select_page.hero_tab_button
	talent_tab_button = hero_select_page.talent_tab_button
	codex_tab_button = hero_select_page.codex_tab_button
	hero_content = hero_select_page.hero_content
	talent_panel = hero_select_page.talent_page
	codex_panel = hero_select_page.codex_page
	crystal_label = hero_select_page.talent_page.crystal_label
	hero_select_page.show()

func _on_start_requested(hero_id: String) -> void:
	selected_hero_id = hero_id
	RuntimeConfig.select_hero(hero_id)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _show_hero_tab() -> void:
	if hero_select_page != null:
		hero_select_page._show_hero_tab()

func _show_talent_tab() -> void:
	if hero_select_page != null:
		hero_select_page._show_talent_tab()

func _show_codex_tab() -> void:
	if hero_select_page != null:
		hero_select_page._show_codex_tab()

func _select_hero(hero_id: String) -> void:
	if hero_select_page != null:
		hero_select_page.select_hero(hero_id)
	selected_hero_id = hero_id

func _clear_host() -> void:
	for child in page_host.get_children():
		child.queue_free()
