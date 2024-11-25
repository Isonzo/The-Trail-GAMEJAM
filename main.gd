extends Node

var card_paths = preload("res://card_paths.gd").new()

const MAX_RESOURCES = 12

var food = 6
var ammo = 6
var morale = 6
var wealth = 0
var movement_speed = 3
var distance = -movement_speed
var landmark_goal = 4
var  immune: int = 0
var attack_immunity: int = 0
var hunkered: int = 0
var ammo_hog: int = 0
var immortality: int = 0
var temp_speed: int = 0
var turn_number = 0

var selected_a: bool = false
var from_draw: bool = false
var double_card: bool = false
var rummed_up: bool = false
var person_helped: bool = false

var possible_cards: Dictionary = {}
var special_cards: Dictionary = {}
var hand: Array[Card] = []
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []


func _ready() -> void:

	load_cards(possible_cards)
	var clover = load("res://special_cards/clover.tres")
	var rum = load("res://special_cards/rum.tres")
	special_cards = {
		clover.title: clover,
		rum.title: rum
	}
	

	$Music.play()
	count_card_types()
	
	draw_pile.append(possible_cards["Campfire Stories"])
	draw_pile.append(possible_cards["Storm"])
	draw_pile.append(possible_cards["Forage"])
	draw_pile.append(possible_cards["Wild Beast"])
	draw_pile.append(possible_cards["Forage"])
	var card = possible_cards.values()[randi() % possible_cards.size()]
	draw_pile.append(card)

	draw_pile.shuffle()
	
	new_turn()
	
func new_turn():
	turn_number += 1
	# Travel distance
	if hunkered <= 0:
		if temp_speed > 0:
			distance += 5
			temp_speed -= 1
		distance += movement_speed
	else:
		hunkered -= 1

	for card in hand:
		discard_pile.append(card)
	hand.clear()
	# Draw cards
	draw()
	
	# Consume food
	food -= 1
	
	if food < 0:
		morale += food
		food = 0
	if wealth < 0:
		morale += wealth
		wealth = 0
	if ammo < 0:
		morale += food
		ammo = 0
	
		
	if wealth > MAX_RESOURCES and turn_number % 2 == 0:
		wealth -= round(float(wealth)/MAX_RESOURCES)
		$NotificationSystem.add_notification("-Wealth, past max")
	if ammo > MAX_RESOURCES and turn_number % 2 == 0:
		ammo -= round(float(ammo)/MAX_RESOURCES)
		$NotificationSystem.add_notification("-Ammo, past max")
	if morale > MAX_RESOURCES and turn_number % 2 == 0:
		morale -= round(float(morale)/MAX_RESOURCES)
		$NotificationSystem.add_notification("-Morale, past max")
	if food > MAX_RESOURCES and turn_number % 2 == 0:
		food -= round(float(food)/MAX_RESOURCES)
		$NotificationSystem.add_notification("-Food, past max")
		
	if immortality > 0:
		immortality -= 1
		if morale <= 0:
			morale = 1
	
	if morale <= 0:
		# Game over man, Game over
		get_tree().change_scene_to_file("res://game_over.tscn")
	elif distance >= 100:
		get_tree().change_scene_to_file("res://you_win.tscn")
	
	update_ui(hand)

func load_cards(deck: Dictionary) -> void:
	for card_path in card_paths.card_paths:
		var card = load(card_path)  # Load the card resource
		if card:
			deck[card.title] = card  # Add the card to the deck dictionary
		else:
			print("Failed to load card at path: ", card_path)


func draw():
	var max_hand_size = 2
	
	# Ensure the draw pile has enough cards; reshuffle if necessary
	if draw_pile.size() == 0:
		reshuffle_discard_pile()

	while hand.size() < max_hand_size and draw_pile.size() > 0:
		var drawn_card = draw_pile.pop_back()  # Remove the last card in the draw pile
		hand.append(drawn_card)
		print("Drew card: ", drawn_card.title)
		if draw_pile.size() == 0:
			reshuffle_discard_pile()
	draw_pile.shuffle()

func reshuffle_discard_pile():
	$Shuffle.play()
	if discard_pile.size() > 0:
		draw_pile.append_array(discard_pile)
		draw_pile.shuffle()
		discard_pile.clear()
		print("Reshuffled discard pile into draw pile.")
	else:
		print("No cards left to draw!")

