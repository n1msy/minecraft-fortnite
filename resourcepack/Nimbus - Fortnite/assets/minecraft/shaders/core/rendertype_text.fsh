#version 150

#moj_import <fog.glsl>
#moj_import <map.glsl>

#define PI 3.1415926535

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

flat in int type;
flat in vec4 ogColor;

out vec4 fragColor;

//default = 0.5
const float zoom = 0; 

vec2 rotate(vec2 point, vec2 center, float rot) {
	float x = center.x + (point.x-center.x)*cos(rot) - (point.y-center.y)*sin(rot);
    float y = center.y + (point.x-center.x)*sin(rot) + (point.y-center.y)*cos(rot);

    return vec2(x, y);
}

void main() {
    // vanilla 
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1 || type == DELETE_TYPE) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    // map
    if (type == MAP_TYPE) {
        getInfoFromColor(ogColor);


        vec2 c0 = texCoord0 + coords - vec2(0.5, 0.5);

        vec2 mapFrom = vec2(0, 0);
        if (displayId == 1 || displayId == 3) {
            if (coords.y > 0.5) mapFrom.y += 1;
                else mapFrom.y -= 1;
        }
        if (displayId == 2 || displayId == 3) {
            if (coords.x > 0.5) mapFrom.x += 1;
                else mapFrom.x -= 1;
        }

        vec2 c1 = mix(c0, coords, zoom);

        fragColor = texture(Sampler0, c1);
        // return opacity back to 255
        fragColor.a = 1;

        //make the edge colors blue, since it's the color of the water rgba(61,61,242,255)
        if (any(lessThan(c1, mapFrom)) || any(greaterThan(c1, mapFrom + vec2(1, 1)))) {
            if (displayId == 0) fragColor = vec4(68/255., 68/255., 252/255., 1);
                else discard;
        }

        //dot
        //if (all(greaterThan(texCoord0, vec2(0.49, 0.49))) && all(lessThan(texCoord0, vec2(0.51, 0.51)))) fragColor = vec4(1, 1, 1, 1);
        
    } else if (type == MARKER_TYPE) {
        fragColor = texture(Sampler0, texCoord0);
        if (fragColor * 255 == vec4(173, 152, 193, 102)) discard;
    }
}
