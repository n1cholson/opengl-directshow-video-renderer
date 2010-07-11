program glrenderer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  mainform,
  LResources,
  dshowtypes,
  sampleloader,
  glsldebugform, dglOpenGL, conversion, glsl, texture;

{$IFDEF WINDOWS}{$R glrenderer.rc}{$ENDIF}

begin
  {$I glrenderer.lrs}
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmGLSLDebug, frmGLSLDebug);

  frmGLSLDebug.Left := (frmMain.Left + frmMain.Width);
  frmGLSLDebug.Top := frmMain.Top;

  if not frmMain.NotSupported then
    Application.Run;
end.

