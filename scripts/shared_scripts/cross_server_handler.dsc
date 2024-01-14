#cross_server_handler:
  #type: world
  #debug: false
  #events:
    #how redis works:
    #you *publish* messages to *subscribers*
    #after server start:
      #- ~redis id:subscriber connect:localhost
      #- ~redis id:publisher connect:localhost
      #- redis id:subscriber subscribe:global_*
      #- if <bungee.server> == backup:
        #- redis id:subscriber connect: