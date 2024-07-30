//
//  ShaderTypes.h
//  ARDummy
//
//  Created by Adeel Tahir on 26/12/2022.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct {
    // Camera Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    
    // Lighting Properties
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    
    float materialShininess;
} SharedUniforms;



typedef struct Vertex {
    vector_float4 position;
    vector_float4 color;
    vector_float4 normal;
} Vertex;


#endif /* ShaderTypes_h */
