## Documentation: Forward Direction in Godot 4.x
## 
## In Godot, the coordinate system follows this convention:
## - transform.basis.x = right vector
## - transform.basis.y = up vector
## - transform.basis.z = back vector
## 
## Therefore, -transform.basis.z is the forward direction.
## 
## This is important for:
## - Spawning projectiles in front of characters
## - Positioning melee hitboxes
## - Moving characters forward
## - Any directional calculations
##
## Example usage:
##   var forward = -transform.basis.z
##   var spawn_pos = global_position + forward * 2.0
##
extends RefCounted 