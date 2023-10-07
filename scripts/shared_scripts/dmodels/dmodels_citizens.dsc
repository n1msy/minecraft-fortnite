###########################
# This file is part of dModels / Denizen Models.
# Refer to the header of "dmodels_main.dsc" for more information.
# ------
# This file may be excluded from servers that do not use Citizens.
###########################


dmodels_npc_assignment:
    type: assignment
    actions:
        on assignment:
        - if <npc.is_spawned>:
            - run dmodels_npc_spawn
        on remove assignment:
        - run dmodels_npc_despawn
        on spawn:
        - run dmodels_npc_spawn
        on despawn:
        - run dmodels_npc_despawn

dmodels_npc_spawn:
    type: task
    debug: false
    script:
    - if !<npc.has_flag[dmodels_model]>:
        - stop
    - run dmodels_spawn_model def.model_name:<npc.flag[dmodels_model]> def.location:<npc.location> save:model
    - define root <entry[model].created_queue.determination.first||null>
    - if !<[root].is_truthy>:
        - debug error "[DModels] NPC <npc.id> tried to use model <npc.flag[dmodels_model]> but spawning failed."
        - stop
    - adjust <npc> hide_from_players
    - flag <npc> dmodels_root:<[root]>
    - run dmodels_attach_to def.root_entity:<[root]> def.target:<npc> def.auto_animate:true

dmodels_npc_despawn:
    type: task
    debug: false
    script:
    - if !<npc.has_flag[dmodels_root]>:
        - stop
    - adjust <npc> show_to_players
    - run dmodels_delete def.root_entity:<npc.flag[dmodels_root]>
    - flag <npc> dmodels_root:!
