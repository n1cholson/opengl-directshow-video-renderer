{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer Texture Class                                    }
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

unit texture;

interface

uses
  dglOpenGL;

type

  { TTexture }

  TTexture = class
  private 
    { OpenGL Texture ID }
    FID:      GLuint;
    { OpenGL Texture Target, InternalFormat and Type }
    FTarget, FInternalFormat, FType: GLuint;
    { OpenGL Texture Format }
    FFormat : Integer; 
    { Texture Dimension }
    FWidth, FHeight: integer;
    { Texture Flags }
    FCreated: boolean;
    FActive:  boolean;
    { Texture Data }
    FDataSize : Integer;
    FData : PByte;
    FDataPos : Integer;
    procedure CreateTexture(AData: PByte);
  public
    constructor Create(ATarget, AInternalFormat, AFormat, AType: GLuint;
      AWidth, AHeight: integer; const ADataSize : Integer = 0; const ADataPos : Integer = 0);
    destructor Destroy; override;
    procedure Upload(AData: PByte); overload;
    procedure Bind(const AIndex: integer = 0);
    procedure Unbind(const AIndex: integer = 0);
    procedure ChangeData(ASource : PByte; ASourcePos, ASourceLen : Integer);
    property Data : PByte read FData;
  published
    property Width: integer Read FWidth;
    property Height: integer Read FHeight;
    property InternalFormat : GLuint read FInternalFormat;
    property TexFormat : Integer read FFormat;
    property Target : GLuint read FTarget;
    property TexType : GLuint read FType;
    property DataSize : Integer read FDataSize;
  end;

implementation

uses
  Windows,
  SysUtils;

constructor TTexture.Create(ATarget, AInternalFormat, AFormat, AType: GLuint;
  AWidth, AHeight: integer; const ADataSize: Integer; const ADataPos: Integer);
begin
  FID      := 0;
  FTarget  := ATarget;
  FInternalFormat := AInternalFormat;
  FType := AType;
  FFormat  := AFormat;
  FWidth   := AWidth;
  FHeight  := AHeight;
  FCreated := False;
  FActive  := False;
  FDataSize := ADataSize;
  FDataPos := ADataPos;
  if FDataSize > 0 then
    FData := AllocMem(FDataSize)
  else
    FData := nil;
end;

destructor TTexture.Destroy;
begin
  if FDataSize > 0 then
  begin
    FreeMem(FData, FDataSize);
    FDataSize := 0;
    FDataPos := 0;
    FData := nil;
  end;
  inherited;
end;

procedure TTexture.CreateTexture(AData: PByte);
begin
  glGenTextures(1, @FID);
  glBindTexture(FTarget, FID);

  glTexEnvf(FTarget, GL_TEXTURE_ENV_MODE, GL_DECAL);

  glTexParameteri(FTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(FTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glTexParameteri(FTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(FTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glTexImage2D(FTarget, 0, FInternalFormat, FWidth, FHeight, 0, FFormat, FType, AData);
end;

procedure TTexture.Upload(AData: PByte);
begin
  glEnable(FTarget);
  if not FCreated then
  begin
    // Create new texture
    if FDataSize > 0 then
    begin
      ChangeData(AData, FDataPos, FDataSize);
      CreateTexture(FData);
    end
    else
      CreateTexture(AData);
    FCreated := True;
  end
  else
  begin
    // Change existing texture
    glBindTexture(FTarget, FID);
    if FDataSize > 0 then
    begin
      ChangeData(AData, FDataPos, FDataSize);
      glTexSubImage2d(FTarget, 0, 0, 0, FWidth, FHeight, FFormat, GL_UNSIGNED_BYTE, FData);
    end
    else
      glTexSubImage2d(FTarget, 0, 0, 0, FWidth, FHeight, FFormat, GL_UNSIGNED_BYTE, AData);
  end;
  glDisable(FTarget);
end;

procedure TTexture.Bind(const AIndex: integer = 0);
begin
  if FActive then
    Exit;
  FActive := True;
  glEnable(FTarget);
  glActiveTexture(GL_TEXTURE0 + AIndex);
  glBindTexture(FTarget, FID);
end;

procedure TTexture.Unbind(const AIndex: integer = 0);
begin
  if not FActive then
    Exit;
  FActive := False;
  glActiveTexture(GL_TEXTURE0 + AIndex);
  glBindTexture(FTarget, 0);
  glDisable(FTarget);
end;

procedure TTexture.ChangeData(ASource: PByte; ASourcePos, ASourceLen: Integer);
var
  Src : PByte;
begin
  if ASource = nil then Exit;
  if ASourceLen <= 0 then Exit;
  if ASourcePos < 0 then Exit;
  if ASourceLen > FDataSize then raise Exception.Create(Format('Source len "%d" > Data size "%d"',[ASourceLen, FDataSize]));
  Src := PByte(UInt64(ASource)+ASourcePos);
  Move(Src^, FData^, ASourceLen);
end;

end.

