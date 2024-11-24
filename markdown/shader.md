# blinn-phong

## diffuse map

vert

```glsl
#version 450

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec2 inUV0;

layout (set = 0, binding = 0) uniform PerSceneData 
{
	mat4 viewMatrix;
	mat4 projectionMatrix;
} sceneData;

layout (set = 2, binding = 0) uniform PerObjDataDynamic 
{
	mat4 modelMatrix;
} objData;

layout (location = 0) out vec3 outPosition;
layout (location = 1) out vec3 outNormal;
layout (location = 2) out vec2 outUV0;

void main() 
{
    mat3 normalMatrix = transpose(inverse(mat3(objData.modelMatrix)));
    vec3 normal = normalize(normalMatrix * inNormal);

    gl_Position = sceneData.projectionMatrix * sceneData.viewMatrix * objData.modelMatrix * vec4(inPosition.xyz, 1.0);

    outPosition = (objData.modelMatrix * vec4(inPosition.xyz, 1.0)).xyz;
    outNormal = normal;
    outUV0 = inUV0;
}

```

frag

```glsl
#version 450

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec2 inUV0;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform PointLight{
	vec3 pos;
	vec3 viewPos;
    int blinn;
} light;

layout (set = 1, binding = 1) uniform sampler2D diffuseMap;

void main() 
{
    vec3 color = texture(diffuseMap, inUV0).rgb;
    // Ambient
    vec3 ambient = 0.05 * color;
    // Diffuse
    vec3 lightDir = normalize(light.pos - inPosition);
    vec3 normal = normalize(inNormal);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;
    // Specular
    vec3 viewDir = normalize(light.viewPos - inPosition);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = 0.0;
    if(light.blinn == 0)
    {
        vec3 halfwayDir = normalize(lightDir + viewDir);  
        spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    }
    else
    {
        vec3 reflectDir = reflect(-lightDir, normal);
        spec = pow(max(dot(viewDir, reflectDir), 0.0), 8.0);
    }
    vec3 specular = vec3(0.3) * spec; // assuming bright white light color
    outFragColor = vec4(ambient + diffuse + specular, 1.0f);
}

```

## diffuse map + normal map

vert

```glsl
#version 450

struct OutPointLight{
	vec3 pos;
	vec3 viewPos;
};

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec2 inUV0;
layout (location = 3) in vec3 inTangent;

layout (set = 0, binding = 0) uniform PerSceneData 
{
	mat4 viewMatrix;
	mat4 projectionMatrix;
} sceneData;

layout (set = 1, binding = 0) uniform PointLight{
	vec3 pos;
	vec3 viewPos;
} light;

layout (set = 2, binding = 0) uniform PerObjDataDynamic 
{
	mat4 modelMatrix;
} objData;

layout (location = 0) out vec3 outPosition;
layout (location = 1) out vec2 outUV0;
layout (location = 2) flat out OutPointLight outLight;

void main() 
{
	mat3 normalMatrix = transpose(inverse(mat3(objData.modelMatrix)));
	vec3 T = normalize(normalMatrix * inTangent);
	vec3 N = normalize(normalMatrix * inNormal);
    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);

	gl_Position = sceneData.projectionMatrix * sceneData.viewMatrix * objData.modelMatrix * vec4(inPosition.xyz, 1.0);
	
	mat3 TBN = transpose(mat3(T, B, N)); 
    outPosition = (objData.modelMatrix * vec4(inPosition.xyz, 1.0)).xyz;
    outUV0 = inUV0;

	outLight.pos = TBN * light.pos;
	outLight.viewPos = TBN * light.viewPos;
}

```

frag

```glsl
#version 450

struct PointLight{
	vec3 pos;
	vec3 viewPos;
};

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec2 inUV0;
layout (location = 2) flat in PointLight inLight;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 1) uniform sampler2D diffuseMap;
layout (set = 1, binding = 2) uniform sampler2D normalMap;

void main() 
{
    // obtain normal from normal map in range [0,1]
    vec3 normal = texture(normalMap, inUV0).rgb;
    // transform normal vector to range [-1,1]
    normal = normalize(normal * 2.0 - 1.0);  // this normal is in tangent space
   
    // get diffuse color
    vec3 color = texture(diffuseMap, inUV0).rgb;
    // ambient
    vec3 ambient = 0.1 * color;
    // diffuse
    vec3 lightDir = normalize(inLight.pos - inPosition);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;
    // specular
    vec3 viewDir = normalize(inLight.viewPos - inPosition);
    vec3 halfwayDir = normalize(lightDir + viewDir);  
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0);

    vec3 specular = vec3(0.2) * spec;
    outFragColor = vec4(ambient + diffuse + specular, 1.0);
}

```

# PBR

