# @ ██ [ Do not change anything here unless you know what you are doing ] ██
nbar_task:
  type: task
  debug: false
  definitions: destination|left_text
  script:
    - if !<server.has_flag[nbar.cached]>:
      - run cache_nbar

    - define left_text_width_padding_size <element[116].sub[<[left_text].text_width>]>
    - define left_text <proc[positive_spacing].context[<[left_text_width_padding_size].div[2].round_down>].font[spacing].if_null[<empty>]><[left_text]><proc[positive_spacing].context[<[left_text_width_padding_size].div[2].round_up>].font[spacing].if_null[<empty>]>

    - define uuid <player.uuid>
    - define lpad <server.flag[nbar.left_padding]>
    - define rpad <server.flag[nbar.right_padding]>

    - bossbar id:nbar_<[uuid]>_top create title:<server.flag[nbar.top_bar]>
    - bossbar id:nbar_<[uuid]>_bottom create title:<empty>

    - flag <player> nbarvigating
    - while <player.has_flag[nbarvigating]> && <player.is_online>:
      - define ploc <player.location>
      - define angle <[ploc].face[<[destination]>].yaw.sub[<[ploc].yaw>].round_to_precision[15].mod[359]>
      - define angle <[angle].add[360]> if:<[angle].is_less_than[0]>
      - define direction <server.flag[nbar.direction.<[angle]>]>
      - bossbar id:nbar_<[uuid]>_bottom update title:<[lpad]><[left_text]><[direction]><[rpad]>
      - wait 2t

    - flag <player> nbarvigating:! if:<player.has_flag[nbarvigating]>
    - wait 2s
    - bossbar id:nbar_<[uuid]>_top remove
    - bossbar id:nbar_<[uuid]>_bottom remove

cache_nbar:
  type: task
  debug: false
  script:
    - flag server nbar.top_bar:<&chr[e820]><proc[negative_spacing].context[2].font[spacing]><&chr[e821]>
    - flag server nbar.left_padding:<proc[negative_spacing].context[143].font[spacing]>
    - flag server nbar.right_padding:<proc[negative_spacing].context[142].font[spacing]>

    - define loc <server.worlds.first.spawn_location>
    - repeat 24 from:0 as:angle:
      - define angle <[angle].mul[15]>
      - define loc <[loc].with_yaw[<[angle]>]>
      - define right_text "<&a><[loc].direction> <&2>/ <&a><[angle]><&2>°<proc[positive_spacing].context[2].font[spacing]>"
      - define right_text_width_padding <element[116].sub[<[right_text].text_width>]>
      - define right_text <proc[positive_spacing].context[<[right_text_width_padding].div[2].round_up>].font[spacing].if_null[<empty>]><[right_text]><proc[positive_spacing].context[<[right_text_width_padding].div[2].round_down>].font[spacing].if_null[<empty>]>

      - define arrow <proc[positive_spacing].context[10].font[spacing]><&f><&chr[e<[angle].div[15].add[832].round>]><proc[positive_spacing].context[11].font[spacing]>
      - flag server nbar.direction.<[angle]>:<[arrow]><[right_text]>

    - flag server nbar.cached