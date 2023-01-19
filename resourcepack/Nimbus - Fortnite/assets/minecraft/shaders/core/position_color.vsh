#version 330

#ifdef LONG_COMPAT_MODE
#define BOTTOM_Y -0.99
#else
#define BOTTOM_Y -0.9864
#endif

#define TOOLTIP_Z_MIN -0.4
#define TOOLTIP_Z_MAX -0.399

in vec3 Position;
out vec4 position;
in vec4 Color;
out float dis;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
void main() {

    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    position = gl_Position;

    // Based on the work by: lolgeny
    // Link: https://github.com/lolgeny/item-tooltip-remover
    dis = 0.0;

    if (position.x < -0.95 && position.x > -1) dis = 100.0;
    if (position.x > 0.7 && position.x < 1) dis = 100.0;
    if (position.y > 2 || position.x < -2 && (position.z > -0.4 && position.z < -0.399) ) dis = 100000000.0;

    vertexColor = Color;
}
