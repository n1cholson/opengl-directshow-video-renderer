{
GL Sample renderer
Copyright (C) 2010 Torsten Spaete
Licensed under Mozilla Public License
}

unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  FileUtil,
  LResources,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ExtCtrls,
  ComCtrls,
  Menus,
  Windows,

  // 3rd party
  dglopengl,

  // Own
  GLTexture,
  sampleloader,
  GLSL;

type
  TFloatRect = record
    Left, Top,
    Right, Bottom : Single;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    IdleTimer1: TIdleTimer;
    MenuItem1: TMenuItem;
    PopupMenu1: TPopupMenu;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
  private
    { private declarations }
    FNotSupported : Boolean;

    FDC: HDC;
    FRC: HGLRC;
    FGLInited : Boolean;

    FNumSamples: integer;
    FSamples:    array of PSample;
    FSelSample:  integer;
    FCurSample:  integer;
    FSamChange: Boolean;
    FNoGLSL: Boolean;

    FTextureRect : TFloatRect;

    FVideoTex:  TTexture;
    FVideoTexY:  TTexture;
    FVideoTexU:  TTexture;
    FVideoTexV: TTexture;

    FYuvShader: TGLSL;
    FUseGLSL:   boolean;
    FPixelShaderFile,
    FVertShaderFile : String;

    FTextureFilter : Integer;

    FGLSLSupported: Boolean;
    FNonPowerOfTwoSupported : Boolean;
    FMaxTextureSize : Integer;

    procedure ReleaseTextures;
    procedure ReleaseShaders;

    procedure SetupOpenGL;

    procedure SetTextureFilter(AMode : GLUint);
    procedure DrawFrame;
    procedure UpdateSample;
  public
    { public declarations }
    procedure PosChanged(var AMsg : TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
  published
    property NotSupported : Boolean read FNotSupported;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  OVRConversion, dshowtypes, glsldebugform;

function FloatRect(ALeft, ATop, ARight, ABottom : Single) : TFloatRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

function GetNonPowerOfTwo(AValue, AMax : Integer) : Integer;
begin
  Result := 2;
  while (Result < AValue) and (Result < AMax) do
    Result := Result * 2;
end;

function NonPowerOfTwo(AWidth, AHeight, AMax : Integer) : TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := GetNonPowerOfTwo(AWidth, AMax);
  Result.Bottom := GetNonPowerOfTwo(AHeight, AMax);
end;

function FileToString(AFilename: string): string;
var
  F: TextFile;
  S: string;
begin
  Result := '';
  if FileExists(AFilename) then
  begin
    AssignFile(F, AFilename);
    Reset(F);
    while not EOF(F) do
    begin
      ReadLn(F, S);
      Result := Result + S + #13#10;
    end;
    CloseFile(F);
  end;
end;

function ExtensionAreSupported(missingExtensions : TStrings; const reqExtension : array of String) : Boolean;
var
  extensions : String;
  i : Integer;
begin
  if missingExtensions = nil then missingExtensions := TStringList.Create;
  extensions := uppercase(glGetString(GL_EXTENSIONS));
  For I := 0 to Length(reqExtension)-1 do
  begin
    if Pos(uppercase(reqExtension[I]), extensions) <= 0 then
      missingExtensions.Add(reqExtension[I]);
  end;
  Result := missingExtensions.Count = 0;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  missingExtensions : TStrings;
  s : String;
  doshutdown : Boolean;
  i : Integer;
begin
  FNotSupported := False;

  // Initialize samples
  FNumSamples := 0;
  SetLength(FSamples, 0);
  FCurSample := -1;
  FSelSample := -1;
  FSamChange := False;
  FNoGLSL := False;

  FGLInited := False;
  FTextureRect := FloatRect(0,0,0,0);

  // Load samples
  LoadSamples(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
    'samples', FSamples, FNumSamples);
  if FNumSamples > 0 then
    FSelSample := 0;

  // Initialize video texture data
  FVideoTex  := nil;
  FVideoTexY  := nil;
  FVideoTexU  := nil;
  FVideoTexV := nil;

  // Initialize opengl
  FDC := GetDC(Handle);
  FRC := CreateRenderingContext(FDC, [opDoubleBuffered], 32, 24, 0, 0, 0, 0);
  ActivateRenderingContext(FDC, FRC);
  SetupOpenGL;

  FNonPowerOfTwoSupported := dglCheckExtension('GL_ARB_texture_rectangle');
  FMaxTextureSize := 0;
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @FMaxTextureSize);

  // Shut down
  missingExtensions := TStringList.Create;
  {
  doshutdown := not ExtensionAreSupported(missingExtensions, [
    'GL_ARB_shader_objects',
    'GL_ARB_vertex_shader',
    'GL_ARB_fragment_shader',
    'GL_ARB_shading_language_100',
    'GL_ARB_texture_rectangle']);
  }
  doshutdown := False;

  FGLSLSupported :=
    dglCheckExtension('GL_ARB_shader_objects') and
    dglCheckExtension('GL_ARB_vertex_shader') and
    dglCheckExtension('GL_ARB_fragment_shader') and
    dglCheckExtension('GL_ARB_shading_language_100');

  s := 'The following opengl extension are not supported by your graphics card but needed for this application to run:'+#13#10;
  for I := 0 to missingExtensions.Count-1 do
    s := s + missingExtensions[i] + #13#10;

  missingExtensions.Free;
  if doshutdown then
  begin
    MessageBox(Handle, PChar(s), 'GL Sample Renderer', MB_OK or MB_ICONEXCLAMATION);
    FNotSupported := True;
  end;

  // No texture filtering by default
  FTextureFilter := 1;

  // Initialize GLSL
  FUseGLSL   := False;
  FPixelShaderFile := '';
  FVertShaderFile := '';

  // Display status panel GL+GLSL Version+Vendor
  StatusBar1.Panels[3].Text :=
    glGetString(GL_VERSION) + ' ' + glGetString(GL_VENDOR);

  FGLInited := True;
