extends Node

# Simple file-backed debug logger. Use DebugLogger.log(), .info(), .warn(), .error()
const LOG_PATH: String = "user://debug.log"
const SYS_LOG_PATH: String = "C:/temp/godot_output.log"

func _timestamp() -> String:
    return str(Time.get_unix_time_from_system())

func _ensure_sys_dir_exists() -> void:
    var sys_dir = SYS_LOG_PATH.get_base_dir()
    if sys_dir == "":
        return
    # Attempt to create directory if missing
    var dir = DirAccess.open(sys_dir)
    if not dir:
        DirAccess.make_dir_recursive_absolute(sys_dir)

func _write_line_to_path(path: String, line: String) -> void:
    # Try to open in append mode; if not available, fallback to write and append
    var file = null
    # WRITE_READ mode may not create files; use WRITE to create/truncate, but we want append — so open and seek_end
    file = FileAccess.open(path, FileAccess.WRITE_READ)
    if not file:
        # Try create+write then reopen
        file = FileAccess.open(path, FileAccess.WRITE)
        if file:
            file.store_string(line + "\n")
            file.close()
            return
        else:
            return
    # Append
    file.seek_end()
    file.store_string(line + "\n")
    file.close()

func _write_line(line: String) -> void:
    # Write to user:// debug file (best-effort)
    _write_line_to_path(LOG_PATH, line)

    # Also attempt to write to the system-level godot output log (best-effort)
    _ensure_sys_dir_exists()
    _write_line_to_path(SYS_LOG_PATH, line)

func log(message: String) -> void:
    var line = "[LOG] [" + _timestamp() + "] " + message
    print(line)
    _write_line(line)

func info(message: String) -> void:
    var line = "[INFO] [" + _timestamp() + "] " + message
    print(line)
    _write_line(line)

func warn(message: String) -> void:
    var line = "[WARN] [" + _timestamp() + "] " + message
    print(line)
    _write_line(line)

func error(message: String) -> void:
    var line = "[ERROR] [" + _timestamp() + "] " + message
    print(line)
    _write_line(line)

func _ready() -> void:
    # Ensure system log directory exists where possible (best-effort)
    _ensure_sys_dir_exists()
