{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Form Unit                                        }
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

unit formOpenGLRenderer;

{$include videorenderer_compiler.inc}

interface

uses
  // Delphi
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,

  // 3rd party
  BaseClass, Direct3D9, DirectShow9,

  // Own
  formrendererbase;
  
type
  TfrmOpenGLRenderer = class(TRendererBaseForm)
  private
    fWidth : integer;
    fHeight : integer;
    fFormat : TVideoInfoHeader;
    fSubType : TGUID;
  public
    procedure DoPaintWindow(Erase : Boolean); override;
    procedure DoRenderSample(Sample : IMediaSample); override;
    procedure DoInitialize(Info : PVideoInfoHeader; SubType : TGUID); override;
  end;

implementation

{$R *.dfm}

uses
  utils;

procedure TfrmOpenGLRenderer.DoPaintWindow(Erase : Boolean);
begin
  InvalidateRect(Handle,nil,Erase);
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

procedure SaveSample(ASample : IMediaSample; AHeader : TVideoInfoHeader; ASubType : TGUID);
var
  S, E : Int64;
begin
  // Save sample for a const time
  if Succeeded(ASample.GetTime(S, E)) then
  begin
    if S >= EncodeReferenceTime(10) then
    begin
      SaveSampleToFileSystem(AHeader, ASubType, ASample, S);
    end;
  end;
end;

procedure TfrmOpenGLRenderer.DoRenderSample(Sample : IMediaSample);
var
  Bits: PByte;
begin
  Sample.GetPointer(Bits);

  if (IsEqualGuid(FSubType, MEDIASUBTYPE_RGB24) or
      IsEqualGuid(FSubType, MEDIASUBTYPE_RGB32)
     ) then
  begin
    Canvas.Lock;
    StretchDIBits(Canvas.Handle,
      0, 0, ClientWidth, ClientHeight,
      0, 0, FWidth, FHeight,
      Bits, PBitmapInfo(@fFormat.bmiHeader)^,
      DIB_RGB_COLORS, SRCCOPY);
    Canvas.Unlock;
  end;
end;

procedure TfrmOpenGLRenderer.DoInitialize(Info : PVideoInfoHeader; SubType : TGUID);
begin
  fFormat := Info^;
  fWidth  := Info.bmiHeader.biWidth;
  fHeight := Info.bmiHeader.biHeight;
  ClientWidth := fWidth;
  ClientHeight := fHeight;
  fSubType := SubType;
end;

end.