end;

procedure TfrmMain.ReleaseTextures;
begin
  // Release video texture and memory (RGBA texture)
  if FVideoTex <> nil then
    FreeAndNil(FVideoTex);

  // Release video texture and memory (Y texture)
  if FVideoTexY <> nil then
    FreeAndNil(FVideoTexY);

  // Release video texture and memory (U or UV texture)
  if FVideoTexU <> nil then
    FreeAndNil(FVideoTexU);

  // Release video texture and memory (V texture)
  if FVideoTexV <> nil then
    FreeAndNil(FVideoTexV);
end;

procedure TfrmMain.ReleaseShaders;
begin
  // Release GLSL
  if FYuvShader <> nil then
    FreeAndNil(FYuvShader);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
var
  I: integer;
begin
  // Release shaders
  ReleaseShaders;

  // Release textures
  ReleaseTextures;

  // Release sample memory
  FSelSample := -1;
  FCurSample := -1;
  for I := 0 to FNumSamples - 1 do
  begin
    FreeMem(FSamples[I]^.Data, FSamples[I]^.Header.DataLength);
    Dispose(FSamples[I]);
  end;
  SetLength(FSamples, 0);
  FNumSamples := 0;

  // Release opengl
  DeactivateRenderingContext;
  DestroyRenderingContext(FRC);
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
  begin
    // Toggle samples
    Inc(FSelSample);
    if FSelSample > FNumSamples - 1 then
      FSelSample := 0;
  end;
  if Key = Ord('F') then
  begin
    Inc(FTextureFilter);
    if FTextureFilter > 1 then FTextureFilter := 0;
  end;
  if (Key = Ord('G')) and (FGLSLSupported) then
  begin
    FNoGLSL := (not FNoGLSL);
    FSamChange := True;
  end;
  if Key = Ord('R') then
  begin
    FSamChange := True;
  end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
end;

