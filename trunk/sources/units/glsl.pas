{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer OpenGL Shading Language Class                    }
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

unit GLSL;

{$ifdef FPC}
  {$mode objfpc}{$H+}
{$endif}

interface

uses
  Classes, SysUtils, dglOpenGL;

type
  TGLSL = class
  private
    FProgram : GLHandle;
    function GetShaderError(AShader : GLHandle) : String;
    function UploadShader(ASource : String; const AShaderID : gluint) : String;
    function GetParameterLocation(const AName : String) : GLint;
  public
    constructor Create;
    destructor Destroy; override;
    function UploadPixelShader(ASource : String) : String;
    function UploadVertexShader(ASource : String) : String;
    procedure Bind;
    procedure Unbind;
    procedure SetParameter1i(const AName : String; AX : Integer);
    procedure SetParameter2i(const AName : String; AX, AY : Integer);
    procedure SetParameter3i(const AName : String; AX, AY, AZ : Integer);
    procedure SetParameter1f(const AName : String; AX : Single);
    procedure SetParameter2f(const AName : String; AX, AY : Single);
    procedure SetParameter3f(const AName : String; AX, AY, AZ : Single);
  published
  end;

implementation

constructor TGLSL.Create;
begin
  FProgram := glCreateProgram();
end;

destructor TGLSL.Destroy;
begin
  glUseProgramObjectARB(0);
  glDeleteObjectARB(FProgram);
  inherited;
end;

function TGLSL.GetShaderError(AShader : GLHandle) : String;
var
 blen,slen : GLInt;
 InfoLog   : PGLCharARB;
begin
  glGetShaderiv(AShader, GL_INFO_LOG_LENGTH , @blen);
  if blen > 1 then
  begin
    InfoLog := AllocMem(blen*SizeOf(GLCharARB));
    slen := 0;
    glGetShaderInfoLog(AShader, blen, slen, InfoLog);
    Result := PChar(InfoLog);
    FreeMem(InfoLog, blen*SizeOf(GLCharARB));
  end
  else
    Result := '';
end;

function TGLSL.UploadShader(ASource : String; const AShaderID : gluint) : String;
var
  l : Integer;
  Shader : GLhandle;
begin
  Shader := glCreateShader(AShaderID);
  l := Length(ASource);
  glShaderSource(Shader,1, @ASource, @l);
  glCompileShader(Shader);
  glAttachShader(FProgram, Shader);
  glDeleteShader(Shader);
  glLinkProgram(FProgram);
  Result := GetShaderError(Shader);
end;

function TGLSL.UploadPixelShader(ASource : String) : String;
begin
  Result := UploadShader(ASource, GL_FRAGMENT_SHADER);
end;

function TGLSL.UploadVertexShader(ASource : String) : String;
begin
  Result := UploadShader(ASource, GL_VERTEX_SHADER);
end;

procedure TGLSL.Bind;
begin
  glUseProgram(FProgram);
end;

procedure TGLSL.Unbind;
begin
  glUseProgram(0);
end;

function TGLSL.GetParameterLocation(const AName : String) : GLint;
begin
  Result := glGetUniformLocation(FProgram, PGLchar(AName));
end;

procedure TGLSL.SetParameter1i(const AName : String; AX : Integer);
begin
  glUniform1i(GetParameterLocation(AName), AX);
end;

procedure TGLSL.SetParameter2i(const AName : String; AX, AY : Integer);
begin
  glUniform2i(GetParameterLocation(AName), AX, AY);
end;

procedure TGLSL.SetParameter3i(const AName : String; AX, AY, AZ : Integer);
begin
  glUniform3i(GetParameterLocation(AName), AX, AY, AZ);
end;

procedure TGLSL.SetParameter1f(const AName : String; AX : Single);
begin
  glUniform1f(GetParameterLocation(AName), AX);
end;

procedure TGLSL.SetParameter2f(const AName : String; AX, AY : Single);
begin
  glUniform2f(GetParameterLocation(AName), AX, AY);
end;

procedure TGLSL.SetParameter3f(const AName : String; AX, AY, AZ : Single);
begin
  glUniform3f(GetParameterLocation(AName), AX, AY, AZ);
end;

end.

