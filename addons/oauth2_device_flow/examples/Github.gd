extends Node


func _ready() -> void:
	var flow_auth = DeviceFlowAuth.new()
	add_child(flow_auth)
	
	var session: DeviceFlowAuth.DeviceFlowSession = await flow_auth.request_auth("https://github.com/login/device/code",
	"https://github.com/login/oauth/access_token",
	"Ov23li4yd53ovWfE724P",
	[])
	
	%Code.text = session.user_code
	OS.shell_open(session.verification_uri)
	
	session.authenticated.connect(_authenticated)
	session.authentication_error.connect(_authentication_error)

func _authenticated(access_token: String, data: Dictionary):
	print("Authenticated: ", access_token)

func _authentication_error(error_code: String, data: Dictionary):
	print("Authentication Error!!: ", error_code)