procedure TfrmMain.SetupOpenGL;
begin
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  glClearColor(1, 1, 1, 1);
  glDisable(GL_CULL_FACE);
  glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
end;

procedure TfrmMain.IdleTimer1Timer(Sender: TObject);
begin
  if not FGLInited then Exit;
  DrawFrame;
end;

procedure TfrmMain.MenuItem1Click(Sender: TObject);
begin
  if not frmGLSLDebug.Visible then
    frmGLSLDebug.Show;
end;

procedure DrawQuad(W, H : Integer; TR : TFloatRect);
begin
  glBegin(GL_QUADS);
  glTexCoord2f(TR.Left, TR.Top); glVertex3f(0, 0, 0);
  glTexCoord2f(TR.Right, TR.Top); glVertex3f(W, 0, 0);
  glTexCoord2f(TR.Right, TR.Bottom); glVertex3f(W, H, 0);
  glTexCoord2f(TR.Left, TR.Bottom); glVertex3f(0, H, 0);
  glEnd;
end;

function OGLTextureFormatToString(AFormat : GLuint) : String;
begin
  case AFormat of
    GL_LUMINANCE: Result := 'GL_LUMINANCE';
    GL_LUMINANCE_ALPHA: Result := 'GL_LUMINANCE_ALPHA';
    GL_LUMINANCE8: Result := 'GL_LUMINANCE8';
    GL_RGB: Result := 'GL_RGB';
    GL_RGB8: Result := 'GL_RGB8';
    GL_RGBA: Result := 'GL_RGBA';
    GL_RGBA8: Result := 'GL_RGBA8';
    GL_BGR: Result := 'GL_BGR';
    GL_BGRA: Result := 'GL_BGRA';
  else
    Result := IntToStr(AFormat);
  end;
end;

function OGLTextureTargetToString(ATarget : GLuint) : String;
begin
  case ATarget of
    GL_TEXTURE_2D: Result := 'GL_TEXTURE_2D';
    GL_TEXTURE_RECTANGLE: Result := 'GL_TEXTURE_RECTANGLE';
  else
    Result := IntToStr(ATarget);
  end;
end;

function OGLTextureTypeToString(AType : GLuint) : String;
begin
  case AType of
    GL_UNSIGNED_BYTE: Result := 'GL_UNSIGNED_BYTE';
    GL_UNSIGNED_INT_8_8_8_8: Result := 'GL_UNSIGNED_INT_8_8_8_8';
    GL_UNSIGNED_INT_8_8_8_8_REV: Result := 'GL_UNSIGNED_INT_8_8_8_8_REV';
  else
    Result := IntToStr(AType);
  end;
end;

procedure ShowTextureInfos(ATexture : TTexture);
begin
  frmGLSLDebug.memDebug.Lines.Add('Texture dimension: ' + Format('%d x %d',[ATexture.Width, ATexture.Height]));
  frmGLSLDebug.memDebug.Lines.Add(Format('Texture format: %s / %s',[OGLTextureFormatToString(ATexture.InternalFormat), OGLTextureFormatToString(ATexture.TexFormat)]));
  frmGLSLDebug.memDebug.Lines.Add(Format('Texture target: %s',[OGLTextureTargetToString(ATexture.Target)]));
  frmGLSLDebug.memDebug.Lines.Add(Format('Texture type: %s',[OGLTextureTypeToString(ATexture.TexType)]));
end;

procedure CreateTexturesBySubtype(const ASubType : TGUID; const ATexWidth, ATexHeight : Integer; var AYTex, AUTex, AVTex : TTexture);
var
  S, S2 : Integer;
