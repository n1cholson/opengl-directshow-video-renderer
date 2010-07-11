unit supports;

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
  SupportGLSL := False;
end;

initialization
  SupportMaxTextureUnits := 0;
  SupportMaxTextureSize := 0;
  SupportNonPowerOfTwoTextures := False;
  SupportGLSL := False;

end.
