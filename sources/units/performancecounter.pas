unit performancecounter;

interface

uses
  Windows;

type
  TPerformanceCounter = class
  private
    FSupportsPerformance : Boolean;
    FFrequency : Int64;
    FStarted : Int64;
    FStopped : Int64;
    function GetMilliseconds : DWord;
    function GetSeconds : Double;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
  published
    property Milliseconds : DWord read GetMilliseconds;
    property Seconds : Double read GetSeconds;
  end;

implementation

constructor TPerformanceCounter.Create;
begin                
  FFrequency := 0;
  FSupportsPerformance := QueryPerformanceFrequency(FFrequency);
  FStarted := 0;
  FStopped := 0;
end;

destructor TPerformanceCounter.Destroy;
begin
  inherited;
end;

procedure TPerformanceCounter.Start;
begin
  if FSupportsPerformance then
    QueryPerformanceCounter(FStarted)
  else
    FStarted := GetTickCount;
  FStopped := 0;
end;

procedure TPerformanceCounter.Stop;
begin
  if FSupportsPerformance then
    QueryPerformanceCounter(FStopped)
  else
    FStopped := GetTickCount;
end;

function TPerformanceCounter.GetMilliseconds : DWord;
begin
  if FSupportsPerformance then
    Result := Trunc((FStopped - FStarted) / FFrequency * 1000)
  else
    Result := FStopped - FStarted;
end;

function TPerformanceCounter.GetSeconds : Double;
begin
  if FSupportsPerformance then
    Result := (FStopped - FStarted) / FFrequency
  else
    Result := (FStopped - FStarted) / 1000;
end;

end.
