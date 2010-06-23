{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Base Renderer Form Unit                          }
{       Version 1.0                                                            }
{       Date : 2010-06-23                                                      }
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

unit formRendererBase;

interface

{$include videorenderer_compiler.inc}

uses
  Classes,
  Windows,
  Forms,
  Messages,
  DirectShow9;

type
  TRendererBaseForm = class(TForm)
  private
    fMessageDrain : hWnd;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    property MessageDrain : hWnd read fMessageDrain write fMessageDrain;
    function DoSetWindowStyle(Style, WindowLong : LongInt) : HRESULT;
    function DoGetWindowStyle(out Style : LongInt; WindowLong : LongInt) : HRESULT;
    function DoShowWindow(ShowCmd: Longint): HResult;
    procedure DoPaintWindow(Erase : Boolean); virtual; abstract;
    procedure DoRenderSample(Sample : IMediaSample); virtual; abstract;
    procedure DoInitialize(Info : PVideoInfoHeader; SubType : TGUID); virtual; abstract;
  end;

implementation

constructor TRendererBaseForm.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
end;

destructor TRendererBaseForm.Destroy;
begin
  inherited;
end;

function PossiblyEatMessage(hwndDrain : hWnd; Msg : Cardinal; wParam : WPARAM; lParam : LPARAM) : Boolean; stdcall;
begin
  if ((hwndDrain <> 0) and not InSendMessage) then
  begin
    case Msg of
      WM_CHAR,
      WM_DEADCHAR,
      WM_KEYDOWN,
      WM_KEYUP,
      WM_LBUTTONDBLCLK,
      WM_LBUTTONDOWN,
      WM_LBUTTONUP,
      WM_MBUTTONDBLCLK,
      WM_MBUTTONDOWN,
      WM_MBUTTONUP,
      WM_MOUSEACTIVATE,
      WM_MOUSEMOVE,
      // If we pass this on we don't get any mouse clicks
      // WM_NCHITTEST,
      WM_NCLBUTTONDBLCLK,
      WM_NCLBUTTONDOWN,
      WM_NCLBUTTONUP,
      WM_NCMBUTTONDBLCLK,
      WM_NCMBUTTONDOWN,
      WM_NCMBUTTONUP,
      WM_NCMOUSEMOVE,
      WM_NCRBUTTONDBLCLK,
      WM_NCRBUTTONDOWN,
      WM_NCRBUTTONUP,
      WM_RBUTTONDBLCLK,
      WM_RBUTTONDOWN,
      WM_RBUTTONUP,
      WM_SYSCHAR,
      WM_SYSDEADCHAR,
      WM_SYSKEYDOWN,
      WM_SYSKEYUP:
      begin
        PostMessage(hwndDrain, Msg, wParam, lParam);
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;

procedure TRendererBaseForm.WndProc(var Message: TMessage);
begin
  if PossiblyEatMessage(fMessageDrain,Message.Msg,Message.WParam,Message.LParam) then Exit;

  case Message.Msg of
    WM_ERASEBKGND:
    begin
      Message.Result := 0;
      Exit;
    end;
  end;

  inherited WndProc(Message);
end;

function TRendererBaseForm.DoSetWindowStyle(Style, WindowLong : LongInt) : HRESULT;
var
  WindowRect : TRect;
  WindowFlags : Cardinal;
begin

  // Set the new style flags for the window
  SetWindowLong(Handle,WindowLong,Style);
  WindowFlags := SWP_SHOWWINDOW or SWP_FRAMECHANGED or SWP_NOACTIVATE;
  WindowFlags := WindowFlags or SWP_NOZORDER or SWP_NOSIZE or SWP_NOMOVE;

  // Show the window again in the current position

  if Visible then
  begin
    SetWindowPos(Handle,            // Base window handle
                 HWND_TOP,          // Just a place holder
                 0,0,0,0,           // Leave size and position
                 WindowFlags);      // Just draw it again
    Result := NOERROR;
    Exit;
  end;

  // Move the window offscreen so the user doesn't see the changes

  MoveWindow(Handle,                            // Base window handle
             GetSystemMetrics(SM_CXSCREEN),     // Current desktop width
             GetSystemMetrics(SM_CYSCREEN),     // Likewise it's height
             Width,                             // Use the same width
             Height,                            // Keep height same to
             True);                             // May as well repaint

  // Now show the previously hidden window

  SetWindowPos(Handle,            // Base window handle
               HWND_TOP,          // Just a place holder
               0,0,0,0,           // Leave size and position
               WindowFlags);      // Just draw it again

  ShowWindow(Handle,SW_HIDE);

  if (ParentWindow > 0) then MapWindowPoints(HWND_DESKTOP,ParentWindow,WindowRect,2);

  MoveWindow(Handle,               // Base window handle
             WindowRect.left,      // Existing x coordinate
             WindowRect.top,       // Existing y coordinate
             Width,                // Use the same width
             Height,               // Keep height same to
             True);                // May as well repaint

  Result := NOERROR;
end;

function TRendererBaseForm.DoGetWindowStyle(out Style : LongInt; WindowLong : LongInt) : HRESULT;
begin
  Style := GetWindowLong(Handle,WindowLong);
  Result := NOERROR;
end;

function TRendererBaseForm.DoShowWindow(ShowCmd: Longint): HResult;
begin
  ShowWindow(Handle,ShowCmd);
  Result := NOERROR;
end;

end.
