unit VideoWindow;

interface

uses
  // Delphi
  Windows,
  DirectShow9,

  // 3rd party
  dglOpenGL;

function CreateVideoWindow(AMediaType : PAMMediaType) : Boolean;
procedure ReleaseVideoWindow;
function ShowVideoWindow : Boolean;
function HideVideoWindow : Boolean;
function CreateOpenGL : Boolean;
procedure ReleaseOpenGL;
procedure UpdateSample(ASample : IMediaSample);
function VideoWindowFormat : TVideoInfoHeader;
function GetVideoWindowVisible : Boolean;
function SetVideoWindowVisible(AVis : Boolean) : Boolean;
function GetVideoWindowOwner : HWND;
function SetVideoWindowOwner(AOwner : HWND) : Boolean;
function SetVideoWindowPosition(ALeft, ATop, AWidth, AHeight : Integer) : Boolean;

implementation

uses
  // Delphi
  Classes,
  SysUtils,
  Messages,

  // Own
  utils,
  conversion,
  glsl,
  texture;

type
  TFloatRect = record
    Left,
    Top,
    Right,
    Bottom : Single;
  end;

var
  // Window variables
  FWndClass : TWndClassEx;
  FWnd      : HWND;
  FDC       : HDC;

  // Sample variables
  FWidth    : Integer;
  FHeight   : Integer;
  FFormat   : TVideoInfoHeader;
  FSubType  : TGUID;
  FSample   : PByte;
  FSampleL  : Integer; // Allocated sample buffer (W X H X 4)
  FSampleS  : Integer; // Current sample size

  // OpenGL variables
  FRC            : HGLRC;
  FGLInited      : Boolean;
  FNonPowOfTwo   : Boolean;
  FNumTextures   : Integer;
  FTextures      : array of TTexture;
  FTextureRect   : TFloatRect;
  FUpdateSample  : Boolean;

function VideoWindowFormat : TVideoInfoHeader;
begin
  Result := FFormat;
end;

procedure DrawQuad(W, H : Integer; TexRect : TFloatRect);
begin
  glBegin(GL_QUADS);
  glTexCoord2f(TexRect.Left, TexRect.Top); glVertex3f(0, 0, 0);
  glTexCoord2f(TexRect.Right, TexRect.Top); glVertex3f(W, 0, 0);
  glTexCoord2f(TexRect.Right, TexRect.Bottom); glVertex3f(W, H, 0);
  glTexCoord2f(TexRect.Left, TexRect.Bottom); glVertex3f(0, H, 0);
  glEnd;
end;

procedure DrawOpenGL(AClientRect : TRect);
var
  W, H : Integer;
begin
  // Activate rendering context
  ActivateRenderingContext(FDC, FRC);

  W := AClientRect.Right - AClientRect.Left;
  H := AClientRect.Bottom - AClientRect.Top;

  glViewPort(0, 0, W, H);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, W, H, 0, -1, 1);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  // Update sample
  if FUpdateSample then
  begin
    FUpdateSample := False;
    if FNumTextures > 0 then
    begin
      Convert(FFormat, FSubType, FSample, FSampleS, FTextures[0].Data, FTextures[0].Height);
      FTextures[0].Upload(FTextures[0].Data);
    end;
  end;

  glColor3f(1,1,1);
  if FNumTextures > 0 then
    FTextures[0].Bind()
  else
    glDisable(GL_TEXTURE_2D);

  DrawQuad(W, H, FTextureRect);

  if FNumTextures > 0 then
    FTextures[0].Unbind();

  SwapBuffers(FDC);
  glFinish;

  // Deactivate rendering context
  DeactivateRenderingContext;
end;

procedure PaintVideoWindow;
var
  R : TRect;
begin
  Windows.GetClientRect(FWnd, R);
  if FGLInited then
    DrawOpenGL(R)
  else
  begin
    // Draw bitmap bits to window device context
    if (IsEqualGuid(FSubType, MEDIASUBTYPE_RGB24) or
        IsEqualGuid(FSubType, MEDIASUBTYPE_RGB32)) and
        (FSampleS > 0) then
    begin
      StretchDIBits(FDC,
        0, 0, R.Right - R.Left, R.Bottom - R.Top,
        0, 0, FWidth, FHeight,
        FSample, PBitmapInfo(@fFormat.bmiHeader)^,
        DIB_RGB_COLORS, SRCCOPY);
    end
    else
      FillRect(FDC, Rect(0, 0, R.Right - R.Left, R.Bottom - R.Top), HBRUSH(COLOR_BTNFACE));
  end;
end;

function WndMessageProc(AhWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): UINT; stdcall;
var
  PS : TPaintStruct;
