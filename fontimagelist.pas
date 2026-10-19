unit FontImageList;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ImgList, Controls, Graphics, iconrender, types, lcltype, LCLIntf, Dialogs, PropEdits;

type
  TFontImageData = record
    GliphIndex: integer;
    Color: TColor;
  end;

  TFontImageDataArray = array of TFontImageData;

  TFontImageDataArrayHelper = record helper for  TFontImageDataArray
    function AddGlyph(AGliphIndex: integer; AColor: TColor): integer;
    procedure RemoveGlyph(AIndex: integer);
    procedure MoveGlyphUp(AIndex: integer);
    procedure MoveGlyphDown(AIndex: integer);
  end;

  { TFontImageFontEditor }
(*
  TFontImageFontEditor = class(TStringPropertyEditor)
  public
    procedure Edit; override;
    function CreateDlg: TOpenDialog; virtual;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;
*)
  { TFontImageList }

  TFontImageList = class(TCustomImageList)
  private
    FIsLoading: boolean;
    FGlyphs: TFontImageDataArray;
    FOnInitialize: TNotifyEvent;
    FSize: TSize;
    FFontData: TMemoryStream;
    FDummy: string;
    procedure SetGlyphs(AValue: TFontImageDataArray);
    procedure SetOnInitialize(AValue: TNotifyEvent);
    procedure SetSize(AValue: TSize);
  protected
    procedure Loaded; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure SetWidth(AValue: integer);
    procedure SetHeight(AValue: integer);
    procedure RegenerateImages;
  public
    property FontStream:TMemoryStream read FFontData;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteGlyphData(AStream: TStream);
    procedure ReadGliphData(AStream: TStream);
    procedure WriteFontData(AStream: TStream);
    procedure ReadFontData(AStream: TStream);
    procedure WriteData(AStream: TStream); override;
    procedure ReadData(AStream: TStream); override;
    procedure WriteAdvData(AStream: TStream); override;
    procedure ReadAdvData(AStream: TStream); override;

    property Glyphs: TFontImageDataArray read FGlyphs write SetGlyphs;
  published
    property OnInitialize: TNotifyEvent read FOnInitialize write SetOnInitialize;
    property Height write SetHeight;
    property Width write SetWidth;
    property Scaled;

  end;

implementation

function TFontImageDataArrayHelper.AddGlyph(AGliphIndex: integer; AColor: TColor): integer;
var
  NewGlyph: TFontImageData;
begin
  NewGlyph.GliphIndex := AGliphIndex;
  NewGlyph.Color      := AColor;

  SetLength(self, Length(self) + 1);
  self[Length(self) - 1] := NewGlyph;

  Result := Length(self) - 1;
end;

procedure TFontImageDataArrayHelper.RemoveGlyph(AIndex: integer);
var
  i: integer;
begin
  if (AIndex < 0) or (AIndex >= Length(self)) then Exit;

  for i := AIndex to Length(Self) - 2 do
    self[i] := self[i + 1];

  SetLength(self, Length(self) - 1);
end;

procedure TFontImageDataArrayHelper.MoveGlyphUp(AIndex: integer);
var
  TempGlyph: TFontImageData;
begin
  if (AIndex <= 0) or (AIndex >= Length(Self)) then Exit;

  TempGlyph    := Self[AIndex];
  Self[AIndex] := Self[AIndex - 1];
  Self[AIndex - 1] := TempGlyph;
end;

procedure TFontImageDataArrayHelper.MoveGlyphDown(AIndex: integer);
var
  TempGlyph: TFontImageData;
begin
  if (AIndex < 0) or (AIndex >= Length(Self) - 1) then Exit;

  TempGlyph    := Self[AIndex];
  Self[AIndex] := Self[AIndex + 1];
  Self[AIndex + 1] := TempGlyph;
end;
(*
{ TFontImageFontEditor }

procedure TFontImageFontEditor.Edit;
var
  TheDialog: TOpenDialog;
  Comp: TFontImageList;
  Hook: TPropertyEditorHook;
begin
  Comp := TFontImageList(GetComponent(0));
  TheDialog := CreateDlg;
  try
  if TheDialog.Execute then
     begin
       Comp.FFontData.LoadFromFile(TheDialog.FileName);
       Comp.RegenerateImages;
     end;

  finally
    TheDialog.Free;
  end;
end;

function TFontImageFontEditor.CreateDlg: TOpenDialog;
begin
  Result := TOpenDialog.Create(nil);
  Result.Filter := 'Fonts|*.ttf;*.otf';

end;

function TFontImageFontEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable, paReadOnly];
end;

function TFontImageFontEditor.GetValue: string;
var
  Comp: TFontImageList;
