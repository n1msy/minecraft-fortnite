vec2 coords;
int displayId;

void getInfoFromColor(vec4 color) {
    coords = color.rg;
    displayId = int(color.b * 255);
}