func fill_hand():
	var max_hand_size = 2

	# Ensure there are enough cards to draw; reshuffle if needed
	while hand.size() < max_hand_size:
		if draw_pile.size() == 0:
			reshuffle_discard_pile()

		# If no cards left after reshuffling, stop filling the hand
		if draw_pile.size() == 0:
			print("No cards available to fill the hand!")
			break

		# Draw a card from the draw pile
		var drawn_card = draw_pile.pop_back()
		hand.append(drawn_card)
		print("Added card to hand: ", drawn_card.title)




func modify_resource(params: EffectParam):
	var resource_name: String = params.name
	var modification_value: int = params.value
	
	if resource_name == "copy":
		discard_pile.append(possible_cards["False Trail"])
		$NotificationSystem.add_notification("False Trail copy added")
		return
	
	if resource_name == "card":
		if modification_value > 0:
			var card = possible_cards.values()[randi() % possible_cards.size()]
			draw_pile.append(card)
			$NotificationSystem.add_notification("Added " + card.title + "(" + card.type + ")")
		elif modification_value < 0:
			if draw_pile.size() == 0 and discard_pile.size() == 0:
				$NotificationSystem.add_notification("No more cards to discard")
			elif draw_pile.size() == 0 and discard_pile.size() > 0:
				reshuffle_discard_pile()
			else:
				var index = randi() % draw_pile.size()
				$NotificationSystem.add_notification("Removed " + draw_pile[index].title + "(" + draw_pile[index].type + ")")
				draw_pile.remove_at(index)
	if landmark_goal < distance:
		var card = possible_cards.values()[randi() % possible_cards.size()]
		draw_pile.append(card)
		$NotificationSystem.add_notification("Added " + card.title + "(" + card.type + ")")
		landmark_goal += 8
	
	if resource_name == "ammo" and ammo_hog > 0 and modification_value > 0:
		modification_value *= 2
		ammo_hog -= 1
	
	if resource_name in self:
		self.set(resource_name, self.get(resource_name) + modification_value)
		
		print("Modified ", resource_name, " by ", modification_value, ". New value: ", 
		self.get(resource_name))
	else:
		print("Resource ", resource_name, " does not exist.")

func get_immunity_status() -> String:
	var statuses = {
		"Immune": immune,
		"Atk Immune": attack_immunity,
		"Hunkered": hunkered,
		"Ammo Hog": ammo_hog,
		"Immortal": immortality,
		"Speed Boost": temp_speed
	}
	
	var non_zero_statuses = []
	for key in statuses:
		if statuses[key] > 0:
			non_zero_statuses.append("%s: %d" % [key, statuses[key]])
	
	return " | ".join(non_zero_statuses)

func update_ui(hand: Array[Card]):
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/Title.text = hand[0].title
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/Type.text = hand[0].type
	if (hand[0].removes_self):
		$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/Persistence.text = "Removes after use"
	else:
		$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/Persistence.text = ""
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/Description.text = hand[0].description

	# Generate GoodText dynamically
	var good_text = "If skipped: "
	for effect in hand[0].bad_effect_params:
		good_text += "%s: %d, " % [effect.name, effect.value]
	if hand[0].bad_effect_params.size() == 0:
		good_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/GoodText.text = good_text.strip_edges()
	
	var a_image
	if hand[0].image:
		a_image = hand[0].image
	else:
		match hand[0].type:
			"Fight":
				a_image = load("res://gun.png")
			"Survival":
				a_image = load("res://survival.png")
			"Interaction":
				a_image = load("res://interaction.png")

	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/TextureRect.texture = a_image
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/TextureRect.set_stretch_mode(5)
	
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/Title.text = hand[1].title
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/Type.text = hand[1].type
	if (hand[1].removes_self):
		$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/Persistence.text = "Removes after use"
	else:
		$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/Persistence.text = ""
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/Description.text = hand[1].description
	

	# Generate GoodText dynamically
	good_text = "If skipped: "
	for effect in hand[1].bad_effect_params:
		good_text += "%s: %d, " % [effect.name, effect.value]
	if hand[1].bad_effect_params.size() == 0:
		good_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/GoodText.text = good_text.strip_edges()

	var b_image
	if hand[1].image:
		b_image = hand[1].image
	else:
		match hand[1].type:
			"Fight":
				b_image = load("res://gun.png")
			"Survival":
				b_image = load("res://survival.png")
			"Interaction":
				b_image = load("res://interaction.png")


	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/TextureRect.texture = b_image
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/TextureRect.set_stretch_mode(5)
	
	# Update Resources
	$UI/Control/VBoxContainer/Resources/Food.text = "Food: " + str(food)
	$UI/Control/VBoxContainer/Resources/Ammo.text = "Ammo : " + str(ammo)
	$UI/Control/VBoxContainer/Resources/Morale.text = "Morale: " + str(morale)
	$UI/Control/VBoxContainer/Resources/Wealth.text = "Wealth: " + str(wealth)
	$UI/Control/VBoxContainer/Resources/Draw.text = "Draw: " + str(draw_pile.size())
	$UI/Control/VBoxContainer/Resources/Discard.text = "Discard: " + str(discard_pile.size())
	
	$UI/Control/VBoxContainer/ProgressBar.value = distance
	
	$UI/Control/VBoxContainer/Status.text = get_immunity_status()
	
	# CODE TO MAKE SURE IT UPDATES AFTER CLICK
	# Get the global mouse position
	if is_inside_tree():
		var mouse_pos = get_viewport().get_mouse_position()

		# Get the CardA and CardB UI elements
		var card_a_rect = $UI/Control/VBoxContainer/Cards/CardA.get_global_rect()
		var card_b_rect = $UI/Control/VBoxContainer/Cards/CardB.get_global_rect()

		# Check if the mouse is over CardA
		if card_a_rect.has_point(mouse_pos):
			_on_card_a_mouse_exited()
			_on_card_a_mouse_entered()
		elif card_b_rect.has_point(mouse_pos):
			_on_card_b_mouse_exited()
			_on_card_b_mouse_entered()


