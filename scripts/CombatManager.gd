class_name CombatManager
extends Node

signal combat_finished(player_won: bool)
signal turn_changed(current_character: Character)
signal combat_message(message: String)

var combat_participants: Array[Character] = []
var current_turn_index: int = 0
var is_combat_active: bool = false

func start_combat(player: Character, enemies: Array):
	combat_participants.clear()
	combat_participants.append(player)
	combat_participants.append_array(enemies)
	
	# 3.5 Initiative: 1d20 + Dex modifier
	for participant in combat_participants:
		var initiative_roll = randi_range(1, 20)
		var dex_modifier = (participant.dexterity - 10) / 2
		participant.initiative = initiative_roll + dex_modifier
		print(participant.character_name, " rolls ", initiative_roll, " + ", dex_modifier, " = ", participant.initiative, " for initiative")
	
	# Sort by initiative (highest first)
	combat_participants.sort_custom(func(a, b): return a.initiative > b.initiative)
	
	current_turn_index = -1  # Start at -1 so first next_turn() call goes to index 0
	is_combat_active = true
	
	print("Combat started! Initiative order:")
	for i in range(combat_participants.size()):
		var participant = combat_participants[i]
		print(str(i + 1), ". ", participant.character_name, " (", participant.initiative, ")")
	
	next_turn()

func next_turn():
	if not is_combat_active:
		return
	
	# Check if combat should end
	var alive_players = combat_participants.filter(func(c): return is_instance_valid(c) and c.current_health > 0 and c is Player)
	var alive_enemies = combat_participants.filter(func(c): return is_instance_valid(c) and c.current_health > 0 and not c is Player)
	
	if alive_players.is_empty():
		end_combat(false)
		return
	elif alive_enemies.is_empty():
		end_combat(true)
		return
	
	# Find next alive participant
	var original_index = current_turn_index
	while true:
		current_turn_index = (current_turn_index + 1) % combat_participants.size()
		var participant = combat_participants[current_turn_index]
		if is_instance_valid(participant) and participant.current_health > 0:
			break
		if current_turn_index == original_index:
			# This shouldn't happen, but prevent infinite loop
			break
	
	var current_character = combat_participants[current_turn_index]
	print("\n", current_character.character_name, "'s turn")
	turn_changed.emit(current_character)
	
	# If it's an enemy turn, handle AI
	if not current_character is Player:
		handle_enemy_turn(current_character)

func handle_enemy_turn(enemy: Character):
	# Enhanced AI for monsters with special abilities
	var alive_players = combat_participants.filter(func(c): return is_instance_valid(c) and c is Player and c.current_health > 0)
	if alive_players.size() > 0:
		var player = alive_players[0]
		
		# Check if this is a Monster with special attacks
		if enemy is Monster:
			var monster = enemy as Monster
			var available_specials = monster.get_available_special_attacks()
			
			# 30% chance to use special attack if available
			if available_specials.size() > 0 and randf() < 0.3:
				var special_attack = available_specials[randi() % available_specials.size()]
				use_monster_special_attack(monster, player, special_attack)
			else:
				# Regular attack
				perform_monster_attack(monster, player)
		else:
			# Regular attack for basic characters
			perform_regular_attack(enemy, player)
	
	# End turn after a short delay
	await get_tree().create_timer(1.0).timeout
	next_turn()

func perform_monster_attack(monster: Monster, target: Character):
	combat_message.emit(monster.character_name + " attacks " + target.character_name)
	
	# 3.5 Attack Roll: 1d20 + BAB + Str modifier + size modifier
	var attack_roll = randi_range(1, 20)
	var str_modifier = (monster.strength - 10) / 2
	var size_modifier = 0
	if monster.monster_data:
		size_modifier = monster.monster_data.get_size_modifier()
	var total_attack = attack_roll + monster.monster_data.base_attack_bonus + str_modifier + size_modifier
	
	print("Attack roll: ", attack_roll, " + ", monster.monster_data.base_attack_bonus, " (BAB) + ", str_modifier, " (Str) + ", size_modifier, " (size) = ", total_attack, " vs AC ", target.armor_class)
	
	if total_attack >= target.armor_class:
		var damage = monster.roll_dice(monster.damage_dice) + str_modifier
		target.take_damage(damage, "physical")
		combat_message.emit("Hit! Dealt " + str(damage) + " damage to " + target.character_name)
	else:
		combat_message.emit("Attack missed! (rolled " + str(total_attack) + " vs AC " + str(target.armor_class) + ")")

func perform_regular_attack(enemy: Character, target: Character):
	combat_message.emit(enemy.character_name + " attacks " + target.character_name)
	
	# Basic 3.5 attack for non-monsters
	var attack_roll = randi_range(1, 20)
	var str_modifier = (enemy.strength - 10) / 2
	var total_attack = attack_roll + enemy.attack_bonus + str_modifier
	
	if total_attack >= target.armor_class:
		var damage = enemy.roll_dice(enemy.damage_dice) + str_modifier
		target.take_damage(damage, "physical")
		combat_message.emit("Hit! Dealt " + str(damage) + " damage to " + target.character_name)
	else:
		combat_message.emit("Attack missed!")

