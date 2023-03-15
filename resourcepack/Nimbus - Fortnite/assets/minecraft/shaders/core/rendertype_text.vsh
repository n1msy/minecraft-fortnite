#version 150

#moj_import <fog.glsl>
#moj_import <map.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

flat out int type;
flat out vec4 ogColor;

vec2 guiPixel(mat4 ProjMat) {
	return vec2(ProjMat[0][0], ProjMat[1][1]) / 2.0;
}

//default - 128
const int mapSize = 135;
const int margin = 16;

const ivec2[] corners = ivec2[](
    ivec2(-1, -1),
    ivec2(-1, 1),
    ivec2(1, 1),
    ivec2(1, -1)
);

vec2 rotate(vec2 point, vec2 center, float rot) {
	float x = center.x + (point.x-center.x)*cos(rot) - (point.y-center.y)*sin(rot);
    float y = center.y + (point.x-center.x)*sin(rot) + (point.y-center.y)*cos(rot);

    return vec2(x, y);
}

#define PI 3.1415926535


void main() {
    ogColor = Color;

    //vanilla
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    // map stuff
    type = -1;
    bool map = texture(Sampler0, vec2(0, 0)).a == 254./255.;
    bool marker = texture(Sampler0, texCoord0) * 255 == vec4(173, 152, 193, 102);
    if (map || marker) {
        vec2 pixel = guiPixel(ProjMat);
        vec4 oldPos = gl_Position;

        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 0), 1.0);
        gl_Position.x *= -1;

        gl_Position.x += -pixel.x * (margin + mapSize);
        gl_Position.y += pixel.y * (margin + mapSize);
        vec2 center = gl_Position.xy;

        if (map) {
            gl_Position.xy += pixel.xy * corners[gl_VertexID % 4] * mapSize;
            type = MAP_TYPE;
        } else if (marker) {
            gl_Position.xy += pixel.xy * corners[gl_VertexID % 4] * 8;
            gl_Position.xy = rotate(gl_Position.xy / pixel.xy, center / pixel.xy, Color.r*PI*2) * pixel.xy;
            type = MARKER_TYPE;
        }
    } 
    if (type != -1 && Position.z == 0) {
        type = DELETE_TYPE;
    }
    //ogColor = texture(Sampler0, texCoord0);
}
