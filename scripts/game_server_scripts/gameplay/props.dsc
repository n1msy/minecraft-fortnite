fort_pro_handler:
  type: world
  debug: false
  events:
    on player right clicks block with:fort_prop_*:
    - determine passively cancelled
    - ratelimit <player> 1t
    - define i   <context.item>
    - define loc <context.location.above.center>

    - narrate <[i].script.name>

fort_prop_bookshelf:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: x

fort_prop_bookshelf_small:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: x

fort_prop_rack:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: metal
    health: 120

fort_prop_closet:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_red_chair:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_television:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_refrigerator:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 120

fort_prop_toilet:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 150

fort_prop_bathtub:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 75

fort_prop_bed:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 120

fort_prop_tires:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: metal
    health: unbreakable