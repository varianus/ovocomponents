{
TimageTrack : a component which use image as trackbar
Copyright (C) 2011 Marco Caselli

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

}
unit ImageTrack;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LResources, Forms, Controls, ExtCtrls, Graphics, Dialogs;

type

  { TImageTrack }

  TImageTrack = class(TCustomControl)
  private
    FBackGroundImage: TPicture;
    FForeGroundImage: TPicture;
    FMax: cardinal;
    FMin: cardinal;
    FOnChange: TNotifyEvent;
    FPosition: cardinal;
    Seeking: boolean;
    fInternalBMP: TBitmap;
    procedure DrawInternalBMP;
    procedure SetBackGroundImage(const AValue: TPicture);
    procedure SetForeGroundImage(const AValue: TPicture);
    procedure SetMax(const AValue: cardinal);
    procedure SetMin(const AValue: cardinal);
    procedure SetPosition(const AValue: cardinal);
    { Private declarations }
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure DoOnResize; override;
    procedure Loaded; override;
    procedure EraseBackground(DC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Max: cardinal read FMax write SetMax;
    property Min: cardinal read FMin write SetMin;
    property Position: cardinal read FPosition write SetPosition;
    property BackGroundImage: TPicture read FBackGroundImage write SetBackGroundImage;
    property ForeGroundImage: TPicture read FForeGroundImage write SetForeGroundImage;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TImageTrack }

procedure TImageTrack.SetBackGroundImage(const AValue: TPicture);
begin
  if FBackGroundImage = AValue then exit;
  FBackGroundImage := AValue;
  if fInternalBMP.Width = 0 then
    fInternalBMP.SetSize(AValue.Width, AValue.Height);

  DrawInternalBMP;
end;

procedure TImageTrack.SetForeGroundImage(const AValue: TPicture);
begin
  if FForeGroundImage = AValue then exit;
  FForeGroundImage := AValue;
  if fInternalBMP.Width = 0 then
    fInternalBMP.SetSize(AValue.Width, AValue.Height);

  DrawInternalBMP;
end;

procedure TImageTrack.SetMax(const AValue: cardinal);
begin
  if FMax = AValue then exit;
  if FMax <= FMin then exit;
  FMax := AValue;
  DrawInternalBMP;
end;

procedure TImageTrack.SetMin(const AValue: cardinal);
begin
  if FMin = AValue then exit;
  if FMin >= FMax then exit;
  FMin := AValue;
  DrawInternalBMP;
end;

procedure TImageTrack.SetPosition(const AValue: cardinal);
begin
  if FPosition = AValue then
    exit;
  FPosition := AValue;
  if FPosition > fmax then
    FPosition := FMax;
  if FPosition < FMin then
    FPosition := FMin;

  DrawInternalBMP;
  if Assigned(FOnChange) then
    FOnChange(self);
end;

procedure TImageTrack.DrawInternalBMP;
var
  r1: TRect;
begin
  if (FBackGroundImage = nil) or
    (FForeGroundImage = nil) then
  begin
    fInternalBMP.SetSize(Width, Height);
    fInternalBMP.Canvas.Rectangle(BoundsRect);
    fInternalBMP.Canvas.Line(0, 0, Width, Height);
    fInternalBMP.Canvas.Line(0, Height, Width, 0);
  end
  else
  begin
    fInternalBMP.Clear;
    fInternalBMP.SetSize(FBackGroundImage.Width, FBackGroundImage.Height);
    fInternalBMP.Canvas.CopyMode := cmSrcCopy;
    r1 := Rect(0, 0, FBackGroundImage.Width, FBackGroundImage.Height);
    fInternalBMP.Canvas.CopyRect(r1, FBackGroundImage.Bitmap.Canvas, r1);
    r1 := Rect(0, 0, trunc(FForeGroundImage.Width * (FPosition / FMax)) - 1, FForeGroundImage.Height);
    fInternalBMP.Canvas.CopyRect(r1, FForeGroundImage.Bitmap.Canvas, r1);
  end;
  fInternalBMP.Transparent := True;
  invalidate;
end;

procedure TImageTrack.Paint;
begin
  Canvas.StretchDraw(rect(0, 0, Width, Height), fInternalBMP);
end;

procedure TImageTrack.MouseMove(Shift: TShiftState; X, Y: integer);
var
  newPosition: integer;
begin
  if ssLeft in Shift then
  begin
    Seeking     := True;
    Cursor      := crHSplit;
    if X > -1 then
      begin
        newPosition := round(x * Max / Width);
        Position    := newPosition;
        DrawInternalBMP;
      end;
  end
  else
  begin
    Cursor  := crDefault;
    Seeking := False;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TImageTrack.DoOnResize;
begin
  inherited DoOnResize;
  DrawInternalBMP;
end;

procedure TImageTrack.Loaded;
begin
  inherited Loaded;
  fInternalBMP.SetSize(FForeGroundImage.Width, FForeGroundImage.Height);
  DrawInternalBMP;
end;

constructor TImageTrack.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMin      := 0;
  FMax      := 100;
  FPosition := 50;

  FBackGroundImage := TPicture.Create;
  FForeGroundImage := TPicture.Create;
  fInternalBMP     := TBitmap.Create;
  fInternalBMP.SetSize(0, 0);

end;


procedure TImageTrack.EraseBackground(DC: HDC);
begin
  //  inherited EraseBackground(DC);
end;


end.
