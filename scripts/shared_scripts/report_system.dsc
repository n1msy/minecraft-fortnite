# TODO: Make Discord-buttons work:
# Ban (Not available until ban-system)
# Kick (Not available until ban-system)
# Mute (Not available until ban-system)
# Teleport to user (In case they are online - Needs Discord-verify system)
# View recording (Data is collected for use later - Needs Discord-verify system and server to show)

ReportSystem_Data:
    type: data
    config:
        # Should we record a player's movements and interactions when they are reported?
        enable_player_recording: true
        channel_report_post: 1195963976908021821

    disabled_servers:

        - fort_lobby


ReportSystem_Events:
    type: world
    debug: false
    events:
        on server start:
        - inject ReportSystem_Connect

        on player animates ARM_SWING flagged:RecordPlayer_Recording:
        - define frame <player.flag[RecordPlayer.Point]>
        - flag player RecordPlayer.Frames.<[frame]>.Arm_Swings

ReportSystem_Connect:
    type: task
    debug: false
    script:
    - inject ReportSystem_Disconnect
    # MongoDB
    - ~mongo id:ReportSystem_MongoDB connect:<secret[report_system_uri]> database:ReportSystem collection:Reports

    # - discordmessage id:ReportSystem_Discord channel:557160153485410324 "Connected to Discord!"

ReportSystem_Disconnect:
    type: task
    debug: false
    scripT:
    # MongoDB
    - if <util.mongo_connections.contains[ReportSystem_MongoDB]>:
        - mongo id:ReportSystem_MongoDB disconnect


ReportSystem_Command:
    type: command
    debug: false
    name: report
    aliases:
    - report_player
    - reportplayer
    - report_user
    - reportuser
    usage: /report (player) (reason)
    description: Reports a player who is not following the rules
    tab completions:
        1: <server.online_players.parse[name]>
    script:
    - if <context.server>:
        - stop
    - if <player.has_flag[ReportSystem.Report_Cooldown]>:
        - narrate "<&c>You may report another player in <player.flag_expiration[ReportSystem.Report_Cooldown].from_now.formatted||0.01s>"
        - stop
    - if <context.args.is_empty>:
        - narrate "<&c>Usage: /report (player) (optional-reason)"
        - stop
    - if <context.args.size> > 1:
        - define reason <context.args.get[2].to[<context.args.size>].separated_by[<&sp>].sql_escaped>
    - define target <server.match_player[<context.args.get[1]>]||null>
    - if <[target]> == null:
        - define target <server.match_offline_player[<context.args.get[1]>]||null>
        - if <[target]> == null:
            - narrate "<&c>The player '<context.args.get[1]>' does not exists."
            - stop
        - if <context.args.get[1]> != <[target].name>:
            - narrate "<&c>The player '<context.args.get[1]>' does not exists."
            - stop
    - if <player.name> == <[target].name>:
        - narrate "<&c>You can not report self"
        - stop
    - if <player.has_flag[ReportSystem.Report_Cooldown_Target.<[target].uuid>]>:
        - narrate "<&c>You may not report the same player again for a while"
        - stop
    - if <server.has_flag[ReportSystem.Report_Cooldown_Spam]>:
        - if <server.flag[ReportSystem.Report_Cooldown_Spam]> >= 3:
            - narrate "<&c>Too many are reporting. Please wait a few seconds and try again."
            - stop
    - flag server ReportSystem.Report_Cooldown_Spam:+:1 expire:5s
    - flag player ReportSystem.Report_Cooldown expire:1m
    - flag player ReportSystem.Report_Cooldown_Target.<[target].uuid> expire:20m
    - inject ReportSystem_Create_New_Report
    - if <[finish_report]>:
        - if <[reason].exists>:
            - narrate "<&a>Sucessfully reported '<[target].name>' with reason '<[reason]>'"
        - else:
            - narrate "<&a>Sucessfully reported '<[target].name>'"
    - else:
        - narrate "<&c>Error while sending report. Please contact staff."

ReportSystem_Create_New_Report:
    type: task
    debug: false
    definitions: target|reason
    script:

    - define timestamp <util.current_time_millis>
    - definemap data:
        timestamp: <[timestamp]>
        reporter: <player.name>
        target: <[target].name>
        reason: <[reason]||None>

    - ~mongo id:ReportSystem_MongoDB insert:<[data]> save:mg
    - define mongo_id <entry[mg].inserted_id||null>

    - define chatlogs <player.chat_history_list.get[1].to[10]||<list[]>>
    - bungeerun backup discord_player_report def:<player.name>|<[target].name>|<[reason]>|<[mongo_id]>|<[chatlogs]>

    - if <[mongo_id]> == null:
        - debug error "<&c>ReportSystem: Error while reporting '<[target].name>' at timestamp '<[timestamp]>' by reporter '<player.name>' with reason: <[reason]||None>"
        - define finish_report false
    - else:
        - announce to_console format:ReportSystem_FF "<&7><player.name> has reported <[target].name> at '<[timestamp]>' for: <[reason]||None>"
        - define finish_report true
        - if <[target].is_online>:
            - if <script[ReportSystem_Data].data_key[config.enable_player_recording]> || <script[ReportSystem_Data.config].data_key[disabled_servers].contains[<bungee.server>]>:
                - run ReportSystem_Record_Task def:<[mongo_id]>|<[timestamp]> player:<[target]>

