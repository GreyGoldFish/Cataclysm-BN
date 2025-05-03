Every clothing item can be `CLEAN`/`WASHED`, which confers you with an infection resistance buff per body part. Having a configurable percentage of your worn clothes `WASHED` gives you a mood buff while they remain above that threshold. Items spawn with `WASHED == false` by default.

The infection resistance buff for a body part is provided by the innermost clean layer covering that part. If an outer layer gets dirty, it doesn't affect the buff unless the innermost clean layer itself gets dirty.

Certain events dirty your clothes and change them back to the default state, based on body part flags. Examples include wading across dirty water (feet, legs, + based on depth), butchering (all - could be tied to skill level?), some types of attacks (already target specific body part).

Butchering dirties hands/arms/torso with very low skill, hands/arms with low skill and hands/nothing with high skill and/or very small corpse?

`dirty triggers` JSON which tie to Lua hooks with a filter to trigger a `clear_washed` function.

Wash methods such as:
- Field Rinse: water
- Ash Scrub: ash and water
- Soap Wash: soap and water
- Machine Wash: soap/detergent and water, requires washing machine and electricity

Possible new traits:
- Neat-freak - increases mood buff
- Slob - removes mood buff

Dirtying events:
- Movement through dirty water
- Butchering
- Boomer bile
- Bleeding
- Clothing damaged

Add PPE flags: `PPE_FULL`, `PPE_SUIT`, `PPE_GLOVES`?

Could tie into odour system.

How to batch wash? Option to wash worn clothing (innermost only option?) "Wash all reachable"? Drop items into washing machine, activate and they're clean or use a timer?