#TODO: make all the storm data unvirsally update instead of per player for more efficiency

minimap:
  type: task
  debug: false
  script:
      - if <player.has_flag[fort.minimap]>:
        - flag player fort.minimap:!
        - stop


      - flag player fort.minimap


      - define uuid <player.uuid>

      # - [ Yaw Data ] - #
      - define yaw_icon <&chr[20].font[icons].color[65,0,0]>
      - define oldRotation <player.location.yaw.div[360].mul[1024].round>
      #spacing to center yaw text in bossbar
      - define yaw_spacing_data <map[1=7;2=10;3=13]>

      # - [ Minimap Data ] - #
      - define top_left_x -1073
      - define top_left_z -1073

      #so it doesnt clog up
      - inject minimap.get_map_definitions
      - define storm_id_data <map[1600=1;800=2;400=3;200=4;100=5;50=6;35=7;20=8;1=9]>

      # - [ Create Minimap/Compass Bossbars ] - #
      - define bb minimap_<[uuid]>
      - bossbar create <[bb]> color:YELLOW
      - bossbar create <[bb]>_yaw color:YELLOW


      - while <player.is_online> && <player.has_flag[fort.minimap]>:

        #either nimnite_map or pregame island
        - define world <player.world>

        #turn loc to color
        - define loc <player.location.round>
        - define yaw <[loc].yaw>
        - define yaw_data <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360]>

        ## - [ UPDATE YAW COMPASS ] - ##
        - if <[loop_index].mod[4]> == 0:
          - inject minimap.update_yaw_compass

        ## - [ UPDATE MINIMAP ] - ##
        - if <[loop_index].mod[7]> == 0:
          - inject minimap.update_minimap

        - wait 1t

      - flag player fort.minimap:!
      - if <server.current_bossbars.contains[<[bb]>]>:
        - bossbar remove <[bb]>
      - if <server.current_bossbars.contains[<[bb]>_yaw]>:
        - bossbar remove <[bb]>_yaw

  update_yaw_compass:

        #minimap MARKER
        #minimap marker green is 0
        - define marker       <&chr[E000].font[map].color[<color[<[yaw_data].mul[255].round>,0,0]>]>

        - define curRotation     <[yaw].div[360].mul[1024].round_down>
        - define gameTime        <[world].duration_since_created.in_ticks.mod[24000].mod[4]>
        - define rotation_color  <color[<[curRotation].mod[256]>,<[oldRotation].mod[256]>,<[curRotation].div[256].round_down.add[<[oldRotation].div[256].round_down.mul[4]>].add[<[gameTime].mul[16]>]>]>
        - define oldRotation     <[curRotation]>
        - define compass_display <&chr[B000].font[map].color[<[rotation_color]>]>
        #the correct number of spaces for the yaw text to be centered
        - define spacing <[yaw_spacing_data].get[<[yaw].length>]>
        - bossbar update <[bb]>_yaw title:<[yaw].color[65,0,0]><proc[spacing].context[-<[spacing]>]><[yaw_icon]><proc[spacing].context[<[spacing]>]> color:YELLOW
        #only update the compass display, but dont update the minimap (uses the previously defined minimap)
        - bossbar update <[bb]> title:<[compass_display]><[marker]><[title]||<empty>> color:YELLOW


  update_minimap:

        #-minimap
        #sub offset
        - define x <[loc].x>
        - define z <[loc].z>

        - define r <[x].sub[<[top_left_x]>].mod[256]>
        - define g <[z].sub[<[top_left_z]>].mod[256]>

        #can't be 0
        - if <[r]> < 0:
          - define r <[r].add[256]>
        - if <[g]> < 0:
          - define g <[g].add[256]>

        - define map_x <[x].sub[<[top_left_x]>].div[256].round_down.add[1]>
        - define map_y <[z].sub[<[top_left_z]>].div[256].round_down.add[1]>

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

        #reset tiles
        - define tiles:!
        - define in_game <[world].name.equals[nimnite_map]>
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

        ## - [ CIRCLE DISPLAY (if it exists) ] - ##
        #-shows FUTURE circle
        #getting the NEW one, since the white circle is showing where the storm will be NEXT
        - define next_storm_diameter <server.flag[fort.temp.storm.new_diameter]||2304>

        #Cirlce only shows up if it's 1600 or less in diameter
        - if <[next_storm_diameter]> <= 1600:
          - define next_storm_center <server.flag[fort.temp.storm.new_center]>

          #circle x and z coords translated to 2d coords
          - define circle_x <[next_storm_center].x>
          - define circle_y <[next_storm_center].z>

          - define relX     <[circle_x].sub[<[loc].x>].add[2048].max[0].min[4095]>
          - define relZ     <[circle_y].sub[<[loc].z>].add[2048].max[0].min[4095]>
          - define r_       <[relX].mod[256]>
          - define g_       <[relZ].mod[256]>
          - define b_       <[relX].div[256].round_down.add[<[relZ].div[256].round_down.mul[16]>]>

          - define circle_display <&chr[E001].font[map].color[<color[<[r_]>,<[g_]>,<[b_]>]>]>

          #storm id for shader to recognize
          - define storm_id <[storm_id_data].get[<[next_storm_diameter]>]>

          ## - [ PURPLE CIRCLE ] - ##
          #-shows from CURRENT circle
        - if <server.has_flag[fort.temp.storm.center]> && <[storm_id].exists>:
          #only show purple circle when white circle shows
          ##CURRENT storm center & diameter

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

          - define purple_offset   <[storm_radius].mul[32].round_down>

          - define purple_circle_display <&chr[E003].font[map].color[<color[<[r_]>,<[g_]>,<[b_]>]>]>
          - define title <[whole_map]><proc[spacing].context[<[storm_id].add[<[purple_offset]>].sub[2].sub[<[tiles].size>]>]><[circle_display]><proc[spacing].context[<[purple_offset].sub[<[storm_id].sub[1]>]>]><[purple_circle_display]><proc[spacing].context[-2]>
        - else:
          #- non-storm minimap
          - define title <[whole_map]><proc[spacing].context[-2]>


        ## - [ UPDATE MINIMAP ] - ##
        # just so you know, adding characters before/and after the title does change the offset. who would've guessed /s
        - bossbar update <[bb]> title:<[compass_display]><[marker]><[title]> color:YELLOW


  get_map_definitions:

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