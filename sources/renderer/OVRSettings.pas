unit OVRSettings;

interface

var
  SettingSoftwareColorConversion : Boolean;
  SettingEnableFrameDrop : Boolean;
  SettingDrawOnPaint : Boolean;

implementation

initialization
  SettingSoftwareColorConversion := False;
  SettingEnableFrameDrop := True;
  SettingDrawOnPaint := True;

end.
