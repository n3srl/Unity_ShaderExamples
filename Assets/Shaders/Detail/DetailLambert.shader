Shader "N3/DetailLambert"
{
    Properties
    {
        _Tint("Color", Color) = (1, 1, 1, 1)
        _MainTex("Main", 2D) = "white" {}
        _Color1Tex("Color 1", 2D) = "white" {}
        _Color2Tex("Color 2", 2D) = "white" {}
        _LightDirection("Light Direction", Vector) = (0,1,0,0)
        _Intensity("Intensity",Float) = 1
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

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                sampler2D _Color1Tex;
                sampler2D _Color2Tex;

                float4 _MainTex_ST;
                float4 _Color1Tex_ST;
                float4 _Color2Tex_ST;

                float4 _Tint;
                float4 _LightDirection;
                float4 _LightColor;

                float _Intensity;

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
                    o.screen_pos = UnityObjectToClipPos(v.object_pos);

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

                    o.world_position = mul(unity_ObjectToWorld, v.object_pos);
                    //o.normal = v.normal;
                    return o;
                }


                fixed4 frag(v2f i) : SV_Target
                {
                    i.normal = normalize(i.normal);

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

                    //lambert diffuse color
                    fixed4 diffuse = color * dot(float3(_LightDirection.x, _LightDirection.y, _LightDirection.z), i.normal);


                    return  saturate(diffuse) ;
                }

                ENDCG
            }
        }
}
