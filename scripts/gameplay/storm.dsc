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

    - define circle <[center].points_around_y[radius=<[radius]>;points=<[plane_qty]>]>
    - foreach <[circle]> as:loc:

      - define i <item[paper].with[custom_model_data=18]>
      #when plane quantity is 50, the perfect size is "1.343"
      #1.343/50=0.02686, which means multiply plane qty by 0.02686
      #- define opacity 153
      - define view_range 3

      - define angle <[loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=<[size]>,<[height]>,<[size]>;view_range=<[view_range]>;left_rotation=<[left_rotation]>]> <[loc]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - define planes:->:<entry[plane].spawned_entity>

    - if <[to]> == null:
      - stop

    - wait 1s

    - define new_plane_qty <[to].mul[5]>
    - define new_circle <[center].points_around_y[radius=<[to]>;points=<[new_plane_qty]>]>

    - define circle_mul <[plane_qty].div[<[new_plane_qty]>]>
    - define start_size 5.2
    #<[size].mul[<[circle_mul].add[1]>].round_up>

    - repeat <[new_plane_qty]>:
      - define p             <[planes].get[<[value].mul[<[circle_mul]>].round_up>]>
      - define new_planes:->:<[p]>
      #account for extra plane removals
      - adjust <[p]> scale:<[start_size]>,<[height]>,<[start_size]>

    #wait 1t for scale to change
    - wait 1t

    #remove extra planes
    - define remove_planes <[planes].exclude[<[new_planes]>]>
    - remove <[remove_planes]>

    - foreach <[new_circle]> as:new_loc:
      - define p           <[new_planes].get[<[loop_index]>]>
      - define plane_loc   <[p].location>
      - define translation <[new_loc].sub[<[plane_loc]>]>

      - define angle <[new_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - adjust <[p]> interpolation_start:0
      - adjust <[p]> translation:<[translation]>
      - adjust <[p]> left_rotation:<[left_rotation]>
      - adjust <[p]> scale:<[size]>,<[height]>,<[size]>
      - adjust <[p]> interpolation_duration:<[time]>t

    ##other option: spiral (coils around a point and whatever overlaps the circle is removed)
    ##other option: just animate the entire thing and then spawn another circle batch and remove the old one (simplest one, but only problem is from the outside, the textures might get screwed)

