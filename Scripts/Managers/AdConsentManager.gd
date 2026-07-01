extends Node
class_name AdConsentManager

signal consent_status_resolved(can_show_ads: bool)

var _admob: Admob
var _is_connected := false
var _label: Label

func setup(admob_node: Admob, debug_label: Label) -> void:
	_admob = admob_node
	_label = debug_label
	_connect_native_signals()

func set_network_connected(connected: bool) -> void:
	_is_connected = connected
	if _is_connected and _admob:
		check_consent()

func check_consent() -> void:
	if not _is_connected:
		_update_label("Offline — waiting for connection to check consent")
		return

	if _admob:
		# update_consent_info is the correct method defined in the Admob plugin wrapper
		_admob.update_consent_info()
		_update_label("Checking GDPR consent...")

func _connect_native_signals() -> void:
	if not _admob:
		return
	if not _admob.consent_info_updated.is_connected(_on_admob_consent_info_updated):
		_admob.consent_info_updated.connect(_on_admob_consent_info_updated)
	if not _admob.consent_info_update_failed.is_connected(_on_admob_consent_info_update_failed):
		_admob.consent_info_update_failed.connect(_on_admob_consent_info_update_failed)
	if not _admob.consent_form_loaded.is_connected(_on_admob_consent_form_loaded):
		_admob.consent_form_loaded.connect(_on_admob_consent_form_loaded)
	if not _admob.consent_form_failed_to_load.is_connected(_on_admob_consent_form_failed_to_load):
		_admob.consent_form_failed_to_load.connect(_on_admob_consent_form_failed_to_load)
	if not _admob.consent_form_dismissed.is_connected(_on_admob_consent_form_dismissed):
		_admob.consent_form_dismissed.connect(_on_admob_consent_form_dismissed)

func _on_admob_consent_info_updated() -> void:
	var consent := _admob.get_consent_status()
	if consent != null:
		print("AdConsentManager: UMP consent status updated: ", consent.to_status_string())
		match consent.status:
			UserConsent.Status.REQUIRED:
				if _admob.is_consent_form_available():
					print("AdConsentManager: Consent form available, loading form")
					_update_label("Loading consent form…")
					_admob.load_consent_form()
				else:
					push_warning("AdConsentManager: Consent REQUIRED but form not available.")
					_resolve(false)
			UserConsent.Status.NOT_REQUIRED, UserConsent.Status.OBTAINED:
				_resolve(true)
			UserConsent.Status.UNKNOWN, _:
				_resolve(false)
	else:
		push_warning("AdConsentManager: Consent status is null.")
		_resolve(false)

func _on_admob_consent_info_update_failed(error_data: FormError) -> void:
	push_warning("AdConsentManager: UMP Consent info update failed: ", error_data.get_message())
	# Fallback: do not block ad setup if checking fails due to transient network issues
	_resolve(true)

func _on_admob_consent_form_loaded() -> void:
	print("AdConsentManager: Consent form loaded successfully, showing form")
	_admob.show_consent_form()

func _on_admob_consent_form_failed_to_load(error_data: FormError) -> void:
	push_warning("AdConsentManager: Consent form failed to load: ", error_data.get_message())
	_resolve(false)

func _on_admob_consent_form_dismissed(error_data: FormError) -> void:
	if error_data and error_data.get_code() != 0:
		push_warning("AdConsentManager: Consent form dismissed with error: ", error_data.get_message())
	
	# Consent form dismissed, recheck current status
	var consent := _admob.get_consent_status()
	if consent != null:
		var consent_ok := (consent.status == UserConsent.Status.OBTAINED or consent.status == UserConsent.Status.NOT_REQUIRED)
		_resolve(consent_ok)
	else:
		_resolve(false)

func _resolve(can_show_ads: bool) -> void:
	print("AdConsentManager: Consent status resolved -> can_show_ads = ", can_show_ads)
	if not can_show_ads:
		_update_label("Ads disabled (consent denied).")
	consent_status_resolved.emit(can_show_ads)

func _update_label(text: String) -> void:
	if _label and _label.visible:
		_label.text = text
