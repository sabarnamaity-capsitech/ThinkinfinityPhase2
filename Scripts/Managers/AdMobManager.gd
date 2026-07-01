extends Control

# Signals forwarded to client scripts
signal rewarded_ad_user_earned_reward(ad_info: AdInfo, reward_data: RewardItem)
signal rewarded_ad_dismissed
signal interstitial_ad_dismissed

# Raw node reference for plugin compatibility
#@onready var admob: Admob = $Admob
#@onready var label: Label = $Label
var admob: Admob
var label: Label

# Modular child components
var _consent_manager: AdConsentManager
var _ad_manager: AdManager

# Backwards compatible property getters
var is_interstitial_ready: bool:
	get:
		return _ad_manager.is_interstitial_ready if _ad_manager else false

var is_rewarded_ready: bool:
	get:
		return _ad_manager.is_rewarded_ready if _ad_manager else false

# ─── Startup ───────────────────────────────────────────────────────────────────

func _ready() -> void:
	if not has_node("Admob"):
		print("Admob node not found in autoload — instantiating dynamically")
		admob = Admob.new()
		admob.name = "Admob"
		admob.is_real = false
		admob.android_debug_application_id = "ca-app-pub-3940256099942544~3347511713"
		admob.android_real_application_id = "ca-app-pub-3940256099942544~3347511713"
		admob.ios_debug_application_id = "ca-app-pub-3940256099942544~1458002511"
		admob.ios_real_application_id = "ca-app-pub-3940256099942544~1458002511"
		admob.banner_position = 1 # BOTTOM
		add_child(admob)
	else:
		admob = $Admob
		
	if not has_node("Label"):
		print("Label node not found in autoload — instantiating dynamically")
		label = Label.new()
		label.name = "Label"
		add_child(label)
	else:
		label = $Label

	# Hide debug label in production / release builds
	if label:
		label.visible = OS.is_debug_build()

	# Instantiate child modules
	_consent_manager = AdConsentManager.new()
	_consent_manager.name = "AdConsentManager"
	add_child(_consent_manager)
	_consent_manager.setup(admob, label)

	_ad_manager = AdManager.new()
	_ad_manager.name = "AdManager"
	add_child(_ad_manager)
	_ad_manager.setup(admob, label)

	# Coordinate modules: Consent resolved -> Initialize AdMob loading
	_consent_manager.consent_status_resolved.connect(_on_consent_status_resolved)

	# Coordinate AdManager events -> Emit on AdMobManager autoload
	_ad_manager.rewarded_ad_user_earned_reward.connect(func(ad_info, reward_data):
		rewarded_ad_user_earned_reward.emit(ad_info, reward_data)
	)
	_ad_manager.rewarded_ad_dismissed.connect(func():
		rewarded_ad_dismissed.emit()
	)
	_ad_manager.interstitial_ad_dismissed.connect(func():
		interstitial_ad_dismissed.emit()
	)

	# Listen to global NetworkManager for connectivity state changes
	NetworkManager.connectivity_changed.connect(_on_network_connectivity_changed)
	_on_network_connectivity_changed(NetworkManager.is_connected)


func _on_consent_status_resolved(can_show_ads: bool) -> void:
	_ad_manager.initialize_admob(can_show_ads)


func _on_network_connectivity_changed(connected: bool) -> void:
	# Inform both modular managers of network state updates 
	if _consent_manager:
		_consent_manager.set_network_connected(connected)
	if _ad_manager:
		_ad_manager.set_network_connected(connected)

# ─── Public API ───────────────────────────────────────────────────────────────

func is_rewarded_available() -> bool:
	return _ad_manager.is_rewarded_available() if _ad_manager else false


func is_interstitial_available() -> bool:
	return _ad_manager.is_interstitial_available() if _ad_manager else false


func show_rewarded() -> void:
	if _ad_manager:
		_ad_manager.show_rewarded()


func show_interstitial() -> void:
	if _ad_manager:
		_ad_manager.show_interstitial()


func load_rewarded() -> void:
	if _ad_manager:
		_ad_manager.load_rewarded()


func load_interstitial() -> void:
	if _ad_manager:
		_ad_manager.load_interstitial()
