return [==[
HORDE: REDUX - EXTERNAL MODULE EXAMPLES


HOW TO USE

horde_example_addon is a ready-to-run addon. Every file sits exactly where
the loader expects it.

To test the whole API, copy horde_example_addon into garrysmod/addons/.
To make your own content, copy the files you need and keep their path
inside lua/horde/modules/.

Files and folders whose name starts with "_" are not loaded
(for example _my_optic.lua, _quality_override.lua). Remove the "_" to
enable them.


WHERE TO PUT FILES

All paths are relative to addons/<your_addon>/lua/horde/modules/

Perk                  perks/<class>/            PERK
Gadget                gadgets/                  GADGET
Spell                 spells/                   SPELL
Mutation              mutations/                MUTATION
Subclass              subclasses/               SUBCLASS
Infusion              infusions/                INFUSION
Shop item             items/<category>/         ITEM
Enemy                 enemies/                  ENEMY
Enemy variation       enemies/                  HORDE:RegisterEnemyVariation
Difficulty config     configs/                  HORDE_CONFIG
Class                 classes/                  HORDE:RegisterClass
Buff                  status/buff/              HORDE:RegisterStatus
Debuff                status/debuff/            HORDE:RegisterStatus
Difficulty            systems/                  HORDE:RegisterDifficulty
Shop tab              systems/                  HORDE:RegisterShopTab
Achievement           systems/                  HORDE.PlayerAchievements:Register
Anything else         systems/                  any code
Translation           languages/<lang>_lan.lua  LANGUAGE

Difficulties go into systems/ because the external loader does not scan
difficulties/.

The file prefix decides the realm:
  sv_         server only
  cl_         client only
  sh_ or none both


LOAD ORDER

1. Core: gamemode/system/, then built-in gamemode/modules/
2. Addons: perks, gadgets, spells, mutations, subclasses, infusions,
   items, enemies, configs
3. Addons: languages
4. Addons: classes, status/buff, status/debuff, systems, gui,
   arccw/attachments
5. Hook Horde_AllModulesLoaded

Inside a folder, files load in alphabetical order.

Addons load after built-in content, so the same ClassName / Key / Id
overrides a built-in module (see infusions/_quality_override.lua).

Register things directly when the file loads. Do not wrap registration in
hook.Add("Horde_AllModulesLoaded", ...): GMod does not guarantee hook order.


RULES THAT ARE EASY TO MISS

Perks: OwnerHooks vs Hooks
  Use PERK.OwnerHooks when the first argument of the event is the player.
  The handler then runs only for players who own the perk, instead of every
  perk handler running on every event. This is faster.
  Use PERK.Hooks when the first argument is not the player
  (for example Horde_OnEnemyKilled), and check Horde_GetPerk yourself.
  See perks/scout/scout_fury.lua.

Active perks (Shift+E)
  PERK.OwnerHooks.Horde_UseActivePerk: return true to cancel the use,
  the cooldown will not start. See perks/scout/scout_dash.lua.

Perk visibility
  A perk is only selectable if it is listed in the class "perks" table or
  in SUBCLASS.Perks.

New classes
  A new class needs a base subclass with the same PrintName
  (subclasses/scout.lua). Items with ITEM.Whitelist are only available to
  the class if its name is in the whitelist.

Difficulties
  A difficulty with Include inherits the fields of its base and counts as
  a modifier. Without Include it is a standalone difficulty.
  Index must be unused (built-in: 1-8, 10, 666).

Custom debuffs
  Apply buildup with ent:Horde_AddDebuffBuildup(HORDE.Status_X, amount,
  attacker) or HORDE:ApplyDebuffInRadius(...). When an enemy's buildup
  reaches the threshold, Horde_PostEnemyDebuffApply(ent, inflictor, debuff,
  pos) fires. See status/debuff/sv_corrosion.lua.

Enemy variations
  A variation does not add a new enemy to the wave pool. It replaces
  ParentEntity on spawn. ParentEntity is the entity class, not ENEMY.Name.

Spells
  SPELL.Fire(ply, wpn, charge_stage): charge_stage goes from 1 to
  #SPELL.ChargeTime.

Infusions
  Ids 0-31 (sent as 5 bits). New infusions get an id automatically.
  Add one to a weapon with ITEM.Infusions = { HORDE.Infusion_<Key> }.


SKILL STATUSES (CHARGES / OWN COOLDOWN)

  HORDE:RegisterStatus({
      Name = "MySkill",
      Icon = "materials/...",
      IsSkill = true,
      IsStackableSkill = true,
      UsePerkCooldown = false,
      Draw = function(status, stack, displacement) return true end,
  })

  ply:Horde_SyncStatus(HORDE.Status_MySkill, 1)
  ply:Horde_SetStatusCharges(HORDE.Status_MySkill, 3)
  ply:Horde_SetStatusCooldown(HORDE.Status_MySkill, 8)
  ply:Horde_GetStatusCharges(HORDE.Status_MySkill)
  ply:Horde_GetStatusCooldown(HORDE.Status_MySkill)

IsStackableSkill   shows the charge count on the icon
UsePerkCooldown    false = the status has its own cooldown
Draw               return true to replace the default icon rendering
Charges = -1       hides the charge count
]==]
