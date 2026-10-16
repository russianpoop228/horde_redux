ITEM = {}

ITEM.Category = "Special"
ITEM.Name = "Pheropod"
ITEM.Class = "horde_pheropod"
ITEM.Price = 0
ITEM.Weight = 0
ITEM.Description = [[Only usable by Hatcher subclass!
    Pheropods that can hatch and control alien Antlions.

    LMB: Throw Pod
    Throws a Pheropod at the target, forcing the Antlions to perform range attacks at the target.
    Pods can also heal Antlion for 5% health.

    RMB: Raise Antlion (40 Energy)
    Creates an Antlion that follows you around. Heal Antlion to accelerate evolution.
    HOLD RMB to force Antlions to your location.
    Antlion gains new effects each stage:
    - Stage I:
        - Bug Pulse: Every 5 seconds, generates a pulse that heals players nearby for 5% health.
    - Stage II:
        - Increased health and damage.
        - Increased Aroma Pulse radius and reduce Bug Pulse cooldown.
        - 50% increased Poison damage resistance.
    - Stage III:
        - Increased health, damage and attack speed.
        - Increased Aroma Pulse radius and reduce Bug Pulse cooldown.
        - Immune to Poison damage and Break.]]
ITEM.Whitelist = { Hatcher = true }
ITEM.AmmoPrice = -1
ITEM.SecondaryAmmoPrice = -1
ITEM.Dmgtype = { HORDE.DMG_SLASH, HORDE.DMG_POISON }
ITEM.StarterClasses = { "Hatcher" }
ITEM.Hidden = true
