unit OVRSupports;

interface

var
  SupportMaxTextureUnits : Integer;
  SupportMaxTextureSize : Integer;
  SupportNonPowerOfTwoTextures : Boolean;
  SupportGLSL : Boolean;

procedure UpdateSupports;

implementation

uses
  dglOpengl;

procedure UpdateSupports;
begin
  glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB, @SupportMaxTextureUnits);
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @SupportMaxTextureSize);
  SupportNonPowerOfTwoTextures := dglCheckExtension('ARB_texture_non_power_of_two');
  SupportGLSL := dglCheckExtension('GL_ARB_shader_objects') and
                 dglCheckExtension('GL_ARB_vertex_shader') and
                 dglCheckExtension('GL_ARB_fragment_shader') and
                 dglCheckExtension('GL_ARB_shading_language_100');
end;

initialization
  SupportMaxTextureUnits := 0;
  SupportMaxTextureSize := 0;
  SupportNonPowerOfTwoTextures := False;
  SupportGLSL := False;

end.
