minimap:
  type: task
  debug: false
  script:
  - if <player.has_flag[fort.minimap]>:
    - flag player fort.minimap:!
    - stop

  - define uuid <player.uuid>

  - define bb minimap_<player.uuid>
  - bossbar create <[bb]> color:YELLOW
  - bossbar create <[bb]>_yaw color:YELLOW
  - flag player fort.minimap

  - define oldRotation <player.location.yaw.div[360].mul[1024].round>

  - define yaw_icon <&chr[20].font[icons].color[65,0,0]>

  - while <player.is_online> && <player.has_flag[fort.minimap]>:

    - define world <player.world>

    #turn loc to color
    - define loc <player.location.round>
    - define yaw <[loc].yaw>

    #-marker
    - define marker_red   <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360].mul[255]>
    #this is minimap marker
    - define marker_green 0

    - define marker_color <color[<[marker_red].round>,<[marker_green]>,0]>
    - define marker       <&chr[E000].font[map].color[<[marker_color]>]>

    #-minimap
    #sub offset
    - define x <[loc].x>
    - define z <[loc].z>

    - define top_left_x -1073
    - define top_left_z -1073

    - define r <[x].sub[<[top_left_x]>].mod[256]>
    - define g <[z].sub[<[top_left_z]>].mod[256]>

    #can't be 0
    - if <[r]> < 0:
      - define r <[r].add[256]>
    - if <[g]> < 0:
      - define g <[g].add[256]>

    - define map_x <[x].sub[<[top_left_x]>].div[256].round_down.add[1]>
    - define map_y <[z].sub[<[top_left_z]>].div[256].round_down.add[1]>

    #array of characters
    - define row_1 <list[0001|0002|0003|0004|0005|0006|0007|0008]>
    - define row_2 <list[0009|000a|000b|000c|000d|000e|000f|0010]>
    - define row_3 <list[0011|0012|0013|0014|0015|0016|0017|0018]>
    - define row_4 <list[0019|001a|001b|001c|001d|001e|001f|0020]>
    - define row_5 <list[0021|0022|0023|0024|0025|0026|0027|0028]>
    - define row_6 <list[0029|002a|002b|002c|002d|002e|002f|0030]>
    - define row_7 <list[0031|0032|0033|0034|0035|0036|0037|0038]>
    - define row_8 <list[0039|003a|003b|003c|003d|003e|003f|0040]>

    - define base_coords <list[0,0|0,1|1,0|1,1]>

    - define chars:!
    - foreach <[base_coords]> as:coords:

      - define x <[coords].before[,]>
      - define y <[coords].after[,]>

      - define x_add <[r].is[LESS].than[128].if_true[<[x].mul[-1]>].if_false[<[x]>]>
      - define y_add <[g].is[LESS].than[128].if_true[<[y].mul[-1]>].if_false[<[y]>]>

      - define final_y <[map_y].add[<[y_add]>]>
      - define final_x <[map_x].add[<[x_add]>]>

      - define oob False
      - if <[final_y]> <= 0 || <[final_y]> > 8 || <[final_x]> <= 0 || <[final_x]> > 8:
        - define oob True
        - define char 0000
      - else:
        - define char <[row_<[final_y]>].get[<[final_x]>]>

      - define chars:->:<[char]>

    - define tiles:!
    - define in_game <[world].name.equals[nimnite_map].or[<player.name.equals[asd988]>]>
    - define displayId 4
    - repeat 4:
      - define displayId <[value].sub[1]> if:<[in_game]>
      #value is display id
      - define loc_to_color <color[<[r]>,<[g]>,<[displayId]>]>
      - define ch <[chars].get[<[value]>]>

      - if <[ch]> == 0000:
        - repeat next

      - define tiles:->:<&chr[<[ch]>].font[map].color[<[loc_to_color]>]>

    - define whole_map <[tiles].unseparated>

    ## - [ COMPASS ] - ##
    # compass display
    - define curRotation     <player.location.yaw.div[360].mul[1024].round_down>
    - define gameTime        <[world].duration_since_created.in_ticks.mod[24000].mod[4]>
    - define rotation_color  <color[<[curRotation].mod[256]>,<[oldRotation].mod[256]>,<[curRotation].div[256].round_down.add[<[oldRotation].div[256].round_down.mul[4]>].add[<[gameTime].mul[16]>]>]>
    - define oldRotation     <[curRotation]>
    - define compass_display <&chr[B000].font[map].color[<[rotation_color]>]>

    ## - [ CIRCLE (if it exists) ] - ##
    # circle display
    #getting the NEW one, since the white circle is showing where the storm will be NEXT
    - define next_storm_diameter <server.flag[fort.temp.storm.new_diameter]||2304>
    - if <[next_storm_diameter]> <= 1600:
      - define next_storm_center <server.flag[fort.temp.storm.new_center]>
      #- circle x and y is in worldspace
      - define circle_x <[next_storm_center].x>
      - define circle_y <[next_storm_center].z>
      - define storm_id <map[1600=1;800=2;400=3;200=4;100=5;50=6;35=7;20=8;1=9].get[<[next_storm_diameter]>]>
      - define relX     <[circle_x].sub[<[loc].x>].add[2048].max[0].min[4095]>
      - define relZ     <[circle_y].sub[<[loc].z>].add[2048].max[0].min[4095]>
      - define r_       <[relX].mod[256]>
      - define g_       <[relZ].mod[256]>
      - define b_       <[relX].div[256].round_down.add[<[relZ].div[256].round_down.mul[16]>]>
      - define circle_offset   <[storm_id]>

      - define circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
      - define circle_display <&chr[E001].font[map].color[<[circle_color]>]>

      ## - [ PURPLE CIRCLE ] - ##
    - if <server.has_flag[fort.temp.storm.center]> && <[circle_offset].exists>:
      #only show purple circle when white circle shows
      #CURRENT storm center & diameter
      - define storm_center   <server.flag[fort.temp.storm.center]>
      - define storm_diameter <server.flag[fort.temp.storm.diameter]>

      - define circle_x <[storm_center].x>
      - define circle_y <[storm_center].z>

      - define storm_radius <[storm_diameter].div[2]>

      - define relX     <[circle_x].sub[<[loc].x>].add[2048].max[0].min[4095]>
      - define relZ     <[circle_y].sub[<[loc].z>].add[2048].max[0].min[4095]>
      - define r_       <[relX].mod[256]>
      - define g_       <[relZ].mod[256]>
      - define b_       <[relX].div[256].round_down.add[<[relZ].div[256].round_down.mul[16]>]>
      # static size
      - define purple_offset   <[storm_radius].mul[32].round_down>
      # idle animation with sin for example
      #(only play idle animation when the storm isn't moving)
      #- define purple_offset   <[storm_radius].add[<[world].duration_since_created.in_seconds.mul[1.5].sin>].mul[32].round_down> if:!<server.has_flag[fort.temp.storm.animating]>

      - define circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
      - define purple_circle_display <&chr[E003].font[map].color[<[circle_color]>]>

      - define title <[compass_display]><[whole_map]><[marker]><proc[spacing].context[<[circle_offset].add[<[purple_offset]>].sub[2].sub[<[tiles].size>]>]><[circle_display]><proc[spacing].context[<[purple_offset].sub[<[circle_offset].sub[1]>]>]><[purple_circle_display]><proc[spacing].context[-2]>
    - else:
      - define title <[compass_display]><[whole_map]><[marker]><proc[spacing].context[-2]>

    - define spacing <map[1=7;2=10;3=13].get[<[yaw].length>]>
    #or: <element[16].sub[<[yaw].length.mul[3]>]>

    # just so you know, adding characters before/and after the title does change the offset. who would've guessed /s
    - bossbar update <[bb]> title:<[title]> color:YELLOW
    - bossbar update <[bb]>_yaw title:<[yaw].color[65,0,0]><proc[spacing].context[-<[spacing]>]><[yaw_icon]><proc[spacing].context[<[spacing]>]> color:YELLOW

    - inject minimap.tab
    - wait 1t

  - flag player fort.minimap:!
  - if <server.current_bossbars.contains[<[bb]>]>:
    - bossbar remove <[bb]>
  - if <server.current_bossbars.contains[<[bb]>_yaw]>:
    - bossbar remove <[bb]>_yaw

  tab:
    # - [ Full map ] - #
    - define neg_spacing <proc[spacing].context[-1]>
    - define border_radius 4
    - define map:!

    #-shader does the map-tile handling
    - repeat 64:
      - define zeroes <element[0].repeat[<element[3].sub[<[value].length>]>]>
      - define char A<[zeroes]><[value]>
      - define map:->:<&chr[<[char]>].font[map].color[<color[1,1,<[value]>]>]>

    - define map <[map].unseparated>
    # - circle
    - define full_circle_display <empty>

    ## - [ FULL CIRCLE ] - ##
    - if <[next_storm_center].exists>:
      # circle_x and circle_y is in worldspace
      - define circle_x <[next_storm_center].x>
      - define circle_y <[next_storm_center].z>
      - define actualX <[circle_x].sub[<[top_left_x]>].div[2].round_down>
      - define actualY <[circle_y].sub[<[top_left_z]>].div[2].round_down>
      - define r_ <[actualX].mod[256]>
      - define g_ <[actualY].mod[256]>
      - define b_ <[storm_id].mul[16].add[<[actualY].div[256].round_down.mul[4]>].add[<[actualX].div[256].round_down>]>
      - define full_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
      - define full_circle_display <&chr[E002].font[map].color[<[full_circle_color]>]>

      ## - [ FULL PURPLE CIRCLE ] - ##
    - if <[storm_center].exists>:
      - define circle_x <[storm_center].x>
      - define circle_y <[storm_center].z>
      # storm_radius is in blocks
      - define sr <[storm_radius].mul[2].round_down>
      - define actualX <[circle_x].sub[<[top_left_x]>].div[2].round_down>
      - define actualY <[circle_y].sub[<[top_left_z]>].div[2].round_down>
      - define r_ <[actualX].mod[256]>
      - define g_ <[actualY].mod[256]>
      - define b_ <[sr].mod[16].mul[16].add[<[actualY].div[256].round_down.mul[4]>].add[<[actualX].div[256].round_down>]>
      - define full_purple_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
      - define full_purple_circle_display <&chr[E004].font[map].color[<[full_purple_circle_color]>]>
      - define offset <[sr].div[16].round_down>

    # - marker
    #for full map
    #uses 1 less bit to send more accurate info for position
    - define rot_data <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360].mul[64].round_down>
    #- narrate <[rot_data]>

    # 0 - 511
    - define x <[loc].x.sub[<[top_left_x]>].div[4].round_down>
    - define y <[loc].z.sub[<[top_left_z]>].div[4].round_down>
    - define full_marker_red <[rot_data].add[<[x].div[256].round_down.mul[64]>].add[<[y].div[256].round_down.mul[128]>]>
    #- define full_marker_red <[rot_data].div[8].round>
    #- narrate <[]>
    - define real_g <[x].mod[256]>
    - define real_b <[y].mod[256]>
    #null is if it's oob
    - define full_marker_color <color[<[full_marker_red]>,<[real_g]>,<[real_b]>]||null>
    - define full_marker       <[world].name.equals[nimnite_map].if_true[<&chr[E000].font[map].color[<[full_marker_color]>].if_null[<empty>]>].if_false[<empty>]>

    - define youtube_icon <&chr[13].font[icons]>
    - define twitch_icon  <&chr[14].font[icons]>
    - define twitter_icon <&chr[15].font[icons]>

    #- define socials "<[youtube_icon]> Nimsy <[twitch_icon]> FlimsyNimsy <[twitter_icon]> N1msy"

    #show storm timer info in tablist too?
    - if <[next_storm_center].exists>:
      - adjust <player> tab_list_info:<[full_marker]><[full_circle_display]><proc[spacing].context[<[offset].mul[2].sub[2]>]><[full_purple_circle_display]><n><[map]><n>
    - else:
      - adjust <player> tab_list_info:<[full_marker]><[full_circle_display]><[map]>