func use_monster_special_attack(monster: Monster, target: Character, attack_name: String):
	monster.use_special_attack(attack_name)
	combat_message.emit(monster.character_name + " uses " + attack_name + "!")
	
	match attack_name:
		"Sneak Attack":
			combat_message.emit(monster.character_name + " strikes from hiding!")
			# Regular attack with extra damage
			var attack_roll = randi_range(1, 20)
			var str_modifier = (monster.strength - 10) / 2
			var total_attack = attack_roll + monster.monster_data.base_attack_bonus + str_modifier
			if total_attack >= target.armor_class:
				var damage = monster.roll_dice(monster.damage_dice) + str_modifier + monster.roll_dice("1d6")  # Sneak attack damage
				target.take_damage(damage, "physical")
				combat_message.emit("Sneak attack! Dealt " + str(damage) + " damage!")
			else:
				combat_message.emit("Sneak attack missed!")
		
		"Trip":
			combat_message.emit(monster.character_name + " attempts to trip " + target.character_name + "!")
			# Touch attack followed by opposed Strength checks in 3.5
			var attack_roll = randi_range(1, 20)
			var dex_modifier = (monster.dexterity - 10) / 2
			if attack_roll + dex_modifier >= target.armor_class:
				var damage = monster.roll_dice(monster.damage_dice) + (monster.strength - 10) / 2
				target.take_damage(damage, "physical")
				combat_message.emit("Trip attack successful! Dealt " + str(damage) + " damage and target is prone!")
			else:
				combat_message.emit("Trip attempt missed!")
		
		"Attach":
			combat_message.emit(monster.character_name + " attempts to attach to " + target.character_name + "!")
			# Touch attack in 3.5
			var attack_roll = randi_range(1, 20)
			var dex_modifier = (monster.dexterity - 10) / 2
			var size_modifier = monster.monster_data.get_size_modifier()
			if attack_roll + monster.monster_data.base_attack_bonus + dex_modifier + size_modifier >= target.armor_class:
				combat_message.emit("Stirge attaches successfully! It will drain blood each round!")
				# Attach status effect would be handled here
			else:
				combat_message.emit("Attach attempt failed!")
		
		"Blood Drain":
			combat_message.emit(monster.character_name + " drains blood from " + target.character_name + "!")
			# Automatic damage if attached
			var drain_damage = monster.roll_dice("1d4")
			target.take_damage(drain_damage, "constitution")  # Con damage in 3.5
			combat_message.emit("Drained " + str(drain_damage) + " points of Constitution!")
		
		"Disease":
			combat_message.emit(monster.character_name + " bites with disease-carrying fangs!")
			var attack_roll = randi_range(1, 20)
			var str_modifier = (monster.strength - 10) / 2
			if attack_roll + monster.monster_data.base_attack_bonus + str_modifier >= target.armor_class:
				var damage = monster.roll_dice(monster.damage_dice) + str_modifier
				target.take_damage(damage, "physical")
				combat_message.emit("Bite hit for " + str(damage) + " damage!")
				# Disease save would be handled here (Fort save vs DC 11)
				if target is Player:
					combat_message.emit("Make a Fortitude save or contract filth fever!")
			else:
				combat_message.emit("Disease bite missed!")
		
		_:
			# Generic special attack
			combat_message.emit("Special ability activated!")
func player_attack(target: Character):
	if not is_combat_active:
		return
	
	var player = combat_participants[current_turn_index]
	if not player is Player:
		return
	
	# 3.5 Player attack
	combat_message.emit(player.character_name + " attacks " + target.character_name)
	var attack_roll = randi_range(1, 20)
	var str_modifier = (player.strength - 10) / 2
	var total_attack = attack_roll + player.attack_bonus + str_modifier
	
	if total_attack >= target.armor_class:
		var damage = player.roll_dice(player.damage_dice) + str_modifier
		target.take_damage(damage, "physical")
		combat_message.emit("Hit! Dealt " + str(damage) + " damage to " + target.character_name)
		
		if target.current_health <= 0:
			combat_message.emit(target.character_name + " has been defeated!")
	else:
		combat_message.emit("Attack missed! (rolled " + str(total_attack) + " vs AC " + str(target.armor_class) + ")")
	
	next_turn()

func player_defend():
	if not is_combat_active:
		return
	
	var player = combat_participants[current_turn_index]
	if not player is Player:
		return
	
	combat_message.emit(player.character_name + " takes the total defense action (+4 AC until next turn)")
	# TODO: Implement defense bonus
	next_turn()

func end_combat(player_won: bool):
	is_combat_active = false
	combat_participants.clear()
	print("Combat ended! Player ", "won" if player_won else "lost")
	combat_finished.emit(player_won)
