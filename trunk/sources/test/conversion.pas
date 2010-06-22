{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Software Conversion Functions                    }
{       Version 1.0                                                            }
{       Date : 2010-06-22                                                      }
{                                                                              }
{==============================================================================}
{                                                                              }
{       Copyright (C) 2010 Torsten Spaete                                      }
{       All Rights Reserved                                                    }
{                                                                              }
{       Uses dglOpenGL (MPL 1.1) from the OpenGL Delphi Community              }
{         http://delphigl.com                                                  }
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

unit conversion;

interface

uses
  Windows,
  SysUtils,
  Dialogs,
  dshowtypes;

procedure Convert(AHdr : TVideoInfoHeader; ASubType : TGUID; ASource : PByte; ASourceLen : Integer; var ARGB : PByte);
function SubTypeToString(AGuid : TGUID) : String;

implementation

function SubTypeToString(AGuid : TGUID) : String;
begin
  if IsEqualGUID(AGuid, MEDIASUBTYPE_RGB24) then Result := 'RGB24'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_RGB32) then Result := 'RGB32'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_RGB555) then Result := 'RGB555'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_RGB565) then Result := 'RGB565'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_YVYU) then Result := 'YVYU'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_YUY2) then Result := 'YUY2'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_UYVY) then Result := 'UYVY'
  else if IsEqualGUID(AGuid, MEDIASUBTYPE_YV12) then Result := 'YV12'
  else Result := 'Unsupported';
end;

procedure Convert(AHdr : TVideoInfoHeader; ASubType : TGUID; ASource : PByte; ASourceLen : Integer; var ARGB : PByte);
var
  Dst : PByte;

  function CLIP(b: Single): Byte;
  begin
    if b < 0 then b := 0;
    if b > 255 then b := 255;
    result := Trunc(b);
  end;

  procedure YUVToRGB8888(dstIdx : Integer; y, u, v : Byte);
  var
    r, g, b : Single;
  begin
    r := (1.164 * (y - 16)) + (2.018 * (v - 128));
    g := (1.164 * (y - 16)) - (0.813 * (u - 128)) - (0.391 * (v - 128));
    b := (1.164 * (y - 16)) + (1.596 * (u - 128));
    PByte(UInt64(Dst)+dstIdx+0)^ := CLIP(b);
    PByte(UInt64(Dst)+dstIdx+1)^ := CLIP(g);
    PByte(UInt64(Dst)+dstIdx+2)^ := CLIP(r);
    PByte(UInt64(Dst)+dstIdx+3)^ := 0;
  end;

  procedure YUV411ToRGB8888(u, v, y1, y2, y3, y4 : Byte);
  begin
    YUVToRGB8888(0, y1, u, v);
    YUVToRGB8888(4, y2, u, v);
    YUVToRGB8888(8, y3, u, v);
    YUVToRGB8888(12, y4, u, v);
    Inc(Dst, 16);
  end;

  procedure YUV422ToRGB8888(u, v, y1, y2 : Byte);
  begin
    YUVToRGB8888(0, y1, u, v);
    YUVToRGB8888(4, y2, u, v);
    Inc(Dst, 8);
  end;

  procedure RGB555ToRGB8888(ARGB555 : Word);
  var
    r, g, b : Integer;
  begin
    R := (ARGB555 shr 10) and $1F;
    G := (ARGB555 shr 5) and $1F;
    B := (ARGB555) and $1F;
    PByte(UInt(Dst)+0)^ := (b shl 3) or (b shr 2);
    PByte(UInt(Dst)+1)^ := (g shl 3) or (g shr 2);
    PByte(UInt(Dst)+2)^ := (r shl 3) or (r shr 2);
    PByte(UInt(Dst)+3)^ := 0;
    Inc(Dst, 4);
  end;

  procedure RGB565ToRGB8888(ARGB565 : Word);
  var
    r, g, b : Integer;
  begin
    R := (ARGB565 shr 11) and $1F;
    G := (ARGB565 shr 5) and $3F;
    B := (ARGB565) and $1F;
    PByte(UInt(Dst)+0)^ := (b shl 3) or (b shr 2);
    PByte(UInt(Dst)+1)^ := (g shl 2) or (g shr 4);
    PByte(UInt(Dst)+2)^ := (r shl 3) or (r shr 2);
    PByte(UInt(Dst)+3)^ := 0;
    Inc(Dst, 4);
  end;

  procedure YV12ToRGB8888(ASrc : PByte; ASize, AX, AY : Integer);
  var
    Y,U,V : Integer;
  begin
    Y := PByte(UInt64(ASrc)+(AY * AHdr.bmiHeader.biWidth + AX))^;
    U := PByte(UInt64(ASrc)+((AY div 2) * (AHdr.bmiHeader.biWidth div 2) + AX div 2 + ASize + (ASize div 4)))^;
    V := PByte(UInt64(ASrc)+((AY div 2) * (AHdr.bmiHeader.biWidth div 2) + AX div 2 + ASize))^;
    YUVToRGB8888(0, Y, U, V);
    Inc(Dst, 4);
  end;

