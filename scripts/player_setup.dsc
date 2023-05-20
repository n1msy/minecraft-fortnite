fort_setup:
  type: task
  debug: false
  script:
  - foreach <server.online_players> as:p:
    - flag <[p]> fort.wood.qty:999
    - flag <[p]> fort.brick.qty:999
    - flag <[p]> fort.metal.qty:999

    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - flag <[p]> fort.ammo.<[ammo_type]>:999