begin
  if AMsg = WM_PAINT then
  begin
    Result := 0;
    BeginPaint(FWnd, PS);
    PaintVideoWindow;
    EndPaint(FWnd, PS);
  end
  else
    Result := DefWindowProc(AhWnd,AMsg,AwParam,AlParam);
end;

function CreateVideoWindow(AMediaType : PAMMediaType) : Boolean;
var
  VIH : PVideoInfoHeader;
  VIH2: PVideoInfoHeader2;
  MPG1: PMPEG1VideoInfo;
  MPG2: PMPEG2VideoInfo;
begin
  WriteTrace('CreateVideoWindow.Enter');
  Result := False;

  WriteTrace('Check mediatype format pointer');
  Assert(Assigned(AMediaType^.pbFormat));

  // Copy video info header to FFormat, based on the given format type
  if IsEqualGuid(AMediaType^.formattype, FORMAT_VideoInfo) then
  begin
    WriteTrace('Handle video info header');
    VIH := PVIDEOINFOHEADER(AMediaType^.pbFormat);
    CopyMemory(@fFormat, VIH, SizeOf(TVideoInfoHeader));
  end
  else if IsEqualGuid(AMediaType^.formattype, FORMAT_VideoInfo2) then
  begin
    WriteTrace('Handle video info header 2');
    VIH2 := PVIDEOINFOHEADER2(AMediaType^.pbFormat);
    with VIH2^ do
    begin
      FFormat.rcSource := rcSource;
      FFormat.rcTarget := rcTarget;
      FFormat.dwBitRate := dwBitRate;
      FFormat.dwBitErrorRate := dwBitErrorRate;
      FFormat.AvgTimePerFrame := AvgTimePerFrame;
      FFormat.bmiHeader := bmiHeader;
    end;
  end
  else if IsEqualGuid(AMediaType^.formattype, FORMAT_MPEGVideo) then
  begin
    WriteTrace('Handle mpeg 1 video info');
    MPG1 := PMPEG1VideoInfo(AMediaType^.pbFormat);
    CopyMemory(@FFormat, @MPG1^.Hdr, SizeOf(TVideoInfoHeader));
  end
  else if IsEqualGuid(AMediaType^.formattype, FORMAT_MPEG2Video) then
  begin
    WriteTrace('Handle mpeg 2 video info');
    MPG2 := PMPEG2VideoInfo(AMediaType^.pbFormat);
    CopyMemory(@FFormat, @MPG2^.Hdr, SizeOf(TVideoInfoHeader));
  end
  else
  begin
    WriteTrace('Unsupported format type: ' + FGuidToString(AMediaType^.formattype));
    Exit;
  end;

  WriteTrace('Using major type: ' + MGuidToString(AMediaType^.majortype));
  WriteTrace('Using sub type: ' + SGuidToString(AMediaType^.subtype));
  WriteTrace('Using format type: ' + FGuidToString(AMediaType^.formattype));

  FWidth  := Abs(FFormat.bmiHeader.biWidth);
  FHeight := Abs(FFormat.bmiHeader.biHeight);
  WriteTrace(Format('Using image size: %d x %d', [FWidth, FHeight]));

  FSubType := AMediaType^.subtype;
  WriteTrace(Format('Using subtype: %s', [SGUIDToString(FSubType)]));

  // Create sample buffer
  FSampleS := 0;
  FSampleL := FWidth * FHeight * 4;
  FSample := AllocMem(FSampleL);

  // Initialize window class
  WriteTrace('Initialize window class');
  FillChar(FWndClass, SizeOf(TWndClassEx), #0);
  FWndClass.cbSize := SizeOf(TWndClassEx);
  FWndClass.hInstance := hInstance;
  FWndClass.lpfnWndProc := @WndMessageProc;
  FWndClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  FWndClass.lpszClassName := 'OpenGLVideoRendererClass';
  FWndClass.hCursor := LoadCursor(0, IDC_ARROW);
  FWndClass.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;

  // Register window class
  WriteTrace('Register window class');
  if Windows.RegisterClassEx(FWndClass) = 0 then
  begin
    WriteTrace('Window class could not be registered: ' + SysErrorMessage(GetLastError()));
    Exit;
  end;

  // Create output window
  WriteTrace('Create window');
  FWnd := CreateWindow(
    FWndClass.lpszClassName,
    'OpenGL Video Renderer',
    WS_CAPTION or WS_THICKFRAME,
    0, 0, 320, 240,
    0, 0, hInstance, nil
    );

  // Window could not be created  
  if FWnd = 0 then
  begin
    WriteTrace('Window could not be created: ' + SysErrorMessage(GetLastError()));
    Exit;
  end;
  WriteTrace('Window handle: ' + IntToStr(FWnd));

  // Get device context
  WriteTrace('Get device context');
  FDC := GetDC(FWnd);

  // Device context could not be detected  
  if FDC = 0 then
  begin
    WriteTrace('Device context could not be created: ' + SysErrorMessage(GetLastError()));
    Exit;
  end;
  WriteTrace('Device context: ' + IntToStr(FDC));

  WriteTrace('Create opengl');
  if not CreateOpenGL then
  begin
    WriteTrace('Could not create opengl!');
    Exit;
  end;

  Result := True;

  WriteTrace('CreateVideoWindow.Leave with result: ' + BoolToStr(Result));
end;

procedure ReleaseVideoWindow;
begin
  WriteTrace('DoClear.Enter');

  // Release opengl
  WriteTrace('Release opengl');
  ReleaseOpenGL;

  // Release device context
  if (FDC <> 0) then
  begin
    WriteTrace('Release device context');
    ReleaseDC(FWnd, FDC);
    FDC := 0;
  end;

  // Destroy window
  if (FWnd <> 0) then
  begin
    WriteTrace('Destroy window');
    DestroyWindow(FWnd);
    FWnd := 0;
  end;

  // Unregister class
  if FWndClass.hInstance <> 0 then
  begin
    WriteTrace('Unregister class');
    Windows.UnRegisterClass(FWndClass.lpszClassName, hInstance);
  end;

  // Clear data
  WriteTrace('Clear data');
  FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
  fWidth := 0;
  fHeight := 0;
  FSubType := GUID_NULL;
  if FSampleL > 0 then
  begin
    FreeMem(FSample, FSampleL);
    FSample := nil;
    FSampleL := 0;
  end;
  FSampleS := 0;

  WriteTrace('DoClear.Leave');
end;

procedure SetupOpenGL;
begin
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  glClearColor(1, 1, 1, 1);
  glDisable(GL_CULL_FACE);
  glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
end;

function CreateOpenGL : Boolean;
var
  NPOT : TRect;
  MaxTextureSize : GLint;
  TexTextureUnits : GLint;
  TexDimW, TexDimH : Integer;
  Target : GLuint;
begin
  WriteTrace('CreateOpenGL.Enter');
  Result := False;

  // Create rendering context
  WriteTrace('Create rendering context');
  FRC := CreateRenderingContext(FDC, [opDoubleBuffered], 32, 16, 0, 0, 0, 0);

  // Rendering context could not be created
  if FRC = 0 then
  begin
    WriteTrace('Rendering context could not be created!');
    Exit;
  end;
  WriteTrace('Rendering context: ' + IntToStr(FRC));

  // Activate rendering context
  WriteTrace('Activate rendering context');
  ActivateRenderingContext(FDC, FRC);

  WriteTrace('Setup opengl');
  SetupOpenGL;

  // Get max texture units and check for at least 3
  glGetIntegerv(GL_MAX_TEXTURE_UNITS_ARB, @TexTextureUnits);
  WriteTrace('Opengl max texture units: ' + IntToStr(TexTextureUnits));
  if (TexTextureUnits < 0) then
  begin
    WriteTrace('No opengl texture support!');
    Exit;
  end;

  // Get max texture size and check for reached image space
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @MaxTextureSize);
  WriteTrace('Opengl max texture size: ' + IntToStr(MaxTextureSize));
  if (MaxTextureSize <= 0) or ((FWidth > MaxTextureSize) or (FHeight > MaxTextureSize)) then
  begin
    WriteTrace(Format('No opengl texture support for dimension %d x %d!',[FWidth, FHeight]));
    Exit;
  end;

  FNonPowOfTwo := dglCheckExtension('ARB_texture_non_power_of_two');
  WriteTrace('Opengl non power of two supported: ' + BoolToStr(FNonPowOfTwo, True));

  if not FNonPowOfTwo then
  begin
    WriteTrace('Calculate non power of two from size: ' + Format('%d x %d',[FWidth, FHeight]));
    NPOT := NonPowerOfTwo(FWidth, FHeight, MaxTextureSize);
    WriteTrace('Non-Power-Of-Two size: ' + Format('%d x %d',[NPOT.Right, NPOT.Bottom]));
    FTextureRect.Left := 0;
    FTextureRect.Top := 0;
    FTextureRect.Right := (1 / NPOT.Right) * FWidth;
    FTextureRect.Bottom := (1 / NPOT.Bottom) * FHeight;
    TexDimW := NPOT.Right;
    TexDimH := NPOT.Bottom;
    Target := GL_TEXTURE_2D;
  end
  else
  begin
    WriteTrace('Using non power of two size: ' + Format('%d x %d',[FWidth, FHeight]));
    FTextureRect.Left := 0;
    FTextureRect.Top := 0;
    FTextureRect.Right := FWidth;
    FTextureRect.Bottom := FHeight;
    TexDimW := FWidth;
    TexDimH := FHeight;
    Target := GL_TEXTURE_RECTANGLE_ARB;
  end;

  WriteTrace('Using texture rect: ' + Format('%f %f %f %f',[FTextureRect.Left, FTextureRect.Top, FTextureRect.Right, FTextureRect.Bottom]));

  WriteTrace('Create single texture (RGBA)');
  FNumTextures := 1;
  SetLength(FTextures, FNumTextures);
  FTextures[0] := TTexture.Create(Target, GL_RGBA8, GL_BGRA, GL_UNSIGNED_BYTE, TexDimW, TexDimH, TexDimW * TexDimH * 4);

  // Deactivate rendering context
  WriteTrace('Deactivate rendering context');
  DeactivateRenderingContext;

  FGLInited := True;
  Result := True;
  WriteTrace('CreateOpenGL.Leave with result: ' + BoolToStr(Result));