begin
  if (IsEqualGuid(ASubType, MEDIASUBTYPE_YUY2) or
      IsEqualGuid(ASubType, MEDIASUBTYPE_YUYV) or
      IsEqualGuid(ASubType, MEDIASUBTYPE_YVYU) or
      IsEqualGuid(ASubType, MEDIASUBTYPE_UYVY)) then
  begin
    // Create Y texture
    AYTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_LUMINANCE_ALPHA, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, ATexWidth, ATexHeight);
    // Create UV texture
    AUTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE, ATexWidth div 2, ATexHeight);
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_YV12) then
  begin
    S := ATexWidth * ATexHeight;
    S2 := (ATexWidth div 2) * (ATexHeight div 2);
    // Create Y texture
    AYTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_LUMINANCE8, GL_LUMINANCE, GL_UNSIGNED_BYTE, ATexWidth, ATexHeight);
    // Create U texture
    AUTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_LUMINANCE8, GL_LUMINANCE, GL_UNSIGNED_BYTE, ATexWidth div 2, ATexHeight div 2, S2, S + S2);
    // Create V texture
    AVTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_LUMINANCE8, GL_LUMINANCE, GL_UNSIGNED_BYTE, ATexWidth div 2, ATexHeight div 2, S2, S);
  end;
end;

procedure TfrmMain.UpdateSample;
var
  W, H: integer;
  s : String;
  d : Int64;
  NPOT : TRect;
  TW, TH : Integer;