func _on_card_a_pressed() -> void:
	$Deal.play()
	selected_a = true
	fill_hand()
	for effect in hand[0].good_effect_params:
		modify_resource(effect)
	if self.has_method(hand[0].special_effect):
		await self.call(hand[0].special_effect)
	if (hand.size() > 1):
		if immune > 0:
			immune -= 1
		elif attack_immunity > 0 and hand[1].type == "Fight":
			attack_immunity -= 1
		else:
			for effect in hand[1].bad_effect_params:
				modify_resource(effect)
	if (double_card and hand[0].title != "Abundance"):
		double_card = false
		_on_card_a_pressed()
		return

	if hand[0].removes_self:
		hand.remove_at(0)
	new_turn()

func _on_card_b_pressed() -> void:
	$Deal.play()
	selected_a = false
	fill_hand()
	for effect in hand[1].good_effect_params:
		modify_resource(effect)
	if self.has_method(hand[1].special_effect):
		await self.call(hand[1].special_effect)
	if (hand.size() > 1):
		if immune > 0:
			immune -= 1
		elif attack_immunity > 0 and hand[1].type == "Fight":
			attack_immunity -= 1
		else:
			for effect in hand[0].bad_effect_params:
				modify_resource(effect)
	if (double_card and hand[1].title != "Abundance"):
		double_card = false
		_on_card_b_pressed()
		return
	
	if hand.size() > 1:
		if hand[1].removes_self:
			hand.remove_at(1)
	new_turn()

# Special effects
func inspiration():
	if morale > 10:
		movement_speed += 1

func immunity():
	immune += 2

func fight_immunity():
	attack_immunity += 1

func hunker_down():
	attack_immunity += round(draw_pile.size() / 2.0)
	hunkered = draw_pile.size()

func ammo_check():
	if ammo > 2: # since the cost is 3 ammo
		morale += 2

signal card_discarded()

func redraw_from_discard():
	from_draw = false
	if discard_pile.size() <= 0:
		return
	$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "Choose a card to redraw"
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	for card in discard_pile:
		var button = Button.new()
		button.text = card.title + " (" + card.type + ")"
		button.connect("pressed", Callable(self, "_on_card_discarded").bind(card))
		$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(button)
		
	# Show the ChoicePanel
	$UI/Control/ChoicePanel.show()
	
	await self.card_discarded

func top_switch():
	if double_card:
		return
	immune += 1
	if selected_a:
		draw_pile.append(hand[0])
		discard_pile.append(hand[1])
	else:
		draw_pile.append(hand[1])
		discard_pile.append(hand[0])

func nomad():
	var net = 0
	for card in discard_pile:
		if card.type == "Fight":
			net += 1
	if net == 0:
		movement_speed += 1
		return
	net = 0
	for card in draw_pile:
		if card.type == "Fight":
			net += 1
	if net == 0:
		movement_speed += 1
		return 

func discard_from_draw():
	from_draw = true
	if draw_pile.size() <= 0:
		return
	$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "Choose a card to discard"
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	for card in draw_pile:
		var button = Button.new()
		button.text = card.title + " (" + card.type + ")"
		button.connect("pressed", Callable(self, "_on_card_discarded").bind(card))
		$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(button)
		
	# Show the ChoicePanel
	draw_pile.shuffle()
	$UI/Control/ChoicePanel.show()
	
	await self.card_discarded

