@icon("res://addons/oauth2_device_flow/DeviceFlowAuth.svg")
extends Node
class_name DeviceFlowAuth

var _http: AwaitableHTTPRequest

class DeviceFlowSession extends Node:
	## The device verification code.
	var device_code: String
	## The end-user verification URI on the authorization
	var verification_uri: String
	## The end-user verification code.
	var user_code: String
	## The lifetime in seconds of the "device_code" and "user_code".
	var expires_in: int
	## The amount of time in seconds that the client will wait.
	var interval: int = 5
	## A verification URI that includes the "user_code"
	var verification_uri_complete: String
	var _poll_url: String
	var _grant_type: String
	var _client_id: String
	var _http: AwaitableHTTPRequest
	
	var _check_timer: Timer
	
	signal authenticated(access_token: String, data: Dictionary)
	signal authentication_error(error_code: String, data: Dictionary)
	
	func _ready() -> void:
		_check_timer = Timer.new()
		_check_timer.autostart = false
		_check_timer.one_shot = false
		_check_timer.wait_time = interval + 1
		add_child(_check_timer)
		_check_timer.timeout.connect(_check_state)
		_check_timer.start()
	
	func _init_http():
		if _http == null:
			_http = AwaitableHTTPRequest.new()
			add_child(_http)
	
	func _check_state():
		_init_http()
		
		var req := await _http.async_request(_poll_url + "?client_id=" + _client_id + "&device_code=" + device_code + "&grant_type=" + _grant_type, [
			"Accept: application/json"
		], HTTPClient.METHOD_POST)
		
		var data := req.body_as_json()
		
		if data.get("error", null) != null:
			if data.error != "authorization_pending" and data.error != "slow_down":
				_check_timer.stop()
				authentication_error.emit(data.error, data)
		
		if data.get("access_token", null) != null:
			_check_timer.stop()
			authenticated.emit(data.access_token, data)

func _init_http():
	if _http == null:
		_http = AwaitableHTTPRequest.new()
		add_child(_http)

## Request Authentication
func request_auth(url: String, poll_url: String, client_id: String, scopes: PackedStringArray = [], grant_type: String = "urn:ietf:params:oauth:grant-type:device_code") -> DeviceFlowSession:
	_init_http()
	
	var req := await _http.async_request(url + "?client_id=" + client_id + "&scopes=" + ",".join(scopes), [
		"Accept: application/json"
	], HTTPClient.METHOD_POST)
	
	var data = req.body_as_json()
	
	var session = DeviceFlowSession.new()
	
	session.device_code = data.device_code
	session.verification_uri = data.verification_uri
	session.user_code = data.user_code
	session.expires_in = data.expires_in
	session.verification_uri_complete = data.get("verification_uri_complete", "")
	session.interval = data.get("interval", 5)
	session._poll_url = poll_url
	session._grant_type = grant_type
	session._client_id = client_id
	
	add_child(session)
	
	return session
