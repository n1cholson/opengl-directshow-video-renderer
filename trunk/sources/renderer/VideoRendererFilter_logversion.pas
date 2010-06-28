{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Filter Class                                     }
{       Version 1.0                                                            }
{       Date : 2010-06-23                                                      }
{                                                                              }
{==============================================================================}
{                                                                              }
{       Copyright (C) 2010 Torsten Spaete                                      }
{       All Rights Reserved                                                    }
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

{$include videorenderer_compiler.inc}

uses
  // Delphi
  Windows, SysUtils, Classes, Forms, ActiveX, Graphics, Messages,

  // 3rd party
  BaseClass, DirectShow9,

  // Own
  formRendererBase;

const
  DEFWIDTH = 320;                    // Initial window width
  DEFHEIGHT = 240;                   // Initial window height

type
  TGUIDArray = array of TGUID;
  TVideoRenderer = class(TBCBaseVideoRenderer, IPersist, IVideoWindow, IDispatch,
                         IBasicVideo, IBasicVideo2, IAMFilterMiscFlags)
  private
    fAutoShow : Boolean;
    fDispatch : TBCBaseDispatch;
    fFormat   : TVideoInfoHeader;
    fRenderer : TRendererBaseForm;
  protected
    function GetGUID : TGUID; virtual; abstract;
    function CreateRenderer : TRendererBaseForm; virtual; abstract;
    function IsConnected(out ARes : HResult) : Boolean;
    function GetSupportedSubTypes(out ASubTypes : TGUIDArray) : Boolean; virtual; abstract;
  public
    constructor Create(ObjName: String; Unk: IUnknown; out hr : HResult);
    constructor CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown); override;
    destructor Destroy; override;
    function CheckMediaType(MediaType: PAMMediaType): HResult; override;
    function DoRenderSample(MediaSample: IMediaSample): HResult; override;
    procedure OnReceiveFirstSample(MediaSample: IMediaSample); override;
    function SetMediaType(MediaType: PAMMediaType): HResult; override;
    function Active: HResult; override;
    function Inactive: HResult; override;
    (*** IDispatch methods ***)
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
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
    function GetVideoSize(out pWidth, Height: Longint): HResult; stdcall;
    function GetVideoPaletteEntries(StartIndex, Entries: Longint; out pRetrieved: Longint; out pPalette): HResult; stdcall;
    function GetCurrentImage(var BufferSize: Longint; var pDIBImage): HResult; stdcall;
    function IsUsingDefaultSource: HResult; stdcall;
    function IsUsingDefaultDestination: HResult; stdcall;
    (*** IBasicVideo2 methods ***)
    function GetPreferredAspectRatio(out plAspectX, plAspectY: Longint): HResult; stdcall;
    (*** IAMFilterMiscFlags methods ***)
    function GetMiscFlags: ULONG; stdcall;
  published
    property RendererForm : TRendererBaseForm read fRenderer;
  end;

implementation

uses
  utils;

procedure LogLine(S : String);
begin
  WriteTrace(S);
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

function TVideoRenderer.IsConnected(out ARes : HResult) : Boolean;
begin
  Result := CheckConnected(FInputPin, ARes);
end;

constructor TVideoRenderer.Create(ObjName: String; Unk: IUnknown; out hr: HResult);
begin
  LogLine('Enter Create');
  inherited Create(GetGUID(), 'Custom Video Renderer', Unk, hr);
  fDispatch := TBCBaseDispatch.Create;
  fRenderer := CreateRenderer();
  fAutoShow := False;
  LogLine('Leave Create');
end;

constructor TVideoRenderer.CreateFromFactory(Factory: TBCClassFactory; const Controller: IUnknown);
var
  hr: HRESULT;
begin
  LogLine('Enter CreateFromFactory');
  Create(Factory.Name, Controller, hr);
  LogLine('Leave CreateFromFactory');
end;

destructor TVideoRenderer.Destroy;
begin
  LogLine('Enter Destroy');
  if Assigned(fDispatch) then FreeAndNil(fDispatch);
  if Assigned(fRenderer) then FreeAndNil(fRenderer);
  inherited Destroy;
  LogLine('Leave Destroy');
end;

function TVideoRenderer.Active: HResult;
begin
  LogLine('Enter Active');
  if fAutoShow then fRenderer.Show;
  Result := inherited Active;
  LogLine('Leave Active');
end;

function TVideoRenderer.Inactive: HResult;
begin
  LogLine('Enter Inactive');
  Result := inherited Inactive;
  LogLine('Leave Inactive');
end;

function TVideoRenderer.CheckMediaType(MediaType: PAMMediaType): HResult;
var
  SubTypes : TGUIDArray;
  I : Integer;
