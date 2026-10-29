unit registerovocomponents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FontImageList, ThemedSlider, ImageTrack, fontimagelisteditor, PropEdits, ComponentEditors;

  procedure Register;

{$R images/TFontImageList.res}
implementation

procedure Register;
begin
  // Registra il componente

  RegisterComponents('ovocomponents', [TFontImageList,TThemedSlider,TImageTrack]);
  RegisterPropertyEditor(TypeInfo(TMemoryStream), TFontImageList, 'FontStream', TFontImageFontEditor);
  RegisterComponentEditor(TFontImageList,TFontImageListEditor);
end;

end.

