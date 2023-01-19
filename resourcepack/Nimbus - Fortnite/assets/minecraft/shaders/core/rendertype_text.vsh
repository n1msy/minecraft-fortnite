#version 400

#moj_import <fog.glsl>
#moj_import <identifiers.glsl>

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
uniform vec2 ScreenSize;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec4 ColorCode;

// Constant for bouncy text
const float BouncyArray[4] = float[4]( 0, 1, 0, -1 );


//
// [!] Make sure each GUI element has a dedicated sidebar slot, otherwise they will not show correctly. [!]
//

// Text Offset Data

// [ Agent Select ]

//Top Left
const int map = 1;
const int type = 2;

//Timer
const int timer = 3;

//Agents (Left)
const int agentIcon1 = 41;
const int agentName1 = 4;
const int picking1 = 5;

const int agentIcon2 = 61;
const int agentName2 = 6;
const int picking2 = 7;

const int agentIcon3 = 81;
const int agentName3 = 8;
const int picking3 = 9;

const int agentIcon4 = 101;
const int agentName4 = 10;
const int picking4 = 11;

//agentIcon = the image (put an extra 1 at the end)
//agentName = the text
const int agentIcon5 = 121;
const int agentName5 = 12;
const int picking5 = 13;

// [ Gameplay UI ] 
const int ammo = 14;
const int health = 15;
//No need for three shield versions, but doing it just
//in case I wanted to change it in the future.
const int shield_100 = 16;
const int shield_50 = 17;
const int shield_1 = 18;

const int customHotbar = 19;
const int crosshair = 20;

const int leftTopUI = 21;
const int rightTopUI = 22;

//bottom left, used in gameplay UI
const int credits = 23;

//related to top_ui
const int healthBarTopUI = 24;
const int healthBarTopUIEmpty = 25;
const int spike = 26;

//buy phase texture (the text showing the round/which side)
const int buyPhase = 27;

//custom inventory
const int slot1 = 28;
const int slot1NotSel = 52;
const int slot2 = 29;
const int slot2NotSel = 53;
const int slot3 = 30;
const int slot3NotSel = 54;
const int slot4 = 31;

const int deadTopLeftUI = 32;
const int deadTopRightUI = 33;

const int agentSelectLock = 34;
//when used in a title
const int agentSelectLockTitle = 35;
//new sidebar line = 0.025 y height difference

const int abilityIcons = 36;

const int abilityEmpty = 37;
const int abilityFull = 38;

const int ultPointsEmpty = 39;
const int ultPointsFull = 40;

const int invLines = 50;
const int invLinesSpike = 51;

//Each offset has one dedicated color (?)
vec3 getColor(int i) {
  switch (i) {

    //red
    //case 1:
    //  return vec3(255, 0, 0)/255.;
    //  break;

    case 4: case 6: case 8: case 10: case 12:
        return vec3(179, 255, 156)/255.;
        break;
 
    case 2: case 5: case 7: case 9: case 11: case 13:
        return vec3(222, 222, 222)/255.;
        break;

    case 16:
        return vec3(96, 224, 254)/255.;
        break;

    //empty health top UI and slot "NotSel" colors
    case 25: case 52: case 53: case 54: case 261:
        return vec3(170, 170, 170)/255.;
        break;

    //top left/right "dead" colors
    case 32: case 33:
        return vec3(200, 200, 200)/255.;
        break;

    //ability/ult point full
    case 38: case 40:
        return vec3(84, 242, 187)/255.;
        break;

    case 241:
        return vec3(252, 232, 40)/255.;
        break;

    case 251:
        return vec3(0, 240, 17)/255.;
        break;

    default:
        return vec3(1, 1, 1);
        break;
  }
}

//For relative positioning based on window size/gui scale
vec2 guiPixel(mat4 ProjMat) {
    return vec2(ProjMat[0][0], ProjMat[1][1]) / 2.0;
}

