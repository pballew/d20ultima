extends Control

signal town_entered(town_data: Dictionary)
signal dialog_cancelled

@onready var town_label = $DialogPanel/VBoxContainer/TownLabel
@onready var message_label = $DialogPanel/VBoxContainer/MessageLabel

var current_town_data: Dictionary = {}

func _ready():
    # Hide dialog initially
    visible = false

    # Ensure dialog appears above other elements
    z_index = 1000

    # Allow processing when paused so input works
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    focus_mode = Control.FOCUS_ALL

    print("DEBUG TownDialog: _ready called, z_index set to: ", z_index)
    print("DEBUG TownDialog: process_mode set to PROCESS_MODE_WHEN_PAUSED")

func show_town_dialog(town_data: Dictionary):
    print("DEBUG TownDialog: show_town_dialog called with: ", town_data)
    current_town_data = town_data

    var viewport_size = get_viewport().size
    print("DEBUG TownDialog: Viewport size: ", viewport_size)

    # Get the camera position to position dialog relative to current view
    var camera_position = Vector2.ZERO
    var camera = get_viewport().get_camera_2d()
    if camera:
        camera_position = camera.get_screen_center_position()
        print("DEBUG TownDialog: Camera center position: ", camera_position)
    else:
        print("DEBUG TownDialog: No camera found, using Vector2.ZERO")

    # Position the entire dialog at the camera's view center
    var dialog_screen_pos = camera_position - viewport_size / 2.0
    position = dialog_screen_pos
    size = viewport_size

    print("DEBUG TownDialog: Dialog positioned at: ", position)
    print("DEBUG TownDialog: Dialog size: ", size)

    # Ensure background fills the dialog area (which now covers the screen)
    var background = $Background
    if background:
        background.position = Vector2.ZERO
        background.size = viewport_size
        background.anchors_preset = Control.PRESET_FULL_RECT
        print("DEBUG TownDialog: Background position: ", background.position)
        print("DEBUG TownDialog: Background size: ", background.size)

    if town_data.has("name"):
        town_label.text = "Welcome to " + town_data.name + "!"
        print("DEBUG TownDialog: Set town label to: ", town_label.text)
    else:
        town_label.text = "Welcome to this town!"
        print("DEBUG TownDialog: Set town label to default")

    # Updated prompt to use keyboard (y/n)
    message_label.text = "Do you want to enter the town? (y/n)"
    print("DEBUG TownDialog: Set message label to: ", message_label.text)

    # Hide/remove the button container if present
    if has_node("DialogPanel/VBoxContainer/ButtonContainer"):
        var btn_container := $DialogPanel/VBoxContainer/ButtonContainer
        btn_container.visible = false
        btn_container.process_mode = Node.PROCESS_MODE_DISABLED
        for child in btn_container.get_children():
            if child is BaseButton:
                child.disabled = true
        print("DEBUG TownDialog: ButtonContainer hidden/disabled")

    visible = true

    # Center the dialog panel within the dialog area
    var dialog_panel = $DialogPanel
    if dialog_panel:
        var panel_size = Vector2(400, 200)
        var center_x = (viewport_size.x - panel_size.x) / 2.0
        var center_y = (viewport_size.y - panel_size.y) / 2.0
        dialog_panel.position = Vector2(center_x, center_y)
        dialog_panel.size = panel_size
        print("DEBUG TownDialog: Panel centered at: ", dialog_panel.position)
        print("DEBUG TownDialog: Viewport size: ", viewport_size)
        print("DEBUG TownDialog: Panel size: ", panel_size)

    # Pause the game while dialog is shown and grab focus for key input
    get_tree().paused = true
    grab_focus()
    print("DEBUG TownDialog: Game paused: ", get_tree().paused, " | Focus grabbed: ", has_focus())

func hide_dialog():
    print("DEBUG TownDialog: hide_dialog() called - hiding dialog and unpausing game")
    visible = false
    get_tree().paused = false
    print("DEBUG TownDialog: Dialog hidden, visible = ", visible, ", paused = ", get_tree().paused)

func _input(event):
    if not visible:
        return
    # Close with Escape as before
    if event.is_action_pressed("ui_cancel"):
        print("DEBUG TownDialog: ui_cancel pressed -> cancel")
        hide_dialog()
        dialog_cancelled.emit()
        return

    # Accept Y/N keys (Godot 4 keycode)
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_Y:
                print("DEBUG TownDialog: 'Y' pressed -> enter town")
                hide_dialog()
                town_entered.emit(current_town_data)
            KEY_N:
                print("DEBUG TownDialog: 'N' pressed -> cancel")
                hide_dialog()
                dialog_cancelled.emit()

# Removed old button handlers and disconnect logic since buttons are no longer used.