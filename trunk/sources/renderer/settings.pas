unit settings;

interface

var
  SettingSoftwareColorConversion : Boolean;
  SettingEnableFrameDrop : Boolean;

implementation

initialization
  SettingSoftwareColorConversion := False;
  SettingEnableFrameDrop := True;

end.
