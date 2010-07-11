{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Helpful Functions                                }
{       Version 1.0                                                            }
{       Date : 2010-07-10                                                      }
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

unit utils;

interface

uses
  Windows;

{$include videorenderer_compiler.inc}

procedure WriteTrace(_Line : WideString);

function SubTypeToString(AGuid : TGUID) : String;

function MGuidToString(_GUID : TGUID) : String;
function FGuidToString(_GUID : TGUID) : String;
function SGuidToString(_GUID : TGUID) : String;

function NonPowerOfTwo(AWidth, AHeight, AMax : Integer) : TRect;

implementation

uses
  // Delphi
  Messages,
  SysUtils,

  // 3rd party
  DirectShow9;

function SubTypeToString(AGuid : TGUID) : String;
begin
  if IsEqualGuid(AGuid, MEDIASUBTYPE_RGB24) then
    Result := 'RGB24'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_RGB32) then
    Result := 'RGB32'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_RGB555) then
    Result := 'RGB555'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_RGB565) then
    Result := 'RGB565'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_YUYV) then
    Result := 'YUYV'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_UYVY) then
    Result := 'UYVY'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_YUY2) then
    Result := 'YUY2'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_YV12) then
    Result := 'YV12'
  else if IsEqualGuid(AGuid, MEDIASUBTYPE_YVYU) then
    Result := 'YVYU'
  else
    Result := 'UNKNOWN';
end;

function SGuidToString(_GUID : TGUID) : String;
begin
  if IsEqualGuid(_GUID, MEDIASUBTYPE_CLPL) then
    Result := 'MEDIASUBTYPE_CLPL'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_YUYV) then
    Result := 'MEDIASUBTYPE_YUYV'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_IYUV) then
    Result := 'MEDIASUBTYPE_IYUV'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_YVU9) then
    Result := 'MEDIASUBTYPE_YVU9'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_Y411) then
    Result := 'MEDIASUBTYPE_Y411'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_Y41P) then
    Result := 'MEDIASUBTYPE_Y41P'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_YUY2) then
    Result := 'MEDIASUBTYPE_YUY2'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_YVYU) then
    Result := 'MEDIASUBTYPE_YVYU'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_UYVY) then
    Result := 'MEDIASUBTYPE_UYVY'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_Y211) then
    Result := 'MEDIASUBTYPE_Y211'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_CLJR) then
    Result := 'MEDIASUBTYPE_CLJR'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_IF09) then
    Result := 'MEDIASUBTYPE_IF09'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_CPLA) then
    Result := 'MEDIASUBTYPE_CPLA'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_MJPG) then
    Result := 'MEDIASUBTYPE_MJPG'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_TVMJ) then
    Result := 'MEDIASUBTYPE_TVMJ'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_WAKE) then
    Result := 'MEDIASUBTYPE_WAKE'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_CFCC) then
    Result := 'MEDIASUBTYPE_CFCC'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_IJPG) then
    Result := 'MEDIASUBTYPE_IJPG'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_Plum) then
    Result := 'MEDIASUBTYPE_Plum'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_DVCS) then
    Result := 'MEDIASUBTYPE_DVCS'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_DVSD) then
    Result := 'MEDIASUBTYPE_DVSD'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_MDVF) then
    Result := 'MEDIASUBTYPE_MDVF'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB1) then
    Result := 'MEDIASUBTYPE_RGB1'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB4) then
    Result := 'MEDIASUBTYPE_RGB4'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB8) then
    Result := 'MEDIASUBTYPE_RGB8'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB565) then
    Result := 'MEDIASUBTYPE_RGB565'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB555) then
    Result := 'MEDIASUBTYPE_RGB555'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB24) then
    Result := 'MEDIASUBTYPE_RGB24'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_RGB32) then
    Result := 'MEDIASUBTYPE_RGB32'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_ARGB1555) then
    Result := 'MEDIASUBTYPE_ARGB1555'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_ARGB4444) then
    Result := 'MEDIASUBTYPE_ARGB4444'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_ARGB32) then
    Result := 'MEDIASUBTYPE_ARGB32'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_A2R10G10B10) then
    Result := 'MEDIASUBTYPE_A2R10G10B10'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_A2B10G10R10) then
    Result := 'MEDIASUBTYPE_A2B10G10R10'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_AYUV) then
    Result := 'MEDIASUBTYPE_AYUV'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_AI44) then
    Result := 'MEDIASUBTYPE_AI44'
  else if IsEqualGuid(_GUID, MEDIASUBTYPE_IA44) then
    Result := 'MEDIASUBTYPE_IA44'
  else
    Result := GUIDToString(_GUID);
end;

function FGuidToString(_GUID : TGUID) : String;
begin
  if IsEqualGuid(_GUID, FORMAT_VideoInfo) then
    Result := 'FORMAT_VideoInfo'
  else if IsEqualGuid(_GUID, FORMAT_VideoInfo2) then
    Result := 'FORMAT_VideoInfo2'
  else if IsEqualGuid(_GUID, FORMAT_MPEGVideo) then
    Result := 'FORMAT_MPEGVideo'
  else if IsEqualGuid(_GUID, FORMAT_MPEG2VIDEO) then
    Result := 'FORMAT_MPEG2VIDEO'
  else if IsEqualGuid(_GUID, FORMAT_MPEGStreams) then
    Result := 'FORMAT_MPEGStreams'
  else if IsEqualGuid(_GUID, FORMAT_DvInfo) then
    Result := 'FORMAT_DvInfo'
  else if IsEqualGuid(_GUID, FORMAT_AnalogVideo) then
    Result := 'FORMAT_AnalogVideo'
  else if IsEqualGuid(_GUID, FORMAT_DolbyAC3) then
    Result := 'FORMAT_DolbyAC3'
  else if IsEqualGuid(_GUID, FORMAT_MPEG2Audio) then
    Result := 'FORMAT_MPEG2Audio'
  else if IsEqualGuid(_GUID, FORMAT_DVD_LPCMAudio) then
    Result := 'FORMAT_DVD_LPCMAudio'
  else if IsEqualGuid(_GUID, FORMAT_WaveFormatEx) then
    Result := 'FORMAT_WaveFormatEx'
  else if IsEqualGuid(_GUID, FORMAT_None) then
    Result := 'FORMAT_None'
  else
    Result := GUIDToString(_GUID);