end;

procedure ReleaseOpenGL;
var
  I : Integer;
begin
  FGLInited := False;

  // Release textures
  if FNumTextures > 0 then
  begin
    WriteTrace(Format('Release %d textures',[FNumTextures]));
    For I := 0 to FNumTextures-1 do
      FTextures[I].Free;
    FNumTextures := 0;
    SetLength(FTextures, 0);
  end;

  // Release rendering context
  if FRC <> 0 then
  begin
    WriteTrace('Deactivate rendering context');
    DeactivateRenderingContext;

    WriteTrace('Release rendering context');
    DestroyRenderingContext(FRC);
    FRC := 0;
  end;
end;

function ShowVideoWindow : Boolean;
begin
  if FWnd <> 0 then
  begin
    ShowWindow(FWnd, SW_SHOWNORMAL);
    Result := True;
  end
  else
    Result := False;
end;

function HideVideoWindow : Boolean;
begin
  if FWnd <> 0 then
  begin
    ShowWindow(FWnd, SW_HIDE);
    Result := True;
  end
  else
    Result := False;
end;

function GetVideoWindowVisible : Boolean;
begin
  if FWnd <> 0 then
    Result := IsWindowVisible(FWnd)
  else
    Result := False;
end;

function SetVideoWindowVisible(AVis : Boolean) : Boolean;
begin
  if FWnd <> 0 then
  begin
    if AVis then
      Result := ShowVideoWindow
    else
      Result := HideVideoWindow;
  end
  else
    Result := False;