begin
  if FSelSample > -1 then
  begin
    if ((FSelSample <> FCurSample) or FSamChange) and (FSamples[FSelSample] <> nil) then
    begin
      // Save texture dimensions
      W := FSamples[FSelSample]^.Header.VIH.bmiHeader.biWidth;
      H := FSamples[FSelSample]^.Header.VIH.bmiHeader.biHeight;

      if FNonPowerOfTwoSupported then
      begin
        TW := W;
        TH := H;
        FTextureRect := FloatRect(0,0,TW,TH);
      end
      else
      begin
        NPOT := NonPowerOfTwo(W, H, FMaxTextureSize);
        TW := NPOT.Right;
        TH := NPOT.Bottom;
        FTextureRect := FloatRect(0,0,(1 / TW) * W,(1 / TH) * H);
      end;

      // Release textures
      ReleaseTextures;

      // Release shaders
      ReleaseShaders;

      // Use GLSL ?
      FUseGLSL := (IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YUY2) or
                   IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YUYV) or
                   IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YVYU) or
                   IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_UYVY) or
                   IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YV12)
                  ) and (not FNoGLSL) and FGLSLSupported;

      // Clear debug infos
      frmGLSLDebug.memDebug.Lines.Clear;

      // Show infos
      frmGLSLDebug.memDebug.Lines.Add('OpenGL Version: ' + glGetString(GL_VERSION));
      frmGLSLDebug.memDebug.Lines.Add('OpenGL Vendor: ' + glGetString(GL_VENDOR));
      frmGLSLDebug.memDebug.Lines.Add('OpenGL Max Texture Size: ' + IntToStr(FMaxTextureSize));
      if FGLSLSupported then
        frmGLSLDebug.memDebug.Lines.Add('GLSL Version: ' + glGetString(GL_SHADING_LANGUAGE_VERSION));
      frmGLSLDebug.memDebug.Lines.Add('');
      frmGLSLDebug.memDebug.Lines.Add('Sample dimension: ' + Format('%d x %d',[W, H]));
      frmGLSLDebug.memDebug.Lines.Add('Sample bitcount: ' + Format('%d',[FSamples[FSelSample]^.Header.VIH.bmiHeader.biBitCount]));
      frmGLSLDebug.memDebug.Lines.Add('Sample size: ' + Format('%d',[FSamples[FSelSample]^.Header.DataLength]));
      frmGLSLDebug.memDebug.Lines.Add('Sample format: ' + Format('%s',[SubTypeToString(FSamples[FSelSample]^.Header.SubType)]));
      frmGLSLDebug.memDebug.Lines.Add('');

      // Create texture if it does not exists
      if FUseGLSL then
      begin
        // Create required textures (Y-U-V)
        CreateTexturesBySubtype(FSamples[FSelSample]^.Header.SubType, W, H, FVideoTexY, FVideoTexU, FVideoTexV);
      end
      else
      begin
        // Create RGBA texture
        if FNonPowerOfTwoSupported then
          FVideoTex  := TTexture.Create(GL_TEXTURE_RECTANGLE, GL_RGBA8, GL_BGRA, GL_UNSIGNED_BYTE, TW, TH, TW * TH * 4)
        else
          FVideoTex  := TTexture.Create(GL_TEXTURE_2D, GL_RGBA8, GL_BGRA, GL_UNSIGNED_BYTE, TW, TH, TW * TH * 4);
      end;

      if FUseGLSL then
      begin
        if FVideoTexY <> nil then
        begin
          frmGLSLDebug.memDebug.Lines.Add('Texture 0 (Y):');
          ShowTextureInfos(FVideoTexY);
          frmGLSLDebug.memDebug.Lines.Add('');
        end;

        if FVideoTexU <> nil then
        begin
          frmGLSLDebug.memDebug.Lines.Add('Texture 1 (U or UV):');
          ShowTextureInfos(FVideoTexU);
          frmGLSLDebug.memDebug.Lines.Add('');
        end;

        if FVideoTexV <> nil then
        begin
          frmGLSLDebug.memDebug.Lines.Add('Texture 2 (V):');
          ShowTextureInfos(FVideoTexV);
          frmGLSLDebug.memDebug.Lines.Add('');
        end;

        // Create new yuv shader object
        FYuvShader := TGLSL.Create;

        // Update shader filenames
        if IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YUY2) or
           IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YUYV) then
          FPixelShaderFile := 'glsl\yuy2.frag'
        else if IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YVYU) then
          FPixelShaderFile := 'glsl\yvyu.frag'
        else if IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_UYVY) then
          FPixelShaderFile := 'glsl\uyvy.frag'
        else if IsEqualGuid(FSamples[FSelSample]^.Header.SubType, MEDIASUBTYPE_YV12) then
          FPixelShaderFile := 'glsl\yv12.frag'
        else
          FPixelShaderFile := '';

        if FVertShaderFile <> '' then
        begin
          frmGLSLDebug.memDebug.Lines.Add('Vertex shader "'+FVertShaderFile+'":');
          s := FYuvShader.UploadVertexShader(
            FileToString(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
            FVertShaderFile));
          frmGLSLDebug.memDebug.Lines.Add(s);
          frmGLSLDebug.memDebug.Lines.Add('');
        end;

        if FPixelShaderFile <> '' then
        begin
          frmGLSLDebug.memDebug.Lines.Add('Pixel shader "'+FPixelShaderFile+'":');
          s := FYuvShader.UploadPixelShader(
            FileToString(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
            FPixelShaderFile));
          s := StringReplace(s, #10, #13#10, [rfReplaceAll]);
          frmGLSLDebug.memDebug.Lines.Add(s);
          frmGLSLDebug.memDebug.Lines.Add('');
        end;

        // Upload sample textures Y and U and or V
        d := GetTickCount;
        if FVideoTexY <> nil then
          FVideoTexY.Upload(FSamples[FSelSample]^.Data);
        if FVideoTexU <> nil then
          FVideoTexU.Upload(FSamples[FSelSample]^.Data);
        if FVideoTexV <> nil then
          FVideoTexV.Upload(FSamples[FSelSample]^.Data);
        frmGLSLDebug.memDebug.Lines.Add(Format('Texture upload done in: %d msecs',[GetTickCount-d]));
      end
      else
      begin
        frmGLSLDebug.memDebug.Lines.Add('Texture 0 (RGBA):');
        ShowTextureInfos(FVideoTex);
        frmGLSLDebug.memDebug.Lines.Add('');

        // Convert format to RGB
        d := GetTickCount;
        Convert(FSamples[FSelSample]^.Header.VIH,
          FSamples[FSelSample]^.Header.SubType,
          FSamples[FSelSample]^.Data,
          FSamples[FSelSample]^.Header.DataLength,
          FVideoTex.Data, TW);
        frmGLSLDebug.memDebug.Lines.Add(Format('Software color conversion done in: %d msecs',[GetTickCount-d]));

        // Upload texture
        d := GetTickCount;
        FVideoTex.Upload(FVideoTex.Data);
        frmGLSLDebug.memDebug.Lines.Add(Format('Texture upload done in: %d msecs',[GetTickCount-d]));
      end;

      // Save cur sample
      FCurSample := FSelSample;
      FSamChange := False;

      // Set caption
      StatusBar1.Panels[1].Text := SubTypeToString(FSamples[FSelSample]^.Header.SubType);
      if FUseGLSL then
        StatusBar1.Panels[1].Text := StatusBar1.Panels[1].Text + ' (GLSL)';
    end;
  end;
end;

function GLErrorToString(ACode: TGLenum): string;
begin
  case ACode of
    GL_NO_ERROR: Result      := 'No error';
    GL_INVALID_ENUM: Result  := 'Invalid enum';
    GL_INVALID_VALUE: Result := 'Invalid value';
    GL_INVALID_OPERATION: Result := 'Invalid operation';
    GL_STACK_OVERFLOW: Result := 'Stack overflow';
    GL_STACK_UNDERFLOW: Result := 'Stack underflow';
    GL_OUT_OF_MEMORY: Result := 'Out of memory';
    else
      Result := 'Unknown ' + IntToStr(ACode);
  end;
end;

function TexFilterToString(AFilter : Integer) : String;
begin
  case AFilter of
    0: Result := 'Off';
    1: Result := 'Bilinear';
  else
    Result := 'Unknown';
  end;
end;

procedure TfrmMain.SetTextureFilter(AMode : GLUint);
begin
  if FTextureFilter = 1 then
  begin
    glTexParameteri(AMode, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(AMode, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  end
  else
  begin
    glTexParameteri(AMode, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(AMode, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  end;
end;

procedure TfrmMain.DrawFrame;
var
  W, H:   integer;
  TH: integer;
begin
  W  := ClientWidth;
  H  := ClientHeight;
  TH := FSamples[FSelSample]^.Header.VIH.bmiHeader.biHeight;

  glViewPort(0, 0, W, H);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, W, H, 0, -1, 1);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  UpdateSample;

  glColor3f(1.0, 1.0, 1.0);
  if (FUseGLSL) then
  begin
    if FVideoTexY <> nil then
    begin
      FVideoTexY.Bind(0);
      SetTextureFilter(FVideoTexY.Target);
    end;
    if FVideoTexU <> nil then
    begin
      FVideoTexU.Bind(1);
      SetTextureFilter(FVideoTexU.Target);
    end;
    if FVideoTexV <> nil then
    begin
      FVideoTexV.Bind(2);
      SetTextureFilter(FVideoTexV.Target);
    end;

    FYuvShader.Bind;
    FYuvShader.SetParameter1i('Ytex', 0);
    FYuvShader.SetParameter1i('Utex', 1);
    FYuvShader.SetParameter1i('Vtex', 2);
    FYuvShader.SetParameter1f('TextureDimH', TH);
  end
  else
  begin
    FVideoTex.Bind;
    SetTextureFilter(FVideoTex.Target);
  end;

  DrawQuad(W, H - Statusbar1.Height, FTextureRect);

  if FUseGLSL then
  begin
    FYuvShader.Unbind;
    if FVideoTexV <> nil then
      FVideoTexV.Unbind(2);
    if FVideoTexU <> nil then
      FVideoTexU.Unbind(1);
    if FVideoTexY <> nil then
      FVideoTexY.Unbind(0);
  end
  else
    FVideoTex.Unbind;

  SwapBuffers(FDC);
  glFinish;

  StatusBar1.Panels[5].Text := GLErrorToString(glGetError());
  StatusBar1.Panels[7].Text := TexFilterToString(FTextureFilter);
end;

procedure TfrmMain.PosChanged(var AMsg : TWMWindowPosChanged);
begin
  inherited;
end;

initialization
  {$I mainform.lrs}

end.

