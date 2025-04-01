#version 330 core

out vec4 FragColor;

in vec2 TextCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    vec2 TextCoordFlipped = vec2(-TextCoord.x, TextCoord.y);
    FragColor = mix(texture(texture1, TextCoord), texture(texture2, TextCoordFlipped), 0.2);
} 
