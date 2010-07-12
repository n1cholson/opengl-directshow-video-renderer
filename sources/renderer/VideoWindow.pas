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
  texture,
  supports,
  settings,
  performancecounter;

type
  TFloatRect = record
    Left, Top,
    Right, Bottom : Single;
  end;

var
  // Window variables
  FWndClass : TWndClassEx;
  FWnd      : HWND;
  FDC       : HDC;
  FFrameDurCounter  : TPerformanceCounter;
  FFpsCounter : DWord;
  FFrames : DWord;
  FFrameDrop : Integer;
  FFramesDropped : Integer;
  FFrameRate : Double;

  // Sample variables
  FWidth    : Integer;
  FHeight   : Integer;
  FFormat   : TVideoInfoHeader;
  FSubType  : TGUID;
  FSample   : PByte;
  FSampleL  : Integer; // Allocated sample buffer (W X H X 4)
  FSampleS  : Integer; // Current sample size

  // OpenGL variables
  FRC             : HGLRC;
  FGLInited       : Boolean;
  FOpenGLCaps     : String;

  FTextureTarget  : GLuint;
  FTextureDim     : TRect;

  FUpdateSample   : Boolean;
  FReloadTextures : Boolean;

  FNumTextures    : Integer;
  FTextures       : array of TTexture;
  FTextureRect    : TFloatRect;

function FloatRect(ALeft, ATop, ARight, ABottom : Single) : TFloatRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

function VideoWindowFormat : TVideoInfoHeader;
begin
  Result := FFormat;
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

procedure ClearTextures;
var
  I : Integer;
begin
  // Release textures
  if FNumTextures > 0 then
  begin
    WriteTrace(Format('Release %d textures',[FNumTextures]));
    For I := 0 to FNumTextures-1 do
      FTextures[I].Free;
    FNumTextures := 0;
    SetLength(FTextures, 0);
  end;
end;

procedure CreateTextures;
begin
  if SettingSoftwareColorConversion then
  begin
    WriteTrace('Create single texture (RGBA)');
    FNumTextures := 1;
    SetLength(FTextures, FNumTextures);
    FTextures[0] := TTexture.Create(FTextureTarget, GL_RGBA8, GL_BGRA, GL_UNSIGNED_BYTE, FTextureDim.Right, FTextureDim.Bottom, FTextureDim.Right * FTextureDim.Bottom * 4);
    FTextures[0].Upload(nil);
  end;
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

  // Reload textures
  if FReloadTextures then
  begin
    WriteTrace('Reload textures');
    FReloadTextures := False;
    // Clear textures
    ClearTextures;
    // Create textures
    CreateTextures;
  end;

  // Update sample
  if FUpdateSample then
  begin
    FUpdateSample := False;
    if FNumTextures > 0 then
    begin
      Convert(FFormat, FSubType, FSample, FSampleS, FTextures[0].Data, FTextures[0].Width);
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
  FPS : Double;
begin
  if (FFrameDrop > 0) and (SettingEnableFrameDrop) then
  begin
    Inc(FFramesDropped);
    Dec(FFrameDrop);
    Exit;
  end;

  if Assigned(FFrameDurCounter) then
    FFrameDurCounter.Start;

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

  Inc(FFrames);

  if Assigned(FFrameDurCounter) then
    FFrameDurCounter.Stop;

  // Frame drop
  if Assigned(FFrameDurCounter) then
    if FFrameDurCounter.Seconds > (1 / FFrameRate) then
      Inc(FFrameDrop);

  if (GetTickCount - FFpsCounter) > 1000 then
  begin
    // Display fps
    Fps := (FFrames * 1000) / (GetTickCount - FFpsCounter);
    SetWindowText(FWnd, PChar(Format('OpenGL Video Renderer (%s) Fps: %.2f, Framedrop: %d/%d',[FOpenGLCaps, Fps, FFrameDrop, FFramesDropped])));
    FFpsCounter := GetTickCount;
    FFrames := 0;
  end;
end;

function WndMessageProc(AhWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): UINT; stdcall;
var
  PS : TPaintStruct;
begin
  if (AMsg = WM_PAINT) and (SettingDrawOnPaint) then
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
  FrameTime : Double;
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
  WriteTrace(Format('Bitmap image size: %d x %d', [FFormat.bmiHeader.biWidth, FFormat.bmiHeader.biHeight]));
  WriteTrace(Format('Using image size: %d x %d', [FWidth, FHeight]));

  FSubType := AMediaType^.subtype;
  WriteTrace(Format('Using subtype: %s', [SGUIDToString(FSubType)]));

  WriteTrace('Average frame time: ' + IntToStr(FFormat.AvgTimePerFrame));
  FrameTime := FFormat.AvgTimePerFrame / 10000000;
  WriteTrace('Frame time: ' + FloatToStr(FrameTime));
  FFrameRate := 1.0 / FrameTime; 
  WriteTrace('Frames rate: ' + FloatToStr(FFrameRate));

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

  // Create performance counter
  WriteTrace('Initialize performance counters');
  FFrameDurCounter := TPerformanceCounter.Create;

  WriteTrace('Create opengl');
  if not CreateOpenGL then
  begin
    WriteTrace('Could not create opengl!');
    Exit;
  end;

  FFpsCounter := GetTickCount;
  FFrames := 0;
  FFrameDrop := 0;
  FFramesDropped := 0;

  Result := True;

  WriteTrace('CreateVideoWindow.Leave with result: ' + BoolToStr(Result, True));
end;

