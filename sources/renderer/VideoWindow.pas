unit VideoWindow;

interface

uses
  // Delphi
  Windows,
  DirectShow9,

  // 3rd party
  dglOpenGL;

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
  FRC       : HGLRC;
  FGLInited : Boolean;

function CreateVideoWindow(AMediaType : PAMMediaType) : Boolean;
procedure ReleaseVideoWindow;
procedure ShowVideoWindow;
procedure HideVideoWindow;
function CreateOpenGL : Boolean;
procedure ReleaseOpenGL;
procedure PaintVideoWindow;

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

  // Deactivate rendering context
  WriteTrace('Deactivate rendering context');
  DeactivateRenderingContext;

  FGLInited := True;
  Result := True;
  WriteTrace('CreateOpenGL.Leave with result: ' + BoolToStr(Result));
end;

procedure ReleaseOpenGL;
begin
  FGLInited := False;

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

procedure DrawQuad(W, H, TW, TH: integer);
begin
  glBegin(GL_QUADS);
  glTexCoord2f(0, 0); glVertex3f(0, H, 0);
  glTexCoord2f(TW, 0); glVertex3f(W, H, 0);
  glTexCoord2f(TW, TH); glVertex3f(W, 0, 0);
  glTexCoord2f(0, TH); glVertex3f(0, 0, 0);
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

  glColor3f(1,0,0);
  DrawQuad(W, H, 1, 1);

  SwapBuffers(FDC);
  glFinish;

  // Deactivate rendering context
  DeactivateRenderingContext;
end;

procedure ShowVideoWindow;
begin
  ShowWindow(FWnd, SW_SHOWNORMAL);
end;

procedure HideVideoWindow;
begin
  ShowWindow(FWnd, SW_HIDE);
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

initialization
  // Initialize window variables
  FillChar(FWndClass, SizeOf(FWndClass), #0);
  FWnd      := 0;
  FDC       := 0;
  FRC       := 0;
  FGLInited := False;

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
