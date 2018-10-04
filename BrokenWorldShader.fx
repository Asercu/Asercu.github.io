//************
// VARIABLES *
//************
cbuffer cbPerObject
{
	float4x4 m_MatrixWorldViewProj : WORLDVIEWPROJECTION;
	float4x4 m_MatrixWorld : WORLD;
	float4x4 m_MatrixProjection : PROJECTION;
	float3 m_LightDir={0.2f,-1.0f,0.2f};
	float4x4 m_MatrixWorldInverse;
}

RasterizerState NoCulling 
{ 
	CullMode = NONE; 
};

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

Texture2D m_TextureDiffuse;
float3 m_PlayerPosition;
float m_SafeRadius;
float m_Intensity;
float m_ElapsedTime;


//**********
// STRUCTS *
//**********
struct VS_DATA
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD;
};

struct GS_DATA
{
	float4 Position : SV_POSITION;
	float3 Normal : NORMAL;
	float2 TexCoord : TEXCOORD0;
};

//****************
// VERTEX SHADER *
//****************
VS_DATA MainVS(VS_DATA vsData)
{
	return vsData;
}

//******************
// GEOMETRY SHADER *
//******************
void CreateVertex(inout TriangleStream<GS_DATA> triStream, float3 pos, float3 normal, float2 texCoord)
{
	GS_DATA vertex = (GS_DATA)0;
	vertex.Position = mul(float4(pos.xyz, 1.0), m_MatrixWorldViewProj);
	vertex.Normal = mul(normalize(normal), (float3x3)m_MatrixWorld);
	vertex.TexCoord = texCoord;
	triStream.Append(vertex);
}


[maxvertexcount(3)]
void TriDisplacer(triangle VS_DATA vertices[3], inout TriangleStream<GS_DATA> triStream)
{
	float3 pos1, pos2, pos3;
	pos1 = vertices[0].Position;
	pos2 = vertices[1].Position;
	pos3 = vertices[2].Position;

	float3 center = (pos1 + pos2 + pos3) / 3;
	center = mul(float4(center, 1), m_MatrixWorld).xyz;
	float displacement = clamp(distance(center, m_PlayerPosition) - m_SafeRadius, 0.0f, 999999.0f) * m_Intensity;

	float2 flatdirection = normalize(float2(center.x - m_PlayerPosition.x, center.z - m_PlayerPosition.z));

	float3 worldSpacedisplacementvector = float3(
		flatdirection.x * displacement,
		flatdirection.y * displacement,
		displacement / 2.f * sin(displacement / 5000.f + m_ElapsedTime * 2.f)
		);
	float3 objectSpacedisplacementVector = mul(float4(worldSpacedisplacementvector, 1), m_MatrixWorldInverse).xyz;

	pos1 += objectSpacedisplacementVector;
	pos2 += objectSpacedisplacementVector;
	pos3 += objectSpacedisplacementVector;

	CreateVertex(triStream,pos1,vertices[0].Normal,vertices[0].TexCoord);
	CreateVertex(triStream,pos2,vertices[1].Normal,vertices[1].TexCoord);
	CreateVertex(triStream,pos3,vertices[2].Normal,vertices[2].TexCoord);

	triStream.RestartStrip();
}

//***************
// PIXEL SHADER *
//***************
float4 MainPS(GS_DATA input) : SV_TARGET 
{
	input.Normal=-normalize(input.Normal);
	float alpha = m_TextureDiffuse.Sample(samLinear,input.TexCoord).a;
	float3 color = m_TextureDiffuse.Sample( samLinear,input.TexCoord ).rgb;
	float s = max(dot(m_LightDir,input.Normal), 0.4f);

	return float4(color*s,alpha);
}


//*************
// TECHNIQUES *
//*************
technique10 DefaultTechnique 
{
	pass p0 {
		SetRasterizerState(NoCulling);	
		SetVertexShader(CompileShader(vs_4_0, MainVS()));
		SetGeometryShader(CompileShader(gs_4_0, TriDisplacer()));
		SetPixelShader(CompileShader(ps_4_0, MainPS()));
	}
}