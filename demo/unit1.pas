unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, ExtCtrls, FontImageList, ThemedSlider,
  ImageTrack, fontimagelisteditor;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    FontImageList1: TFontImageList;
    ImageList1: TImageList;
    ImageTrack1: TImageTrack;
    ThemedSlider1: TThemedSlider;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolBar3: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton2: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    ToolButton22: TToolButton;
    ToolButton23: TToolButton;
    ToolButton24: TToolButton;
    ToolButton25: TToolButton;
    ToolButton26: TToolButton;
    ToolButton27: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure Button1Click(Sender: TObject);
    procedure ImageTrack1Change(Sender: TObject);
    procedure ThemedSlider1Change(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ThemedSlider1Change(Sender: TObject);
begin
  ImageTrack1.Position := ThemedSlider1.Position;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  FontImageListDialog: TFontImageListDialog;
begin
  FontImageListDialog := TFontImageListDialog.Create(Application, FontImageList1.FontStream);
  try
    FontImageListDialog.Glyphs := FontImageList1.Glyphs;
    if FontImageListDialog.ShowModal = mrOk then
    begin
      FontImageList1.Glyphs := FontImageListDialog.Glyphs;
      FontImageList1.RegenerateImages;

    end;
  finally
    FontImageListDialog.Free;
  end;
end;

procedure TForm1.ImageTrack1Change(Sender: TObject);
begin
  ThemedSlider1.Position := ImageTrack1.Position;
end;

end.
