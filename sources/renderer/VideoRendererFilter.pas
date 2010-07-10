{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Filter Unit                                      }
{       Version 1.0                                                            }
{       Date : 2010-07-10                                                      }
{                                                                              }
{==============================================================================}
{                                                                              }
{       Copyright (C) 2010 Torsten Spaete                                      }
{       All Rights Reserved                                                    }
{                                                                              }
{       Uses dglOpenGL (MPL 1.1) from the OpenGL Delphi Community              }
{         http://delphigl.com                                                  }
{                                                                              }
{       Uses DSPack (MPL 1.1) from                                             }
{         http://progdigy.com                                                  }
{                                                                              }
{==============================================================================}
{ The contents of this file are used with permission, subject to               }
{ the Mozilla Public License Version 1.1 (the "License"); you may              }
{ not use this file except in compliance with the License. You may             }
{ obtain a copy of the License at                                              }
{ http://www.mozilla.org/MPL/MPL-1.1.html                                      }
{                                                                              }
{ Software distributed under the License is distributed on an                  }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or               }
{ implied. See the License for the specific language governing                 }
{ rights and limitations under the License.                                    }
{==============================================================================}
{ History :                                                                    }
{ Version 1.0    Initial Release                                               }
{==============================================================================}

unit VideoRendererFilter;

interface

uses
  // Delphi
  Messages,
  Windows,
  SysUtils,
  Classes,
  ActiveX,

  // 3rd party
  BaseClass,
  DirectShow9;

const
  CLSID_OpenGLVideoRenderer: TGUID = '{5BA04474-46C4-4802-B52F-3EA19B75B227}';

type
  TVideoRendererFilter = class(TBCBaseRenderer, IPersist, IDispatch,
                               IBasicVideo, IBasicVideo2,
                               IAMFilterMiscFlags,
                               IVideoWindow)
  private
    // Dispatch variables
    FDispatch : TBCBaseDispatch;

    // Window variables
    FWndClass : TWndClass;
    FWnd      : HWND;
    FDC       : HDC;

    // Sample variables
    FWidth    : Integer;
    FHeight   : Integer;
    FFormat   : TVideoInfoHeader;

    function NotImplemented : HResult;

    procedure DoClear;
    procedure DoShowWindow;
    procedure DoHideWindow;

  public
    (*** TBCBaseRenderer methods ***)
    constructor Create(ObjName: String; Unk: IUnknown; out hr : HResult);
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    destructor Destroy; override;
    function CheckMediaType(MediaType: PAMMediaType): HResult; override;
    function DoRenderSample(MediaSample: IMediaSample): HResult; override;
    function SetMediaType(MediaType: PAMMediaType): HResult; override;
    function Active: HResult; override;
    function Inactive: HResult; override;
    (*** IDispatch methods ***)
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
    (*** IBasicVideo methods ***)
    function get_AvgTimePerFrame(out pAvgTimePerFrame: TRefTime): HResult; stdcall;
    function get_BitRate(out pBitRate: Longint): HResult; stdcall;
    function get_BitErrorRate(out pBitErrorRate: Longint): HResult; stdcall;
    function get_VideoWidth(out pVideoWidth: Longint): HResult; stdcall;
    function get_VideoHeight(out pVideoHeight: Longint): HResult; stdcall;
    function put_SourceLeft(SourceLeft: Longint): HResult; stdcall;
    function get_SourceLeft(out pSourceLeft: Longint): HResult; stdcall;
    function put_SourceWidth(SourceWidth: Longint): HResult; stdcall;
    function get_SourceWidth(out pSourceWidth: Longint): HResult; stdcall;
    function put_SourceTop(SourceTop: Longint): HResult; stdcall;
    function get_SourceTop(out pSourceTop: Longint): HResult; stdcall;
    function put_SourceHeight(SourceHeight: Longint): HResult; stdcall;
    function get_SourceHeight(out pSourceHeight: Longint): HResult; stdcall;
    function put_DestinationLeft(DestinationLeft: Longint): HResult; stdcall;
    function get_DestinationLeft(out pDestinationLeft: Longint): HResult; stdcall;
    function put_DestinationWidth(DestinationWidth: Longint): HResult; stdcall;
    function get_DestinationWidth(out pDestinationWidth: Longint): HResult; stdcall;
    function put_DestinationTop(DestinationTop: Longint): HResult; stdcall;
    function get_DestinationTop(out pDestinationTop: Longint): HResult; stdcall;
    function put_DestinationHeight(DestinationHeight: Longint): HResult; stdcall;
    function get_DestinationHeight(out pDestinationHeight: Longint): HResult; stdcall;
    function SetSourcePosition(Left, Top, Width, Height: Longint): HResult; stdcall;
    function GetSourcePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
    function SetDefaultSourcePosition: HResult; stdcall;
    function SetDestinationPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
    function GetDestinationPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
    function SetDefaultDestinationPosition: HResult; stdcall;
    function GetVideoSize(out pWidth, pHeight: Longint): HResult; stdcall;
    function GetVideoPaletteEntries(StartIndex, Entries: Longint; out pRetrieved: Longint; out pPalette): HResult; stdcall;
    function GetCurrentImage(var BufferSize: Longint; var pDIBImage): HResult; stdcall;
    function IsUsingDefaultSource: HResult; stdcall;
    function IsUsingDefaultDestination: HResult; stdcall;
    (*** IBasicVideo2 methods ***)
    function GetPreferredAspectRatio(out plAspectX, plAspectY: Longint): HResult; stdcall;
    (*** IAMFilterMiscFlags methods ***)
    function GetMiscFlags: ULONG; stdcall;
    (*** IVideoWindow methods ***)
    function put_Caption(strCaption: WideString): HResult; stdcall;
    function get_Caption(out strCaption: WideString): HResult; stdcall;
    function put_WindowStyle(WindowStyle: Longint): HResult; stdcall;
    function get_WindowStyle(out WindowStyle: Longint): HResult; stdcall;
    function put_WindowStyleEx(WindowStyleEx: Longint): HResult; stdcall;
    function get_WindowStyleEx(out WindowStyleEx: Longint): HResult; stdcall;
    function put_AutoShow(AutoShow: LongBool): HResult; stdcall;
    function get_AutoShow(out AutoShow: LongBool): HResult; stdcall;
    function put_WindowState(WindowState: Longint): HResult; stdcall;
    function get_WindowState(out WindowState: Longint): HResult; stdcall;
    function put_BackgroundPalette(BackgroundPalette: Longint): HResult; stdcall;
    function get_BackgroundPalette(out pBackgroundPalette: Longint): HResult; stdcall;
    function put_Visible(Visible: LongBool): HResult; stdcall;
    function get_Visible(out pVisible: LongBool): HResult; stdcall;
    function put_Left(Left: Longint): HResult; stdcall;
    function get_Left(out pLeft: Longint): HResult; stdcall;
    function put_Width(Width: Longint): HResult; stdcall;
    function get_Width(out pWidth: Longint): HResult; stdcall;
    function put_Top(Top: Longint): HResult; stdcall;
    function get_Top(out pTop: Longint): HResult; stdcall;
    function put_Height(Height: Longint): HResult; stdcall;
    function get_Height(out pHeight: Longint): HResult; stdcall;
    function put_Owner(Owner: OAHWND): HResult; stdcall;
    function get_Owner(out Owner: OAHWND): HResult; stdcall;
    function put_MessageDrain(Drain: OAHWND): HResult; stdcall;
    function get_MessageDrain(out Drain: OAHWND): HResult; stdcall;
    function get_BorderColor(out Color: Longint): HResult; stdcall;
    function put_BorderColor(Color: Longint): HResult; stdcall;
    function get_FullScreenMode(out FullScreenMode: LongBool): HResult; stdcall;
    function put_FullScreenMode(FullScreenMode: LongBool): HResult; stdcall;
    function SetWindowForeground(Focus: Longint): HResult; stdcall;
    function NotifyOwnerMessage(hwnd: Longint; uMsg, wParam, lParam: Longint): HResult; stdcall;
    function SetWindowPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
    function GetWindowPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
    function GetMinIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
    function GetMaxIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
    function GetRestorePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
    function HideCursor(HideCursor: LongBool): HResult; stdcall;
    function IsCursorHidden(out CursorHidden: LongBool): HResult; stdcall;
  end;

implementation

var
  SupportedSubTypes : array of TGUID;
  SupportedFormatTypes : array of TGUID;

function IsSubTypeSupported(ASubType : TGUID) : Boolean;
var I : Integer;
begin
  Result := False;
  For I := 0 to Length(SupportedSubTypes)-1 do
    if IsEqualGuid(SupportedSubTypes[i], ASubType) then
    begin
      Result := True;
      Exit;
    end;
end;

function IsFormatTypeSupported(AFormatType : TGUID) : Boolean;
var I : Integer;
begin
  Result := False;
  For I := 0 to Length(SupportedFormatTypes)-1 do
    if IsEqualGuid(SupportedFormatTypes[i], AFormatType) then
    begin
      Result := True;
      Exit;
    end;
end;

function CheckConnected(Pin : TBCBasePin; out Res : HRESULT) : Boolean;
begin
  if not Pin.IsConnected then
  begin
    Res := VFW_E_NOT_CONNECTED;
    Result := False;
  end else
  begin
    Res := S_OK;
    Result := True;
  end;
end;

function WndMessageProc(hWnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): UINT; stdcall;
begin
  Result := DefWindowProc(hWnd,Msg,wParam,lParam);
end;

constructor TVideoRendererFilter.Create(ObjName: String; Unk: IUnknown;
  out hr: HResult);
begin
  inherited Create(CLSID_OpenGLVideoRenderer, 'OpenGLVideoRenderer', Unk, hr);

  // Initialize base dispatch
  fDispatch := TBCBaseDispatch.Create;

  // Initialize window variables
  FillChar(FWndClass, SizeOf(FWndClass), #0);
  FWnd      := 0;
  FDC       := 0;

  // Initialize sample variables
  FWidth    := 0;
  FHeight   := 0;
  FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
end;

constructor TVideoRendererFilter.CreateFromFactory(Factory: TBCClassFactory;
  const Controller: IUnknown);
var
  hr: HRESULT;
begin
  Create(Factory.Name, Controller, hr);
end;

destructor TVideoRendererFilter.Destroy;
begin
  // Release window (Clear data)
  DoClear;

  // Release dispatch handler
  if Assigned(fDispatch) then FreeAndNil(fDispatch);
  inherited Destroy;
end;

procedure TVideoRendererFilter.DoClear;
begin
  // Release device context
  if (FDC <> 0) then
  begin
    ReleaseDC(FWnd, FDC);
    FDC := 0;
  end;

  // Destroy window
  if (FWnd <> 0) then
  begin
    DestroyWindow(FWnd);
    FWnd := 0;
  end;

  // Unregister class
  Windows.UnRegisterClass(FWndClass.lpszClassName, hInstance);

  // Clear data
  FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
  fWidth := 0;
  fHeight := 0;
end;

function TVideoRendererFilter.NotImplemented : HResult;
begin
  Result := E_POINTER;
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
end;

procedure TVideoRendererFilter.DoShowWindow;
begin
  ShowWindow(FWnd, SW_SHOWNORMAL);
end;

procedure TVideoRendererFilter.DoHideWindow;
begin
  ShowWindow(FWnd, SW_HIDE);
end;

function TVideoRendererFilter.Active: HResult;
begin
  DoShowWindow;
  Result := inherited Active;
end;

function TVideoRendererFilter.Inactive: HResult;
begin
  DoHideWindow;
  Result := inherited Inactive;
end;

function TVideoRendererFilter.CheckMediaType(MediaType: PAMMediaType): HResult;
begin
  // No mediatype, exit with pointer error
  if (MediaType = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // We want only video major types to be supported
  if (not IsEqualGUID(MediaType^.majortype, MEDIATYPE_Video)) then
  begin
    Result := E_NOTIMPL;
    Exit;
  end;

  // We want only supported sub types
  if not IsSubTypeSupported(MediaType^.subtype) then
  begin
    Result := E_NOTIMPL;
    Exit;
  end;

  // We want only supported format types
  if not IsFormatTypeSupported(MediaType^.formattype) then
  begin
    Result := E_NOTIMPL;
    Exit;
  end;

  Assert(Assigned(MediaType.pbFormat));

  Result := NOERROR;
end;

function TVideoRendererFilter.DoRenderSample(MediaSample: IMediaSample): HResult;
var
  Bits: PByte;
  R : TRect;
begin
  // No mediatype, exit with pointer error
  if (MediaSample = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // Get current sample pointer
  MediaSample.GetPointer(Bits);

  // Get client rect
  Windows.GetClientRect(fWnd, R);

  // Draw bitmap bits to window device context
  StretchDIBits(FDC,
    0, 0, R.Right - R.Left, R.Bottom - R.Top,
    0, 0, FWidth, FHeight,
    Bits, PBitmapInfo(@fFormat.bmiHeader)^,
    DIB_RGB_COLORS, SRCCOPY);

  Result := NOERROR;
end;

function TVideoRendererFilter.SetMediaType(MediaType: PAMMediaType): HResult;
var
  VIH : PVideoInfoHeader;
  VIH2: PVideoInfoHeader2;
  MPG1: PMPEG1VideoInfo;
  MPG2: PMPEG2VideoInfo;
begin
  // No mediatype, exit with pointer error
  if (MediaType = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // Release window (Clear data)
  DoClear;

  Assert(Assigned(MediaType^.pbFormat));

  // Copy video info header to FFormat, based on the given format type
  if IsEqualGuid(MediaType.formattype, FORMAT_VideoInfo) then
  begin
    VIH := PVIDEOINFOHEADER(MediaType.pbFormat);
    CopyMemory(@fFormat, VIH, SizeOf(TVideoInfoHeader));
  end
  else if IsEqualGuid(MediaType.formattype, FORMAT_VideoInfo2) then
  begin
    VIH2 := PVIDEOINFOHEADER2(MediaType.pbFormat);
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
  else if IsEqualGuid(MediaType.formattype, FORMAT_MPEGVideo) then
  begin
    MPG1 := PMPEG1VideoInfo(MediaType.pbFormat);
    CopyMemory(@FFormat, @MPG1^.Hdr, SizeOf(TVideoInfoHeader));
  end
  else if IsEqualGuid(MediaType.formattype, FORMAT_MPEG2Video) then
  begin
    MPG2 := PMPEG2VideoInfo(MediaType.pbFormat);
    CopyMemory(@FFormat, @MPG2^.Hdr, SizeOf(TVideoInfoHeader));
  end
  else
  begin
    Result := E_NOTIMPL;
    Exit;
  end;

  FWidth  := FFormat.bmiHeader.biWidth;
  FHeight := FFormat.bmiHeader.biHeight;

  // Initialize window class
  FillChar(FWndClass, SizeOf(TWndClass), #0);
  FWndClass.hInstance := hInstance;
  FWndClass.lpfnWndProc := @WndMessageProc;
  FWndClass.hIcon := LoadIcon(hInstance, 'MAINICON');
  FWndClass.lpszClassName := 'OpenGLVideoRendererClass';
  FWndClass.hCursor := LoadCursor(0, IDC_ARROW);

  // Register window class
  Windows.RegisterClass(FWndClass);

  // Create output window
  FWnd := CreateWindow(
    FWndClass.lpszClassName,
    'OpenGL Video Renderer',
    WS_CAPTION or WS_THICKFRAME, // NOT Visible
    0, 0, FWidth, FHeight,
    0, 0, hInstance, nil
    );

  // Get device context
  FDC := GetDC(FWnd);

  Result := NOERROR;
end;

{*** IDispatch methods *** taken from CBaseVideoWindow *** ctlutil.cpp ********}
function TVideoRendererFilter.GetTypeInfoCount(out Count: Integer): HResult; stdcall;
begin
  Result := fDispatch.GetTypeInfoCount(Count);
end;

function TVideoRendererFilter.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
begin
  Result := fDispatch.GetTypeInfo(IID_IVideoWindow,Index,LocaleID,TypeInfo);
end;

function TVideoRendererFilter.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
begin
  Result := fDispatch.GetIDsOfNames(IID_IVideoWindow,Names,NameCount,LocaleID,DispIDs);
end;

function TVideoRendererFilter.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
var
  pti : ITypeInfo;
begin
  if not IsEqualGUID(GUID_NULL,IID) then
  begin
    Result := DISP_E_UNKNOWNINTERFACE;
    Exit;
  end;

  Result := GetTypeInfo(0, LocaleID, pti);

  if FAILED(Result) then Exit;

  Result :=  pti.Invoke(Pointer(Self as IVideoWindow),DispID,Flags,
                        TDispParams(Params),VarResult,ExcepInfo,ArgErr);
  pti := nil;
end;

(*** IBasicVideo methods ******************************************************)
function TVideoRendererFilter.get_AvgTimePerFrame(out pAvgTimePerFrame: TRefTime): HResult; stdcall;
begin
  if not CheckConnected(FInputPin, Result) then Exit;
  pAvgTimePerFrame := fFormat.AvgTimePerFrame;
  Result := NOERROR;
end;

function TVideoRendererFilter.get_BitRate(out pBitRate: Longint): HResult; stdcall;
begin
  if not CheckConnected(FInputPin,Result) then Exit;
  pBitRate := fFormat.dwBitRate;
  Result := NOERROR;
end;

function TVideoRendererFilter.get_BitErrorRate(out pBitErrorRate: Longint): HResult; stdcall;
begin
  if not CheckConnected(FInputPin,Result) then Exit;
  pBitErrorRate := fFormat.dwBitErrorRate;
  Result := NOERROR;
end;

function TVideoRendererFilter.get_VideoWidth(out pVideoWidth: Longint): HResult; stdcall;
begin
  if not CheckConnected(FInputPin,Result) then Exit;
  pVideoWidth := fFormat.bmiHeader.biWidth;
  Result := NOERROR;
end;

function TVideoRendererFilter.get_VideoHeight(out pVideoHeight: Longint): HResult; stdcall;
begin
  if not CheckConnected(FInputPin,Result) then Exit;
  pVideoHeight := fFormat.bmiHeader.biHeight;
  Result := NOERROR;
end;

function TVideoRendererFilter.put_SourceLeft(SourceLeft: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_SourceLeft(out pSourceLeft: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_SourceWidth(SourceWidth: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_SourceWidth(out pSourceWidth: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_SourceTop(SourceTop: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_SourceTop(out pSourceTop: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_SourceHeight(SourceHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_SourceHeight(out pSourceHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_DestinationLeft(DestinationLeft: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_DestinationLeft(out pDestinationLeft: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_DestinationWidth(DestinationWidth: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_DestinationWidth(out pDestinationWidth: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_DestinationTop(DestinationTop: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_DestinationTop(out pDestinationTop: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_DestinationHeight(DestinationHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_DestinationHeight(out pDestinationHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetSourcePosition(Left, Top, Width, Height: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetSourcePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetDefaultSourcePosition: HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetDestinationPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetDestinationPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetDefaultDestinationPosition: HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetVideoSize(out pWidth, pHeight: Longint): HResult; stdcall;
begin
  if not CheckConnected(FInputPin,Result) then Exit;
  pWidth := fFormat.bmiHeader.biWidth;
  pHeight := fFormat.bmiHeader.biHeight;
  Result := NOERROR;
end;

function TVideoRendererFilter.GetVideoPaletteEntries(StartIndex, Entries: Longint; out pRetrieved: Longint; out pPalette): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetCurrentImage(var BufferSize: Longint; var pDIBImage): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.IsUsingDefaultSource: HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.IsUsingDefaultDestination: HResult; stdcall;
begin
  Result := NotImplemented();
end;

(*** IBasicVideo2 methods *****************************************************)
function TVideoRendererFilter.GetPreferredAspectRatio(out plAspectX, plAspectY: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

(*** IAMFilterMiscFlags methods ***********************************************)
function TVideoRendererFilter.GetMiscFlags: ULONG; stdcall;
begin
  Result := AM_FILTER_MISC_FLAGS_IS_RENDERER;
end;

(*** IVideoWindow methods *****************************************************)
function TVideoRendererFilter.put_Caption(strCaption: WideString): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Caption(out strCaption: WideString): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_WindowStyle(WindowStyle: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_WindowStyle(out WindowStyle: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_WindowStyleEx(WindowStyleEx: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_WindowStyleEx(out WindowStyleEx: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_AutoShow(AutoShow: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_AutoShow(out AutoShow: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_WindowState(WindowState: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_WindowState(out WindowState: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_BackgroundPalette(BackgroundPalette: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_BackgroundPalette(out pBackgroundPalette: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Visible(Visible: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Visible(out pVisible: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Left(Left: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Left(out pLeft: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Width(Width: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Width(out pWidth: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Top(Top: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Top(out pTop: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Height(Height: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_Height(out pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_Owner(Owner: OAHWND): HResult; stdcall;
begin
  if FWnd <> 0 then
  begin
    SetParent(FWnd, Owner);
    Result := NOERROR;
  end
  else
    Result := E_FAIL;
end;

function TVideoRendererFilter.get_Owner(out Owner: OAHWND): HResult; stdcall;
begin
  if FWnd <> 0 then
  begin
    Owner := GetParent(FWnd);
    Result := NOERROR;
  end
  else
    Result := E_FAIL;
end;

function TVideoRendererFilter.put_MessageDrain(Drain: OAHWND): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_MessageDrain(out Drain: OAHWND): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_BorderColor(out Color: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_BorderColor(Color: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.get_FullScreenMode(out FullScreenMode: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.put_FullScreenMode(FullScreenMode: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetWindowForeground(Focus: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.NotifyOwnerMessage(hwnd: Longint; uMsg, wParam, lParam: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.SetWindowPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetWindowPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetMinIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetMaxIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.GetRestorePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.HideCursor(HideCursor: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

function TVideoRendererFilter.IsCursorHidden(out CursorHidden: LongBool): HResult; stdcall;
begin
  Result := NotImplemented();
end;

initialization
  SetLength(SupportedSubTypes, 1);
  SupportedSubTypes[0] := MEDIASUBTYPE_RGB24;
  
  SetLength(SupportedFormatTypes, 4);
  SupportedFormatTypes[0] := FORMAT_VideoInfo;
  SupportedFormatTypes[1] := FORMAT_VideoInfo2;
  SupportedFormatTypes[2] := FORMAT_MPEGVideo;
  SupportedFormatTypes[3] := FORMAT_MPEG2Video;

  TBCClassFactory.CreateFilter(TVideoRendererFilter, 'OpenGLVideoRenderer',
    CLSID_OpenGLVideoRenderer, CLSID_LegacyAmFilterCategory, MERIT_DO_NOT_USE,
    0, nil
    );

end.