func _on_card_discarded(card: Card):
	# Remove the card from the draw pile and add it to the discard pile
	if rummed_up:
		discard_pile.erase(card)
		print("Forgot card: ", card.title)
		rummed_up = false
	elif from_draw:
		draw_pile.erase(card)
		discard_pile.append(card)
		print("Discarded card: ", card.title)
	else:
		discard_pile.erase(card)
		draw_pile.append(card)
		print("Redrawn card: ", card.title)
		

	$UI/Control/ChoicePanel.hide()
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()

	# Update the UI to reflect changes
	update_ui(hand)
	emit_signal("card_discarded")

func see_next_cards(card_count: int = 3):
	# Ensure there are cards in the draw pile
	if draw_pile.size() <= 0:
		$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "The draw pile is empty."
		$UI/Control/ChoicePanel.show()
		return

	# Limit the number of cards displayed to the smaller of draw pile size or card_count
	var preview_count = min(draw_pile.size(), card_count)

	# Update UI
	$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "Next %d cards in the draw pile:" % preview_count
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	
	# Show only the last 'preview_count' cards in the draw pile
	for i in range(draw_pile.size() - preview_count, draw_pile.size()):
		var card = draw_pile[i]
		var button = Button.new()
		button.text = "%s (%s)" % [card.title, card.type]
		button.disabled = true  # Disable interaction to prevent discarding
		$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(button)

	# Show the ChoicePanel
	$UI/Control/ChoicePanel.show()


func see_and_discard(card_count: int = 3):
	# Ensure there are cards in the draw pile
	from_draw = true
	if draw_pile.size() <= 0:
		$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "The draw pile is empty."
		$UI/Control/ChoicePanel.show()
		return

	# Limit the number of cards displayed to the smaller of draw pile size or card_count
	var preview_count = min(draw_pile.size(), card_count)

	# Update UI
	$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "Choose a card to discard:"
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	
	# Create interactable buttons for the last 'preview_count' cards
	for i in range(draw_pile.size() - preview_count, draw_pile.size()):
		var card = draw_pile[i]
		var button = Button.new()
		button.text = "%s (%s)" % [card.title, card.type]
		button.connect("pressed", Callable(self, "_on_card_discarded").bind(card))
		$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(button)

	# Show the ChoicePanel
	$UI/Control/ChoicePanel.show()
	
	# Add a "Go Back" button
	var back_button = Button.new()
	back_button.text = "Go Back"
	back_button.connect("pressed", Callable(self, "_on_go_back_pressed").bind())
	$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(back_button)

# Define the function for the "Go Back" button
func _on_go_back_pressed():
	$UI/Control/ChoicePanel.hide()

func morale_per_fight():
	var num = 0
	for card in draw_pile:
		if card.type == "Fight":
			num += 1
	morale += min(7, num)

func food_per_survival_discard():
	for card in discard_pile:
		if card.type == "Survival":
			food += 1

func exhaust_other_card():
	if double_card:
		hand.remove_at(0)
		hand.remove_at(1)
		double_card = false
		return
		
	if (selected_a):
		hand.remove_at(1)
	else:
		hand.remove_at(0)

func double_morale():
	var num = draw_pile.size() + 2 + discard_pile.size()
	if morale < 5:
		morale += num

func double_ammo_gain():
	ammo_hog += 2

func multiplication():
	double_card = true

func immortal():
	immortality += 3

func outlaw():
	var possible_card_keys = possible_cards.keys()
	var card: Card = null
	possible_card_keys.shuffle()
	for key in possible_card_keys:
		var possible_card = possible_cards[key]
		if possible_card.type == "Fight":
			card = possible_card
			break
	draw_pile.append(card)

func speed_boost():
	temp_speed += 3

func replace_discard():
	var num = discard_pile.size()
	discard_pile.clear()
	var possible_card_keys = possible_cards.keys()
	possible_card_keys.shuffle()
	for i in range(num):
		var random_key = possible_card_keys[randi() % possible_card_keys.size()]
		discard_pile.append(possible_cards[random_key])
	morale -= num

func bonanza():
	var net = 0
	for card in discard_pile:
		match card.type:
			"Survival":
				ammo -= 1
			"Interaction":
				wealth += 1

