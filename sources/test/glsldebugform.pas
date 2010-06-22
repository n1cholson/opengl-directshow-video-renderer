unit glsldebugform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfrmGLSLDebug }

  TfrmGLSLDebug = class(TForm)
    memDebug: TMemo;
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmGLSLDebug: TfrmGLSLDebug;

implementation

initialization
  {$I glsldebugform.lrs}

end.

