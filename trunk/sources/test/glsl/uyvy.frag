#extension GL_ARB_texture_rectangle : enable

// UYVY Fragment Shader

uniform sampler2DRect Ytex;
uniform sampler2DRect Utex;
uniform float TextureDimH;

const float y_const = 0.0625;
const float vu_const = 0.5;

// YUV to RGBA function
vec4 YUVToRGBA(float y, float u, float v)
{
  vec4 rgbcolor; 
  rgbcolor.r = (1.164 * (y - y_const)) + (2.018 * (v - vu_const));
  rgbcolor.g = (1.164 * (y - y_const)) - (0.813 * (u - vu_const)) - (0.391 * (v - vu_const));
  rgbcolor.b = (1.164 * (y - y_const)) + (1.596 * (u - vu_const));
  rgbcolor.a = 0.0;
  return rgbcolor;
}

// Main entry function
void main(void) {
  float fx, fy, y, u, v, r, g, b;

  fx   = gl_TexCoord[0].x;	  
  fy   = TextureDimH-gl_TexCoord[0].y;

  vec4 ytex = texture2DRect(Ytex,vec2(fx,fy)); 
  vec4 uvtex = texture2DRect(Utex,vec2(fx/2.0,fy)); 

  y = ytex.a;
  u = uvtex.r;
  v = uvtex.b;
    
  gl_FragColor = YUVToRGBA(y, u, v);
}
