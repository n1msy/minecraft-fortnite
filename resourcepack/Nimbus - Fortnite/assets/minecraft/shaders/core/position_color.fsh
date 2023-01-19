#version 330

#define TOOLTIP_Z_MIN -0.4
#define TOOLTIP_Z_MAX -0.399

in vec4 vertexColor;
in vec4 position;
in float dis;

uniform vec4 ColorModulator;

out vec4 fragColor;

const vec3 TooltipRainbowArray[8] = vec3[8](
    vec3( 1.0, 0.0, 0.0 ),
    vec3( 1.0, 0.5, 0.0 ),
    vec3( 1.0, 1.0, 0.0 ),
    vec3( 0.0, 0.5, 0.0 ),
    vec3( 0.0, 0.0, 1.0 ),
    vec3( 0.25, 0.0, 0.5 ),
    vec3( 0.9, 0.5, 0.9 ),
    vec3( 1.0, 1.0, 1.0 )
    );

void main() {

    vec4 color = vertexColor;

    if (color.a == 0.0) discard;

    //remove the pink dot from anywhere on the screen (used for encoding pixels)
    if (color.rgb*255. == vec3(255., 0., 182.)) discard;

    //custom tooltip
    if (position.z > TOOLTIP_Z_MIN && position.z < TOOLTIP_Z_MAX) //capture the tooltip
    {

        //so any tooltips that are huge are just invisible
        if (dis > 100) discard;

        //main outline
        if (color.r*255 > 38)
        {
            color = vec4(54,214,158,255)/255.;
        }
        //fill
        else
        {
            color = vec4(41,160,119,195)/255.;
        }
    }

    // This is the method I've used to capture the sidebar background
    // We just make it go poof!
    if (((color.a >= 0.29 && color.a < 0.3 ) || ( color.a > 0.39 && color.a <= 0.40)) && (color.r < 0.1)) discard;

    fragColor = color * ColorModulator;
}