ReportSystem_FF:
    type: format
    debug: false
    format: <&8>[<&9>ReportSystem<&8>] <&r><[text]>

ReportSystem_Record_Task:
    type: task
    debug: false
    definitions: report_id|timestamp
    script:
    - if <player.has_flag[RecordPlayer_Recording]>:
        - announce to_console format:ReportSystem_FF "<&7>Tried to start a recording for '<player.name>' with report `<[report_id]>` but there is already a recording with report: <player.flag[RecordPlayer_Recording]>"
        - stop
    - announce to_console format:ReportSystem_FF "<&7>Started recording on '<player.name>' for report: <[report_id]>"
    # Record 100 frames (10 seconds)
    - define standard_frames 100
    - flag player RecordPlayer_Recording:<[report_id]> expire:1m
    - flag player RecordPlayer:!
    - flag player RecordPlayer.Total_Frames:<[standard_frames]>
    - repeat <[standard_frames]> as:frame:
        - if !<player.is_online>:
            - flag player RecordPlayer.Total_Frames:<[frame].sub[1]>
            - announce to_console format:ReportSystem_FF "<&7>Stopped recording '<[frame].sub[1]>' frames on '<player.name>' for report: <[report_id]>"
            - inject ReportSystem_Save_Recording_Task
            - stop
        - flag player RecordPlayer.Frames.<[frame]>.loc:<player.location>
        - flag player RecordPlayer.Frames.<[frame]>.sneaking:<player.is_sneaking>
        - flag player RecordPlayer.Point:<[frame]>
        - wait 2t
    - flag player RecordPlayer_Recording:!
    - announce to_console format:ReportSystem_FF "<&7>Finished recording on '<player.name>' for report: <[report_id]>"
    - inject ReportSystem_Save_Recording_Task

ReportSystem_Save_Recording_Task:
    type: task
    definitions: report_id|timestamp
    script:
    - definemap old_data:
        target: <player.name>
        timestamp: <[timestamp]>
    - definemap new_data:
        $set:
            recording:
                amount_of_frames: <player.flag[RecordPlayer.Total_Frames]>
                frames: <player.flag[RecordPlayer.Frames]>
    - ~mongo id:ReportSystem_MongoDB update:<[old_data]> new:<[new_data]> by_id:<[report_id]>

# TODO: Code dump to play-back recordings. Not finished, use for later. Wait until a server is provided.
# RecordPlayer_Play_Task:
#     type: task
#     definitions: type
#     script:
#     - narrate "<&7>Playing recording..."
#     - if !<server.has_flag[RecordPlayer.Tracks.<[type]>.first_item]>:
#         - narrate "<&7>Recording type '<[type]>' does not exists"
#         - stop
#     - create player <player.name> <player.location> save:npc
#     - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP
#     - wait 1s
#     - ~run RecordPlayer_Npc_Play_Task def:<[type]> npc:<entry[npc].created_npc>
#     - narrate "<&7>Replaying ended."
#     - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP
#     - wait 5t
#     - remove <entry[npc].created_npc>

# RecordPlayer_Npc_Play_Task:
#     type: task
#     definitions: type
#     script:
#     - if !<server.has_flag[RecordPlayer.Tracks.<[type]>]>:
#         - debug error "Missing recorded track: <[type]>"
#         - stop
#     - define start_loc <server.flag[RecordPlayer.Tracks.<[type]>.Frames.1.loc]>
#     - spawn <npc> <[start_loc]>
#     - define standard_frames <server.flag[RecordPlayer.Tracks.<[type]>.Total_Frames]>
#     - teleport <npc> <[start_loc]>
#     - equip <npc> hand:<server.flag[RecordPlayer.Tracks.<[type]>.first_item]>
#     - repeat <[standard_frames]> as:frame:
#         - define loc <server.flag[RecordPlayer.Tracks.<[type]>.Frames.<[frame]>.loc]>
#         - if <server.flag[RecordPlayer.Tracks.<[type]>.Frames.<[frame]>.sneaking]>:
#             - adjust <npc> set_sneaking:true
#         - else:
#             - adjust <npc> set_sneaking:false
#         - if <server.has_flag[RecordPlayer.Tracks.<[type]>.Frames.<[frame]>.Arm_Swings]>:
#             - animate <npc> animation:ARM_SWING
#         - if <server.has_flag[RecordPlayer.Tracks.<[type]>.Frames.<[frame]>.Held_Item]>:
#             - equip <npc> hand:<server.flag[RecordPlayer.Tracks.<[type]>.Frames.<[frame]>.Held_Item]>
#         - teleport <npc> <[loc]>
#         - pose add id:MyPose <[loc]>
#         - pose assume id:MyPose
#         - pose remove id:MyPose
#         - wait 2t
#     - equip <npc> hand:air boots:air chest:air head:air legs:air
#     - despawn <npc>