end;

function MGuidToString(_GUID : TGUID) : String;
begin
  if IsEqualGuid(_GUID, MEDIATYPE_NULL) then
    Result := 'MEDIATYPE_NULL'
  else if IsEqualGuid(_GUID, MEDIATYPE_Video) then
    Result := 'MEDIATYPE_Video'
  else if IsEqualGuid(_GUID, MEDIATYPE_Audio) then
    Result := 'MEDIATYPE_Audio'
  else if IsEqualGuid(_GUID, MEDIATYPE_Text) then
    Result := 'MEDIATYPE_Text'
  else if IsEqualGuid(_GUID, MEDIATYPE_Midi) then
    Result := 'MEDIATYPE_Midi'
  else if IsEqualGuid(_GUID, MEDIATYPE_Stream) then
    Result := 'MEDIATYPE_Stream'
  else if IsEqualGuid(_GUID, MEDIATYPE_Interleaved) then
    Result := 'MEDIATYPE_Interleaved'
  else if IsEqualGuid(_GUID, MEDIATYPE_File) then
    Result := 'MEDIATYPE_File'
  else if IsEqualGuid(_GUID, MEDIATYPE_ScriptCommand) then
    Result := 'MEDIATYPE_ScriptCommand'
  else if IsEqualGuid(_GUID, MEDIATYPE_AUXLine21Data) then
    Result := 'MEDIATYPE_AUXLine21Data'
  else if IsEqualGuid(_GUID, MEDIATYPE_VBI) then
    Result := 'MEDIATYPE_VBI'
  else if IsEqualGuid(_GUID, MEDIATYPE_Timecode) then
    Result := 'MEDIATYPE_Timecode'
  else if IsEqualGuid(_GUID, MEDIATYPE_LMRT) then
    Result := 'MEDIATYPE_LMRT'
  else if IsEqualGuid(_GUID, MEDIATYPE_URL_STREAM) then
    Result := 'MEDIATYPE_URL_STREAM'
  else if IsEqualGuid(_GUID, MEDIATYPE_MPEG1SystemStream) then
    Result := 'MEDIATYPE_MPEG1SystemStream'
  else if IsEqualGuid(_GUID, MEDIATYPE_AnalogAudio) then
    Result := 'MEDIATYPE_AnalogAudio'
  else if IsEqualGuid(_GUID, MEDIATYPE_AnalogVideo) then
    Result := 'MEDIATYPE_AnalogVideo'
  else if IsEqualGuid(_GUID, MEDIATYPE_MPEG2_PACK) then
    Result := 'MEDIATYPE_MPEG2_PACK'
  else if IsEqualGuid(_GUID, MEDIATYPE_MPEG2_PES) then
    Result := 'MEDIATYPE_MPEG2_PES'
  else if IsEqualGuid(_GUID, MEDIATYPE_CONTROL) then
    Result := 'MEDIATYPE_CONTROL'
  else if IsEqualGuid(_GUID, MEDIATYPE_MPEG2_SECTIONS) then
    Result := 'MEDIATYPE_MPEG2_SECTIONS'
  else if IsEqualGuid(_GUID, MEDIATYPE_DVD_ENCRYPTED_PACK) then
    Result := 'MEDIATYPE_DVD_ENCRYPTED_PACK'
  else if IsEqualGuid(_GUID, MEDIATYPE_DVD_NAVIGATION) then
    Result := 'MEDIATYPE_DVD_NAVIGATION'
  else
    Result := GUIDToString(_GUID);
end;

// returns number of characters in a string excluding the null terminator
function StrLenW(Str: PWideChar): Cardinal;
asm
         MOV EDX, EDI
         MOV EDI, EAX
         MOV ECX, 0FFFFFFFFH
         XOR AX, AX
         REPNE SCASW
         MOV EAX, 0FFFFFFFEH
         SUB EAX, ECX
         MOV EDI, EDX
end;

{$ifdef EnableXenorateTrace}
procedure WriteTrace(_Line : WideString);
const
  TrennZeichen: WideString = '<[XTR]>';
var
  Parameter: WideString;
  MyCopyDataStruct: TCopyDataStruct;
  tracewnd: HWND;
begin
  tracewnd := FindWindowW(nil, 'Xenorate Trace');
  if tracewnd <> 0 then
  begin

    Parameter := FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz',Now) + TrennZeichen + '5' + TrennZeichen + 'OpenGLVideoRenderer - ' + _Line + #0;

    // fill the TCopyDataStruct structure with data to send
    // TCopyDataStruct mit den Sende-Daten Infos ausfüllen
    with MyCopyDataStruct do
    begin
      dwData := 0; // may use a value do identify content of message
      cbData := (StrLenW(PWideChar(Parameter))*2)+2;  //Need to transfer terminating #0 as well
      lpData := Pointer(PWideChar(Parameter));
    end;

    SendMessageW(tracewnd, WM_COPYDATA, Longint(tracewnd), Longint(@MyCopyDataStruct));
  end;
end;
{$else}
procedure WriteTrace(_Line : WideString);
begin
end;
{$endif}

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

end.
