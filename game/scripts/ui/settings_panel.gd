class_name SettingsPanel
extends Control
## Shared settings overlay used by both the main menu and the pause menu.
##
## Exposes master volume, fullscreen, mouse-sensitivity, graphics quality,
## controller enable/disable, and touch controls enable/disable — and applies
## them to the live engine. Settings persist to user://settings.cfg so they
## survive between sessions and across scene loads.

signal closed

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "options"
const MASTER_BUS: String = "Master"

const MAX_DB: float = 0.0
const MUTE_THRESHOLD: float = 0.001

@onready var _volume: HSlider = $Panel/Margin/VBox/VolumeRow/Volume
@onready var _fullscreen: CheckButton = $Panel/Margin/VBox/FullscreenRow/Fullscreen
@onready var _graphics: OptionButton = $Panel/Margin/VBox/GraphicsRow/Graphics
@onready var _sensitivity: HSlider = $Panel/Margin/VBox/SensRow/Sensitivity
@onready var _controller: CheckButton = $Panel/Margin/VBox/ControllerRow/Controller
@onready var _touch: CheckButton = $Panel/Margin/VBox/TouchRow/Touch
@onready var _back: Button = $Panel/Margin/VBox/Back


func _ready() -> void:
	var cfg := load_settings()
	_volume.value = cfg["volume"]
	_fullscreen.button_pressed = cfg["fullscreen"]
	_graphics.selected = cfg["graphics"]
	_sensitivity.value = cfg["sensitivity"]
	_controller.button_pressed = cfg.get("controller", true)
	_touch.button_pressed = cfg.get("touch", false)
	apply(cfg, get_tree())

	_volume.value_changed.connect(func(_v): _on_changed())
	_sensitivity.value_changed.connect(func(_v): _on_changed())
	_fullscreen.toggled.connect(func(_v): _on_changed())
	_graphics.item_selected.connect(func(_idx): _on_changed())
	_controller.toggled.connect(func(_v): _on_changed())
	_touch.toggled.connect(func(_v): _on_changed())
	_back.pressed.connect(_on_back)


func _on_changed() -> void:
	var cfg := current()
	apply(cfg, get_tree())
	save_settings(cfg)


func current() -> Dictionary:
	return {
		"volume": _volume.value,
		"fullscreen": _fullscreen.button_pressed,
		"sensitivity": _sensitivity.value,
		"graphics": _graphics.selected,
		"controller": _controller.button_pressed,
		"touch": _touch.button_pressed,
	}


func _on_back() -> void:
	hide()
	closed.emit()


# --- Engine application ---------------------------------------------------


static func apply(cfg: Dictionary, tree: SceneTree = null) -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if bus >= 0:
		var vol := float(cfg.get("volume", 0.8))
		AudioServer.set_bus_mute(bus, vol < MUTE_THRESHOLD)
		AudioServer.set_bus_volume_db(bus, volume_to_db(vol))
	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if bool(cfg.get("fullscreen", false))
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_mode(mode)
	apply_graphics(int(cfg.get("graphics", 1)), tree)
	if tree:
		apply_controller(bool(cfg.get("controller", true)), tree)
		apply_touch(bool(cfg.get("touch", false)), tree)
		apply_sensitivity(float(cfg.get("sensitivity", 0.5)), tree)


static func apply_graphics(quality: int, tree: SceneTree) -> void:
	if not tree or not tree.root:
		return
	var root := tree.root
	match quality:
		0:  # Very Low
			root.msaa_3d = Viewport.MSAA_DISABLED
			root.scaling_3d_scale = 0.5
			RenderingServer.directional_shadow_atlas_set_size(512, true)
		1:  # Low
			root.msaa_3d = Viewport.MSAA_DISABLED
			root.scaling_3d_scale = 0.75
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		2:  # Medium
			root.msaa_3d = Viewport.MSAA_2X
			root.scaling_3d_scale = 1.0
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		3:  # High
			root.msaa_3d = Viewport.MSAA_4X
			root.scaling_3d_scale = 1.0
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		4:  # Ultra
			root.msaa_3d = Viewport.MSAA_8X
			root.scaling_3d_scale = 1.0
			RenderingServer.directional_shadow_atlas_set_size(8192, true)
	tree.call_group("density_aware", "apply_graphics_setting", quality)


static func apply_controller(enabled: bool, tree: SceneTree) -> void:
	if not tree:
		return
	for node in tree.get_nodes_in_group("controller_aware"):
		if node.has_method("set_controller_enabled"):
			node.set_controller_enabled(enabled)


static func apply_touch(enabled: bool, tree: SceneTree) -> void:
	if not tree:
		return
	for node in tree.get_nodes_in_group("touch_controls"):
		if node is TouchControls:
			node.set_enabled(enabled)


static func apply_sensitivity(value: float, tree: SceneTree) -> void:
	if not tree:
		return
	var mult := sensitivity_to_multiplier(value)
	tree.call_group("sensitivity_aware", "set_sensitivity_multiplier", mult)


# --- Pure helpers (unit-tested) ------------------------------------------


static func volume_to_db(value: float) -> float:
	var v := clampf(value, 0.0, 1.0)
	if v < MUTE_THRESHOLD:
		return -80.0
	return clampf(linear_to_db(v), -80.0, MAX_DB)


static func sensitivity_to_multiplier(value: float) -> float:
	var v := clampf(value, 0.0, 1.0)
	if v <= 0.5:
		return lerpf(0.25, 1.0, v / 0.5)
	return lerpf(1.0, 2.0, (v - 0.5) / 0.5)


# --- Persistence ----------------------------------------------------------


static func defaults() -> Dictionary:
	return {
		"volume": 0.8,
		"fullscreen": false,
		"sensitivity": 0.5,
		"graphics": 1,
		"controller": true,
		"touch": false,
	}


static func load_settings() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := defaults()
	if cfg.load(CONFIG_PATH) != OK:
		return out
	out["volume"] = clampf(float(cfg.get_value(SECTION, "volume", out["volume"])), 0.0, 1.0)
	out["fullscreen"] = bool(cfg.get_value(SECTION, "fullscreen", out["fullscreen"]))
	out["sensitivity"] = clampf(
		float(cfg.get_value(SECTION, "sensitivity", out["sensitivity"])), 0.0, 1.0
	)
	out["graphics"] = int(cfg.get_value(SECTION, "graphics", out["graphics"]))
	out["controller"] = bool(cfg.get_value(SECTION, "controller", out["controller"]))
	out["touch"] = bool(cfg.get_value(SECTION, "touch", out["touch"]))
	return out


static func save_settings(cfg_dict: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "volume", cfg_dict.get("volume", 0.8))
	cfg.set_value(SECTION, "fullscreen", cfg_dict.get("fullscreen", false))
	cfg.set_value(SECTION, "sensitivity", cfg_dict.get("sensitivity", 0.5))
	cfg.set_value(SECTION, "graphics", cfg_dict.get("graphics", 1))
	cfg.set_value(SECTION, "controller", cfg_dict.get("controller", true))
	cfg.set_value(SECTION, "touch", cfg_dict.get("touch", false))
	cfg.save(CONFIG_PATH)
