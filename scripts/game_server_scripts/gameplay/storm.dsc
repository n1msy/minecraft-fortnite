fort_storm_info:
  type: data
  # - Some stuff for understanding what the storm flags are and what they're used for - #

  fort.temp.storm.diameter: the LIVE (current) diameter of the storm. this is updated while the storm changes size.
  fort.temp.storm.center:   the LIVE (current) center of the storm. this is also updated while the storm transforms.

  fort.temp.storm.new_diameter: the diameter's end size of the storm.
  fort.temp.storm.new_center: the center's end destination of the storm.

fort_storm_handler:
  type: world
  debug: false
  definitions: new_diameter|seconds
  events:

    # - [ EXITING THE STORM ] - #
    #checking flagged: so it doesn't fire multiple times
    on player enters fort_storm_circle flagged:fort.in_storm:
    - flag player fort.in_storm:!
    #- cast BLINDNESS duration:15t hide_particles no_ambient no_icon no_clear
    - time player reset
    - weather player reset
    - while <player.is_online> && !<player.has_flag[fort.spectating]> && <player.has_flag[fort.in_storm]>:
      - hurt <server.flag[fort.temp.storm_dps]||1> cause:WORLD_BORDER
      - wait 1s

    # - [ ENTERING THE STORM ] - #
    on player exits fort_storm_circle flagged:!fort.in_storm:
    - flag player fort.in_storm
    #remember: night vision plays a part in showing the purple sky
    #- cast BLINDNESS duration:15t hide_particles no_ambient no_icon no_clear
    - time player 13000
    - weather player storm

  ## - [ CREATE STORM ] - ##
  create:
    - execute as_server "globaldisplay destroy storm"
    - flag server fort.temp.storm:!

    ##

    - define diameter 2048

    #center is the world's spawn
    - define storm_center <world[nimnite_map].spawn_location.with_y[20]>

    - execute as_server "globaldisplay create storm paper{CustomModelData:19} <[storm_center].x> <[storm_center].y> <[storm_center].z> <[diameter]> 150 <[diameter]>"
    - execute as_server "globaldisplay player add storm @a"

    - define circle_radius <[diameter].div[2].round>
    #- define storm_circle <[storm_center].points_around_y[radius=<[circle_radius]>;points=16].to_polygon.with_y_min[0].with_y_max[300]>
    - define storm_circle <[storm_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
    - note <[storm_circle]> as:fort_storm_circle

    - flag server fort.temp.storm.diameter:<[diameter]>
    - flag server fort.temp.storm.center:<[storm_center]>


  ## - [ SET NEW STORM ] - ##
  #just setting new data and for the white circle
  set_new:
    - define new_diameter 100
    ##

    #save current storm data
    - define current_diameter <server.flag[fort.temp.storm.diameter]>
    - define current_center   <server.flag[fort.temp.storm.center]>

    #doing radius, since we're getting it from the center of the circle
    - define cur_radius <[current_diameter].div[2]>
    - define x <util.random.int[-<[cur_radius]>].to[<[cur_radius]>]>
    - define z <util.random.int[-<[cur_radius]>].to[<[cur_radius]>]>

    - flag server fort.temp.storm.new_center:<[current_center].add[<[x]>,0,<[z]>]>
    - flag server fort.temp.storm.new_diameter:<[new_diameter]>

  ## - [ RESIZE/TRANSFORM STORM ] - ##
  resize:
    - define seconds 5
    ##

    - define start_center   <server.flag[fort.temp.storm.center]>
    - define end_center     <server.flag[fort.temp.storm.new_center]>

    - define start_diameter <server.flag[fort.temp.storm.diameter]>
    - define end_diameter   <server.flag[fort.temp.storm.new_diameter]>

    - define ticks <[seconds].mul[20]>

    - execute as_server "globaldisplay transform storm <[end_center].x> <[end_center].y> <[end_center].z> <[end_diameter]> 150 <[end_diameter]> <[ticks]>"

    #how many points between the two centers
    - define center_increment   <[start_center].distance[<[end_center]>].div[<[ticks]>]>
    - define diameter_increment <[end_diameter].sub[<[start_diameter]>].div[<[ticks]>]>

    #for debug purposes
    #- define final_center <[start_center].face[<[end_center]>].forward[<[center_increment].mul[<[ticks]>]>].round>

    - define start_center <[start_center].face[<[end_center]>]>
    - repeat <[ticks]>:
      #rounding so it works with color codes
      - define next_center   <[start_center].forward[<[center_increment].mul[<[value]>]>].round>
      - define next_diameter <[start_diameter].add[<[diameter_increment].mul[<[value]>]>].round>

      - define circle_radius <[next_diameter].div[2]>
      #- define storm_circle <[next_center].points_around_y[radius=<[circle_radius]>;points=16].to_polygon.with_y_min[0].with_y_max[300]>
      - define storm_circle <[next_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
      - note <[storm_circle]> as:fort_storm_circle

      - flag server fort.temp.storm.center:<[next_center]>
      - flag server fort.temp.storm.diameter:<[next_diameter]>

      - wait 1t