begin
  LogLine('Enter CheckMediaType');
  if (MediaType = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  // Check major type
  if not IsEqualGUID(MediaType.majortype, MEDIATYPE_Video) then
  begin
    LogLine('Unsupported major type: ' + MGuidToString(MediaType.majortype));
    Result := E_INVALIDARG;
    Exit;
  end;

  // Check format type
  if not (IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo) or
          IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo2) or
          IsEqualGUID(MediaType.formattype, FORMAT_MPEGVideo) or
          IsEqualGUID(MediaType.formattype, FORMAT_MPEG2VIDEO)
          ) then
  begin
    LogLine('Unsupported format type: ' + FGuidToString(MediaType.formattype));
    Result := E_INVALIDARG;
    Exit;
  end;

  // Check sub type
  SetLength(SubTypes, 0);
  GetSupportedSubTypes(SubTypes);
  For I := 0 to Length(SubTypes)-1 do
  begin
    if IsEqualGuid(MediaType.subtype, SubTypes[i]) then
    begin
      Result := NOERROR;
      Exit;
    end;
  end;

  LogLine('Unsupported sub type: ' + SGuidToString(MediaType.subtype));
  Result := E_INVALIDARG;
  LogLine('Leave CheckMediaType');
end;

function TVideoRenderer.DoRenderSample(MediaSample: IMediaSample): HResult;
begin
  LogLine('Enter DoRenderSample');
  if (MediaSample = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;
  fRenderer.DoRenderSample(MediaSample);
  Result := NOERROR;
  LogLine('Leave DoRenderSample');
end;

procedure TVideoRenderer.OnReceiveFirstSample(MediaSample: IMediaSample);
begin
  LogLine('Enter OnReceiveFirstSample');
  DoRenderSample(MediaSample);
  LogLine('Leave OnReceiveFirstSample');
end;

function TVideoRenderer.SetMediaType(MediaType: PAMMediaType): HResult;
var
  VIH: PVIDEOINFOHEADER;
  VIH2: PVIDEOINFOHEADER2;
  MPGVI: PMPEG1VIDEOINFO;
  MPGVI2: PMPEG2VIDEOINFO;
begin
  LogLine('Enter SetMediaType');
  if (MediaType = nil) then
  begin
    Result := E_POINTER;
    Exit;
  end;

  if IsEqualGuid(MediaType.formattype, FORMAT_VideoInfo) then
  begin
    VIH := PVIDEOINFOHEADER(MediaType.pbFormat);
    if (VIH = nil) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    CopyMemory(@fFormat,VIH,SizeOf(TVideoInfoHeader));
  end
  else if IsEqualGuid(MediaType.formattype, FORMAT_VideoInfo2) then
  begin
    VIH2 := PVIDEOINFOHEADER2(MediaType.pbFormat);
    if (VIH2 = nil) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
    fFormat.rcSource := VIH2^.rcSource;
    fFormat.rcTarget := VIH2^.rcTarget;
    fFormat.dwBitRate := VIH2^.dwBitRate;
    fFormat.dwBitErrorRate := VIH2^.dwBitErrorRate;
    fFormat.AvgTimePerFrame := VIH2^.AvgTimePerFrame;
    fFormat.bmiHeader := VIH2^.bmiHeader;
  end
  else if IsEqualGuid(MediaType.formattype, FORMAT_MPEGVideo) then
  begin
    MPGVI := PMPEG1VIDEOINFO(MediaType.pbFormat);
    if (MPGVI = nil) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
    fFormat.rcSource := MPGVI^.hdr.rcSource;
    fFormat.rcTarget := MPGVI^.hdr.rcTarget;
    fFormat.dwBitRate := MPGVI^.hdr.dwBitRate;
    fFormat.dwBitErrorRate := MPGVI^.hdr.dwBitErrorRate;
    fFormat.AvgTimePerFrame := MPGVI^.hdr.AvgTimePerFrame;
    fFormat.bmiHeader := MPGVI^.hdr.bmiHeader;
  end
  else if IsEqualGuid(MediaType.formattype, FORMAT_MPEG2Video) then
  begin
    MPGVI2 := PMPEG2VIDEOINFO(MediaType.pbFormat);
    if (MPGVI2 = nil) then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    FillChar(fFormat, SizeOf(TVideoInfoHeader), #0);
    fFormat.rcSource := MPGVI2^.hdr.rcSource;
    fFormat.rcTarget := MPGVI2^.hdr.rcTarget;
    fFormat.dwBitRate := MPGVI2^.hdr.dwBitRate;
    fFormat.dwBitErrorRate := MPGVI2^.hdr.dwBitErrorRate;
    fFormat.AvgTimePerFrame := MPGVI2^.hdr.AvgTimePerFrame;
    fFormat.bmiHeader := MPGVI2^.hdr.bmiHeader;
  end
  else
  begin
    Result := E_UNEXPECTED;
    Exit;
  end;

  fRenderer.DoInitialize(@fFormat, MediaType.subtype);
  Result := S_OK;
  LogLine('Leave SetMediaType');
end;
{*** IDispatch methods *** taken from CBaseVideoWindow *** ctlutil.cpp ********}
function TVideoRenderer.GetTypeInfoCount(out Count: Integer): HResult; stdcall;
begin
  LogLine('Enter GetTypeInfoCount');
  Result := fDispatch.GetTypeInfoCount(Count);
  LogLine('Leave GetTypeInfoCount');
end;

function TVideoRenderer.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
begin
  LogLine('Enter GetTypeInfo');
  Result := fDispatch.GetTypeInfo(IID_IVideoWindow,Index,LocaleID,TypeInfo);
  LogLine('Leave GetTypeInfo');
end;

function TVideoRenderer.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
begin
  LogLine('Enter GetIDsOfNames');
  Result := fDispatch.GetIDsOfNames(IID_IVideoWindow,Names,NameCount,LocaleID,DispIDs);
  LogLine('Leave GetIDsOfNames');
end;

function TVideoRenderer.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
var
  pti : ITypeInfo;
begin
  LogLine('Enter Invoke');
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
  LogLine('Leave Invoke');
end;
(*** IVideoWindow methods *****************************************************)
function TVideoRenderer.put_Caption(strCaption: WideString): HResult; stdcall;
begin
  LogLine('Enter put_Caption');
  if not CheckConnected(FInputPin,Result) then Exit;
  fRenderer.Caption := strCaption;
  LogLine('Leave put_Caption');
end;

function TVideoRenderer.get_Caption(out strCaption: WideString): HResult; stdcall;
begin
  LogLine('Enter get_Caption');
  if not CheckConnected(FInputPin,Result) then Exit;
  strCaption := fRenderer.Caption;
  LogLine('Leave get_Caption');
end;

function TVideoRenderer.put_WindowStyle(WindowStyle: Longint): HResult; stdcall;
begin
  LogLine('Enter put_WindowStyle');
  if not CheckConnected(FInputPin,Result) then Exit;

  // These styles cannot be changed dynamically
  if (Bool(WindowStyle and WS_DISABLED) or
      Bool(WindowStyle and WS_ICONIC) or
      Bool(WindowStyle and WS_MAXIMIZE) or
      Bool(WindowStyle and WS_MINIMIZE) or
      Bool(WindowStyle and WS_HSCROLL) or
      Bool(WindowStyle and WS_VSCROLL)) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
      
  Result := fRenderer.DoSetWindowStyle(WindowStyle,GWL_STYLE);
  LogLine('Leave put_WindowStyle');
end;

function TVideoRenderer.get_WindowStyle(out WindowStyle: Longint): HResult; stdcall;
begin
  LogLine('Enter get_WindowStyle');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := fRenderer.DoGetWindowStyle(WindowStyle,GWL_STYLE);
  LogLine('Leave get_WindowStyle');
end;

function TVideoRenderer.put_WindowStyleEx(WindowStyleEx: Longint): HResult; stdcall;
begin
  LogLine('Enter put_WindowStyleEx');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Should we be taking off WS_EX_TOPMOST
  if (GetWindowLong(fRenderer.Handle,GWL_EXSTYLE) and WS_EX_TOPMOST > 0) then
  begin
    if ((WindowStyleEx and WS_EX_TOPMOST) = 0) then
    begin
//      SendMessage(fRenderer.Handle,m_ShowStageTop,WPARAM(FALSE),0);
    end;
  end;

  // Likewise should we be adding WS_EX_TOPMOST
  if (WindowStyleEx and WS_EX_TOPMOST > 0) then
  begin
//    SendMessage(m_hwnd,m_ShowStageTop,(WPARAM) TRUE,(LPARAM) 0);
    WindowStyleEx := WindowStyleEx and not WS_EX_TOPMOST;
    if (WindowStyleEx = 0) then
    begin
      Result := NOERROR;
      Exit;
    end;
  end;

  Result := fRenderer.DoSetWindowStyle(WindowStyleEx,GWL_EXSTYLE);
  LogLine('Leave put_WindowStyleEx');
end;

function TVideoRenderer.get_WindowStyleEx(out WindowStyleEx: Longint): HResult; stdcall;
begin
  LogLine('Enter get_WindowStyleEx');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := fRenderer.DoGetWindowStyle(WindowStyleEx,GWL_EXSTYLE);
  LogLine('Leave get_WindowStyleEx');
end;

function TVideoRenderer.put_AutoShow(AutoShow: LongBool): HResult; stdcall;
begin
  LogLine('Enter put_AutoShow');
  if not CheckConnected(FInputPin,Result) then Exit;
  fAutoShow := AutoShow;
  LogLine('Leave put_AutoShow');
end;

function TVideoRenderer.get_AutoShow(out AutoShow: LongBool): HResult; stdcall;
begin
  LogLine('Enter get_AutoShow');
  if not CheckConnected(FInputPin,Result) then Exit;
  AutoShow := fAutoShow;
  LogLine('Leave get_AutoShow');
end;

function TVideoRenderer.put_WindowState(WindowState: Longint): HResult; stdcall;
begin
  LogLine('Enter put_WindowState');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := fRenderer.DoShowWindow(WindowState);
  LogLine('Leave put_WindowState');
end;

function TVideoRenderer.get_WindowState(out WindowState: Longint): HResult; stdcall;
begin
  LogLine('Enter get_WindowState');
  if not CheckConnected(FInputPin,Result) then Exit;

  WindowState := 0;

  // Is the window visible, a window is termed visible if it is somewhere on
  // the current desktop even if it is completely obscured by other windows
  // so the flag is a style for each window set with the WS_VISIBLE bit

  if fRenderer.Visible then
  begin
    // Is the base window iconic
    if IsIconic(fRenderer.Handle) then
    begin
      WindowState := WindowState or SW_MINIMIZE;
    end
    // Has the window been maximised
    else if IsZoomed(fRenderer.Handle) then
    begin
      WindowState := WindowState or SW_MAXIMIZE;
    end
    // Window is normal
    else
    begin
      WindowState := WindowState or SW_SHOW;
    end

  end else
  begin
    WindowState := WindowState or SW_HIDE;
  end;
  Result := NOERROR;
  LogLine('Leave get_WindowState');
end;

function TVideoRenderer.put_BackgroundPalette(BackgroundPalette: Longint): HResult; stdcall;
begin
  LogLine('Enter put_BackgroundPalette');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_BackgroundPalette');
end;

function TVideoRenderer.get_BackgroundPalette(out pBackgroundPalette: Longint): HResult; stdcall;
begin
  LogLine('Enter get_BackgroundPalette');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_BackgroundPalette');
end;

function TVideoRenderer.put_Visible(Visible: LongBool): HResult; stdcall;
begin
  LogLine('Enter put_Visible');
  if not CheckConnected(FInputPin,Result) then Exit;
  fRenderer.Visible := Visible;
  LogLine('Leave put_Visible');
end;

function TVideoRenderer.get_Visible(out pVisible: LongBool): HResult; stdcall;
begin
  LogLine('Enter get_Visible');
  if not CheckConnected(FInputPin,Result) then Exit;
  pVisible := fRenderer.Visible;
  LogLine('Leave get_Visible');
end;

function TVideoRenderer.put_Left(Left: Longint): HResult; stdcall;
var
  bSuccess : Boolean;
  WindowRect : TRect;
  WindowFlags : Cardinal;
begin
  LogLine('Enter put_Left');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Get the current window position in a RECT
  GetWindowRect(fRenderer.Handle,WindowRect);

  if (fRenderer.ParentWindow > 0) then
    MapWindowPoints(HWND_DESKTOP, fRenderer.ParentWindow, WindowRect, 2);

  // Adjust the coordinates ready for SetWindowPos, the window rectangle we
  // get back from GetWindowRect is in left,top,right and bottom while the
  // coordinates SetWindowPos wants are left,top,width and height values

  WindowRect.bottom := WindowRect.bottom - WindowRect.top;
  WindowRect.right := WindowRect.right - WindowRect.left;
  WindowFlags := SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOACTIVATE;

  bSuccess := SetWindowPos(fRenderer.Handle,                // Window handle
                           HWND_TOP,              // Put it at the top
                           Left,                  // New left position
                           WindowRect.top,        // Leave top alone
                           WindowRect.right,      // The WIDTH (not right)
                           WindowRect.bottom,     // The HEIGHT (not bottom)
                           WindowFlags);          // Show window options

  if not bSuccess then Result := E_INVALIDARG
                  else Result := NOERROR;
  LogLine('Leave put_Left');
end;

function TVideoRenderer.get_Left(out pLeft: Longint): HResult; stdcall;
var
  WindowRect : TRect;
begin
  LogLine('Enter get_Left');
  if not CheckConnected(FInputPin,Result) then Exit;

  GetWindowRect(fRenderer.Handle,WindowRect);
  pLeft := WindowRect.left;
  Result := S_OK;
  LogLine('Leave get_Left');
end;

function TVideoRenderer.put_Width(Width: Longint): HResult; stdcall;
var
  bSuccess : Boolean;
  WindowRect : TRect;
  WindowFlags : Cardinal;
begin
  LogLine('Enter put_Width');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Adjust the coordinates ready for SetWindowPos, the window rectangle we
  // get back from GetWindowRect is in left,top,right and bottom while the
  // coordinates SetWindowPos wants are left,top,width and height values

  GetWindowRect(fRenderer.Handle,WindowRect);

  if (fRenderer.ParentWindow > 0)
    then MapWindowPoints(HWND_DESKTOP, fRenderer.ParentWindow, WindowRect, 2);


  WindowRect.bottom := WindowRect.bottom - WindowRect.top;
  WindowFlags := SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOACTIVATE;

    // This seems to have a bug in that calling SetWindowPos on a window with
    // just the width changing causes it to ignore the width that you pass in
    // and sets it to a mimimum value of 110 pixels wide (Windows NT 3.51)

  bSuccess := SetWindowPos(fRenderer.Handle,                // Window handle
                           HWND_TOP,              // Put it at the top
                           WindowRect.left,       // Leave left alone
                           WindowRect.top,        // Leave top alone
                           Width,                 // New WIDTH dimension
                           WindowRect.bottom,     // The HEIGHT (not bottom)
                           WindowFlags);          // Show window options

  if not bSuccess then Result := E_INVALIDARG
                  else Result := NOERROR;
  LogLine('Leave put_Width');
end;

function TVideoRenderer.get_Width(out pWidth: Longint): HResult; stdcall;
var
  WindowRect : TRect;
begin
  LogLine('Enter get_Width');
  if not CheckConnected(FInputPin,Result) then Exit;
  GetWindowRect(fRenderer.Handle,WindowRect);
  pWidth := WindowRect.right - WindowRect.left;
  Result := NOERROR;
  LogLine('Leave get_Width');
end;

function TVideoRenderer.put_Top(Top: Longint): HResult; stdcall;
var
  bSuccess : Boolean;
  WindowRect : TRect;
  WindowFlags : Cardinal;
begin
  LogLine('Enter put_Top');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Get the current window position in a RECT
  GetWindowRect(fRenderer.Handle,WindowRect);

  if (fRenderer.ParentWindow > 0) then
     MapWindowPoints(HWND_DESKTOP, fRenderer.ParentWindow, WindowRect, 2);


  // Adjust the coordinates ready for SetWindowPos, the window rectangle we
  // get back from GetWindowRect is in left,top,right and bottom while the
  // coordinates SetWindowPos wants are left,top,width and height values

  WindowRect.bottom := WindowRect.bottom - WindowRect.top;
  WindowRect.right := WindowRect.right - WindowRect.left;
  WindowFlags := SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOACTIVATE;

  bSuccess := SetWindowPos(fRenderer.Handle,                // Window handle
                           HWND_TOP,              // Put it at the top
                           WindowRect.left,       // Leave left alone
                           Top,                   // New top position
                           WindowRect.right,      // The WIDTH (not right)
                           WindowRect.bottom,     // The HEIGHT (not bottom)
                           WindowFlags);          // Show window flags

  if not bSuccess then Result := E_INVALIDARG
                  else Result := NOERROR;
  LogLine('Leave put_Top');
end;

function TVideoRenderer.get_Top(out pTop: Longint): HResult; stdcall;
var
  WindowRect : TRect;
begin
  LogLine('Enter get_Top');
  if not CheckConnected(FInputPin,Result) then Exit;
  GetWindowRect(fRenderer.Handle,WindowRect);
  pTop := WindowRect.Top;
  Result := NOERROR;
  LogLine('Leave get_Top');
end;

function TVideoRenderer.put_Height(Height: Longint): HResult; stdcall;
var
  bSuccess : Boolean;
  WindowRect : TRect;
  WindowFlags : Cardinal;
begin
  LogLine('Enter put_Height');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Adjust the coordinates ready for SetWindowPos, the window rectangle we
  // get back from GetWindowRect is in left,top,right and bottom while the
  // coordinates SetWindowPos wants are left,top,width and height values

  GetWindowRect(fRenderer.Handle,WindowRect);

  if (fRenderer.ParentWindow > 0) then
     MapWindowPoints(HWND_DESKTOP, fRenderer.ParentWindow, WindowRect, 2);

  WindowRect.right := WindowRect.right - WindowRect.left;
  WindowFlags := SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOACTIVATE;

  bSuccess := SetWindowPos(fRenderer.Handle,                // Window handle
                           HWND_TOP,              // Put it at the top
                           WindowRect.left,       // Leave left alone
                           WindowRect.top,        // Leave top alone
                           WindowRect.right,      // The WIDTH (not right)
                           Height,                // New height dimension
                           WindowFlags);          // Show window flags

  if not bSuccess then Result := E_INVALIDARG
                  else Result := NOERROR;
  LogLine('Leave put_Height');
end;

function TVideoRenderer.get_Height(out pHeight: Longint): HResult; stdcall;
var
  WindowRect : TRect;
begin
  LogLine('Enter get_Height');
  if not CheckConnected(FInputPin,Result) then Exit;

  GetWindowRect(fRenderer.Handle,WindowRect);
  pHeight := WindowRect.bottom - WindowRect.top;
  Result := NOERROR;
  LogLine('Leave get_Height');
end;

function TVideoRenderer.put_Owner(Owner: OAHWND): HResult; stdcall;
begin
  LogLine('Enter put_Owner');
  if not CheckConnected(FInputPin,Result) then Exit;
  fRenderer.ParentWindow := Owner;

  // Don't call this with the filter locked
  fRenderer.DoPaintWindow(True);
  Result := NOERROR;
  LogLine('Leave put_Owner');
end;

function TVideoRenderer.get_Owner(out Owner: OAHWND): HResult; stdcall;
begin
  LogLine('Enter get_Owner');
  if not CheckConnected(FInputPin,Result) then Exit;
  Owner := fRenderer.ParentWindow;
  LogLine('Leave get_Owner');
end;

function TVideoRenderer.put_MessageDrain(Drain: OAHWND): HResult; stdcall;
begin
  LogLine('Enter put_MessageDrain');
  if not CheckConnected(FInputPin,Result) then Exit;
  fRenderer.MessageDrain := Drain;
  LogLine('Leave put_MessageDrain');
end;

function TVideoRenderer.get_MessageDrain(out Drain: OAHWND): HResult; stdcall;
begin
  LogLine('Enter get_MessageDrain');
  if not CheckConnected(FInputPin,Result) then Exit;
  Drain := fRenderer.MessageDrain;
  LogLine('Leave get_MessageDrain');
end;

function TVideoRenderer.get_BorderColor(out Color: Longint): HResult; stdcall;
begin
  LogLine('Enter get_BorderColor');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_BorderColor');
end;

function TVideoRenderer.put_BorderColor(Color: Longint): HResult; stdcall;
begin
  LogLine('Enter put_BorderColor');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_BorderColor');
end;

function TVideoRenderer.get_FullScreenMode(out FullScreenMode: LongBool): HResult; stdcall;
begin
  LogLine('Enter get_FullScreenMode');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_FullScreenMode');
end;

function TVideoRenderer.put_FullScreenMode(FullScreenMode: LongBool): HResult; stdcall;
begin
  LogLine('Enter put_FullScreenMode');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_FullScreenMode');
end;

function TVideoRenderer.SetWindowForeground(Focus: Longint): HResult; stdcall;
begin
  LogLine('Enter SetWindowForeground');
  if not CheckConnected(FInputPin,Result) then Exit;
  SendMessage(fRenderer.Handle,WM_SHOWWINDOW,Focus,0);
  LogLine('Leave SetWindowForeground');
end;

function TVideoRenderer.NotifyOwnerMessage(hwnd: Longint; uMsg, wParam, lParam: Longint): HResult; stdcall;
begin
  LogLine('Enter NotifyOwnerMessage');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Only interested in these Windows messages
  case uMsg of
    WM_SYSCOLORCHANGE,
    WM_PALETTECHANGED,
    WM_PALETTEISCHANGING,
    WM_QUERYNEWPALETTE,
    WM_DEVMODECHANGE,
    WM_DISPLAYCHANGE,
    WM_ACTIVATEAPP:
    begin
      // If we do not have an owner then ignore
      if (fRenderer.ParentWindow = 0) then
      begin
        Result := NOERROR;
        Exit;
      end;
      SendMessage(fRenderer.Handle,uMsg,wParam,lParam);
    end;
    // do NOT fwd WM_MOVE. the parameters are the location of the parent
    // window, NOT what the renderer should be looking at.  But we need
    // to make sure the overlay is moved with the parent window, so we
    // do this.
    WM_MOVE: PostMessage(fRenderer.Handle,WM_PAINT,0,0);
  end;
  LogLine('Leave NotifyOwnerMessage');
end;

function TVideoRenderer.SetWindowPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
var
  bSuccess : Boolean;
  WindowFlags : Cardinal;
begin
  LogLine('Enter SetWindowPosition');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Set the new size and position
  WindowFlags := SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOACTIVATE;

  ASSERT(IsWindow(fRenderer.Handle));
  bSuccess := SetWindowPos(fRenderer.Handle,         // Window handle
                           HWND_TOP,       // Put it at the top
                           Left,           // Left position
                           Top,            // Top position
                           Width,          // Window width
                           Height,         // Window height
                           WindowFlags);   // Show window flags
  ASSERT(bSuccess);
  {$IFDEF DEBUG}
    DbgLog(Self,'SWP failed error : ' + inttohex(GetLastError,8));
  {$ENDIF}
  if not bSuccess then Result := E_INVALIDARG
                  else Result := NOERROR;
  LogLine('Leave SetWindowPosition');
end;

function TVideoRenderer.GetWindowPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
var
  WindowRect : TRect;
begin
  LogLine('Enter GetWindowPosition');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Get the current window coordinates

  GetWindowRect(fRenderer.Handle,WindowRect);

  // Convert the RECT into left,top,width and height values

  pLeft := WindowRect.left;
  pTop := WindowRect.top;
  pWidth := WindowRect.right - WindowRect.left;
  pHeight := WindowRect.bottom - WindowRect.top;

  Result := NOERROR;
  LogLine('Leave GetWindowPosition');
end;

function TVideoRenderer.GetMinIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
var
  State : TFilterState;
  DefaultRect : TRect;
begin
  LogLine('Enter GetMinIdealImageSize');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Must not be stopped for this to work correctly
  GetState(0,State);
  if (State = State_Stopped) then
  begin
    Result := VFW_E_WRONG_STATE;
    Exit;
  end;

  DefaultRect := Rect(0,0,DEFWIDTH,DEFHEIGHT);
  pWidth := DefaultRect.Right - DefaultRect.Left;
  pHeight := DefaultRect.Bottom - DefaultRect.Top;
  Result := NOERROR;
  LogLine('Leave GetMinIdealImageSize');
end;

function TVideoRenderer.GetMaxIdealImageSize(out pWidth, pHeight: Longint): HResult; stdcall;
var
  State : TFilterState;
  DefaultRect : TRect;
begin
  LogLine('Enter GetMaxIdealImageSize');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Must not be stopped for this to work correctly
  GetState(0,State);
  if (State = State_Stopped) then
  begin
    Result := VFW_E_WRONG_STATE;
    Exit;
  end;

  DefaultRect := Rect(0,0,DEFWIDTH,DEFHEIGHT);
  pWidth := DefaultRect.Right - DefaultRect.Left;
  pHeight := DefaultRect.Bottom - DefaultRect.Top;
  Result := NOERROR;
  LogLine('Leave GetMaxIdealImageSize');
end;

function TVideoRenderer.GetRestorePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
var
  Place : TWindowPlacement;
  WorkArea : TRect;
begin
  LogLine('Enter GetRestorePosition');
  if not CheckConnected(FInputPin,Result) then Exit;

  // Use GetWindowPlacement to find the restore position

  Place.length := sizeof(TWindowPlacement);
  GetWindowPlacement(fRenderer.Handle,@Place);

  // We must take into account any task bar present

  if SystemParametersInfo(SPI_GETWORKAREA,0,@WorkArea,0) then
  begin
    if (fRenderer.ParentWindow = 0) then
    begin
      inc(Place.rcNormalPosition.top,WorkArea.top);
      inc(Place.rcNormalPosition.bottom,WorkArea.top);
      inc(Place.rcNormalPosition.left,WorkArea.left);
      inc(Place.rcNormalPosition.right,WorkArea.left);
    end;
  end;

  // Convert the RECT into left,top,width and height values

  pLeft := Place.rcNormalPosition.left;
  pTop := Place.rcNormalPosition.top;
  pWidth := Place.rcNormalPosition.right - Place.rcNormalPosition.left;
  pHeight := Place.rcNormalPosition.bottom - Place.rcNormalPosition.top;

  Result := NOERROR;
  LogLine('Leave GetRestorePosition');
end;

function TVideoRenderer.HideCursor(HideCursor: LongBool): HResult; stdcall;
begin
  LogLine('Enter HideCursor');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave HideCursor');
end;

function TVideoRenderer.IsCursorHidden(out CursorHidden: LongBool): HResult; stdcall;
begin
  LogLine('Enter IsCursorHidden');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave IsCursorHidden');
end;
(*** IBasicVideo methods ******************************************************)
function TVideoRenderer.get_AvgTimePerFrame(out pAvgTimePerFrame: TRefTime): HResult; stdcall;
begin
  LogLine('Enter get_AvgTimePerFrame');
  if not CheckConnected(FInputPin,Result) then Exit;
  pAvgTimePerFrame := fFormat.AvgTimePerFrame;
  Result := NOERROR;
  LogLine('Leave get_AvgTimePerFrame');
end;

function TVideoRenderer.get_BitRate(out pBitRate: Longint): HResult; stdcall;
begin
  LogLine('Enter get_BitRate');
  if not CheckConnected(FInputPin,Result) then Exit;
  pBitRate := fFormat.dwBitRate;
  Result := NOERROR;
  LogLine('Leave get_BitRate');
end;

function TVideoRenderer.get_BitErrorRate(out pBitErrorRate: Longint): HResult; stdcall;
begin
  LogLine('Enter get_BitErrorRate');
  if not CheckConnected(FInputPin,Result) then Exit;
  pBitErrorRate := fFormat.dwBitErrorRate;
  Result := NOERROR;
  LogLine('Leave get_BitErrorRate');
end;

function TVideoRenderer.get_VideoWidth(out pVideoWidth: Longint): HResult; stdcall;
begin
  LogLine('Enter get_VideoWidth');
  if not CheckConnected(FInputPin,Result) then Exit;
  pVideoWidth := fFormat.bmiHeader.biWidth;
  Result := NOERROR;
  LogLine('Leave get_VideoWidth');
end;

function TVideoRenderer.get_VideoHeight(out pVideoHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter get_VideoHeight');
  if not CheckConnected(FInputPin,Result) then Exit;
  pVideoHeight := fFormat.bmiHeader.biHeight;
  Result := NOERROR;
  LogLine('Leave get_VideoHeight');
end;

function TVideoRenderer.put_SourceLeft(SourceLeft: Longint): HResult; stdcall;
begin
  LogLine('Enter put_SourceLeft');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_SourceLeft');
end;

function TVideoRenderer.get_SourceLeft(out pSourceLeft: Longint): HResult; stdcall;
begin
  LogLine('Enter get_SourceLeft');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_SourceLeft');
end;

function TVideoRenderer.put_SourceWidth(SourceWidth: Longint): HResult; stdcall;
begin
  LogLine('Enter put_SourceWidth');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_SourceWidth');
end;

function TVideoRenderer.get_SourceWidth(out pSourceWidth: Longint): HResult; stdcall;
begin
  LogLine('Enter get_SourceWidth');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_SourceWidth');
end;

function TVideoRenderer.put_SourceTop(SourceTop: Longint): HResult; stdcall;
begin
  LogLine('Enter put_SourceTop');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_SourceTop');
end;

function TVideoRenderer.get_SourceTop(out pSourceTop: Longint): HResult; stdcall;
begin
  LogLine('Enter get_SourceTop');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_SourceTop');
end;

function TVideoRenderer.put_SourceHeight(SourceHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter put_SourceHeight');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_SourceHeight');
end;

function TVideoRenderer.get_SourceHeight(out pSourceHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter get_SourceHeight');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_SourceHeight');
end;

function TVideoRenderer.put_DestinationLeft(DestinationLeft: Longint): HResult; stdcall;
begin
  LogLine('Enter put_DestinationLeft');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_DestinationLeft');
end;

function TVideoRenderer.get_DestinationLeft(out pDestinationLeft: Longint): HResult; stdcall;
begin
  LogLine('Enter get_DestinationLeft');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_DestinationLeft');
end;

function TVideoRenderer.put_DestinationWidth(DestinationWidth: Longint): HResult; stdcall;
begin
  LogLine('Enter put_DestinationWidth');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_DestinationWidth');
end;

function TVideoRenderer.get_DestinationWidth(out pDestinationWidth: Longint): HResult; stdcall;
begin
  LogLine('Enter get_DestinationWidth');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_DestinationWidth');
end;

function TVideoRenderer.put_DestinationTop(DestinationTop: Longint): HResult; stdcall;
begin
  LogLine('Enter put_DestinationTop');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_DestinationTop');
end;

function TVideoRenderer.get_DestinationTop(out pDestinationTop: Longint): HResult; stdcall;
begin
  LogLine('Enter get_DestinationTop');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_DestinationTop');
end;

function TVideoRenderer.put_DestinationHeight(DestinationHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter put_DestinationHeight');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave put_DestinationHeight');
end;

function TVideoRenderer.get_DestinationHeight(out pDestinationHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter get_DestinationHeight');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave get_DestinationHeight');
end;

function TVideoRenderer.SetSourcePosition(Left, Top, Width, Height: Longint): HResult; stdcall;
begin
  LogLine('Enter SetSourcePosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave SetSourcePosition');
end;

function TVideoRenderer.GetSourcePosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter GetSourcePosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave GetSourcePosition');
end;

function TVideoRenderer.SetDefaultSourcePosition: HResult; stdcall;
begin
  LogLine('Enter SetDefaultSourcePosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave SetDefaultSourcePosition');
end;

function TVideoRenderer.SetDestinationPosition(Left, Top, Width, Height: Longint): HResult; stdcall;
begin
  LogLine('Enter SetDestinationPosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave SetDestinationPosition');
end;

function TVideoRenderer.GetDestinationPosition(out pLeft, pTop, pWidth, pHeight: Longint): HResult; stdcall;
begin
  LogLine('Enter GetDestinationPosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave GetDestinationPosition');
end;

function TVideoRenderer.SetDefaultDestinationPosition: HResult; stdcall;
begin
  LogLine('Enter SetDefaultDestinationPosition');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave SetDefaultDestinationPosition');
end;

function TVideoRenderer.GetVideoSize(out pWidth, Height: Longint): HResult; stdcall;
begin
  LogLine('Enter GetVideoSize');
  if not CheckConnected(FInputPin,Result) then Exit;
  pWidth := fFormat.bmiHeader.biWidth;
  Height := fFormat.bmiHeader.biHeight;
  Result := NOERROR;
  LogLine('Leave GetVideoSize');
end;

function TVideoRenderer.GetVideoPaletteEntries(StartIndex, Entries: Longint; out pRetrieved: Longint; out pPalette): HResult; stdcall;
begin
  LogLine('Enter GetVideoPaletteEntries');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave GetVideoPaletteEntries');
end;

function TVideoRenderer.GetCurrentImage(var BufferSize: Longint; var pDIBImage): HResult; stdcall;
begin
  LogLine('Enter GetCurrentImage');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave GetCurrentImage');
end;

function TVideoRenderer.IsUsingDefaultSource: HResult; stdcall;
begin
  LogLine('Enter IsUsingDefaultSource');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave IsUsingDefaultSource');
end;

function TVideoRenderer.IsUsingDefaultDestination: HResult; stdcall;
begin
  LogLine('Enter IsUsingDefaultDestination');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave IsUsingDefaultDestination');
end;
(*** IBasicVideo2 methods *****************************************************)
function TVideoRenderer.GetPreferredAspectRatio(out plAspectX, plAspectY: Longint): HResult; stdcall;
begin
  LogLine('Enter GetPreferredAspectRatio');
  if not CheckConnected(FInputPin,Result) then Exit;
  Result := E_NOTIMPL;
  LogLine('Leave GetPreferredAspectRatio');
end;
(*** IAMFilterMiscFlags methods ***********************************************)
function TVideoRenderer.GetMiscFlags: ULONG; stdcall;
begin
  LogLine('Enter GetMiscFlags');
  Result := AM_FILTER_MISC_FLAGS_IS_RENDERER;
  LogLine('Leave GetMiscFlags');
end;

end.

