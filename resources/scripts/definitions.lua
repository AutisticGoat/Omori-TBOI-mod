local function secsToFrames(secs)
	return math.ceil(secs * 30)
end

OmoriMod.Enums = {
	PlayerType = {
		PLAYER_OMORI = Isaac.GetPlayerTypeByName("Omori"),
		PLAYER_OMORI_B = Isaac.GetPlayerTypeByName("Sunny", true),
		PLAYER_AUBREY = Isaac.GetPlayerTypeByName("Aubrey"),
		PLAYER_AUBREY_B = Isaac.GetPlayerTypeByName("Aubrey", true),
	},
	NullItemID = {
		ID_OMORI = Isaac.GetCostumeIdByPath("gfx/characters/costume_omori.anm2"),
		ID_SUNNY = Isaac.GetCostumeIdByPath("gfx/characters/costume_omori2.anm2"),
		ID_DW_AUBREY = Isaac.GetCostumeIdByPath("gfx/characters/costume_aubrey.anm2"),
		ID_RW_AUBREY = Isaac.GetCostumeIdByPath("gfx/characters/costume_aubrey_2.anm2"),
		ID_EMOTION = Isaac.GetCostumeIdByPath("gfx/characters/costume_emotion.anm2"),
	},
	SoundEffect = {
		SOUND_BLADE_SLASH = Isaac.GetSoundIdByName("Blade Slash"),
		SOUND_OMORI_HEART_BEAT = Isaac.GetSoundIdByName("Heartbeat"),
		SOUND_VIOLIN_BOW_SLASH = Isaac.GetSoundIdByName("Bow Slash"),
		SOUND_OMORI_FEAR = Isaac.GetSoundIdByName("Omori Fear"),
		SOUND_CALM_DOWN = Isaac.GetSoundIdByName("Calm Down"),
		SOUND_OVERCOME = Isaac.GetSoundIdByName("Overcome"),
		SOUND_RIGHT_IN_THE_HEART = Isaac.GetSoundIdByName("Right In The Heart"),
		SOUND_MISS_ATTACK = Isaac.GetSoundIdByName("Fail Attack"),
		SOUND_HAPPY_UPGRADE = Isaac.GetSoundIdByName("Happy Upgrade"),
		SOUND_HAPPY_UPGRADE_2 = Isaac.GetSoundIdByName("Happy Upgrade 2"),
		SOUND_HAPPY_UPGRADE_3 = Isaac.GetSoundIdByName("Happy Upgrade 3"),
		SOUND_SAD_UPGRADE = Isaac.GetSoundIdByName("Sad Upgrade"),
		SOUND_SAD_UPGRADE_2 = Isaac.GetSoundIdByName("Sad Upgrade 2"),
		SOUND_SAD_UPGRADE_3 = Isaac.GetSoundIdByName("Sad Upgrade 3"),
		SOUND_ANGRY_UPGRADE = Isaac.GetSoundIdByName("Angry Upgrade"),
		SOUND_ANGRY_UPGRADE_2 = Isaac.GetSoundIdByName("Angry Upgrade 2"),
		SOUND_ANGRY_UPGRADE_3 = Isaac.GetSoundIdByName("Angry Upgrade 3"),
		SOUND_BACK_NEUTRAL = Isaac.GetSoundIdByName("Back to Neutral"),
		SOUND_HEADBUTT_START = Isaac.GetSoundIdByName("HeadButt Start"),
		SOUND_HEADBUTT_HIT = Isaac.GetSoundIdByName("HeadButt Hit"),
		SOUND_HEADBUTT_KILL = Isaac.GetSoundIdByName("HeadButt Kill"),
		SOUND_HEART_HEAL = Isaac.GetSoundIdByName("Heart Heal"),
		SOUND_AUBREY_SWING = Isaac.GetSoundIdByName("AubreySwing"),
		SOUND_AUBREY_HIT = Isaac.GetSoundIdByName("AubreyHit"),
		SOUND_HOMERUN = Isaac.GetSoundIdByName("HomeRun"),
		SOUND_SAD_POEM = Isaac.GetSoundIdByName("SadPoem"),
	},
	EffectVariant = {
		EFFECT_EMOTION_GLOW = Isaac.GetEntityVariantByName("Emotion Glow"),
		EFFECT_SHINY_KNIFE = Isaac.GetEntityVariantByName("Shiny Knife"),
	
	},
	CollectibleType = {
		COLLECTIBLE_SHINY_KNIFE = Isaac.GetItemIdByName("Shiny Knife"),
		COLLECTIBLE_EMOTION_CHART = Isaac.GetItemIdByName("Emotion Chart"),
		COLLECTIBLE_CALM_DOWN = Isaac.GetItemIdByName("Calm Down"),
		COLLECTIBLE_OVERCOME = Isaac.GetItemIdByName("Overcome"),
		COLLECTIBLE_MR_PLANTEGG = Isaac.GetItemIdByName("Mr Plantegg"),
		COLLECTIBLE_NAIL_BAT = Isaac.GetItemIdByName("Nail Bat"),
		COLLECTIBLE_VIOLIN_BOW = Isaac.GetItemIdByName("Violin Bow"),
		COLLECTIBLE_SPARKLER = Isaac.GetItemIdByName("Sparkler"),
		COLLECTIBLE_POETRY_BOOK = Isaac.GetItemIdByName("Poetry book"),
		COLLECTIBLE_PRESENT = Isaac.GetItemIdByName("Present"),
	},
	Utils = {
		Game = Game(),
		SFX = SFXManager(),
		RNG = RNG(),
	},
	Callbacks = {
		KNIFE_SWING_UPDATE = "OmoriModCallbacks_KNIFE_SWING_UPDATE", -- Fires every swing frame update
		KNIFE_SWING_TRIGGER = "OmoriModCallbacks_KNIFE_SWING_TRIGGER", -- Fires on Swing's first frame
		KNIFE_SWING_FINISH = "OmoriModCallbacks_KNIFE_SWING_FINISH", -- Fires on Swing's finishing
		KNIFE_HIT_ENEMY = "OmoriModCallbacks_KNIFE_HIT_ENEMY",-- Fires on knife colliding with enemies
		KNIFE_ENTITY_COLLISION = "OmoriModCallbacks_KNIFE_ENTITY_COLLISION", -- Fires on knife colliding with non-enemy entities
		KNIFE_KILL_ENEMY = "OmoriModCallbacks_KNIFE_KILL_ENEMY", -- Fires on knife colliding with non-enemy entities
		PRE_KNIFE_UPDATE = "OmoriModCallbacks_PRE_KNIFE_UPDATE", -- Fires every knife update, return false to cancel knife logic
		PRE_KNIFE_CHARGE = "OmoriModCallbacks_PRE_KNIFE_CHARGE", -- Fires when knife is charging, return a number to change knife charge rythm 
		POST_KNIFE_RENDER = "OmoriModCallbacks_POST_KNIFE_RENDER", -- Fires on every Knife render frame
		POST_KNIFE_UPDATE = "OmoriModCallbacks_POST_KNIFE_UPDATE", -- Fires after Knife logic update
		HEADBUTT_ENEMY_HIT = "OmoriModCallbacls_HEADBUTT_ENEMY_HIT", -- Fires on Headbutt hit
		HEADBUTT_ENEMY_KILL = "OmoriModCallbacls_HEADBUTT_ENEMY_KILL", -- Fires on Headbutt kill
		EMOTION_CHANGE_TRIGGER = "OmoriModCallbacks_EMOTION_CHANGE_TRIGGER", -- Fires on Emotion change
	},
	---@enum KnifeType
	KnifeType = {
		SHINY_KNIFE = "ShinyKnife",
		VIOLIN_BOW = "ViolinBow",
		MR_PLANT_EGG = "MrPlantEgg",
		NAIL_BAT = "BaseballBat",
	},
	Tables = {
		NoDischargeEmotions = {
			["Neutral"] = true,
			["Manic"] = true,
			["Miserable"] = true,
			["Furious"] = true,
		},
		HappinessTiers = {
			["Happy"] = true,
			["Ecstatic"] = true,
			["Manic"] = true,
		},
		HappinessFailChance = {
			["Happy"] = 10,
			["Ecstatic"] = 20,
			["Manic"] = 30,
		},
		SadnessIgnoreDamageChance = {
			["Sad"] = 20,
			["Depressed"] = 30,
			["Miserable"] = 40,
		},
		AngerDoubleDamageChance = {
			["Angry"] = 50,
			["Enraged"] = 70,
			["Furious"] = 85,
		},
		HappynessCriticDamageChance = { -- Change for critic damage
			["Happy"] = {VelMult = 1, HappyChance = 25},
			["Ecstatic"] = {VelMult = 2, HappyChance = 38},
			["Manic"] = {VelMult = 3, HappyChance = 50},
		},
		HappyKnifeCriticChance = {
            ["Happy"] = 25,
            ["Ecstatic"] = 40,
            ["Manic"] = 60,
        },
		EmotionChartFrame = {
			Neutral = 0,
			Happy = 1,
			Sad = 2,
			Angry = 3,
		},
		EmotionUpgradesOmori = {
			["Happy"] = "Ecstatic",
			["Ecstatic"] = "Manic",
			["Sad"] = "Depressed",
			["Depressed"] = "Miserable",
			["Angry"] = "Enraged",
			["Enraged"] = "Furious",
		},
		EmotionUpgradesOmoriCarBattery = {
			["Happy"] = "Manic",
			["Ecstatic"] = "Manic",
			["Sad"] = "Miserable",
			["Depressed"] = "Miserable",
			["Angry"] = "Furious",
			["Enraged"] = "Furious",
		},
		EmotionUpgrades = {
			["Neutral"] = "Happy",
			["Happy"] = "Sad",
			["Sad"] = "Angry",
			["Angry"] = "Happy",
		},
		EmotionUpgradesCarBattery = {
			["Neutral"] = "Ecstatic",
			["Happy"] = "Depressed",
			["Sad"] = "Enraged",
			["Angry"] = "Ecstatic",
			["Ecstatic"] = "Depressed",
			["Depressed"] = "Enraged",
			["Enraged"] = "Ecstatic",
		},
		EmotionToChange = {
			["Neutral"] = "Happy",
			["Happy"] = "Sad",
			["Sad"] = "Angry",
			["Angry"] = "Neutral",
			["Ecstatic"] = "Sad",
			["Depressed"] = "Angry",
			["Enraged"] = "Neutral",
			["Manic"] = "Sad",
			["Miserable"] = "Angry",
			["Furious"] = "Neutral",
		},
		DamageAlterEmotions = {
			["Sad"] = { EmotionDamageMult = 0.75, damageMult = 1, birthrightMult = 0.9 },
			["Depressed"] = { EmotionDamageMult = 0.625, damageMult = 1, birthrightMult = 0.9 },
			["Miserable"] = { EmotionDamageMult = 0.5, damageMult = 1, birthrightMult = 0.9 },
			["Angry"] = { EmotionDamageMult = 1.3, damageMult = 1.2, birthrightMult = 1.15 },
			["Enraged"] = { EmotionDamageMult = 1.6, damageMult = 1.2, birthrightMult = 1.15 },
			["Furious"] = { EmotionDamageMult = 2, damageMult = 1.2, birthrightMult = 1.15 },
		},
		TearsAlterEmotions = {
			["Sad"] = { tearsMult = 1.3, birthrightMult = 1.2 },
			["Depressed"] = { tearsMult = 1.4, birthrightMult = 1.2 },
			["Miserable"] = { tearsMult = 1.5, birthrightMult = 1.2 },
			["Angry"] = { tearsMult = 0.8, birthrightMult = 0.9 },
			["Enraged"] = { tearsMult = 0.75, birthrightMult = 0.9 },
			["Furious"] = { tearsMult = 0.65, birthrightMult = 0.9 },
		},
		SpeedAlterEmotions = {
			["Happy"] = { speedMult = 1.25, birthrightMult = 1.1 },
			["Ecstatic"] = { speedMult = 1.375, birthrightMult = 1.1 },
			["Manic"] = { speedMult = 1.5, birthrightMult = 1.1 },
			["Sad"] = { speedMult = 0.8, birthrightMult = 0.9 },
			["Depressed"] = { speedMult = 0.7, birthrightMult = 0.9 },
			["Miserable"] = { speedMult = 0.6, birthrightMult = 0.9 },
		},
		LuckAlterEmotions = {
			["Happy"] = 1,
			["Ecstatic"] = 2,
			["Manic"] = 3,
		},
		DirectionToDegrees = {
			[Direction.NO_DIRECTION] = 0,
			[Direction.RIGHT] = 0,
			[Direction.DOWN] = 90,
			[Direction.LEFT] = 180,
			[Direction.UP] = 270
		},
		DirectionToVector = {
			[Direction.NO_DIRECTION] = Vector.Zero,
			[Direction.RIGHT] = Vector(1, 0),
			[Direction.DOWN] = Vector(0, 1),
			[Direction.LEFT] = Vector(-1, 0),
			[Direction.UP] = Vector(0, -1)
		},
		SadnessKnockbackMult = {
			["Sad"] = 1.25,
			["Depressed"] = 1.375,
			["Miserable"] = 1.5,
		},
		SunnyEmotionAlter = {
			["Afraid"] = {
				DamageMult = 0.85,
				FireDelayMult = 0.7,
				RangeReduction = -1,
				SpeedMult = 0.8,
			},
			["StressedOut"] = {
				DamageMult = 0.75,
				FireDelayMult = 0.65,
				RangeReduction = -2,
				SpeedMult = 0.7,
			},
		},
		AubreyHeadButtParams = {
			["Neutral"] = {
				HeadButtCooldown = secsToFrames(1),
				EmotionCooldown = secsToFrames(5),
				Emotion = "Angry",
				DamageMult = 1,
			},
			["Happy"] = {
				HeadButtCooldown = secsToFrames(1),
				EmotionCooldown = secsToFrames(5),
				Emotion = "Angry",
				DamageMult = 1,
			},
			["Ecstatic"] = {
				HeadButtCooldown = secsToFrames(1),
				EmotionCooldown = secsToFrames(5),
				Emotion = "Angry",
				DamageMult = 1,
			},
			["Sad"] = {
				HeadButtCooldown = secsToFrames(1),
				EmotionCooldown = secsToFrames(5),
				Emotion = "Angry",
				DamageMult = 1,
			},
			["Depressed"] = {
				HeadButtCooldown = secsToFrames(1),
				EmotionCooldown = secsToFrames(5),
				Emotion = "Angry",
				DamageMult = 1,
			},
			["Angry"] = {
				HeadButtCooldown = secsToFrames(1.5),
				EmotionCooldown = secsToFrames(6),
				Emotion = "Enraged",
				DamageMult = 1.25
			},
			["Enraged"] = {
				HeadButtCooldown = secsToFrames(2),
				EmotionCooldown = secsToFrames(7),
				Emotion = "Enraged",
				DamageMult = 1.5
			},
		},
		PickupBlacklist = {
			[PickupVariant.PICKUP_COLLECTIBLE] = true,
			[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
			[PickupVariant.PICKUP_TROPHY] = true,
			[PickupVariant.PICKUP_BED] = true,
			[PickupVariant.PICKUP_MOMSCHEST] = true,
		},
		BlacklistedFireplaces = {
			[2] = true,
			[3] = true,
			[4] = true,
			[12] = true,
			[13] = true,
		}
	},
	Misc = {
		SelfHelpRenderPos = Vector(16, 16),
		SelfHelpRenderScale = Vector.One,
		CriticColor = Color(0.8, 0.8, 0.8, 1, 255/255, 200/255, 100/255),
		NeutralColor = Color(1, 1, 1, 1, 0.2, 0.2, 0.2),
		AngryColor = Color(1, 1, 1, 1, 0.6),
		HappyColor = Color(1, 1, 1, 1, 0.6, 0.6),
		SadColor = Color(1, 1, 1, 1, 0.0, 0.1, 0.8),
		AfraidColor = Color(1, 1, 1, 1, 0.2, 0.2, 0.2),
		StressColor = Color(1, 1, 1, 1, 0.2),
		ReadyColor = Color(1, 1, 1, 1, 0.2, 0.6),
		EmotionTitleOffset = Vector(0, -75),
		HappyColorMod = ColorModifier(1, 1, 0, 0.6, 0.1, 1.2),
		SadColorMod = ColorModifier(0, 0.3, 1, 0.5, 0.1, 1.2),
		AngryColorMod = ColorModifier(1, 0.3, 0, 0.7, 0.1, 1.2),
		AfraidColorMod = ColorModifier(0.7, 0.7, 0.7, 0.4, 0, 1),
		StressColorMod = ColorModifier(0.5, 0.4, 0.4, 0.7, 0, 1)
	},
}
-- Globals end

local game = OmoriMod.Enums.Utils.Game

local function setRNG()
	local rng = OmoriMod.Enums.Utils.RNG
	local RECOMMENDED_SHIFT_IDX = 35
	
	local seeds = game:GetSeeds()
	local startSeed = seeds:GetStartSeed()
	
	rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)	
end

function OmoriMod:GameStartedFunction()
	setRNG()
end
OmoriMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OmoriMod.GameStartedFunction)

function OmoriMod:SetObjects()
	OmoriMod.Enums.Utils.Room = game:GetRoom()
	OmoriMod.Enums.Utils.Level = game:GetLevel()
	
	-- print(OmoriMod.Enums.Utils.Room, OmoriMod.Enums.Utils.Level)
end
OmoriMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OmoriMod.SetObjects)