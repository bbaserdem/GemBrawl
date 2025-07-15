# Concept & Design

- The core mechanic of the game is brawling, with each gem having different skills.
- Each gem will have the following base skills;
    * glide (evasive fast manuever)
    * refract (block incoming attacks)
- Each gem will have 3 main skills, that will be different between gems.
    * cut (main damaging attack) - attack
    * polish (situational damaging skill) - special
    * shine (area denial) - cast
- Each player will have HP, and lives. When HP reaches 0, the player dies and respawns.
- There will be limited number of respawns.
- Game goal is to kill other players enough times so that there is only one player standing.
- I'm unsure the difference between peer-to-peer vs. server authoritative means.
But I'm thinking one player can open up a lobby.
- Game perspective will be top down isometric, with the game geometry being hexagonal
- The game should be controller centric; I have a PS4 controller.

# Game Experience

- Users open the game, greeted with a launcher.
- There are five options; Practice (solo), Open Room, Join Room, Settings, Exit

## Settings

- Menu allows changing game options.

## Exit

Closes the game

## Practice

- Goes to a gem selection interfaces, where user picks a gem to play.
- User selects a second gem for the enemy; there is a special selection (coal) that will work as just immobile target practice.
- After selecting the opponent, the game progresses to arena selection interface. User can select the arena.
- Game starts with one opponent. Opponent utilizes a simple AI, or is stationary if it's coal.

## Open Room

- User is met with a screen where they define their lobby preference (arena/name/password/# of players from 2 to 4)
- Once user defines the preference and confirms, they get a menu overseeing their lobby created.
- The lobby preview shows the users connected to the lobby, and a chat for people already joined.
- Once lobby is full, advance to the interface to start character selection.

## Join Room

- Users are met with a screen showing open lobbies accepting users.
- They can filter for lobby names and arenas.
- They can choose which lobby to join, and need to enter a password if protected.
- Once they join a lobby and the owner starts the game, there is an advance to the interface

## Character Selection

- Each player chooses their gem to play with.
- Every player can see what other players are trying to pick.
- There is a brief text description of what each of their main skills do
- They also see a stat distribution that shows gem stats
- Players can lock in, and once all players in the lobby is locked in, the game starts.

## Main game

- All players are put on the arena in designated spawn points.
- A timer goes on 3 2 1 and start, when all players can start moving and acting.
- Each player sees their own health bar (prominent) and every other opponents' health bars (not as prominent)
- The player's own gem is highlighted to differentiate their gem.
- Gems are free to move around the arena, and perform their skills.
- Each skills (base and special) have cooldowns, and each player sees their cooldowns on the bottom left
- Depending on the arena, there are traps and obstacles of various types.

