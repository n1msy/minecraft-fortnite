##things to add: /nick, /hat, /lore, /sudo

#/ex toast "Mentioned by <&a>DessieWessie<&r>!" icon:player_head[skull_skin=<player.skull_skin>] targets:<player>
#add net symbol for error message too, or no?
#-Nimbus Essential Tools
#Important permission: Bypass = you're exempt from everything (ie no need to be subbed, no cooldowns, etc)

net_help:
  type: command
  name: net
  debug: false
  description: NET Command Info
  permission: Net.Utility.Help
  usage: /net
  aliases:
  - help
  - ?
  tab complete:
  - if !<player.has_permission[Net.Utility.Help]||<context.server>>:
    - stop
  script:
  - define commands <server.scripts.filter[container_type.equals[command]].filter[name.before[_].is[==].to[net]].filter_tag[<player.has_permission[<[filter_value].data_key[permission]>]||false>].alphabetical.sub_lists[7]>
  - define page <context.args.first||1>
  - define total_pages <[commands].size>
  - if !<[page].is_integer> || <[page]> <= 0:
    - define page 1
  #if total pages = 1 or 0 -> used to be else if, but it errors idk y
  - if <[page]> > <[total_pages]>:
    - define page <[total_pages]>
  - if <[commands].is_empty>:
    - narrate "<&c>You can't use any commands!"
    - stop
  - define commands <[commands].get[<[page]>]>
  - narrate "<&8><&l><&m><&sp.repeat[12]><&8><&l>| <element[N].color[<color[0,180,255]>]><&b><&l>imbus <element[E].color[<color[0,180,255]>]><&b><&l>ssential <element[T].color[<color[0,180,255]>]><&b><&l>ools <&8><&l>|<&8><&l><&m><&sp.repeat[12]>"
  - foreach <[commands]> as:cmd:
    - define name <[cmd].data_key[usage].after[/].before[<&sp>].color_gradient[from=#00b4ff;to=#00ffff]>
    - define usage  <[cmd].data_key[usage].after[<&sp>].color[<color[255,227,87]>]>
    - define desc <[cmd].data_key[description]>
    - define perm <[cmd].data_key[permission]||<&c>None>
    - define aliases <[cmd].data_key[aliases]||<list[<&c>None]>>
    - narrate "<element[<&8>/<[name]> <[usage]>].on_hover[<&7>Permission:<&f> <[Perm]><&nl><&7>Aliases: <&r><[aliases].comma_separated>]><&7> - <&r><[desc].color[<color[222,222,222]>]>"
  - narrate "<&8><&l><&m><&sp.repeat[4]><&r><tern[<[page].sub[1].equals[0]>].pass[<&8><&l><&m><&sp.repeat[11]>].fail[ <&r><element[<&l><element[«].color[<color[0,200,255]>]> <&7>Page <[page].sub[1]>].on_hover[<&e>Click for previous page.].on_click[/net <[page].sub[1]>]><&8><&l> ]><&8><&l><&m><&sp.repeat[6]><&r> <&b>Page <[page]><&7>/<&b><[total_pages]><&8><&l> <&8><&l><&m><&sp.repeat[6]><&r><tern[<[total_pages].equals[<[page]>]>].pass[<&8><&l><&m><&sp.repeat[11]>].fail[ <&7><element[Page <[page].add[1]> <proc[net_symbol]>].on_hover[<&e>Click for next page.].on_click[/net <[page].add[1]>]><&8><&l> ]><&8><&l><&m><&sp.repeat[5]>"


net_config:
  type: data
  error_msg: You cannot do that.

net_symbol:
  type: procedure
  debug: false
  script:
  #«
  - determine <&l><element[»].color[<color[0,200,255]>]><&r>

net_coords:
  type: command
  name: coords
  debug: false
  description: View current coordinates.
  permission: Net.Gamemode.Coords
  usage: /coords
  tab complete:
  - if !<player.has_permission[Net.Gamemode.Creative]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  #«
  - define click "/tp <player.location.round.xyz.replace[,].with[<&sp>]>"
  - narrate "<proc[net_symbol]> <element[Your location:].color[<color[180,180,180]>]> <&b><player.location.simple.on_hover[<&e>Click to copy.].on_click[<[click]>].type[COPY_TO_CLIPBOARD]>"

net_tasks:
  type: task
  debug: false
  definitions: data
  script:
  - narrate "run net reptitive net tasks"
  tab:
  - if <context.args.is_empty>:
    - determine <server.online_players.parse[name]>
    - stop
  - determine <server.online_players.parse[name].filter[starts_with[<context.args.last>]]>
  gamemode:
  - define gamemode <[data].get[gamemode]>
  - define args <[data].get[args]>
  - if !<[args].is_empty> && <[args].size> > 1:
    - narrate "<&c>Incorrect command usage! Type /<map[creative=gmc;survival=gms;spectator=gmsp].get[<[gamemode]>]> (player)"
    - stop
  - if <[args].is_empty>:
    - adjust <player> gamemode:<[gamemode]>
    - narrate "<proc[net_symbol]> <element[Gamemode:].color[<color[180,180,180]>]> <&a><[gamemode]>"
    - stop
  - define player <server.match_offline_player[<[args].first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Cannot find player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - adjust <[player]> gamemode:<[gamemode]>
  - narrate "<proc[net_symbol]> <element[<[Player].name>'s Gamemode:].color[<color[180,180,180]>]> <&a><[gamemode]>"
  - narrate "<proc[net_symbol]> <element[Gamemode:].color[<color[180,180,180]>]> <&a><[gamemode]>" targets:<[player]>

#<element[Gamemode:].color_gradient[from=#D3D3D3;to=#8c8c8c]>
net_gamemode_creative:
  type: command
  name: gmc
  debug: false
  description: Set gamemode to creative
  permission: Net.Gamemode.Creative
  usage: /gmc (player)
  tab complete:
  - if !<player.has_permission[Net.Gamemode.Creative]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - run net_tasks path:gamemode def:<map[gamemode=Creative].with[args].as[<context.args>]>

net_gamemode_survival:
  type: command
  name: gms
  debug: false
  description: Set gamemode to survival
  permission: Net.Gamemode.Survival
  usage: /gms (player)
  tab complete:
  - if !<player.has_permission[Net.Gamemode.Survival]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - run net_tasks path:gamemode def:<map[gamemode=Survival].with[args].as[<context.args>]>

net_gamemode_spectator:
  type: command
  name: gmsp
  debug: false
  description: Set gamemode to spectator
  permission: Net.Gamemode.Spectator
  usage: /gmsp (player)
  tab complete:
  - if !<player.has_permission[Net.Gamemode.Spectator]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - run net_tasks path:gamemode def:<map[gamemode=Spectator].with[args].as[<context.args>]>

#use feed and hunger on one person only, then define player as themselves?
net_heal:
  type: command
  name: heal
  debug: false
  description: Fully recover player's bars
  permission: Net.Utility.Heal
  usage: /heal (player)
  tab complete:
  - if !<player.has_permission[Net.Utility.Heal]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if !<context.args.is_empty> && <context.args.size> > 1:
    - narrate "<&c>Incorrect command usage! Type /heal (player)"
    - stop
  - if <context.args.is_empty>:
    - heal
    - feed
    - narrate "<proc[net_symbol]> <&a>Healed."
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Cannot find player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - heal <[player]>
  - feed <[player]>
  - narrate "<proc[net_symbol]> <&a>Healed <[Player].name>."
  - narrate "<proc[net_symbol]> <&a>Healed." targets:<[player]>

#-Not sure if we should use this command
net_resourcepack:
  type: command
  name: resourcepack
  debug: false
  description: Download the resourcepack.
  permission: Net.Utility.Resourcepack
  usage: /resourcepack
  tab complete:
  - if !<player.has_permission[Net.Utility.Resourcepack]||<context.server>>:
    - stop
  aliases:
  - rp
  script:
  - if !<player.has_flag[resourcepack.failed]>:
    - narrate "<&c>Nimbus resource pack is already on!"
    - stop
  - narrate "<&8>[<&c><&l>!<&8>] <element[Loading resource pack...].color_gradient[from=#D3D3D3;to=#8c8c8c]>"
  - flag player net.rp.using_command
  - resourcepack url:https://download.mc-packs.net/pack/0516201efffe3825cbc4973955425303092bfc34.zip hash:0516201efffe3825cbc4973955425303092bfc34 forced

net_bypass:
  type: command
  name: bypass
  debug: false
  description: Bypass all restrictions.
  permission: Net.Utility.Bypass
  usage: /bypass (player)
  tab complete:
  - if !<player.has_permission[Net.Utility.Bypass]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  aliases:
  - bp
  script:
  - if <context.args.is_empty>:
    - if <player.has_flag[net.utility.bypassing]>:
      - flag player net.utility.bypassing:!
      - narrate "<proc[net_symbol]> <element[Bypass:].color[<color[180,180,180]>]> <&c>Disabled"
      - stop
    - flag player net.utility.bypassing
    - narrate "<proc[net_symbol]> <element[Bypass:].color[<color[180,180,180]>]> <&a>Enabled"
    - stop
  - define player <server.match_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].has_flag[net.utility.bypassing]>:
    - flag <[player]> net.utility.bypassing:!
    - narrate "<proc[net_symbol]> <element[<[player].name>'s Bypass:].color[<color[180,180,180]>]> <&c>Disabled"
    - narrate "<proc[net_symbol]> <element[Bypass:].color[<color[180,180,180]>]> <&c>Disabled" targets:<[player]>
    - stop
  - flag <[player]> net.utility.bypassing
  - narrate "<proc[net_symbol]> <element[<[player].name>'s Bypass:].color[<color[180,180,180]>]> <&a>Enabled"
  - narrate "<proc[net_symbol]> <element[Bypass:].color[<color[180,180,180]>]> <&a>Enabled" targets:<[player]>

net_setspawn:
  type: command
  name: setspawn
  debug: false
  description: Set server's spawn
  permission: Net.Utility.SetSpawn
  usage: /setspawn
  tab complete:
  - if !<player.has_permission[Net.Utility.SetSpawn]||<context.server>>:
    - stop
  script:
  - flag server net.spawn_location:<player.location.center>
  - narrate "<proc[net_symbol]> <&a>Spawn Set <&7>(<player.location.simple>)"

net_sethub:
  type: command
  name: sethub
  debug: false
  description: Set server's hub
  permission: Net.Utility.SetHub
  usage: /sethub
  tab complete:
  - if !<player.has_permission[Net.Utility.SetHub]||<context.server>>:
    - stop
  script:
  - flag server net.hub_location:<player.location.center>
  - narrate "<proc[net_symbol]> <&a>Hub Set <&7>(<player.location.simple>)"

net_setworldspawn:
  type: command
  name: setworldspawn
  debug: false
  description: Set sworld's spawn
  permission: Net.Utility.SetWorldSpawn
  usage: /setworldspawn
  tab complete:
  - if !<player.has_permission[Net.Utility.SetWorldSpawn]||<context.server>>:
    - stop
  script:
  - adjust <player.world> spawn_location:<player.location.center>
  - narrate "<proc[net_symbol]> <&a>World Spawn Set <&7>(<player.location.simple>)"

net_spawn:
  type: command
  name: spawn
  debug: false
  description: Teleport to server's spawn
  usage: /spawn
  permission: Net.Utility.Spawn
  aliases:
  - l
  script:
  - if !<server.has_flag[net.spawn_location]>:
    - narrate "<&c>Spawn isn't setup."
    - stop
  - narrate "<proc[net_symbol]> <&a>Teleporting..."
  - inject fade_effect
  - teleport <player> <server.flag[net.spawn_location]>

net_fly:
  type: command
  name: fly
  debug: false
  description: Toggle flight
  usage: /fly (player)
  permission: Net.Utility.Fly
  #-Second Permission: Net.Utility.Other_Fly
  script:
  - if !<context.args.is_empty> && <context.args.size> > 1:
    - narrate "<&c>Incorrect command usage! Type /fly (player)"
    - stop
  - if <context.args.is_empty>:
    - adjust <player> can_fly:<tern[<player.can_fly>].pass[false].fail[true]>
    - narrate "<proc[net_symbol]> <element[Flight:].color[<color[180,180,180]>]> <tern[<player.can_fly>].pass[<&a>Enabled].fail[<&c>Disabled]>"
    - stop
  - if !<player.has_permission[Net.Utility.Other_Fly]>:
    - narrate <&c><script[net_config].data_key[error_msg]>
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Cannot find player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - adjust <[player]> can_fly:<tern[<[player].can_fly>].pass[false].fail[true]>
  - narrate "<proc[net_symbol]> <element[<[Player].name>'s Flight:].color[<color[180,180,180]>]> <tern[<[player].can_fly>].pass[<&a>Enabled].fail[<&c>Disabled]>"
  - narrate "<proc[net_symbol]> <element[Flight:].color[<color[180,180,180]>]> <tern[<[player].can_fly>].pass[<&a>Enabled].fail[<&c>Disabled]>" targets:<[player]>

net_speed:
  type: command
  name: speed
  debug: false
  description: Adjust walk/fly speed
  usage: /speed (0-1/reset)
  permission: Net.Utility.Speed
  tab complete:
  - if !<player.has_permission[Net.Utility.Speed]||<context.server>>:
    - stop
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /speed (0-1/reset)"
    - stop
  - define arg <context.args.first>
  - if <[arg]> == reset:
      - adjust <player> walk_speed:0.2
      - adjust <player> fly_speed:0.1
      - narrate "<proc[net_symbol]> <element[Walk/Fly Speed:].color[<color[180,180,180]>]> <&a>Default"
      - stop
  - if !<[arg].is_decimal> || <[arg]> < 0 || <[arg]> > 1:
    - narrate "<&c>Incorrect command usage! Argument must be a valid number from 0 to 1."
    - stop
  - define number <[arg].round_to[2]>
  - if <player.is_on_ground>:
    - adjust <player> walk_speed:<[number]>
    - narrate "<proc[net_symbol]> <element[Walk Speed:].color[<color[180,180,180]>]> <&a><[number]>"
  - else:
    - adjust <player> fly_speed:<[number]>
    - narrate "<proc[net_symbol]> <element[Fly Speed:].color[<color[180,180,180]>]> <&a><[number]>"


net_vanish:
  type: command
  name: vanish
  debug: false
  description: Hide from other players
  usage: /vanish
  permission: Net.Utility.Vanish
  #aliases:
  #- v
  script:
  - if !<player.has_flag[net.is_vanished]>:
    - adjust <player> hide_from_players
    - flag player net.is_vanished
    - narrate "<proc[net_symbol]> <element[Vanish:].color[<color[180,180,180]>]> <&a>Enabled"
    - stop
  - adjust <player> show_to_players
  - flag player net.is_vanished:!
  - narrate "<proc[net_symbol]> <element[Vanish:].color[<color[180,180,180]>]> <&c>Disabled"

net_link:
  type: command
  name: link
  debug: false
  description: Link Minecraft to Discord.
  permission: Net.Utility.Link
  usage: /link
  script:
  #<util.random_decimal.substring[3,6]>
  - if <player.has_flag[net.link_cooldown]>:
    - stop
  - define id playerdata_<player.uuid>
  - if <context.args.is_empty> && !<yaml[<[id]>].contains[Stats.Discord_Linked]>:
    - define invite <script[phone_data].data_key[heads.socials.discord.link]>
    - narrate "<&nl><element[<&o><&l>You haven't linked your Discord account yet!].color[#ff4d4d]>"
    - narrate "Join the <element[<&n><&l>Discord].color[#8d97fc].on_click[<[invite]>].type[OPEN_URL].on_hover[<&e>Click to join!]> and type <&e>/link <player.name><&nl>"
    - flag player net.link_cooldown duration:3s
    - stop
  #checking if empty, so players can relink their accounts
  - if <context.args.is_empty> && <yaml[<[id]>].contains[Stats.Discord_Linked]>:
    #i dont want ddiscordbot on all servers, so im not saying the user
    - define discord_user <yaml[<[id]>].read[Stats.Discord_Linked]>
    - define group <script[discord_data].data_key[group]>
    - ~bungeetag server:backup "<element[<[discord_user].name.color[<[discord_user].roles[<[group]>].first.color>]><&8>#<[discord_user].discriminator>].on_hover[<element[<&l>Roles].color[<color[222,222,222]>]><&nl><[discord_user].roles[<[group]>].parse_tag[<[parse_value].name.color[<[parse_value].color||null>]||null>].exclude[null].parse_tag[<&b>• <[parse_value]>].separated_by[<&nl>]>]>" save:discord_name
    - narrate "<proc[net_symbol]> <element[Your account is already linked with].color[<color[222,222,222]>]> <entry[discord_name].result>"
    - stop
  - define code <context.args.first>
  - if !<yaml[<[id]>].contains[Stats.Discord_Requests.<[code]>]>:
    - narrate "<&c>Invalid link code."
    - stop
  - define discord_user <yaml[<[id]>].read[Stats.Discord_Requests.<[code]>]>
  #-This checks if the discord user was previously linked with another player, and if so,
  #-remove that player's linked discord user
  - ~bungeetag server:backup <[discord_user].flag[linked_player]||null> save:previous_linked
  - define last_uuid <entry[previous_linked].result>
  - if <[last_uuid]> != null:
    - define last_id playerdata_<[last_uuid]>
    - define is_online <server.has_flag[bungee.online_players.<[last_uuid]>]>
    - if <[is_online]>:
      - if <server.flag[bungee.online_players.<[last_uuid]>]> == <bungee.server>:
        - yaml id:<[last_id]> set Stats.Discord_Linked:!
        - ~yaml savefile:../../../../globaldata/playerdata/<[last_uuid]>.yml id:<[last_id]>
      - else:
        #just adding the discord_user def because it needs it
        - bungeerun <server.flag[bungee.online_players.<[last_uuid]>]> bungee_discord_linked def:<[discord_user]>|<[last_uuid]>|unlink
    - else:
      - yaml load:../../../../globaldata/playerdata/<[last_uuid]>.yml id:<[last_id]>
      - yaml set id:<[last_id]> Stats.Discord_Linked:!
      - ~yaml savefile:../../../../globaldata/playerdata/<[last_uuid]>.yml id:<[last_id]>
      - yaml unload id:<[last_id]>
  #-
  - yaml id:<[id]> set Stats.Discord_Requests:!
  - yaml id:<[id]> set Stats.Discord_Linked:<[discord_user]>
  - ~yaml savefile:../../../../globaldata/playerdata/<player.uuid>.yml id:<[id]>
  - bungeerun backup bungee_discord_linked def:<[discord_user]>|<player.uuid>|link
  - define group <script[discord_data].data_key[group]>
  - ~bungeetag server:backup "<element[<[discord_user].name.color[<[discord_user].roles[<[group]>].first.color>]><&8>#<[discord_user].discriminator>].on_hover[<element[<&l>Roles].color[<color[222,222,222]>]><&nl><[discord_user].roles[<[group]>].parse_tag[<[parse_value].name.color[<[parse_value].color||null>]||null>].exclude[null].parse_tag[<&b>• <[parse_value]>].separated_by[<&nl>]>]>" save:discord_name
  #- ~bungeetag server:backup <element[<[discord_user].name.color[<[discord_user].roles[<[group]>].first.color>]><&8>#<[discord_user].discriminator>].on_hover[<[discord_user].roles[<[group]>].parse_tag[<[parse_value].name.color[<[parse_value].color||null>]||null>].exclude[null]>]> save:discord_name
  - define discord_name <entry[discord_name].result>
  - narrate "<proc[net_symbol]> <&a>Discord account linked to <[discord_name]><&a>!"

bungee_discord_linked:
  type: task
  debug: false
  definitions: discord_user|uuid|action
  script:
  - if <[action]> == link:
    - ~discordmessage id:bot user:<[discord_user]> "Success! Your Discord account is now linked to **<server.flag[bungee.players.<[uuid]>]>** on Nimbus."
    - flag <[discord_user]> linked_player:<[uuid]>
  - else:
    - yaml id:playerdata_<[uuid]> set Stats.Discord_Linked:!
    - ~yaml savefile:../../../../globaldata/playerdata/<[uuid]>.yml id:playerdata_<[uuid]>

bungee_discord_request:
  type: task
  debug: false
  definitions: data
  script:
  - define target_uuid <[data].get[target_uuid]>
  - define id playerdata_<[target_uuid]>
  - define discord_user <[data].get[discord_user]>
  - define code <[data].get[code]>
  - define action <[data].get[action]>
  - if <[action]> == add:
    - yaml id:<[id]> set Stats.Discord_Requests.<[code]>:<[discord_user]>
    - ~yaml savefile:../../../../globaldata/playerdata/<[target_uuid]>.yml id:<[id]>
  - else:
    #- if !<yaml[<[id]>].contains[Stats.Discord_Requests.<[code]>]>:
    #  - stop
    - yaml id:<[id]> set Stats.Discord_Requests.<[code]>:!
    - ~yaml savefile:../../../../globaldata/playerdata/<[target_uuid]>.yml id:<[id]>

bungee_discord_voice:
  type: task
  debug: false
  definitions: discord_user|location
  script:
  #one tagger = possible, but nah
  #possible locations: Hub, Backup, Wilderness, Cozy Town
  - foreach <script[discord_data].data_key[voice_channels]> as:id:
    - if <discord_channel[bot,<[id]>].connected_users.contains[<[discord_user]>]>:
      - define in_vc True
      - foreach stop
  - if !<[in_vc].exists>:
    - stop
  - define vc <discord_channel[bot,<script[discord_data].data_key[voice_channels.<[location]>]>]>
  - adjust <[discord_user]> move:<[vc]>
  - if <[location]> == join:
    - stop
  - define uuid <[discord_user].flag[linked_player]>
  - bungeerun <server.flag[bungee.online_players.<[uuid]>]> bungee_discord_connected def:<[uuid]>|<[location]>

bungee_discord_connected:
  type: task
  debug: false
  definitions: uuid|location
  script:
  - define player <[uuid].as_player>
  - narrate "<&nl><&sp.repeat[16]> <element[[Joined <&b><[location].to_titlecase><&r> VC]].color[<color[180,180,180]>]><&nl>" targets:<[player]>
  - playsound <[player]> sound:BLOCK_NOTE_BLOCK_HAT pitch:1

net_youtube:
  type: command
  name: youtube
  debug: false
  description: Get Nimsy's YouTube link.
  permission: Net.Utility.YouTube
  usage: /youtube
  aliases:
  - yt
  script:
  - define social youtube
  - inject net_youtube.socials
  socials:
  - define name <map[youtube=<&l><element[YOUTUBE].color[#f25050]>;twitch=<&l><element[TWITCH].color[#ba42ff]>;twitter=<&l><element[TWITTER].color[#5ac4ed]>;discord=<element[DISCORD].color[#8d97fc]>;tiktok=<element[TIKTOK].color[#ff80e1]>].get[<[social]>]>
  - narrate "<&a><&l><[name]> <&7>» <&e><&n><script[phone_data].data_key[heads.socials.<[social]>.link]>"

net_twitch:
  type: command
  name: twitch
  debug: false
  description: Get Nimsy's Twitch link.
  permission: Net.Utility.Twitch
  usage: /twitch
  script:
  - define social twitch
  - inject net_youtube.socials

net_twitter:
  type: command
  name: twitter
  debug: false
  description: Get Nimsy's Twitter link.
  permission: Net.Utility.Twitter
  usage: /twitter
  script:
  - define social twitter
  - inject net_youtube.socials

net_discord:
  type: command
  name: discord
  debug: false
  description: Get the Discord link.
  permission: Net.Utility.Discord
  usage: /discord
  script:
  - define social discord
  - inject net_youtube.socials

net_tiktok:
  type: command
  name: tiktok
  debug: false
  description: Get Nimsy's TikTok link.
  permission: Net.Utility.TikTok
  usage: /tiktok
  script:
  - define social tiktok
  - inject net_youtube.socials

net_live:
  type: command
  name: live
  debug: false
  description: Twitch "live" announcement
  permission: Net.Utility.Live
  usage: /live
  tab complete:
  - if !<player.has_permission[Net.Utility.Live]||<context.server>>:
    - stop
  script:
  - define twitch_logo <&chr[0001].font[denizen:logos]>
  - define console "<&l>Twitch Announcement <&gt><&gt> <element[Nimsy is live!].color[#bf4fff]>"
  - define border <&8><&l><&m><&sp.repeat[51]><&r>
  - define line1 "<&sp.repeat[9]><element[Nimsy is live!].color_gradient[from=#ac1cff;to=#d68fff]><&r><&sp.repeat[8]><[twitch_logo]><&nl>"
  - define line2 <&sp.repeat[17]><&8><&o><element[Twitch.Tv/FlimsyNimsy].color[#737373]><&nl>
  - define line3 "<&sp.repeat[23]><&e><&l><element[CLICK HERE].on_hover[<&a>Join stream!].on_click[https://twitch.tv/flimsynimsy].type[OPEN_URL]>"
  - define text <[border]><&nl><&sp.repeat[8]><[twitch_logo]><[line1]><[line2]><[line3]><&nl><[border]>
  - announce <[text]>
  - announce to_console <[console]>
  - redis id:publisher publish:global_chat_<bungee.server> message:<map[message=<[text]>;twitch=true;console=<[console]>]>
  #v1
  #- define twitch_logo <&chr[0001].font[denizen:logos]>
  #- define console "<&l>Twitch Announcement <&gt><&gt> <element[Nimsy is live!].color[#ac1cff]>"
  #- define line1 "<&sp.repeat[10]><element[Nimsy is live!].color_gradient[from=#ac1cff;to=#d68fff]><&nl>"
  #- define line2 <&sp.repeat[10]><&8><&o><element[Twitch.Tv/FlimsyNimsy].color[#737373]><&nl>
  #- define line3 "<&sp.repeat[16]><&e><&l><element[CLICK HERE].on_hover[<&a>Join stream!].on_click[https://twitch.tv/flimsynimsy].type[OPEN_URL]>"
  #- define text <[twitch_logo]><[line1]><[line2]><[line3]>
  #- announce <[text]>
  #- announce to_console <[console]>
  #- redis id:publisher publish:global_chat_<bungee.server> message:<map[message=<[text]>;twitch=true;console=<[console]>]>

net_announce:
  type: command
  name: announce
  debug: false
  description: Announce a message
  permission: Net.Utility.Announce
  usage: /announce (message)
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /announce (message)"
    - stop
  - define text <context.args.space_separated.parse_color>
  - announce "<&l><element[ANNOUNCEMENT].color[#ffc800]> <proc[net_symbol]> <[text]>"
  - announce to_console "(From: <player.name>) <&l><element[ANNOUNCEMENT].color[#ffc800]> <&gt><&gt> <[text]>"
  - redis id:publisher publish:global_chat_<bungee.server> message:<map[message=<[text]>;name=<player.name>;announcement=true]>

net_message:
  type: command
  name: message
  debug: false
  description: Message a player
  permission: Net.Utility.Message
  usage: /message (player) (message)
  tab complete:
  #- inject net_tasks path:tab
  - define online_names <server.flag[bungee.players].keys.filter_tag[<server.flag[bungee.online_players].contains[<[filter_value]>]>].parse_tag[<server.flag[bungee.players.<[parse_value]>]>].alphabetical>
  - if <context.args.is_empty>:
    - determine passively <[online_names].exclude[<player.name>]>
    - stop
  - if <context.args.size> > 1 || <context.raw_args.ends_with[<&sp>]>:
    - stop
  - determine <[online_names].filter[starts_with[<context.args.last>]]>
  aliases:
  - msg
  script:
  - if <context.args.size> <= 1:
    - narrate "<&c>Incorrect command usage! Type /message (player) (message)"
    - stop
  - if <bungee.server||null> == null:
    - narrate "<proc[net_symbol]> BungeeCord is not installed on this server."
    - stop
  - define input <context.args.first>
  - define players <server.flag[bungee.players].values>
  - if <[players].filter[starts_with[<[input]>]].is_empty>:
    - narrate "<&c>Invalid player."
    - stop
  - define target_name <[players].filter[starts_with[<[input]>]].first>
  - define online_names <server.flag[bungee.players].keys.filter_tag[<server.flag[bungee.online_players].contains[<[filter_value]>]>].parse_tag[<server.flag[bungee.players.<[parse_value]>]>].alphabetical>
  - if !<[online_names].contains[<[target_name]>]>:
    - narrate "<&c><[target_name]> is offline. Try /mail instead."
    - stop
  - define found_name <[online_names].filter[starts_with[<[input]>]].first>
  - define uuid <server.flag[bungee.players].filter_tag[<[filter_value].equals[<[found_name]>]>].keys.first>
  - define target <[uuid].as_player>
  - if <[target]> == <player>:
    - narrate "<&c>You cannot send messages to yourself!"
    - stop
  - define pfp <&chr[<yaml[playerdata_<player.uuid>].read[Profile.Avatar]>].font[denizen:pfps]||<empty>>
  - define from <player.name>
  - define tint <yaml[playerdata_<player.uuid>].read[Profile.Tint]>
  - define msg <context.args.exclude[<[input]>].space_separated.split_lines_by_width[300].split[<n>].parse_tag[<&sp.repeat[6]><[parse_value]>].separated_by[<n>]>
  - define id playerdata_<[uuid]>
  - if <server.flag[bungee.online_players.<[uuid]>]> != <bungee.server>:
    - inject net_message path:global_block_check
    - definemap data:
        pfp: <[pfp]>
        tint: <[tint]>
        from: <player.uuid>
        target: <[target]>
        msg: <[msg]>
    - bungeerun <server.flag[bungee.online_players.<[uuid]>]> net_bungee_msg def:<[data]>
    - stop
  - inject net_message path:local_block_check
  - narrate "<[pfp]> <[from].color_gradient[from=<[tint]>;to=#f2f2f2]><&r> <element[»].color[<color[180,180,180]>]> <&a>You<n><&r><[msg]>" targets:<[target]>
  - flag <[target]> Net.Utility.Reply:<player.uuid> duration:5m
  local_block_check:
  - if <yaml[<[id]>].read[Social.Blocked_Players].contains[<player.uuid>]>:
    - narrate "<&c>Cannot send! <[found_name]> has blocked you."
    - stop
  - narrate "<[pfp]> <&a>You <element[»].color[<color[180,180,180]>]> <[found_name].color_gradient[from=<yaml[<[id]>].read[Profile.Tint]>;to=#f2f2f2]><&r><&nl><[msg]>"
  #local = for messages within the same server
  global_block_check:
  #global = for message across servers
  #-Two Methods:
  #1: use bungeerun and check if the player is blocked from the other player's server, if yes, bungeerun back to sender w/ error msg
  #2: load player's yaml file here, read it, and then unload it. Could this pose as a problem? idk
  - yaml load:../../../../globaldata/playerdata/<[uuid]>.yml id:<[id]>
  - if <yaml[<[id]>].read[Social.Blocked_Players].contains[<player.uuid>]>:
    - yaml unload id:<[id]>
    - narrate "<&c>Cannot send! <[found_name]> has blocked you."
    - stop
  - narrate "<[pfp]> <&a>You<&r> <element[»].color[<color[180,180,180]>]> <[found_name].color_gradient[from=<yaml[<[id]>].read[Profile.Tint]>;to=#f2f2f2]><n><&r><[msg]>"
  - yaml unload id:<[id]>

#one problem with replies: if you switch servers, you cant do /r until they msg u again
net_reply:
  type: command
  name: reply
  debug: false
  description: Reply to a player
  permission: Net.Utility.Message
  usage: /reply (message)
  tab complete:
  - inject net_tasks path:tab
  aliases:
  - r
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /reply (message)"
    - stop
  - if !<player.has_flag[net.utility.reply]>:
    - narrate "<&c>No messages received."
    - stop
  - define uuid <player.flag[net.utility.reply]>
  - if !<server.flag[bungee.online_players].keys.contains[<[uuid]>]>:
    - narrate "<&c>Player offline."
    - stop
  - define target <[uuid].as_player>
  - define pfp <&chr[<yaml[playerdata_<player.uuid>].read[Profile.Avatar]>].font[denizen:pfps]||<empty>>
  - define from <player.name>
  - define tint <yaml[playerdata_<player.uuid>].read[Profile.Tint]>
  - define found_name <server.flag[bungee.players.<[uuid]>]>
  - define name <&e><[found_name]><&r><&nl>
  - define msg <context.args.separated_by[<&sp>].split_lines_by_width[300].split[<n>].parse_tag[<&sp.repeat[6]><[parse_value]>].separated_by[<n>]>
  - define id playerdata_<[uuid]>
  - if <server.flag[bungee.online_players.<[uuid]>]> != <bungee.server>:
    - inject net_message path:global_block_check
    - definemap data:
        pfp: <[pfp]>
        tint: <[tint]>
        from: <player.uuid>
        target: <[target]>
        msg: <[msg]>
        #-Two Methods:
    - bungeerun <server.flag[bungee.online_players.<[uuid]>]> net_bungee_msg def:<[data]>
    - stop
  - inject net_message path:local_block_check
  - narrate "<[pfp]> <&e><[from].color_gradient[from=<[tint]>;to=#f2f2f2]><&r> <element[»].color[<color[180,180,180]>]> <&a>You<n><&r><[msg]>" targets:<[target]>
  - flag <[target]> Net.Utility.Reply:<player.uuid> duration:5m


net_bungee_msg:
  type: task
  debug: false
  definitions: data
  script:
  - define pfp <[data].get[pfp]>
  - define from <[data].get[from]>
  - define from_name <server.flag[bungee.players.<[from]>]>
  - define target <[data].get[target]>
  - define msg <[data].get[msg]>
  - narrate "<[pfp]> <[from_name].color_gradient[from=<[data].get[tint]>;to=#f2f2f2].on_hover[<&e>Reply<&nl><&7>/r <[from_name]>].on_click[/msg <[from_name]> ].type[SUGGEST_COMMAND]> <element[»].color[<color[180,180,180]>]><&r> <&a>You<n><&r><[msg]>" targets:<[target]>
  - flag <[data].get[target]> Net.Utility.Reply:<[from]> duration:5m

net_spy:
  type: command
  name: spy
  debug: false
  #and pms?
  description: View other user commands
  permission: Net.Moderation.Spy
  usage: /spy
  tab complete:
  - if !<player.has_permission[Net.Moderation.Spy]||<context.server>>:
    - stop
  script:
  - if <player.has_flag[Net.Moderation.Spy_Mode]>:
    - flag player Net.Moderation.Spy_Mode:!
    - narrate "<proc[net_symbol]> <element[Spy Mode:].color[<color[180,180,180]>]> <&c>Disabled"
    - stop
  - flag player Net.Moderation.Spy_Mode
  - narrate "<proc[net_symbol]> <element[Spy Mode:].color[<color[180,180,180]>]> <&a>Enabled"

net_inventorysee:
  type: command
  name: inventorysee
  debug: false
  description: View another player's inventory.
  permission: Net.Moderation.InventorySee
  usage: /inventorysee (player)
  aliases:
  - invsee
  tab complete:
  - if !<player.has_permission[Net.Utility.InventorySee]||<context.server>>:
    - stop
  - else:
    - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /inventorysee (player)"
    - stop
  #other fly = you can make other people fly
  - if !<player.has_permission[Net.Utility.Other_Fly]>:
    - narrate <&c><script[net_config].data_key[error_msg]>
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Cannot find player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - inventory open d:<[player].inventory>
  - narrate "<proc[net_symbol]> <element[Now viewing].color[<color[180,180,180]>]> <&a><[player].name><element['s inventory.].color[<color[180,180,180]>]>"

net_server:
  type: command
  name: server
  debug: false
  description: Transfer between servers
  permission: Net.Utility.Server
  usage: /server (server)
  tab complete:
  - if <context.args.is_empty>:
    - determine <bungee.list_servers>
  - else if <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]>:
    - determine <bungee.list_servers.filter[starts_with[<context.args.last>]]>
  aliases:
  - serv
  script:
  - if <bungee.server||null> == null:
    - narrate "<&c>This server doesn't have BungeeCord installed."
    - stop
  - if <context.args.is_empty>:
    - narrate "<proc[net_symbol]> <&7>Available Servers: <&a><bungee.list_servers.separated_by[<&7>, <&a>]>"
    - stop
  - define server <context.args.first>
  - if !<bungee.list_servers.contains[<[server]>]>:
    - narrate "<&c>Invalid server."
    - stop
  - narrate "<proc[net_symbol]> <element[Sending you to:].color[<color[180,180,180]>]> <&a><[server]>"
  - adjust <player> send_to:<[server]>

net_kick:
  type: command
  name: kick
  debug: false
  description: Kick a player
  permission: Net.Moderation.Kick
  usage: /kick (player) (reason)
  tab complete:
  - if !<player.has_permission[Net.Moderation.Kick]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /kick (player) (reason)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - if <[player].is_op>:
    - narrate <&c><script[net_config].data_key[error_msg]>
    - stop
  - if <context.args.size> >= 2:
    - define reason <context.raw_args.after[<context.args.first><&sp>]>
  - else:
    - define reason Kicked.
  - kick <[player]> reason:<[reason]>
  - narrate "<proc[net_symbol]> <element[Kicked].color[<color[180,180,180]>]> <&c><[player].name> <element[Reason:].color[<color[180,180,180]>]> <&e><[reason]>"

net_ban:
  type: command
  name: ban
  debug: false
  description: Ban a player
  permission: Net.Moderation.Ban
  usage: /ban (player) (reason) d(duration) [ip]
  tab complete:
  - if !<player.has_permission[Net.Moderation.Ban]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  #is_empty
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage!<&nl>Type /ban (player) (reason) d:(duration) [ip]"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].is_banned>:
    - narrate "<&c>Player is already banned."
    - stop
  - if <[player].is_op>:
    - narrate <&c><script[net_config].data_key[error_msg]>
    - stop
  - if !<context.args.filter[starts_with[d:]].is_empty>:
    - define duration <context.args.filter[starts_with[d:]].first.after[d:]>
    - define unit <[duration].to_list.last>
    - define time <[duration].replace_text[<[unit]>].with[<empty>]>
    - if !<[time].is_integer>:
      - narrate "<&c>Invalid time specified! Type (duration)(s/m/h/d)."
      - stop
    - if !<list[s|m|h|d].contains[<[unit]>]>:
      - narrate "<&c>Invalid unit! Type (duration)(s/m/h/d)."
      - stop
  #remove the duration element went finding the reason, this way the duration can be put any where
  - define ip_ban <context.args.contains[ip]>
  - if <[ip_ban]>:
    - flag server net.moderation.banned_ips:->:<[player].uuid>/<[player].ip>
  - define args <context.args.filter[starts_with[d:].not].exclude[<context.args.first>|ip]>
  - if !<[args].is_empty>:
    - define reason <[args].separated_by[<&sp>]>
  - else:
    - define reason Banned.
  - if <[duration].exists>:
    - ban <[player]> addresses:<tern[<[ip_ban]>].pass[<[player].ip>].fail[<empty>]> reason:<[reason]> duration:<[duration]>
  - else:
    - ban <[player]> addresses:<tern[<[ip_ban]>].pass[<[player].ip>].fail[<empty>]> reason:<[reason]>
  - narrate "<proc[net_symbol]> <element[Banned].color[<color[180,180,180]>]> <&c><[player].name> <element[Reason:].color[<color[180,180,180]>]> <&e><[reason]> <element[For:].color[<color[180,180,180]>]> <&e><[duration]||∞> <element[IP:].color[<color[180,180,180]>]> <tern[<[ip_ban]>].pass[<&a>Yes].fail[<&c>No]>"

net_unban:
  type: command
  name: unban
  debug: false
  description: Unban a player
  permission: Net.Moderation.Ban
  usage: /unban (player)
  tab complete:
  - if <context.args.is_empty>:
    - determine <server.banned_players.parse[name]>
  - else if <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]>:
    - determine <server.banned_players.parse[name].filter[starts_with[<context.args.last>]]>
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage!Type /unban (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<[player].is_banned>:
    - narrate "<&c><[player].name> is not banned."
    - stop
  - if <server.flag[net.moderation.banned_ips].filter[before[/]].contains[<[player].uuid>]||false>:
    - define ip_data <server.flag[net.moderation.banned_ips].filter[before[/].equals[<[player].uuid>]].first>
    - flag server net.moderation.unbanned_ips:<-:<[ip_data]>
  #<empty> for address if it wasn't an IP aban
  - ban remove <[player]> addresses:<[ip_data].after[/]||<empty>>
  - narrate "<proc[net_symbol]> <element[Unbanned <[player].name>.].color[<color[180,180,180]>]>"

#dynamically updating bans list
#add clicking players in list to unban?
net_bans:
  type: command
  name: bans
  debug: false
  description: Lists banned players
  permission: Net.Moderation.Ban
  usage: /bans
  tab complete:
  - if !<player.has_permission[Net.Utility.Help]||<context.server>>:
    - stop
  script:
  - define banned_players <server.banned_players.alphabetical.sub_lists[7]>
  - if <[banned_players].is_empty>:
    - narrate "<proc[net_symbol]> <&a>No players are banned yet. HOORAY!"
    - stop
  - define page <context.args.first||1>
  - define total_pages <[banned_players].size>
  - if !<[page].is_integer> || <[page]> <= 0:
    - define page 1
  - if <[page]> > <[total_pages]>:
    - define page <[total_pages]>
  - define banned_players <[banned_players].get[<[page]>]>
  - narrate "<&8><&l><&m><&sp.repeat[14]><&8><&l>| <element[B].color[<color[255,65,65]>]><&c><&l>anned <element[P].color[<color[255,65,65]>]><&c><&l>layers <&8><&l>|<&m><&sp.repeat[14]>"
  - foreach <[banned_players]> as:player:
    - define name <[player].name>
    - define reason <[player].ban_reason||null>
    #players are only removed from the bans list when they join back
    - if <[reason]> == null:
      - foreach next
    - if <[reason].to_list.size> > 20:
      - define full_reason <[reason].split_lines[35].color[<color[222,222,222]>]>
      - define reason <[reason].substring[1,20]>...
    - define duration <[player].ban_expiration_time.from_now.formatted.if_null[∞]>
    - narrate "<&b>• <&c><[name].color_gradient[from=#ff4747;to=#ff9191]> <&7>R: <element[<[reason].color[<color[222,222,222]>]>].on_hover[<tern[<[full_reason].exists>].pass[<[full_reason]>].fail[<empty>]>]> <&7>For: <&e><[duration]>"
  - narrate "<&8><&l><&m><&sp.repeat[3]><tern[<[page].sub[1].equals[0]>].pass[<&8><&l><&m><&sp.repeat[8]>].fail[ <&r><element[<&l><element[«].color[<color[255,50,50]>]> <&7>Page <[page].sub[1]>].on_hover[<&e>Click for previous page.].on_click[/bans <[page].sub[1]>]><&8><&l> ]><&8><&l><&m><&sp.repeat[8]><&r> <&c>Page <[page]><&7>/<&c><[total_pages]><&8><&l> <&8><&l><&m><&sp.repeat[8]><tern[<[total_pages].equals[<[page]>]>].pass[<&8><&l><&m><&sp.repeat[8]>].fail[ <&7><element[Page <[page].add[1]> <&l><element[»].color[<color[255,50,50]>]>].on_hover[<&e>Click for next page.].on_click[/bans <[page].add[1]>]><&8><&l> ]><&8><&l><&m><&sp.repeat[4]>"


#-Add universal muting?
net_mute:
  type: command
  name: mute
  debug: false
  description: Toggle mute for players in chat
  permission: Net.Moderation.Mute
  usage: /mute (player)
  tab complete:
  - if !<player.has_permission[Net.Moderation.Mute]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /mute (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].has_flag[net.moderation.muted]>:
    - flag <[player]> net.moderation.muted:!
    - narrate "<proc[net_symbol]> <element[Unmuted <[player].name>.].color[<color[180,180,180]>]>"
    - narrate "<proc[net_symbol]> <element[You have been unmuted.].color[<color[180,180,180]>]>" targets:<[player]>
    - stop
  - flag <[player]> net.moderation.muted
  - narrate "<proc[net_symbol]> <element[Muted <[player].name>.].color[<color[180,180,180]>]>"
  - narrate "<proc[net_symbol]> <element[You have been muted.].color[<color[180,180,180]>]>" targets:<[player]>

net_deafen:
  type: command
  name: deafen
  debug: false
  description: Deafen players in chat
  permission: Net.Moderation.Deafen
  usage: /deafen (player)
  tab complete:
  - if !<player.has_permission[Net.Moderation.Deafen]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /deafen (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].has_flag[net.moderation.deafened]>:
    - flag <[player]> net.moderation.deafened:!
    - narrate "<proc[net_symbol]> <element[Undeafened <[player].name>.].color[<color[180,180,180]>]>"
    - narrate "<proc[net_symbol]> <element[You have been undeafened.].color[<color[180,180,180]>]>" targets:<[player]>
    - stop
  - flag <[player]> net.moderation.deafened
  - narrate "<proc[net_symbol]> <element[Deafened <[player].name>.].color[<color[180,180,180]>]>"
  - narrate "<proc[net_symbol]> <element[You have been deafened.].color[<color[180,180,180]>]>" targets:<[player]>


##next add: /utp (teleport to players between servers)
#add teleport cooldown?
net_teleport:
  type: command
  name: teleport
  debug: false
  description: Teleport to a player
  permission: Net.Utility.Teleport
  usage: /teleport (player/x y z)
  aliases:
  - tp
  tab complete:
  - if !<player.has_permission[Net.Utility.Teleport]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty> || <context.args.size> != 1 && <context.args.size> != 3:
    - narrate "<&c>Incorrect command usage! Type /teleport (player/x y z)"
    - stop
  - if <context.args.size> == 3:
    - define coords <context.args>
    - if <[coords].filter[is_decimal].size> != <[coords].size>:
      - narrate "<&c>Incorrect command usage! Use valid numbers."
      - stop
    - narrate "<proc[net_symbol]> <&a>Teleporting..."
    - teleport <player> <location[<[coords].comma_separated>,<player.world>]>
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].uuid> == <player.uuid>:
    - narrate "<&c>Cannot teleport to yourself!"
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - narrate "<proc[net_symbol]> <&a>Teleporting to <[player].name>..."
  - teleport <player> <[player].location>

net_tphere:
  type: command
  name: teleporthere
  debug: false
  permission: Net.Utility.TeleportHere
  description: Teleport a player to you
  usage: /teleporthere (player)
  aliases:
  - tphere
  tab complete:
  - if !<player.has_permission[Net.Utility.TeleportHere]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty> || <context.args.size> != 1:
    - narrate "<&c>Incorrect command usage! Type /teleporthere (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - narrate "<proc[net_symbol]> <&a>Teleporting <[player].name> to you..."
  - teleport <[player]> <player.location>

net_fuckyou:
  type: command
  name: fuckyou
  debug: false
  permission: Net.Utility.FuckYou
  description: Fuck you.
  usage: /fuckyou
  aliases:
  - fu
  tab complete:
  - if !<player.has_permission[Net.Utility.FuckYou]||<context.server>>:
    - stop
  script:
  - if <player.has_flag[net.FU_Cooldown]>:
    - stop
  - narrate "<&c>fuck you too"
  - flag player net.FU_Cooldown duration:3s

net_tpacancel:
  type: command
  name: tpacancel
  debug: false
  description: Cancel your teleport request.
  permission: Net.Utility.TPA
  usage: /tpacancel (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /tpacancel (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - if !<[player].has_flag[Net.Utility.TP_Requests]> || !<[player].flag[Net.Utility.TP_Requests].parse[get[from]].contains[<player.uuid>]>:
    - narrate "<&c>No teleport request sent."
    - stop
  - define tp_data <[player].flag[Net.Utility.TP_Requests].filter[get[from].equals[<player.uuid>]].first>
  - flag <[player]> Net.Utility.TP_Requests:<-:<[tp_data]>
  - narrate "<proc[net_symbol]> <&c>Request to <[player].name> cancelled."
  - narrate "<proc[net_symbol]> <&c><player.name> cancelled the request." targets:<[player]>

#gotta make a task script for tpa and tpahere
net_tpa:
  type: command
  name: tpa
  debug: false
  description: Teleport to a player via request.
  permission: Net.Utility.TPA
  usage: /tpa (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /tpa (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].uuid> == <player.uuid>:
    - narrate "<&c>Cannot teleport to yourself!"
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - if <[player].has_flag[Net.Utility.TP_Requests]> && <[player].flag[Net.Utility.TP_Requests].parse[get[from]].contains[<player.uuid>]>:
    - narrate "<&c>Teleport request already sent."
    - stop
  - define accept "<element[<&8><&lb><&a><&l>✔<&8><&rb>].on_hover[<&a>Accept request!<&nl><&7>/tpaaccept <player.name>].on_click[/tpaccept <player.name>]>"
  - define deny "<element[<&8><&lb><&c><&l>✘<&8><&rb>].on_hover[<&c>Deny request!<&nl><&7>/tpadeny <player.name>].on_click[/tpdeny <player.name>]>"
  - define epearl <&chr[0003].font[denizen:announcements]>
  - define line1 "<&sp.repeat[6]><element[Teleport request from].color[<color[180,180,180]>]> <&a><player.name><element[.].color[<color[180,180,180]>]>"
  - define line2 "<&sp.repeat[16]><element[You have].color[<color[180,180,180]>]> <element[10s].color[<color[222,222,222]>]> <element[to accept.].color[<color[180,180,180]>]>"
  - define line3 <&sp.repeat[24]><[accept]><&sp.repeat[5]><[deny]>
  - define border <&8><&l><&m><&sp.repeat[50]><&r>
  - flag <[player]> Net.Utility.TP_Requests:->:<map[from=<player.uuid>;type=there]> duration:10s
  - narrate <[border]><&nl><[epearl]><[line1]><n><&o><[line2]><&r><n><[line3]><&nl><[border]> targets:<[player]>
  #- narrate "<proc[net_symbol]> <element[Teleport request sent to].color[<color[180,180,180]>]> <&a><[player].name><element[.].color[<color[180,180,180]>]>"
  - define line1 "<&sp.repeat[2]><element[Teleport request sent to].color[<color[180,180,180]>]> <&a><[player].name><element[.].color[<color[180,180,180]>]>"
  - define line2 "<&sp.repeat[13]><element[They have].color[<color[180,180,180]>]> <element[10s].color[<color[222,222,222]>]> <element[to accept.].color[<color[180,180,180]>]>"
  - define line3 "<&sp.repeat[27]><element[<&8><&lb><&c><&l>✘<&8><&rb>].on_hover[<&e>Cancel request!].on_click[/tpacancel <[player].name>]>"
  - narrate <[border]><&nl><[epearl]><[line1]><n><&o><[line2]><&r><n><[line3]><&nl><[border]>

net_tpahere:
  type: command
  name: tpahere
  debug: false
  description: Teleport player's to you via request.
  permission: Net.Utility.TPA
  usage: /tpahere (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /tpahere (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].uuid> == <player.uuid>:
    - narrate "<&c>Cannot teleport to yourself!"
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - if <[player].has_flag[Net.Utility.TP_Request]> && <[player].flag[Net.Utility.TP_Request].contains[<player.uuid>]>:
    - narrate "<&c>Teleport request already sent."
    - stop
  - define accept "<element[<&8><&lb><&a><&l>✔<&8><&rb>].on_hover[<&e>Accept request!].on_click[/tpaccept <player.name>]>"
  - define deny "<element[<&8><&lb><&c><&l>✘<&8><&rb>].on_hover[<&e>Deny request!].on_click[/tpdeny <player.name>]>"
  - flag <[player]> Net.Utility.TP_Requests:->:<map[from=<player.uuid>;type=here]> duration:10s
  - define epearl <&chr[0003].font[denizen:announcements]>
  - define line1 "<&sp><element[Teleport <&n>here<&r> request from].color[<color[180,180,180]>]> <&a><player.name><element[.].color[<color[180,180,180]>]>"
  - define line2 "<&sp.repeat[14]><element[You have].color[<color[180,180,180]>]> <element[10s].color[<color[222,222,222]>]> <element[to accept.].color[<color[180,180,180]>]>"
  - define line3 <&sp.repeat[22]><[accept]><&sp.repeat[5]><[deny]>
  - define border <&8><&l><&m><element[-].repeat[30]><&r>
  #- flag <[player]> Net.Utility.TP_Requests:->:<map[from=<player.uuid>;type=there]> duration:10s
  - narrate <[border]><&nl><[epearl]><[line1]><n><&o><[line2]><&r><n><[line3]><&nl><[border]> targets:<[player]>
  #- narrate "<proc[net_symbol]> <element[Teleport here request sent to].color[<color[180,180,180]>]> <&a><[player].name><element[.].color[<color[180,180,180]>]>"
  - define line1 "<&sp><element[Teleport <&n>here<&r> request sent to].color[<color[180,180,180]>]> <&a><[player].name><element[.].color[<color[180,180,180]>]>"
  - define line2 "<&sp.repeat[13]><element[They have].color[<color[180,180,180]>]> <element[10s].color[<color[222,222,222]>]> <element[to accept.].color[<color[180,180,180]>]>"
  - define line3 "<&sp.repeat[27]><element[<&8><&lb><&c><&l>✘<&8><&rb>].on_hover[<&e>Cancel request!].on_click[/tpacancel <[player].name>]>"
  - narrate <[border]><&nl><[epearl]><[line1]><n><&o><[line2]><&r><n><[line3]><&nl><[border]>

#make a task script for both accepting ones? tp_decision
net_tpaccept:
  type: command
  name: tpaccept
  debug: false
  description: Accept teleport requests.
  permission: Net.Utility.TPA
  usage: /tpaccept (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /tpaccept (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<player.has_flag[Net.Utility.TP_Requests]> || !<player.flag[Net.Utility.TP_Requests].parse[get[from]].contains[<[player].uuid>]>:
    - narrate "<&c><[player].name> has not sent you a request."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  #.first = for latest tp request
  - define tp_data <player.flag[Net.Utility.TP_Requests].filter[get[from].equals[<[player].uuid>]].first>
  - define target <tern[<[tp_data].get[type].equals[here]>].pass[<player>].fail[<[player]>]>
  - define dest <tern[<[tp_data].get[type].equals[here]>].pass[<[player].location>].fail[<player.location>]>
  - teleport <[target]> <[dest]>
  - flag <player> Net.Utility.TP_Requests:<-:<[tp_data]>
  - narrate "<proc[net_symbol]> <&a>Request accepted."
  - narrate "<proc[net_symbol]> <&a><player.name> accepted your teleport request." targets:<[player]>

net_tpdeny:
  type: command
  name: tpdeny
  debug: false
  description: Deny teleport requests.
  permission: Net.Utility.TPA
  usage: /tpdeny (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /tpdeny (player)"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<player.has_flag[Net.Utility.TP_Requests]> || !<player.flag[Net.Utility.TP_Requests].parse[get[from]].contains[<[player].uuid>]>:
    - narrate "<&c><[player].name> has not sent you a request."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  #.first = for latest tp request
  - define tp_data <player.flag[Net.Utility.TP_Requests].filter[get[from].equals[<[player].uuid>]].first>
  - define target <tern[<[tp_data].get[type].equals[here]>].pass[<player>].fail[<[player]>]>
  - define dest <tern[<[tp_data].get[type].equals[here]>].pass[<[player].location>].fail[<player.location>]>
  - flag <player> Net.Utility.TP_Requests:<-:<[tp_data]>
  - narrate "<proc[net_symbol]> <&c>Request denied."
  - narrate "<proc[net_symbol]> <&c><player.name> denied your request." targets:<[player]>

net_teleportall:
  type: command
  name: teleportall
  debug: false
  description: Teleport everyone to a you
  permission: Net.Utility.TeleportAll
  usage: /teleportall (player)
  aliases:
  - tpall
  tab complete:
  - if !<player.has_permission[Net.Utility.TeleportAll]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<proc[net_symbol]> <&a>Teleporting all players to you..."
    - teleport <server.online_players> <player.location>
    - stop
  - if <context.args.size> != 1:
     - narrate "<&c>Incorrect command usage! Type /teleportall (player)"
     - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if !<[player].is_online>:
    - narrate "<&c>Player offline."
    - stop
  - narrate "<proc[net_symbol]> <&a>Teleporting all players to <[player].name>..."
  - teleport <server.online_players> <[player].location>

net_repair:
  type: command
  name: repair
  debug: false
  description: Repair the item in-hand
  permission: Net.Utility.Repair
  usage: /repair
  script:
  - if !<player.item_in_hand.repairable>:
    - narrate "<&c>Item not repairable!"
    - stop
  - inventory adjust slot:<player.held_item_slot> durability:0
      #.material.name?
  - narrate "<proc[net_symbol]> <element[Repaired].color[<color[180,180,180]>]> <&a><player.item_in_hand.material.name.replace[_].with[<&sp>].to_titlecase>"

net_clear:
  type: command
  name: clear
  debug: false
  description: Clear player inventories
  permission: Net.Utility.Clear
  usage: /clear (player)
  tab complete:
  - if !<player.has_permission[Net.Utility.Clear]||<context.server>>:
    - stop
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - inventory clear d:<player.inventory>
    - narrate "<proc[net_symbol]> <element[Inventory cleared.].color[<color[180,180,180]>]>"
    - stop
  - define player <server.match_offline_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - inventory clear d:<[player].inventory>
  - narrate "<proc[net_symbol]> <&a><[player].name>'s <element[inventory cleared.].color[<color[180,180,180]>]>"
  - narrate "<proc[net_symbol]> <element[Inventory cleared.].color[<color[180,180,180]>]>" targets:<[player]>

net_statistics:
  type: command
  name: statistics
  debug: false
  description: View server information
  permission: Net.Utility.Statistics
  usage: /statistics
  aliases:
  - stats
  tab complete:
  - if !<player.has_permission[Net.Utility.Statistics]||<context.server>>:
    - stop
  script:
  - define name "<&r><&l><element[S].color[<color[0,180,255]>]><&b><&l>erver <element[S].color[<color[0,180,255]>]><&b><&l>tats<&r>"
  - define bungee_server <bungee.server||null>
  - define server "<tern[<[bungee_server].equals[null]>].pass[<element[Server].color_gradient[from=#D3D3D3;to=#8c8c8c]> <&f>- <&c>N/A].fail[<element[Server].color_gradient[from=#D3D3D3;to=#8c8c8c]> <&f>- <&a><bungee.server>]>"
  - define versions "<element[<&7><&l>[<&e><&l>Versions<&7><&l>]].on_hover[<element[Denizen:].color[<color[255,227,87]>]> <server.denizen_version><&nl><element[Paper:].color[<color[255,227,87]>]> <server.bukkit_version>]>"
  - define plugins "<element[<&7><&l>[<&a><&l>Plugins <&f>(<server.plugins.size>)<&7><&l>]].on_hover[<&a><server.plugins.parse[name].separated_by[<&f>, <&a>].split_lines[50]>]>"
  - define worlds "<element[<&7><&l>[<&l><element[Worlds].color[<color[20,169,255]>]> <&f>(<server.worlds.size>)<&7><&l>]].on_hover[<server.worlds.parse_tag[<element[<[parse_value].name>].color[<color[20,169,255]>]>].separated_by[, ].split_lines[100]>]>"
  - define ram "<element[<&7><&l>[<element[RAM].color[#74d463]><&7><&l>]].on_hover[<&7>Free Ram: <&a><server.ram_free.mul[0.000000001].round_to[2].format_number><&8>GB <&nl><&e><server.ram_usage.mul[0.000000001].round_to[2].format_number><&8>GB <&7>/ <&a><server.ram_max.mul[0.000000001].round_to[2].format_number><&8>GB]>"
  - define tps "<element[TPS:].color[<color[255,227,87]>]> <&a><server.recent_tps.parse[round_to[2]].separated_by[<&7>,<&a> ]>"
  - define uptime "<element[Uptime].color_gradient[from=#D3D3D3;to=#8c8c8c]> <&f>- <&a><server.delta_time_since_start.formatted>"
  - define joins "<element[Unique players].color_gradient[from=#D3D3D3;to=#8c8c8c]> <&f>- <&a><server.players.size.format_number>"
  - narrate <&8><&l>|<&m>---------<[name]><&8><&l><&m>---------<&l>|
  - narrate <&sp.repeat[17]><[uptime]>
  - narrate "<&sp.repeat[5]><[server]>   <[joins]><&nl>"
  - narrate "<&sp.repeat[4]><element[Performance].color_gradient[from=#D3D3D3;to=#8c8c8c]> <&f>- <[tps]> <[ram]><&nl>"
  - narrate "<[versions]> <[plugins]> <[worlds]>"
  - narrate <&8><&l>|<&m>-----------------------------<&l>|

net_restart:
  type: command
  name: restart
  debug: false
  description: Restart the server
  permission: Net.Utility.Restart
  usage: /restart (seconds)
  tab complete:
  - if !<player.has_permission[Net.Utility.Restart]||<context.server>>:
    - stop
  script:
  - define time <context.args.first||10>
  - if !<[time].is_integer> || <[time]> <= 0:
    - narrate "<&c>Incorrect command usage! Invalid number."
    - stop
  - if <server.has_flag[Net.Utility.Restarting]>:
    - flag server Net.Utility.Restarting:!
    - narrate "<proc[net_symbol]> <element[Cancelled server restart.].color[<color[180,180,180]>]>"
    - stop
  - define time <[time]>
  - narrate "<proc[net_symbol]> <element[Restarting server in].color[<color[180,180,180]>]> <&a><[time].as_duration.formatted><element[.].color[<color[180,180,180]>]> <element[Retype to cancel.].color[<color[255,227,87]>]>"
  - flag server Net.Utility.Restarting duration:<[time].as_duration>
  - bossbar create net_restart "title:<&e><&l>SERVER RESTART IN <&c><&l><[time].as_duration.formatted>" progress:1 players:<server.online_players> color:red
  - repeat <[time]>:
    - if !<server.has_flag[Net.Utility.Restarting]>:
      - bossbar update net_restart title:<&e><&l>CANCELLED! players:<server.online_players> color:green
      - wait 1s
      - bossbar remove net_restart
      - flag server Net.Utility.Restarting:!
      - stop
    - bossbar update net_restart "title:<&e><&l>SERVER RESTART IN <&c><&l><[time].add[1].sub[<[Value]>].as_duration.formatted>" progress:<[time].add[1].sub[<[Value]>].div[<[time]>]> players:<server.online_players> color:red
    - wait 1s
  - bossbar update net_restart title:<&c><&l>RESTARTING... progress:0 players:<server.online_players> color:red
  - wait 1s
  - flag server Net.Utility.Restarting:!
  - bossbar remove net_restart
  - wait 5t
  - adjust server restart

net_ping:
  type: command
  name: ping
  debug: false
  description: View a player's ping
  permission: Net.Utility.Ping
  usage: /ping (player)
  tab complete:
  - inject net_tasks path:tab
  script:
  - if <context.args.is_empty>:
    - narrate "<proc[net_symbol]> <element[Your ping:].color[<color[180,180,180]>]> <&a><player.ping> <element[ms].color[<color[180,180,180]>]>"
    - stop
  - define player <server.match_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - narrate "<proc[net_symbol]> <element[<[player].name>'s ping:].color[<color[180,180,180]>]> <&a><player.ping> <element[ms].color[<color[180,180,180]>]>"
      #should i say "doesn't exist" or "is invalid"? because exist means "exist on the server"

net_reloadall:
  debug: false
  type: command
  name: reloadall
  description: Reload Denizen on all servers.
  usage: /reloadall
  tab complete:
  - if !<player.has_permission[Net.Utility.ServerStats]||<context.server>>:
    - stop
  permission: Net.Utility.ReloadAll
  script:
  - bungeerun <bungee.list_servers.exclude[<bungee.server>]> bungee_reloadall
  - reload
  - narrate "<proc[net_symbol]> <element[Reloaded dScripts on all servers.].color[<color[180,180,180]>]>"
  - bungeerun backup bungee_discord_reload

bungee_reloadall:
  type: task
  debug: false
  script:
  - reload

net_blank:
  debug: false
  type: command
  name: blank
  description: Clear (own) chat
  usage: /blank
  aliases:
  - bl
  tab complete:
  - if !<player.has_permission[Net.Utility.ServerStats]||<context.server>>:
    - stop
  permission: Net.Utility.Blank
  script:
  - repeat 20:
    - narrate <&n>

net_zoom:
  debug: false
  type: command
  name: zoom
  description: See much farther distances.
  usage: /zoom
  permission: Net.Utility.Zoom
  aliases:
  - z
  script:
  - if <context.args.is_empty>:
    - if <player.has_flag[Net.Utility.Zoom]>:
      - adjust <player> fov_multiplier
      - actionbar <&r>
      - flag player Net.Utility.Zoom:!
      - stop
    - flag player Net.Utility.Zoom:Default
    - adjust <player> fov_multiplier:-0.5
    - while <player.has_flag[Net.Utility.Zoom]>:
      - actionbar '<&e><&l>Zoom<&f><&l>: <&a><&l>50<&pc> <&7>/z to toggle'
      - wait 1s
    - stop
  - define input <context.args.first>
  - if !<[input].is_decimal> || <[input]> < 1 && <[input]> > 100:
    - narrate "<&c>Incorrect command usage! Number has to range from 1 to 100."
    - stop
  - define input <[input].round>
  - define mult <tern[<[input].is[or_less].than[50]>].pass[<element[0.018].mul[<context.args.first>].add[0.1]>].fail[<element[-1].add[<element[0.018].mul[<context.args.first.sub[50]>]>]>]>
  - flag player Net.Utility.Zoom:<[input]>
  - adjust <player> fov_multiplier:<[mult]>
  - while <player.has_flag[Net.Utility.Zoom]>:
    - actionbar '<&e><&l>Zoom<&f><&l>: <&a><&l><player.flag[Net.Utility.Zoom]><&pc> <&7>/z to toggle'
    - wait 1s

net_nightvision:
  debug: false
  type: command
  name: nightvision
  description: See in the dark
  permission: Net.Utility.NightVision
  usage: /nightvision (player)
  tab complete:
  - if !<player.has_permission[Net.Utility.NightVision]||<context.server>>:
    - stop
  - else:
    - inject net_tasks path:tab
  aliases:
  - nv
  script:
  - if <context.args.is_empty>:
    - if <player.has_flag[net.utility.using_nightvision]>:
      - cast night_vision remove <player>
      - flag player net.utility.using_nightvision:!
      - narrate "<proc[net_symbol]> <element[Night Vision:].color[<color[180,180,180]>]> <&c>Disabled"
      - stop
    - cast night_vision duration:0 no_ambient hide_particles no_icon no_clear
    - flag player net.utility.using_nightvision
    - narrate "<proc[net_symbol]> <element[Night Vision:].color[<color[180,180,180]>]> <&a>Enabled"
    - stop
  - define player <server.match_player[<context.args.first>]||null>
  - if <[player]> == null:
    - narrate "<&c>Invalid player."
    - stop
  - if <[player].has_flag[net.utility.using_nightvision]>:
    - adjust <[player]> remove_effects
    - flag <[player]> net.utility.using_nightvision:!
    - narrate "<proc[net_symbol]> <element[<[player].name>'s Night Vision:].color[<color[180,180,180]>]> <&c>Disabled"
    - narrate "<proc[net_symbol]> <element[Night Vision:].color[<color[180,180,180]>]> <&c>Disabled" targets:<[player]>
    - stop
  - cast night_vision <[player]> duration:0 no_ambient hide_particles no_icon no_clear
  - flag <[player]> net.utility.using_nightvision
  - narrate "<proc[net_symbol]> <element[<[player].name>'s Night Vision:].color[<color[180,180,180]>]> <&a>Enabled"
  - narrate "<proc[net_symbol]> <element[Night Vision:].color[<color[180,180,180]>]> <&a>Enabled" targets:<[player]>

net_hologram:
  type: command
  name: hologram
  debug: false
  description: Create a holograms
  permission: Net.Utility.hologram
  usage: /hologram (text/addline/remove)
  aliases:
  - holo
  script:
  #- define loc <player.location.below.center>
  #- spawn "ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=<&b><&l>[Backup Server];custom_name_visibility=true]" <[loc]> save:holo1
  #- flag server Net.Holograms:->:<entry[holo1].spawned_entity>
  #- spawn "ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=This is <&a>Nimsy<&r>'s old server lobby!;custom_name_visibility=true]" <[loc].below[0.3]> save:holo2
  #- flag server Net.Holograms:->:<entry[holo2].spawned_entity>
  #- spawn "ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=It's a <&n>backup server <&r>in case;custom_name_visibility=true]" <[loc].below[0.6]> save:holo3
  #- flag server Net.Holograms:->:<entry[holo3].spawned_entity>
  #- spawn "ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=any thing goes wrong.;custom_name_visibility=true]" <[loc].below[0.9]> save:holo4
  #- flag server Net.Holograms:->:<entry[holo4].spawned_entity>
  #- spawn "ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=<&e>You will be redirected shortly.;custom_name_visibility=true]" <[loc].below[1.2]> save:holo5
  #- flag server Net.Holograms:->:<entry[holo5].spawned_entity>
  #- stop
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage!<&nl>Type /hologram (text/addline/remove)"
    - stop
  - define target <player.target||null>
  - if <context.args.size> == 1 && <context.args.first> == remove:
    - if <[target]> == null || !<server.has_flag[Net.Holograms]> || !<server.flag[Net.Holograms].contains[<[target]>]>:
      - narrate "<&c>Not looking at a hologram!"
      - stop
    - flag server Net.Holograms:<-:<[target]>
    - remove <[target]>
    - narrate "<proc[net_symbol]> <&a>Removed hologram."
    - stop
  - define loc <player.location.below.center>
  - if <context.args.first> == addline:
    - if <[target]> == null || !<server.has_flag[Net.Holograms]> || !<server.flag[Net.Holograms].contains[<[target]>]>:
      - narrate "<&c>Not looking at a hologram!"
      - stop
    - define text <context.args.exclude[addline].space_separated.parse_color>
    - define loc <player.target.location.below[0.3]>
  - else:
    - define text <context.raw_args.parse_color>
  - spawn ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false;custom_name=<[text]>;custom_name_visibility=true] <[loc]> save:holo
  - flag server Net.Holograms:->:<entry[holo].spawned_entity>
  - narrate "<proc[net_symbol]> <element[Hologram Set:].color[<color[180,180,180]>]> <[text]>"

net_rename:
  debug: false
  type: command
  name: rename
  description: Change the name of the item in hand
  permission: Net.Utility.Rename
  usage: /rename
  tab complete:
  - if !<player.has_permission[Net.Utility.Rename]||<context.server>>:
    - stop
  script:
  - if <context.args.is_empty>:
    - narrate "<&c>Incorrect command usage! Type /rename (name)"
    - stop
  - if <player.item_in_hand.material.name> == air:
    - narrate "<&c>Have an item in your hand."
    - stop
  - define name <context.raw_args.parse_color>
  - inventory adjust slot:<player.held_item_slot> display_name:<[name]>
  - narrate "<proc[net_symbol]> <element[Renamed].color[<color[180,180,180]>]> <&c><player.item_in_hand.material.name.replace[_].with[<&sp>].to_titlecase> <element[→].color[<color[180,180,180]>]> <&a><[name]>"

net_sethome:
  type: command
  name: sethome
  debug: false
  description: Set your home
  permission: Net.Utility.Home
  usage: /sethome
  script:
  #don't let players set their home in spawn area?
  - flag player Net.Utility.Home:<player.location>
  - narrate "<proc[net_symbol]> <&a>Home set <element[(<player.location.simple>)].color[<color[180,180,180]>]>"

net_home:
  type: command
  name: home
  debug: false
  description: Teleport to your home
  permission: Net.Utility.Home
  usage: /home
  script:
  - if !<player.has_flag[Net.Utility.Home]>:
    - narrate "<&c>No home set."
    - stop
  - narrate "<proc[net_symbol]> <&a>Teleporting home..."
  - inject fade_effect
  - teleport <player> <player.flag[Net.Utility.Home]>

net_time:
  type: command
  name: time
  debug: false
  description: Set the time of day
  permission: Net.Utility.Time
  usage: /time (day,midnight,night,noon/ticks)
  tab complete:
  - if !<player.has_permission[Net.Utility.Time]||<context.server>>:
    - stop
  - else:
    - if <context.args.is_empty>:
      - determine <list[day|midnight|night|noon]>
    - else if <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]>:
      - determine <list[day|midnight|night|noon].filter[starts_with[<context.args.last>]]>
  script:
  - if <context.args.is_empty> || !<context.args.first.is_integer> && !<list[day|noon|night|midnight].contains[<context.args.first>]>:
    - narrate "<&c>Incorrect command usage!<&nl>Type /time (day,midnight,night,noon/ticks)"
    - stop
  - define arg <context.args.first||null>
  - if <[arg].is_integer>:
    - adjust <player.world> time:<[arg]>
    - narrate "<proc[net_symbol]> <&a><element[Time set:].color[<color[180,180,180]>]> <&a><[arg].format_number>"
    - stop
  - adjust <player.world> time:<map[Day=1000;Noon=6000;Night=13000;Midnight=18000].get[<[arg]>]>
  - narrate "<proc[net_symbol]> <&a><element[Time set:].color[<color[180,180,180]>]> <&a><[arg].to_titlecase>"

net_gamerule:
  type: command
  name: gamerule
  debug: false
  description: Set the gamerule
  permission: Net.Utility.Gamerule
  usage: /gamerule (rule) (value)
  aliases:
  - gr
  tab complete:
  - if !<player.has_permission[Net.Utility.Gamerule]||<context.server>>:
    - stop
  - if <context.args.is_empty>:
    - determine passively <server.gamerules>
    - stop
  - if <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]>:
    - determine <server.gamerules.filter[starts_with[<context.args.last>]]>
  script:
  - if <context.args.size> != 2:
    - narrate "<&c>Incorrect command usage! Type /gamerule (gamerule) (value)"
    - stop
  - if !<server.gamerules.contains_case_sensitive[<context.args.first>]>:
    - narrate "<&c>Invalid gamerule."
    - stop
  - define gamerule <context.args.first>
  - define input <context.args.get[2]>
  - define world <player.world>
  - define int_inputs <server.gamerules.filter_tag[<[world].gamerule[<[filter_value]>].is_integer>]>
  - if <[int_inputs].contains[<[gamerule]>]>:
    - if !<[int_inputs].contains_case_sensitive[<[gamerule]>]>:
      - narrate "<&c>Incorrect command usage! Gamerules are case-sensitive."
      - stop
    - if !<[input].is_integer>:
      - narrate "<&c>Invalid number."
      - stop
  #denizen is fucking broken here
  - wait 1t
  - else if !<list[true|false].contains[<[input]>]>:
    - narrate "<&c>Input is not 'true' or 'false'."
    - stop
  - gamerule <[world]> <[gamerule]> <[input]>
  - narrate "<proc[net_symbol]> <&a><element[<[gamerule]> set:].color[<color[180,180,180]>]> <&a><tern[<[input].is_integer>].pass[<[input].format_number>].fail[<[input].to_titlecase>]>"

net_gamerules:
  type: command
  name: gamerules
  debug: false
  description: View the available gamerules.
  permission: Net.Utility.Gamerule
  usage: /gamerules
  aliases:
  - grs
  tab complete:
  - if !<player.has_permission[Net.Utility.Gamerule]||<context.server>>:
    - stop
  script:
  #- define gamerules <script[gamerule_data].data_key[gamerules].alphabetical.sub_lists[7]>
  - define gamerules <server.gamerules.alphabetical.sub_lists[7]>
  - define page <context.args.first||1>
  - define total_pages <[gamerules].size>
  - define world <player.world>
  - define color <color[0,180,255]>
  - if !<[page].is_integer> || <[page]> <= 0:
    - define page 1
  - if <[page]> > <[total_pages]>:
    - define page <[total_pages]>
  - define gamerules <[gamerules].get[<[page]>]>
  - narrate "<&8><&l>-------------| <&8><&l><element[G].color[#ffc800]><&6><&l>amerules <&8><&l>|-------------"
  - foreach <[gamerules]> as:rule:
    - define value <[world].gamerule[<[rule]>]>
    - if <[value].is_integer>:
      - define input "<[value].color[<[color]>].on_hover[<&e>Set gamerule<&nl><&7>/gr <[rule]> (number)].on_click[/gr <[rule]> ].type[SUGGEST_COMMAND]>"
    - else:
      - define true "<element[true].color[<tern[<[value]>].pass[<[color]>].fail[<color[222,222,222]>]>].on_hover[<&e>Set gamerule<&nl><&7>/gr <[rule]> true].on_click[/gr <[rule]> true].type[RUN_COMMAND]>"
      - define false "<element[false].color[<tern[<[value]>].pass[<color[222,222,222]>].fail[<[color]>]>].on_hover[<&e>Set gamerule<&nl><&7>/gr <[rule]> false].on_click[/gr <[rule]> false].type[RUN_COMMAND]>"
      - define input "<[true]> <[false]>"
    - narrate "<&c>• <&6><[rule].color_gradient[from=#ffc400;to=#ffaa00]> <[input]>"
  - narrate "<&8><&l>--<tern[<[page].sub[1].equals[0]>].pass[--------].fail[ <&r><element[<&l><element[«].color[#ffaa00]> <&7>Page <[page].sub[1]>].on_hover[<&e>Click for previous page.].on_click[/gamerules <[page].sub[1]>]><&8><&l> ]>---- <&c>Page <[page]><&7>/<&c><[total_pages]><&8><&l> -----<tern[<[total_pages].equals[<[page]>]>].pass[-------].fail[ <&7><element[Page <[page].add[1]> <&l><element[»].color[<color[#ffaa00]>]>].on_hover[<&e>Click for next page.].on_click[/gamerules <[page].add[1]>]><&8><&l> ]>--"

gamerule_data:
  type: data
  gamerules:
  #Bools
  - announceAdvancements
  - commandBlockOutput
  - disableElytraMovementCheck
  - disableRaids
  - doDaylightCycle
  - doEntityDrops
  - doFireTick
  - doImmediateRespawn
  - doInsomnia
  - doLimitedCrafting
  - doMobLoot
  - doMobSpawning
  - doPatrolSpawning
  - doTileDrops
  - doTraderSpawning
  - doWeatherCycle
  - drowningDamage
  - fallDamage
  - fireDamage
  - keepInventory
  - logAdminCommands
  - mobGriefing
  - naturalRegeneration
  - reducedDebugInfo
  - spectatorsGenerateChunks
  - showDeathMessages
  - sendCommandFeedBack
  #Values
  - maxCommandChainLength
  - maxEntityCramming
  - randomTickSpeed
  - spawnRadius

net_hub:
  type: command
  debug: false
  name: Hub
  description: Return to the hub server.
  usage: /hub
  permission: Net.Utility.Hub
  aliases:
  - lobby
  script:
  - if <bungee.server> == hub:
    - if !<server.has_flag[net.hub_location]>:
      - narrate "<&c>Hub isn't setup."
      - stop
    - inject fade_effect
    - teleport <player> <server.flag[net.hub_location]>
  - else:
    - inject fade_effect
    - adjust <player> send_to:hub
  #transporting or sending?
  - narrate "<proc[net_symbol]> <element[Transporting to hub...].color[<color[180,180,180]>]>"

zoom_leave:
  type: world
  debug: false
  events:
    on player quits flagged:zoom:
    - flag player zoom:!

net_update:
  type: command
  name: update
  debug: false
  description: Get update links.
  permission: Net.Utility.Update
  usage: /update
  #aliases:
  #- grs
  tab complete:
  - if !<player.has_permission[Net.Utility.Gamerule]||<context.server>>:
    - stop
  script:
  - define dev "<element[<&7><&l>[<&e><&l>Dev<&7><&l>]].on_hover[<&e>Open link!<&nl><&7>Latest <&o>developmental<&nl><&7>version of <element[Denizen].color[<color[255,227,87]>]><&7>.].on_click[https://ci.citizensnpcs.co/job/Denizen_Developmental/].type[open_url]>"
  - define stable "<element[<&7><&l><&lb><&l><element[Stable].color[<color[#fad052]>]><&7><&l><&rb>].on_hover[<&e>Open link!<&nl><&7>Latest <&o>stable<&nl><&7>version of <element[Denizen].color[<color[255,227,87]>]><&7>.].on_click[https://ci.citizensnpcs.co/job/Denizen/].type[open_url]>"
  - define paper "<element[<&7><&l>[<&f><&l>Paper<&7><&l>]].on_hover[<&e>Open link!<&nl><&7>Latest version of <&f>Paper<&7>.].on_click[https://papermc.io/downloads].type[open_url]>"
  - narrate "<proc[net_symbol]> <element[Update Links:].color[<color[180,180,180]>]> <[dev]> <[stable]> <[paper]>"

net_worldteleport:
  type: command
  name: worldteleport
  debug: false
  description: Teleport to different worlds
  permission: Net.Utility.WorldTeleport
  usage: /worldteleport (world)
  aliases:
  - wtp
  - worldtp
  tab complete:
  - if !<player.has_permission[Net.Utility.WorldTeleport]||<context.server>>:
    - stop
  - else:
    - if <context.args.is_empty>:
      - determine <server.worlds.parse[name]>
    - else if <context.args.size||0> == 1 && !<context.raw_args.ends_with[<&sp>]>:
      - determine <server.worlds.parse[name].filter[starts_with[<context.args.last>]]>
  script:
  - if <context.args.size> != 1:
    - narrate "<&c>Incorrect command usage! Type /worldteleport (world)"
    - stop
  - define world <context.args.first.as_world>
  - if !<server.worlds.contains[<[world]>]>:
    - narrate "<&c>Invalid world."
    - stop
  - narrate "<proc[net_symbol]> <element[Teleporting to].color[<color[180,180,180]>]> <&a><[world].name><element[...].color[<color[180,180,180]>]>"
  - teleport <player> <[world].spawn_location>

net_commands_handler:
  debug: false
  type: world
  events:
    on LP command:
    - if <player.is_op>:
       - stop
    - determine passively cancelled
    - narrate "Unknown command. Type <&dq>/help<&dq> for help."
    on command:
    - if <context.source_type> == PLAYER:
      - if <bungee.server||null> == hub && !<server.has_flag[resourcepack_loaded.<player.uuid>]>:
        - stop
      - narrate "<proc[net_symbol]> <element[<player.name>:].color[<color[180,180,180]>]> <&8>/<&e><context.command> <&b><context.raw_args>" targets:<server.online_players_flagged[Net.Moderation.Spy_Mode].exclude[<player>]>
      - if <player.is_op>:
        - stop
      - if <script[tab_data].data_key[blacklist].contains[<context.command>]>:
        - narrate <&c><script[net_config].data_key[error_msg]>
        - determine fulfilled
    on player receives commands:
    - if <player.is_op>:
       - stop
    - define command_scripts <server.scripts.filter[container_type.equals[command]].filter[name.before[_].is[==].to[net]]>
    - define commands <[command_scripts].parse[after[_]]>
    - foreach <[command_scripts].filter[data_key[aliases].equals[null].not]> as:cmd:
      - foreach <[cmd].data_key[aliases]> as:a:
        - define aliases:->:<[a]>
    - determine <[commands].include[<[aliases]>].alphabetical>
    #- determine <server.scripts.filter[container_type.equals[command]].filter[name.before[_].is[==].to[net]].parse[after[_]].alphabetical>

tab_data:
  type: data
  blacklist:
    - pl
    - plugins
    - ver
    - version
    - about
    - tps
    - icanhasbukkit
    - bukkit
    - bukkit
    - bukkit:?
    - bukkit:about
    - bukkit:help
    - bukkit:plugins
    - bukkit:pl
    - bukkit:ver
    - bukkit:version

chatdata:
  type: data
  adfilter:
    - .net
    - .org
    - .com
    - .gg
    - .co
    - .gov
    - .xyz
    - .gov
    - .biz
    - .int
    - .edu
    - .mil
    - .at
    - .az
    - .bb
    - .de
    - .me
    - .us
  swearfilter:
  #swear words
    - fuck
    - horny
    - aroused
    - hentai
    - slut
    - slag
    - boob
    - pussy
    - vagina
    - faggot
    - bugger
    - bastard
    - cunt
    - nigga
    - nigger
    - jerk
    - anal
    - wanker
    - tosser
    - shit
    - rape
    - rapist
    - dick
    - cock
    - whore
    - bitch
    - asshole
    - ass
    - twat
    - titt
    - piss
    - intercourse
    - sperm
    - spunk
    - testicle
    - milf
    - retard
    - anus