var
  LineWidth : Integer;
  I, X, Y : Integer;
  Src : PByte;
  YUV : array of Byte;
  SixTeenByte : WORD;
  ArraySize : Integer;
begin
  Dst := ARGB;
  Src := ASource;
  if IsEqualGuid(ASubType, MEDIASUBTYPE_RGB24) then
  begin
    For I := 0 to (ASourceLen div 3)-1 do
    begin
      PByte(UInt(Dst)+0)^ := PByte(UInt(Src)+0)^;
      PByte(UInt(Dst)+1)^ := PByte(UInt(Src)+1)^;
      PByte(UInt(Dst)+2)^ := PByte(UInt(Src)+2)^;
      PByte(UInt(Dst)+3)^ := 0;
      Inc(Dst, 4);
      Inc(Src, 3);
    end;
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_RGB32) then
  begin
    Move(Src^, Dst^, ASourceLen);
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_RGB555) then
  begin
    if ASourceLen mod 2 = 0 then
    begin
      For I := 0 to (ASourceLen div 2)-1 do
      begin
        SixTeenByte := PWord(UINT(Src))^;
        RGB555ToRGB8888(SixTeenByte);
        Inc(Src, 2);
      end;
    end;
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_RGB565) then
  begin
    if ASourceLen mod 2 = 0 then
    begin
      For I := 0 to (ASourceLen div 2)-1 do
      begin
        SixTeenByte := PWord(UINT(Src))^;
        RGB565ToRGB8888(SixTeenByte);
        Inc(Src, 2);
      end;
    end;
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_YVYU) or
          IsEqualGuid(ASubType, MEDIASUBTYPE_YUY2) or
          IsEqualGuid(ASubType, MEDIASUBTYPE_YUYV) or
          IsEqualGuid(ASubType, MEDIASUBTYPE_UYVY) then
  begin
    SetLength(YUV, 4);
    if ASourceLen mod 4 = 0 then
    begin
      LineWidth := AHdr.bmiHeader.biWidth div 2;
      For Y := AHdr.bmiHeader.biHeight-1 downto 0 do
      begin
        Src := PByte(UInt64(ASource) + (Y*(LineWidth*4)));
        For X := 0 to LineWidth-1 do
        begin
          if (IsEqualGuid(ASubType, MEDIASUBTYPE_YUY2) or
              IsEqualGuid(ASubType, MEDIASUBTYPE_YUYV)
             ) then
          begin
            YUV[0] := PByte(UInt64(Src)+0)^; // y1
            YUV[1] := PByte(UInt64(Src)+1)^; // u
            YUV[2] := PByte(UInt64(Src)+2)^; // y2
            YUV[3] := PByte(UInt64(Src)+3)^; // v
          end
          else if IsEqualGuid(ASubType, MEDIASUBTYPE_YVYU) then
          begin
            YUV[0] := PByte(UInt64(Src)+0)^; // y1
            YUV[3] := PByte(UInt64(Src)+1)^; // v
            YUV[2] := PByte(UInt64(Src)+2)^; // y2
            YUV[1] := PByte(UInt64(Src)+3)^; // u
          end
          else if IsEqualGuid(ASubType, MEDIASUBTYPE_UYVY) then
          begin
            YUV[1] := PByte(UInt64(Src)+0)^; // u
            YUV[0] := PByte(UInt64(Src)+1)^; // y1
            YUV[3] := PByte(UInt64(Src)+2)^; // v
            YUV[2] := PByte(UInt64(Src)+3)^; // y2
          end;
          YUV422ToRGB8888(YUV[1], YUV[3], YUV[0], YUV[2]);
          Inc(Src, 4);
        end;
      end;
    end;
  end
  else if IsEqualGuid(ASubType, MEDIASUBTYPE_YV12) then
  begin
    ArraySize := AHdr.bmiHeader.biHeight * AHdr.bmiHeader.biWidth;
    For Y := AHdr.bmiHeader.biHeight-1 downto 0 do
    begin
      for X := 0 to AHdr.bmiHeader.biWidth-1 do
      begin
        YV12ToRGB8888(Src, ArraySize, X, Y);
      end; 
    end;
  end;
end;

end.
