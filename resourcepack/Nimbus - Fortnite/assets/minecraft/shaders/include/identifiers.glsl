#version 400

bool isScoreboard(vec4 a) {
    return (a.r >= 0.95 && a.r <= 9.9) && (a.g >= 0.31 && a.g <= 0.34) && (a.b >= 0.31 && a.b <= 3.4 ) && a.a == 1.0;
}

bool is100(vec4 a) {
    return (a.r > 0.0 && a.r < 0.005) && a.g == 0.0 && a.b == 0.0;
}

bool is001(vec4 a) {
    return (a.b > 0.0 && a.b < 0.005) && a.r == 0.0 && a.g == 0.0;
}

bool is010(vec4 a) {
    return (a.g > 0.0 && a.g < 0.005) && a.r == 0.0 && a.b == 0.0;
}

bool is200(vec4 a) {
    return (a.r < 0.01 && a.r > 0.005) && a.g == 0.0 && a.b == 0.0;
}

// Courtesy of Onnowhere
// (https://github.com/onnowhere)
bool isGUI(mat4 ProjMat) {
    return ProjMat[3][2] == -2.0;
}