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

unit OpenGLVideoRendererFilter;

interface

uses
  // Own
  formRendererBase,
  VideoRendererFilter;

const
  CLSID_OpenGLVideoRenderer: TGUID = '{ED9E6396-9080-4100-8369-335B05D1A704}';

type
  IVideoRendererControl = interface(IUnknown)
  ['{28665505-416D-4330-ACF6-823331D92C9A}']
    function RepaintVideo: HRESULT; stdcall;
  end;

  TOpenGLVideoRenderer = class(TVideoRenderer, IVideoRendererControl)
  private
  protected
    function GetGUID : TGUID; override;
    function CreateRenderer : TRendererBaseForm; override;
    function GetSupportedSubTypes(out ASubTypes : TGUIDArray) : Boolean; override;
  public
    (*** IVideoRendererControl methods ***)
    function RepaintVideo: HRESULT; stdcall;
  end;

implementation

uses
  // Delphi
  Windows,

  // 3rd party
  BaseClass,
  DirectShow9,

  // Own
  formOpenGLRenderer;

{ TOpenGLVideoRenderer }
function TOpenGLVideoRenderer.CreateRenderer : TRendererBaseForm;
begin
  Result := TfrmOpenGLRenderer.Create(nil);
end;

function TOpenGLVideoRenderer.GetGUID : TGUID;
begin
  Result := CLSID_OpenGLVideoRenderer;
end;

function TOpenGLVideoRenderer.GetSupportedSubTypes(out ASubTypes : TGUIDArray) : Boolean;
begin
  Result := True;
  SetLength(ASubTypes, 2);
  ASubTypes[0] := MEDIASUBTYPE_RGB24;
  ASubTypes[1] := MEDIASUBTYPE_RGB24;
end;

(*** IVideoRendererControl methods ********************************************)
function TOpenGLVideoRenderer.RepaintVideo: HRESULT; stdcall;
begin
  if not IsConnected(Result) then Exit;
  RendererForm.Repaint;
  Result := NOERROR;
end;

initialization
  TBCClassFactory.CreateFilter(TOpenGLVideoRenderer, 'OpenGL Video Renderer',
    CLSID_OpenGLVideoRenderer, CLSID_LegacyAmFilterCategory, MERIT_DO_NOT_USE,
    0, nil
  );

end.
