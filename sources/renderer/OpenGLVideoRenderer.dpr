{==============================================================================}
{                                                                              }
{       OpenGL Video Renderer                                                  }
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

library OpenGLVideoRenderer;

{$include videorenderer_compiler.inc}

uses
  BaseClass,
  utils in 'utils.pas',
  formOpenGLRenderer in 'formOpenGLRenderer.pas' {frmRenderer},
  VideoRendererFilter in 'VideoRendererFilter.pas',
  OpenGLVideoRendererFilter in 'OpenGLVideoRendererFilter.pas';

{$E ax}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

begin
end.

