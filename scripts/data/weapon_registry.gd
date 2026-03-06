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
		"boomerang":
			return Boomerang.new()
		"spike_strip":
			return SpikeStrip.new()
		"void_orb":
			return VoidOrb.new()
		"storm_tempest":
			return StormTempest.new()
		"cyclone_dash":
			return CycloneDash.new()
		"nova_bolt":
			return NovaBolt.new()
		"sacred_mantle":
			return SacredMantle.new()
		"thunderlord":
			return Thunderlord.new()
		"cyclone_blades":
			return CycloneBlades.new()
		"graviton_ring":
			return GravitonRing.new()
		"toxic_fortress":
			return ToxicFortress.new()
		"bazooka":
			return Bazooka.new()
		"bloodburst":
			return Bloodburst.new()
	push_warning("WeaponRegistry: unknown weapon_id '%s'" % weapon_id)
	return null
