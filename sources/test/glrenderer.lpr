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
  dglopengl in '..\headers\dglopengl.pas',
  dshowtypes,
  texture,
  conversion,
  sampleloader,
  glsl,
  glsldebugform;

{$IFDEF WINDOWS}{$R glrenderer.rc}{$ENDIF}

begin
  {$I glrenderer.lrs}
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmGLSLDebug, frmGLSLDebug);

  frmGLSLDebug.Left := (frmMain.Left + frmMain.Width);
  frmGLSLDebug.Top := frmMain.Top;

  Application.Run;
end.

