extends Node

func create_weapon(weapon_id: String) -> WeaponBase:
	match weapon_id:
		"magic_bolt":
			return ProjectileWeapon.new()
		"holy_onion":
			return AuraWeapon.new()
		"thunder_strike":
			return ThunderStrike.new()
		"knife_fan":
			return KnifeFan.new()
		"jump":
			return Jump.new()
		"void_orb":
			return VoidOrb.new()
		"storm_tempest":
			return StormTempest.new()
	push_warning("WeaponRegistry: unknown weapon_id '%s'" % weapon_id)
	return null