begin
  Comp := TFontImageList(GetComponent(0));
   if (Comp <> nil) and (Comp.FFontData.Size > 0) then
     Result := Format('(%d Bytes Embedded)', [Comp.FFontData.Size])
   else
     Result := '(Empty)';
end;
  *)
{ TFontImageList }

constructor TFontImageList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFontData := TMemoryStream.Create;
  //  FIsLoading := False;
  SetLength(FGlyphs, 0);
end;

destructor TFontImageList.Destroy;
begin
  SetLength(FGlyphs, 0);
  FFontData.Free;
  inherited Destroy;
end;

procedure TFontImageList.Loaded;
begin
  inherited Loaded;
  FIsLoading := True;
  if Assigned(FOnInitialize) then
    FOnInitialize(self);
  FIsLoading := False;
  RegenerateImages;
end;

procedure TFontImageList.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('GlyphsData', ReadGliphData, WriteGlyphData, True);
  Filer.DefineBinaryProperty('FontData', ReadFontData, WriteFontData, True);
end;

procedure TFontImageList.SetHeight(AValue: integer);
begin
  SetWidthHeight(Width, AValue);
  RegenerateImages;
end;

procedure TFontImageList.WriteGlyphData(AStream: TStream);
var
  Glyph: TFontImageData;
  i: integer;
begin
  AStream.WriteDWord(Length(FGlyphs));
  for i := 0 to length(FGlyphs) - 1 do
  begin
    Glyph := FGlyphs[i];
    AStream.WriteDWord(Glyph.GliphIndex);
    AStream.WriteDWord(Glyph.Color);
  end;
end;

procedure TFontImageList.ReadGliphData(AStream: TStream);
var
  GlyphCnt: Dword;
  Glyph: TFontImageData;
  i: integer;
begin
  GlyphCnt := AStream.ReadDWord;
  SetLength(FGlyphs, GlyphCnt);

  for i := 0 to GlyphCnt - 1 do
  begin
    Glyph.GliphIndex := AStream.ReadDWord;
    Glyph.Color := AStream.ReadDWord;
    FGlyphs[i] := Glyph;
  end;
end;

procedure TFontImageList.WriteFontData(AStream: TStream);
begin
  FFontData.Position := 0;
  AStream.Write(FFontData.Size,SizeOf(int64));
  if FFontData.Size > 0 then
    AStream.CopyFrom(FFontData, FFontData.Size);
end;

procedure TFontImageList.ReadFontData(AStream: TStream);
var ASize: Int64;
begin
  ASize := AStream.ReadQWord;
  if ASize > 0 then
    FFontData.CopyFrom(AStream,ASize);
end;

procedure TFontImageList.WriteData(AStream: TStream);
begin
  //Do nothing
end;

procedure TFontImageList.ReadData(AStream: TStream);
begin
  //Do nothing
end;

procedure TFontImageList.WriteAdvData(AStream: TStream);
begin
  //Do nothing
end;

procedure TFontImageList.ReadAdvData(AStream: TStream);
begin
  //Do nothing
end;

procedure TFontImageList.SetWidth(AValue: integer);
begin
  SetWidthHeight(AValue, Height);
  RegenerateImages;
end;

procedure TFontImageList.SetGlyphs(AValue: TFontImageDataArray);
begin
  if FGlyphs = AValue then Exit;
  FGlyphs := AValue;
  RegenerateImages;
end;

procedure TFontImageList.SetOnInitialize(AValue: TNotifyEvent);
begin
  FOnInitialize := AValue;
end;

procedure TFontImageList.SetSize(AValue: TSize);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  RegenerateImages;
end;


procedure TFontImageList.RegenerateImages;
var
  Item: TFontImageData;
  IconRenderer: TIconRenderer;
  bmp: TBitMap;
begin
  if FIsLoading or (csLoading in ComponentState) then Exit;
  if FFontData.Size = 0 then
     exit;
  Clear;
  RegisterResolutions([Height]);

  try
    IconRenderer := TIconRenderer.Create(FFontData);
    IconRenderer.SetSize(Height, Width, Scaled); // Scaling occurs inside object, no need to do it here

    for item in FGlyphs do
    begin
      if IsSysColor(Item.Color) then
        IconRenderer.Color := GetSysColor(SysColorToSysColorIndex(Item.Color))
      else
        IconRenderer.Color := Item.Color;

      Bmp := TBitmap.Create;
      try
        IconRenderer.getGlyph(Item.GliphIndex, bmp); //;then
        Add(bmp, nil);
      finally
        Bmp.Free;
      end;
    end;

  finally
    IconRenderer.Free;
  end;
end;


end.
