extends CanvasLayer

# Notification settings
@export var fade_duration: float = 1.0
@export var display_duration: float = 3.0
@export var max_notifications: int = 5
@export var notification_style: String = "Default" # Optional style/theme handling

# Called when a new notification is added
func add_notification(message: String):
	var notification = create_notification_label(message)
	$VBoxContainer.add_child(notification)
	
	# Ensure notification removal after duration
	await get_tree().create_timer(display_duration).timeout
	remove_notification(notification)

func create_notification_label(message: String) -> Panel:
	# Create a panel for the notification
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 200)  # Adjust size for readability
	
	# Create a label for the text
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	label.set_autowrap_mode(TextServer.AUTOWRAP_WORD)
	
	# Add the label to the panel
	panel.add_child(label)
	return panel

func remove_notification(notification: Panel):
	if notification in $VBoxContainer.get_children():
		# Fade-out animation for panel
		var tween = create_tween()
		tween.tween_property(notification, "modulate:a", 0.0, fade_duration).from(1.0)
		await tween.finished
		$VBoxContainer.remove_child(notification)
		notification.queue_free()

func get_notification_theme() -> Theme:
	# Optional: Load a custom theme
	return null