end;

function GetVideoWindowOwner : HWND;
begin
  if FWnd <> 0 then
    Result := GetParent(FWnd)
  else
    Result := 0;
end;

function SetVideoWindowOwner(AOwner : HWND) : Boolean;
begin
  WriteTrace('SetVideoWindowOwner.Enter');
  Result := False;
  if FWnd <> 0 then
  begin
    // Release opengl
    WriteTrace('Release opengl');
    ReleaseOpenGL;

    // Change parent
    WriteTrace('Set new parent');
    SetParent(FWnd, AOwner);
    
    // Release opengl
    WriteTrace('Create opengl');
    if CreateOpenGL() then
      Result := True
    else
      WriteTrace('Could not create opengl!');
  end
  else
    WriteTrace('No window handle present!');
  WriteTrace('SetVideoWindowOwner.Leave with result: ' + BoolToStr(Result));
end;

function SetVideoWindowPosition(ALeft, ATop, AWidth, AHeight : Integer) : Boolean;
begin
  if FWnd <> 0 then
  begin
    MoveWindow(FWnd, ALeft, ATop, AWidth, AHeight, True);
    Result := True;
  end
  else
    Result := False;
end;

procedure UpdateSample(ASample : IMediaSample);
var
  Bits: PByte;
  R : TRect;
begin
  // Get current sample pointer
  FSampleS := ASample.GetSize;
  ASample.GetPointer(Bits);

  // Move sample to sample buffer
  Assert(FSampleS <= FSampleL);
  Move(Bits^, FSample^, FSampleS);

  // Update sample flag
  FUpdateSample := True;

  // Paint window
  Windows.GetClientRect(FWnd, R);
  InvalidateRect(FWnd, @R, False);
end;

initialization
  // Initialize window variables
  FillChar(FWndClass, SizeOf(FWndClass), #0);
  FWnd      := 0;
  FDC       := 0;
  FRC       := 0;
  FGLInited := False;
  FNumTextures := 0;
  SetLength(FTextures, 0);
  FNonPowOfTwo := False;
  FillChar(FTextureRect, SizeOf(FTextureRect), #0);
  FUpdateSample := False;

  // Initialize sample variables
  WriteTrace('Clear data');
  FWidth    := 0;
  FHeight   := 0;
  FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
  FSubType := GUID_NULL;
  FSample := nil;
  FSampleL := 0;
  FSampleS := 0;

end.