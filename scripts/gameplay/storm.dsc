storm:
  type: task
  debug: false
  definitions: data
  script:
    #-test command: /ex run storm def:<map[from=x;to=x]>
    ##only gets smaller, not bigger

    - remove item_display
    #make circle size server flag

    #time for it to change sizes (ticks)
    - define time   100
    - define height 5

    - define from <[data].get[from]>
    - define to <[data].get[to]||null>

    - define radius <[from]>

    - define center <player.location.below[10].with_pose[0,0]>
    #when radius is 1, plane_qty is 5
    - define plane_qty <[radius].mul[5]>
    - define size 1.259

    - define view_range 2

    - define circle <[center].points_around_y[radius=<[radius]>;points=<[plane_qty]>]>
    - foreach <[circle]> as:loc:

      - define i <item[paper].with[custom_model_data=18]>
      #when plane quantity is 50, the perfect size is "1.343"
      #1.343/50=0.02686, which means multiply plane qty by 0.02686

      - define angle <[loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=<[size]>,<[height]>,<[size]>;view_range=<[view_range]>;left_rotation=<[left_rotation]>]> <[loc]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - define planes:->:<entry[plane].spawned_entity>

    - if <[to]> == null:
      - stop

    - wait 1s

    - define new_circle <[center].points_around_y[radius=<[to]>;points=<[plane_qty]>]>

    - foreach <[new_circle]> as:new_loc:
      - define p           <[planes].get[<[loop_index]>]>
      - define plane_loc   <[p].location>
      - define translation <[new_loc].sub[<[plane_loc]>]>

      - define angle <[new_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - adjust <[p]> interpolation_start:0
      - adjust <[p]> translation:<[translation]>
      - adjust <[p]> left_rotation:<[left_rotation]>
      - adjust <[p]> scale:<[size]>,<[height]>,<[size]>
      - adjust <[p]> interpolation_duration:<[time]>t

    #wait for animation to complete
    - wait <[time]>t

    - define new_plane_qty     <[to].mul[5]>
    - define actual_new_circle <[center].points_around_y[radius=<[to]>;points=<[new_plane_qty]>]>

    - foreach <[actual_new_circle]> as:loc:

      - define i <item[paper].with[custom_model_data=18]>

      - define angle <[loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=<[size]>,<[height]>,<[size]>;view_range=<[view_range]>;left_rotation=<[left_rotation]>]> <[loc]> save:plane
      #- define new_plane     <entry[plane].spawned_entity>
      #- define new_planes:->:<entry[plane].spawned_entity>

    #wait for new planes to spawn first
    - wait 1t
    #remove the old planes
    - remove <[planes]>

    ##other option: spiral (coils around a point and whatever overlaps the circle is removed) (idk how)