func carpentry():
	if selected_a:
		hand.remove_at(1)
	else:
		hand.remove_at(0)
	var possible_card_keys = possible_cards.keys()
	possible_card_keys.shuffle()
	for i in range(2):
		var random_key = possible_card_keys[randi() % possible_card_keys.size()]
		draw_pile.append(possible_cards[random_key])
		
func last_stand():
	var net = 3 - morale
	morale += 2 * net
	attack_immunity += 1 * net
	ammo-= net

func special_card_help():
	possible_cards["Campfire Stories"].description = "After you helped that person in need, you finally have someone to share a story with."
	possible_cards["Campfire Stories"].special_desc = ""
	# Double the values of EffectParam for "Campfire Stories"
	for effect in possible_cards["Campfire Stories"].good_effect_params:
		effect.value *= 2

	for effect in possible_cards["Campfire Stories"].bad_effect_params:
		effect.value *= 2
	
	var num = randi_range(0, 1)
	if double_card:
		draw_pile.append(special_cards["Lucky Charm"])
		draw_pile.append(special_cards["Fancy Rum"])
		double_card = false
		possible_cards.erase("Person in Need")
		return
	if num == 0:
		draw_pile.append(special_cards["Lucky Charm"])
	else:
		draw_pile.append(special_cards["Fancy Rum"])

	possible_cards.erase("Person in Need")

func random_reward():
	var num = randi_range(0, 2)
	match num:
		0:
			food += 5
		1:
			ammo += 5
		2:
			wealth += 5

func survival_deck():
	var net = 0
	for card in discard_pile:
		match card.type:
			"Fight":
				net -= 1
			"Survival":
				net += 1
	food += net

func remove_card():
	rummed_up = true
	if discard_pile.size() <= 0:
		if selected_a:
			hand.remove_at(0)
		else:
			hand.remove_at(1)
		return
	$UI/Control/ChoicePanel/Margin/VBoxContainer/Label.text = "Choose a card to remove"
	for child in $UI/Control/ChoicePanel/Margin/VBoxContainer.get_children():
		if child is Button:
			child.queue_free()
	for card in discard_pile:
		var button = Button.new()
		button.text = card.title + " (" + card.type + ")"
		button.connect("pressed", Callable(self, "_on_card_discarded").bind(card))
		$UI/Control/ChoicePanel/Margin/VBoxContainer.add_child(button)
		
	# Show the ChoicePanel
	$UI/Control/ChoicePanel.show()
	
	await self.card_discarded

func _on_card_a_mouse_entered() -> void:
	# Generate GoodText dynamically
	var good_text = "If chosen: "
	for effect in hand[0].good_effect_params:
		good_text += "%s: %d, " % [effect.name, effect.value]
	if hand[0].good_effect_params.size() == 0:
		good_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/GoodText.text = good_text.strip_edges()
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/BadText.text = hand[0].special_desc



func _on_card_a_mouse_exited() -> void:
	# Generate BadText dynamically
	var bad_text = "If skipped: "
	for effect in hand[0].bad_effect_params:
		bad_text += "%s: %d, " % [effect.name, effect.value]
	if hand[0].bad_effect_params.size() == 0:
		bad_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/GoodText.text = bad_text.strip_edges()
	$UI/Control/VBoxContainer/Cards/CardA/VBoxContainer/BadText.text = ""


func _on_card_b_mouse_entered() -> void:
	# Generate GoodText dynamically
	var good_text = "If chosen: "
	for effect in hand[1].good_effect_params:
		good_text += "%s: %d, " % [effect.name, effect.value]
	if hand[1].good_effect_params.size() == 0:
		good_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/GoodText.text = good_text.strip_edges()
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/BadText.text = hand[1].special_desc


func _on_card_b_mouse_exited() -> void:
	# Generate BadText dynamically
	var bad_text = "If skipped: "
	for effect in hand[1].bad_effect_params:
		bad_text += "%s: %d, " % [effect.name, effect.value]
	if hand[1].bad_effect_params.size() == 0:
		bad_text += "Nothing happens"
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/GoodText.text = bad_text.strip_edges()
	$UI/Control/VBoxContainer/Cards/CardB/VBoxContainer/BadText.text = ""

func count_card_types():
	var card_counts = {
		"Interaction": 0,
		"Fight": 0,
		"Survival": 0
	}

	# Iterate through all possible cards
	for card in possible_cards.values():
		if card_counts.has(card.type):
			card_counts[card.type] += 1
		else:
			print("Unknown card type: ", card.type)

	# Print the counts
	for card_type in card_counts.keys():
		print("%s Cards: %d" % [card_type, card_counts[card_type]])
