{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ovocomponents;

{$warn 5023 off : no warning about unused units}
interface

uses
  ThemedSlider, ImageTrack, FontImageList, iconrender, fontimagelisteditor, registerovocomponents, SkinnedSlider, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('registerovocomponents', @registerovocomponents.Register);
end;

initialization
  RegisterPackage('ovocomponents', @Register);
end.
