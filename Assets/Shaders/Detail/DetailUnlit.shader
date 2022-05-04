Shader "N3/DetailUnlit"
{
    Properties
    {
        _Tint("Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main", 2D) = "white" {}
        _Color1Tex("Color 1", 2D) = "white" {}
        _Color2Tex("Color 2", 2D) = "white" {}
        _Distance("Distance", float) = 0.5
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

            float _Distance;
            float4 _Tint;

            struct appdata
            {
                float4 world_pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 screen_pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.screen_pos = UnityObjectToClipPos(v.world_pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 main = tex2D(_MainTex, i.uv);
                fixed4 color1 = tex2D(_Color1Tex, i.uv);
                fixed4 color2 = tex2D(_Color2Tex, i.uv);

                fixed4 col = _Tint * (main.r * color1 + (1 - main.r) * color2);

                return col;
            }

            ENDCG
        }
    }
}