#version 400

#moj_import <fog.glsl>
#moj_import <identifiers.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec3 Position;
in vec4 ColorCode;

out vec4 fragColor;

// Constant for the rainbow array
const vec3 RainbowArray[8] = vec3[8](
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

    //remove shadow if the texture's corner is pink
    if ((texture(Sampler0, vec2(1., 1.)).rgb*255. == vec3(255., 0., 182.)) && (ColorCode.r*255. <= 7.) && (ColorCode.gb*255. == vec2(0., 0.))) discard;

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;

    if (color.a < 0.1) discard;

    //used for corner pixels of the ability icons to make them all the same size
    if (color.rgb == vec3(1, 1, 1) && color.a == 38/255.) discard;

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    // Remove scoreboard background and red text
    if((isScoreboard(fragColor)) && ((ScreenSize.x - gl_FragCoord.x) < 36)) discard;
    
}
