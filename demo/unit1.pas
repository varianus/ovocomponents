unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, FontImageList, ThemedSlider, ImageTrack,
  SkinnedSlider;

type

  { TForm1 }

  TForm1 = class(TForm)
    FontImageList1: TFontImageList;
    ImageTrack1: TImageTrack;
    ThemedSlider1: TThemedSlider;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
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

end.

