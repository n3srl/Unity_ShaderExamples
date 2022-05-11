Shader "N3/DetailBlinnPhongDisplaced"
{
    Properties
    {
        _Tint("Color", Color) = (1, 1, 1, 1)
        _GlobalLightColor("Global Light Color", Color) = (1, 1, 1, 1)
        _LightColor("Light Color", Color) = (1, 1, 1, 1)
        _MainTex("Main", 2D) = "white" {}
        _Color1Tex("Color 1", 2D) = "white" {}
        _Color2Tex("Color 2", 2D) = "white" {}
        _LightDirection("Light Direction", Vector) = (0,1,0,0)
        _Intensity("Intensity",Float) = 1
        _Specular("Specular",Float) = 0.5
        _SpecularIntensity("Specular Intensity",Float) = 0.5
        _Displacement("Displacement Map" ,2D) = "black" {}
        _DisplacementIntensity("Displacement Intensity" ,Float) = 0.5
        [MaterialToggle] _Blinn("Blinn Specular Enabled",Float) = 0
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

               // #include "UnityCG.cginc"
                #include "UnityStandardBRDF.cginc"

                sampler2D _MainTex;
                sampler2D _Color1Tex;
                sampler2D _Color2Tex;
                sampler2D _Displacement;
                
                float4 _MainTex_ST;
                float4 _Color1Tex_ST;
                float4 _Color2Tex_ST;
                float4 _Displacement_ST;

                float4 _Tint;
                float4 _LightDirection;
                float4 _LightColor;
                float4 _GlobalLightColor;

                float _Intensity;
                float _Specular;
                float _SpecularIntensity;

                float _Blinn;

                float _DisplacementIntensity;
                struct appdata
                {
                    float4 object_pos : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal:NORMAL;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float2 uv1_detail : TEXCOORD1;
                    float2 uv2_detail : TEXCOORD2;
                    float4 screen_pos : SV_POSITION;
                    float3 normal:TEXCOORD3;
                    float3 world_position: TEXCOORD4;
                };

                v2f vert(appdata v)
                {
                    v2f o;

                    //approx
                    //o.normal = mul( unity_ObjectToWorld, float4( v.normal , 0 ) );
                    //o.normal = normalize(o.normal);

                    //local
                    // o.normal = v.normal;

                    //UnityObjectToWorldNormal
                    o.normal = UnityObjectToWorldNormal( v.normal);

                    //texel offset + tiling
                    o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;

                    o.uv1_detail = v.uv * _Color1Tex_ST.xy + _Color1Tex_ST.zw;
                    o.uv2_detail = v.uv * _Color2Tex_ST.xy + _Color2Tex_ST.zw;

                    float2 uv_displace = v.uv * _Displacement_ST.xy+ _Displacement_ST.zw;
                    float4 displace_color = tex2Dlod(_Displacement, float4(uv_displace.x, uv_displace.y, 0, 0));
                    float displace_height = displace_color.r ;
                    float3 displace_vector = v.normal * displace_height * _DisplacementIntensity;
                    
                    float3 vertex_displaced = v.object_pos + displace_vector;


                    o.world_position = mul(unity_ObjectToWorld, vertex_displaced);
                    o.screen_pos = UnityObjectToClipPos(vertex_displaced);


                    return o;
                }


                fixed4 frag(v2f i) : SV_Target
                {
                    i.normal = normalize(i.normal);

                    float3 viewDir = normalize( _WorldSpaceCameraPos - i.world_position );
                    
                    _LightDirection = normalize(_LightDirection) * _Intensity;

                    _LightDirection.x = max(0, _LightDirection.x);
                    _LightDirection.y = max(0, _LightDirection.y);
                    _LightDirection.z = max(0, _LightDirection.z);

                    //detail texture
                    fixed4 main = tex2D(_MainTex, i.uv);
                    fixed4 color1 = tex2D(_Color1Tex, i.uv1_detail);
                    fixed4 color2 = tex2D(_Color2Tex, i.uv2_detail);

                    //texture color
                    fixed4 color = _Tint * (main.r * color1 + (1 - main.r) * color2);

                    //global light illumination
                    fixed4 global = _GlobalLightColor * _Intensity * color;
                   
                    //lambert diffuse color
                    fixed4 diffuse = color * dot(float3(_LightDirection.x, _LightDirection.y, _LightDirection.z), i.normal);

                    fixed4 specular;

                    if (!_Blinn) 
                    {
                        float3 reflectionDir = reflect(-_LightDirection, i.normal);
                        specular = _LightColor * _Intensity * _SpecularIntensity * pow(DotClamped(viewDir, reflectionDir), _Specular*100);
                    }
                    else {
                        float3 halfVector = normalize(_LightDirection + viewDir);
                        specular = pow(DotClamped(halfVector, i.normal), _Specular*100);
                    }

                    return global + saturate(diffuse) + specular;
                    //  return global  +  specular;
                    //return specular;
                }

                ENDCG
            }
        }
}