void main() {

    //Vanilla Code
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
    ColorCode = Color;

    //SHADOW REMOVER Cred: PuckiSilver
    //Use this color code to remove it: #4e5c24
    if (Color == vec4(78/255., 92/255., 36/255., Color.a) && Position.z == 0.03) {
        vertexColor = texelFetch(Sampler2, UV2 / 16, 0); // remove color from no shadow marker
    } else if (Color == vec4(19/255., 23/255., 9/255., Color.a) && Position.z == 0) {
        vertexColor = vec4(0); // remove shadow
    }

    // Text Offsets
    if (Color.r > 0 && Color.g == 0 && Color.b == 0)
    {
        vec2 pixel = guiPixel(ProjMat);

        gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

        switch (int(Color.r*255))
        {
            //Agent Select Menu
            case map:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += pixel.y * 175 + gl_Position.w * 1;


                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case type:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += pixel.y * 175 + gl_Position.w * 1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            //use a bossbar for this instead??
            //i feel like this is better because it's all in one sidebar
            case timer:
                gl_Position.x += pixel.x * 190 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 140 + gl_Position.w * 1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentIcon1: case agentName1:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.35;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case picking1:
                gl_Position.x += pixel.x * 375 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.35;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;
            
            case agentIcon2: case agentName2:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.2;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case picking2:
                gl_Position.x += pixel.x * 375 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.2;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentIcon3: case agentName3:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.05;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case picking3:
                gl_Position.x += pixel.x * 375 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * 0.05;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentIcon4: case agentName4:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * -0.1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case picking4:
                gl_Position.x += pixel.x * 375 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * -0.1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentIcon5: case agentName5:
                gl_Position.x += pixel.x * 300 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * -0.25;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case picking5:
                gl_Position.x += pixel.x * 375 + gl_Position.w * -2;
                gl_Position.y += gl_Position.w * -0.25;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case ammo:
                gl_Position.x += pixel.x * 1325 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 14 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case health:
                gl_Position.x += pixel.x * 462 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 14 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case shield_100:
                gl_Position.x += pixel.x * 492 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 14 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case shield_50:
                gl_Position.x += pixel.x * 542 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 14 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case shield_1:
                gl_Position.x += pixel.x * 542 + gl_Position.w * -1;
                gl_Position.y += pixel.y * 14 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case customHotbar:
                gl_Position.x += pixel.x * 503 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -46 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case crosshair:
                //to line up with f3 = 960, 7
                gl_Position.x += pixel.x * 958 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -8;
                //gl_Position.y += gl_Position.w * -0.88;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case leftTopUI: case deadTopLeftUI:
                gl_Position.y += pixel.y * -48;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case rightTopUI: case deadTopRightUI:
                gl_Position.y += pixel.y * -86;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case credits:
                gl_Position.x += pixel.x * 1800 + gl_Position.w * -1;
                //it would be this (below), but then the credits would go over the other UI if gui scale is changed
                //gl_Position.x += gl_Position.w * 0.9;
                gl_Position.y += pixel.y * -75 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case healthBarTopUI: case healthBarTopUIEmpty:
                gl_Position.y += pixel.y * -100;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;


            case spike:
                gl_Position.y += pixel.y * -117;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case buyPhase:
                gl_Position.y += pixel.y * -316;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            //starts at bottom
            case slot1: case slot1NotSel:
                gl_Position.x -= pixel.x * 30 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -80;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case slot2: case slot2NotSel:
                gl_Position.x -= pixel.x * 128 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -135;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case slot3: case slot3NotSel:
                gl_Position.x -= pixel.x * 226 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -185;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case slot4:
                gl_Position.x -= pixel.x * 285 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -235;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentSelectLock:
                gl_Position.y += pixel.y * -110 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case agentSelectLockTitle:
                gl_Position.y += pixel.y * -295 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case abilityIcons:
                gl_Position.x += pixel.x * 730 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -28 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case abilityEmpty:
                gl_Position.x += pixel.x * 720 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -8 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                //opacity
                vertexColor.a = 150/255.;
                break;

            case abilityFull:
                gl_Position.x += pixel.x * 720 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -8 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case ultPointsEmpty:
                gl_Position.x += pixel.x * 1186 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -40 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                vertexColor.a = 150/255.;
                break;

            case ultPointsFull:
                gl_Position.x += pixel.x * 1186 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -40 + gl_Position.w * -1;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case invLines:
                gl_Position.x -= pixel.x * -125 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -80;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            case invLinesSpike:
                gl_Position.x -= pixel.x * -125 + gl_Position.w * -1;
                gl_Position.y += pixel.y * -106;

                vertexColor.rgb = getColor(int(Color.r*255));
                break;

            default:
                break;
        }

    }
    // Bouncy Text
    else if (Color.rgb == vec3(24,0,1)/255. || Color.rgb == vec3(25,0,1)/255. || Color.rgb == vec3(26,0,1)/255.)
    {

        if (Color.rgb == vec3(24,0,1)/255.)
        {
            vertexColor.rgb = getColor(int(241));
        }
        else if (Color.rgb == vec3(25,0,1)/255.)
        {
            vertexColor.rgb = getColor(int(251));
        }
        else
        {
            vertexColor.rgb = getColor(int(261));
        }

        float ticker = mod((GameTime * 10000), 4) + (mod((Position.x), 512) / 64);
        float final;
        if (ticker > 3) 
        {
            final = mod(ticker, 4);
        }
        else 
        {
            final = ticker;
        }

        gl_Position = ProjMat * ModelViewMat * vec4(Position.x, (Position.y + BouncyArray[int(final)]) - 50, Position.z, 1.0);
    }
    else
    {
        gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    }

}