extends Node
class_name AdManager

# Forwarded signals from the internal Admob plugin
signal rewarded_ad_user_earned_reward(ad_info: AdInfo, reward_data: RewardItem)
signal rewarded_ad_dismissed
signal interstitial_ad_dismissed

var _admob: Admob
var _label: Label
var _is_connected := false
var _consent_given := false
var _admob_initialized := false
var _banner_showing := false

# State variables
var is_interstitial_ready := false
var is_rewarded_ready := false

# Exponential Backoff variables
var _banner_retry_delay := 5.0
var _interstitial_retry_delay := 5.0
var _rewarded_retry_delay := 5.0
const MAX_RETRY_DELAY := 60.0

func setup(admob_node: Admob, debug_label: Label) -> void:
	_admob = admob_node
	_label = debug_label
	_connect_native_signals()

func set_network_connected(connected: bool) -> void:
	_is_connected = connected
	if _is_connected:
		if _admob_initialized:
			# If already initialized, show banner if active, and reload missing ads
			if _banner_showing:
				_show_banner()
			_load_missing_ads()
		else:
			if _consent_given:
				initialize_admob()
	else:
		_update_label("No internet connection. Ads disabled.")
		# Hide banner immediately when connection drops
		if _admob_initialized and _banner_showing:
			_hide_banner()

func initialize_admob(consent_given: bool = true) -> void:
	_consent_given = consent_given
	if not _consent_given:
		_update_label("Ads disabled (no consent)")
		return

	if not _is_connected:
		return

	if not _admob_initialized and _admob:
		_admob.initialize()
		_update_label("Initializing AdMob…")

func _connect_native_signals() -> void:
	if not _admob:
		return
	if not _admob.initialization_completed.is_connected(_on_admob_initialization_completed):
		_admob.initialization_completed.connect(_on_admob_initialization_completed)
	
	# Banner signals
	if not _admob.banner_ad_loaded.is_connected(_on_admob_banner_ad_loaded):
		_admob.banner_ad_loaded.connect(_on_admob_banner_ad_loaded)
	if not _admob.banner_ad_failed_to_load.is_connected(_on_admob_banner_ad_failed_to_load):
		_admob.banner_ad_failed_to_load.connect(_on_admob_banner_ad_failed_to_load)

	# Interstitial signals
	if not _admob.interstitial_ad_loaded.is_connected(_on_admob_interstitial_ad_loaded):
		_admob.interstitial_ad_loaded.connect(_on_admob_interstitial_ad_loaded)
	if not _admob.interstitial_ad_failed_to_load.is_connected(_on_admob_interstitial_ad_failed_to_load):
		_admob.interstitial_ad_failed_to_load.connect(_on_admob_interstitial_ad_failed_to_load)
	if not _admob.interstitial_ad_dismissed_full_screen_content.is_connected(_on_admob_interstitial_dismissed):
		_admob.interstitial_ad_dismissed_full_screen_content.connect(_on_admob_interstitial_dismissed)

	# Rewarded signals
	if not _admob.rewarded_ad_loaded.is_connected(_on_admob_rewarded_ad_loaded):
		_admob.rewarded_ad_loaded.connect(_on_admob_rewarded_ad_loaded)
	if not _admob.rewarded_ad_failed_to_load.is_connected(_on_admob_rewarded_ad_failed_to_load):
		_admob.rewarded_ad_failed_to_load.connect(_on_admob_rewarded_ad_failed_to_load)
	if not _admob.rewarded_ad_dismissed_full_screen_content.is_connected(_on_admob_rewarded_dismissed):
		_admob.rewarded_ad_dismissed_full_screen_content.connect(_on_admob_rewarded_dismissed)
	if not _admob.rewarded_ad_user_earned_reward.is_connected(_on_admob_rewarded_ad_user_earned_reward):
		_admob.rewarded_ad_user_earned_reward.connect(_on_admob_rewarded_ad_user_earned_reward)

func _load_missing_ads() -> void:
	if not _admob.is_banner_ad_loaded():
		_load_banner()
	if not is_interstitial_ready:
		_load_interstitial()
	if not is_rewarded_ready:
		_load_rewarded()

# ─── Ad Loading Helpers with Backoff ──────────────────────────────────────────

func _load_banner() -> void:
	if not _is_ready_to_load():
		return
	_admob.load_banner_ad()

func _load_interstitial() -> void:
	if not _is_ready_to_load() or is_interstitial_ready:
		return
	_admob.load_interstitial_ad()

func _load_rewarded() -> void:
	if not _is_ready_to_load() or is_rewarded_ready:
		return
	_admob.load_rewarded_ad()

func _show_banner() -> void:
	if _admob and _is_connected:
		_admob.show_banner_ad()

func _hide_banner() -> void:
	if _admob:
		_admob.hide_banner_ad()

func _is_ready_to_load() -> bool:
	return _is_connected and _admob_initialized and _consent_given

