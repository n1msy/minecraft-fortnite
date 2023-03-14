vec2 coords;
int displayId;

void getInfoFromColor(vec4 color) {
    coords = color.rg;
    displayId = int(color.b * 255);
}

#define DELETE_TYPE 0
#define MAP_TYPE 1
#define MARKER_TYPE 2