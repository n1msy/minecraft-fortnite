#version 150

#moj_import <fog.glsl>

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

flat out int isMap;
flat out int delete;
flat out float xOffset;
flat out vec4 ogColor;

vec2 guiPixel(mat4 ProjMat) {
	return vec2(ProjMat[0][0], ProjMat[1][1]) / 2.0;
}

//default - 128
const int mapSize = 135;
const int margin = 16;

void main() {
    ogColor = Color;

    //vanilla
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;

    // map stuff
    isMap = 0;
    delete = 0;
    bool map = texture(Sampler0, vec2(0, 0)).a == 254./255.;
    if (map && Position.z == 0) {
        delete = 1;
    } else if (map) {
        vec2 pixel = guiPixel(ProjMat);
        vec4 oldPos = gl_Position;
        xOffset = oldPos.x / pixel.x;

        gl_Position = ProjMat * ModelViewMat * vec4(vec3(0, 0, 0), 1.0);
        gl_Position.x *= -1;

        gl_Position.x += -pixel.x * (margin + mapSize);
        gl_Position.y += pixel.y * (margin + mapSize);

        //gl_Position.y *= -1;

        switch (gl_VertexID % 4) {
            //left top
            case 0:
                gl_Position.x += pixel.x * -mapSize;
                gl_Position.y += pixel.y * -mapSize;
                // xOffset += 0
                break;
            //left bottom
            case 1:
                gl_Position.x += pixel.x * -mapSize;
                gl_Position.y += pixel.y * mapSize;
                // xOffset += 0
                break;
            //right bottom
            case 2:
                gl_Position.x += pixel.x * mapSize;
                gl_Position.y += pixel.y * mapSize;
                //xOffset += 4;
                break;
            //right top
            case 3:
                gl_Position.x += pixel.x * mapSize;
                gl_Position.y += pixel.y * -mapSize;
                //xOffset += 4;
                break;
        }

        isMap = 1;
    }
}
