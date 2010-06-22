{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Sample Loader Class                              }
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

unit sampleloader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dshowtypes;

type
  TSampleHeader = record
    VIH : TVideoInfoHeader;
    SubType : TGUID;
    DataLength : Integer;
  end;

  PSample = ^TSample;
  TSample = record
    Header : TSampleHeader;
    Data : PByte;
  end;

  PSampleArray = array of PSample;

procedure LoadSamples(ADir : String; var ASamples : PSampleArray; var ASampleCount : Integer);
function LoadSample(AFilename : String; out ASample : PSample) : Boolean;

implementation

function LoadSample(AFilename : String; out ASample : PSample) : Boolean;
var
  Str : TFileStream;
begin
  if FileExists(AFilename) then
  begin
    New(ASample);
    Str := TFileStream.Create(AFilename, fmOpenRead);
    try
      Str.Read(ASample^.Header.VIH, SizeOf(TVideoInfoHeader));
      Str.Read(ASample^.Header.SubType, SizeOf(TGUID));
      Str.Read(ASample^.Header.DataLength, SizeOf(Integer));
      ASample^.Data := AllocMem(ASample^.Header.DataLength);
      Str.Read(ASample^.Data^, ASample^.Header.DataLength);
    finally
      Str.Free;
    end;
    Result := True;
  end
  else
  begin
    ASample := nil;
    Result := False;
  end;
end;

procedure LoadSamples(ADir : String; var ASamples : PSampleArray; var ASampleCount : Integer);
var
  SR : TSearchRec;
  Lst : TStrings;
  I : Integer;
begin
  if FindFirst(IncludeTrailingBackslash(ADir) + '*.data', faAnyFile, SR) = 0 then
  begin
    Lst := TStringList.Create;
    try
      repeat
        if SR.Attr and faDirectory <> faDirectory then
          Lst.Add(IncludeTrailingPathDelimiter(ADir) + SR.Name);
      until FindNext(SR) <> 0;
      ASampleCount := Lst.Count;
      SetLength(ASamples, ASampleCount);
      For I := 0 to ASampleCount-1 do
        LoadSample(Lst[I], ASamples[I]);
    finally
      FindClose(SR);
      Lst.Free;
    end;
  end;
end;

end.