# ─── AdMob Callbacks ──────────────────────────────────────────────────────────

func _on_admob_initialization_completed(_status_data: InitializationStatus) -> void:
	_admob_initialized = true
	_update_label("AdMob initialized — loading ads…")
	_load_banner()
	_load_interstitial()
	_load_rewarded()

func _on_admob_banner_ad_loaded(_ad_info: AdInfo, _response_info: ResponseInfo) -> void:
	_banner_showing = true
	_banner_retry_delay = 5.0 # Reset backoff
	if _is_connected:
		_show_banner()
		_update_label("Banner showing")
	else:
		_update_label("Banner loaded (offline — will show on reconnect)")

func _on_admob_banner_ad_failed_to_load(_ad_info: AdInfo, _error_data: LoadAdError) -> void:
	_update_label("Banner failed to load — retrying in %ds" % int(_banner_retry_delay))
	if _is_connected:
		get_tree().create_timer(_banner_retry_delay).timeout.connect(func():
			if _is_connected and not _admob.is_banner_ad_loaded():
				_load_banner()
		)
		_banner_retry_delay = min(_banner_retry_delay * 2, MAX_RETRY_DELAY)

func _on_admob_interstitial_ad_loaded(_ad_info: AdInfo, _response_info: ResponseInfo) -> void:
	is_interstitial_ready = true
	_interstitial_retry_delay = 5.0 # Reset backoff
	_update_label("Interstitial loaded")

func _on_admob_interstitial_ad_failed_to_load(_ad_info: AdInfo, _error_data: LoadAdError) -> void:
	is_interstitial_ready = false
	_update_label("Interstitial failed — retrying in %ds" % int(_interstitial_retry_delay))
	if _is_connected:
		get_tree().create_timer(_interstitial_retry_delay).timeout.connect(func():
			if _is_connected and not is_interstitial_ready:
				_load_interstitial()
		)
		_interstitial_retry_delay = min(_interstitial_retry_delay * 2, MAX_RETRY_DELAY)

func _on_admob_rewarded_ad_loaded(_ad_info: AdInfo, _response_info: ResponseInfo) -> void:
	is_rewarded_ready = true
	_rewarded_retry_delay = 5.0 # Reset backoff
	_update_label("Rewarded ad loaded")

func _on_admob_rewarded_ad_failed_to_load(_ad_info: AdInfo, _error_data: LoadAdError) -> void:
	is_rewarded_ready = false
	_update_label("Rewarded failed — retrying in %ds" % int(_rewarded_retry_delay))
	if _is_connected:
		get_tree().create_timer(_rewarded_retry_delay).timeout.connect(func():
			if _is_connected and not is_rewarded_ready:
				_load_rewarded()
		)
		_rewarded_retry_delay = min(_rewarded_retry_delay * 2, MAX_RETRY_DELAY)

func _on_admob_rewarded_ad_user_earned_reward(ad_info: AdInfo, reward_data: RewardItem) -> void:
	rewarded_ad_user_earned_reward.emit(ad_info, reward_data)

func _on_admob_rewarded_dismissed(_ad_info: AdInfo) -> void:
	print("AdManager: Rewarded ad dismissed by user")
	is_rewarded_ready = false
	rewarded_ad_dismissed.emit()
	# Preload next ad
	get_tree().create_timer(1.0).timeout.connect(func():
		_load_rewarded()
	)

func _on_admob_interstitial_dismissed(_ad_info: AdInfo) -> void:
	print("AdManager: Interstitial ad dismissed by user")
	is_interstitial_ready = false
	interstitial_ad_dismissed.emit()
	# Preload next ad
	get_tree().create_timer(1.0).timeout.connect(func():
		_load_interstitial()
	)

# ─── Public API ───────────────────────────────────────────────────────────────

func is_rewarded_available() -> bool:
	return is_rewarded_ready and _is_connected

func is_interstitial_available() -> bool:
	return is_interstitial_ready and _is_connected

func show_rewarded() -> void:
	if not _is_ready_to_show():
		return
	if is_rewarded_ready:
		_admob.show_rewarded_ad()
		is_rewarded_ready = false
	else:
		_update_label("Rewarded ad not ready yet")

func show_interstitial() -> void:
	if not _is_ready_to_show():
		return
	if is_interstitial_ready:
		_admob.show_interstitial_ad()
		is_interstitial_ready = false
	else:
		_update_label("Interstitial not ready yet")

func load_rewarded() -> void:
	_load_rewarded()

func load_interstitial() -> void:
	_load_interstitial()

func _is_ready_to_show() -> bool:
	if not _is_connected:
		_update_label("No internet connection")
		return false
	if not _admob_initialized:
		_update_label("AdMob not initialized yet")
		return false
	if not _consent_given:
		_update_label("Ads disabled (no consent)")
		return false
	return true

func _update_label(text: String) -> void:
	if _label and _label.visible:
		_label.text = text