procedure ReleaseVideoWindow;
begin
  WriteTrace('DoClear.Enter');

  // Release opengl
  WriteTrace('Release opengl');
  ReleaseOpenGL;

  // Release performance counter
  WriteTrace('Release performance counter');
  FFrameDurCounter.Free;

  FFrames := 0;
  FFrameDrop := 0;
  FFrameRate := 0;

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

  WriteTrace('Update supports');
  UpdateSupports;

  WriteTrace('Opengl max texture units: ' + IntToStr(SupportMaxTextureUnits));
  WriteTrace('Opengl max texture size: ' + IntToStr(SupportMaxTextureSize));
  WriteTrace('Opengl non power of two supported: ' + BoolToStr(SupportNonPowerOfTwoTextures, True));
  WriteTrace('Opengl glsl supported: ' + BoolToStr(SupportGLSL, True));

  // Get max texture units and check for at least 3
  if (SupportMaxTextureUnits < 0) then
  begin
    WriteTrace('No opengl texture support!');
    Exit;
  end;

  // Get max texture size and check for reached image space
  if (SupportMaxTextureSize <= 0) or ((FWidth > SupportMaxTextureSize) or (FHeight > SupportMaxTextureSize)) then
  begin
    WriteTrace(Format('No opengl texture support for dimension %d x %d!',[FWidth, FHeight]));
    Exit;
  end;

  if not SupportNonPowerOfTwoTextures then
  begin
    NPOT := NonPowerOfTwo(FWidth, FHeight, SupportMaxTextureSize);
    FTextureDim.Right := NPOT.Right;
    FTextureDim.Bottom := NPOT.Bottom;
    FTextureTarget := GL_TEXTURE_2D;
    FTextureRect := FloatRect(0,0,(1 / NPOT.Right) * FWidth,(1 / NPOT.Bottom) * FHeight);
  end
  else
  begin
    WriteTrace('Using non power of two size: ' + Format('%d x %d',[FWidth, FHeight]));
    FTextureRect.Left := 0;
    FTextureRect.Top := 0;
    FTextureRect.Right := FWidth;
    FTextureRect.Bottom := FHeight;
    FTextureDim.Right := FWidth;
    FTextureDim.Bottom := FHeight;
    FTextureTarget := GL_TEXTURE_RECTANGLE_ARB;
  end;

  // Detect settings
  SettingSoftwareColorConversion := True{not SupportGLSL};
  SettingEnableFrameDrop := True;
  SettingDrawOnPaint := True;

  // Force reloading textures
  FReloadTextures := True;

  WriteTrace('Using texture rect: ' + Format('%f %f %f %f',[FTextureRect.Left, FTextureRect.Top, FTextureRect.Right, FTextureRect.Bottom]));
  WriteTrace('Using texture dimension: ' + Format('%d x %d',[FTextureDim.Right, FTextureDim.Bottom]));

  // Deactivate rendering context
  WriteTrace('Deactivate rendering context');
  DeactivateRenderingContext;

  FGLInited := True;
  Result := True;
  FOpenGLCaps := 'Software';
  WriteTrace('CreateOpenGL.Leave with result: ' + BoolToStr(Result, True));
end;

procedure ReleaseOpenGL;
begin
  FGLInited := False;
  FOpenGLCaps := '';

  // Clear textures
  ClearTextures;

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
  WriteTrace('SetVideoWindowOwner.Leave with result: ' + BoolToStr(Result, True));
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

procedure SaveSampleToFileSystem(HDR : TVideoInfoHeader; SubType : TGUID; Sample : IMediaSample; Time : Int64);
var
  S : String;
  M : TStream;
  L : Integer;
  B : PByte;
begin
  S := 'c:\sample_'+SubTypeToString(SubType)+'.data';
  if not FileExists(S) then
  begin
    L := Sample.GetActualDataLength;
    if Succeeded(Sample.GetPointer(B)) then
    begin
      M := TFileStream.Create(S, fmCreate);
      M.Write(HDR, SizeOf(TVideoInfoHeader));
      M.Write(SubType, SizeOf(TGUID));
      M.Write(L, SizeOf(Integer));
      M.WriteBuffer(B^, L);
      M.Free;
    end;
  end;
end;

function EncodeReferenceTime(Secs : Double) : Int64;
begin
  Result := Trunc(Secs * 10000000);
end;

procedure UpdateSample(ASample : IMediaSample);
var
  Bits: PByte;
  R : TRect;
{  S, E : Int64; }
begin
  // Get current sample pointer
  FSampleS := ASample.GetSize;
  ASample.GetPointer(Bits);

  {
  if Succeeded(ASample.GetTime(S, E)) then
  begin
    if S >= EncodeReferenceTime(120) then
    begin
      SaveSampleToFileSystem(fFormat, fSubType, ASample, S);
    end;
  end;
  }

  // Move sample to sample buffer
  Assert(FSampleS <= FSampleL);
  Move(Bits^, FSample^, FSampleS);

  // Update sample flag
  FUpdateSample := True;

  // Paint window
  if SettingDrawOnPaint then
  begin
    Windows.GetClientRect(FWnd, R);
    InvalidateRect(FWnd, @R, False);
  end
  else
    PaintVideoWindow;
end;

initialization
  // Initialize window variables
  FillChar(FWndClass, SizeOf(FWndClass), #0);
  FWnd      := 0;
  FDC       := 0;
  FRC       := 0;
  FGLInited := False;
  FOpenGLCaps := '';

  FTextureTarget := 0;
  FTextureDim := Rect(0,0,0,0);

  FNumTextures := 0;
  SetLength(FTextures, 0);
  FillChar(FTextureRect, SizeOf(FTextureRect), #0);

  FUpdateSample := False;
  FReloadTextures := False;

  FFrameDurCounter := nil;
  FFpsCounter := 0;
  FFrames := 0;
  FFrameDrop := 0;
  FFramesDropped := 0;
  FFrameRate := 0;

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
