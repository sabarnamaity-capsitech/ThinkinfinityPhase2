extends Node

signal connectivity_changed(connected: bool)

const CONNECTIVITY_CHECK_INTERVAL := 10.0
const REQUEST_TIMEOUT := 5.0

var is_connected := false

var _timer: Timer
var _http_check: HTTPRequest

func _ready() -> void:
	_setup_timer()
	check_internet()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		# Check internet immediately when app is resumed
		check_internet()

func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = CONNECTIVITY_CHECK_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(check_internet)
	add_child(_timer)

func check_internet() -> void:
	if _http_check != null:
		# A check is already in progress
		return
	call_deferred(&"_check_internet_deferred")

func _check_internet_deferred() -> void:
	if _http_check != null:
		return
		
	_http_check = HTTPRequest.new()
	_http_check.timeout = REQUEST_TIMEOUT
	add_child(_http_check)
	_http_check.request_completed.connect(_on_request_completed)
	
	var err := _http_check.request("https://www.google.com/generate_204")
	if err != OK:
		_cleanup()
		_set_connectivity(false)

func _cleanup() -> void:
	if _http_check != null:
		_http_check.queue_free()
		_http_check = null

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_cleanup()
	
	var connected := (result == HTTPRequest.RESULT_SUCCESS and response_code > 0)
	_set_connectivity(connected)

func _set_connectivity(new_state: bool) -> void:
	if is_connected != new_state:
		is_connected = new_state
		print("NetworkManager: Connectivity changed to: ", "ONLINE" if is_connected else "OFFLINE")
		connectivity_changed.emit(is_connected)
