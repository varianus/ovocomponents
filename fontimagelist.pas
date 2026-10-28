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

  TFontImageFontEditor = class(TStringPropertyEditor)
  public
    procedure Edit; override;
    function CreateDlg: TOpenDialog; virtual;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

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
    procedure WriteGlyphData(AStream: TStream);
    procedure ReadGliphData(AStream: TStream);
    procedure WriteFontData(AStream: TStream);
    procedure ReadFontData(AStream: TStream);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RegenerateImages;
    procedure CustomRender(AImageList: TCustomImageList; const AColor: TColor; const Size: TSize; const CodeList: array of cardinal);
    property Glyphs: TFontImageDataArray read FGlyphs write SetGlyphs;
  published
    property OnInitialize: TNotifyEvent read FOnInitialize write SetOnInitialize;
    property Height write SetHeight;
    property Width write SetWidth;
    property Scaled;
    property FontStream: TMemoryStream read FFontData;
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

{ TFontImageFontEditor }

procedure TFontImageFontEditor.Edit;
var
  TheDialog: TOpenDialog;
  comp: TFontImageList;
  Hook: TPropertyEditorHook;
begin
  comp      := TFontImageList(GetComponent(0));
  TheDialog := CreateDlg;
  try
    if TheDialog.Execute then
    begin
      comp.FFontData.Clear;
      comp.FFontData.LoadFromFile(TheDialog.FileName);

      comp.RegenerateImages;
    end;

  finally
    TheDialog.Free;
  end;
end;

function TFontImageFontEditor.CreateDlg: TOpenDialog;
begin
  Result := TOpenDialog.Create(nil);
  Result.Filter := 'TrueType Fonts|*.ttf;*.otf';
  Result.Options := [ofFileMustExist];

end;

function TFontImageFontEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable, paReadOnly];
end;

function TFontImageFontEditor.GetValue: string;
var
  comp: TFontImageList;
begin
  comp := TFontImageList(GetComponent(0));
  if (comp <> nil) and (comp.FFontData.Size > 0) then
    Result := '(FontData)'
  else
    Result := '(Empty)';
end;

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
type
  TDefinePropertiesProc = procedure(AFiler: TFiler) of object;
var
  M: TMethod;
begin
  M.Code := @TComponent.DefineProperties;
  M.Data := Self;
  TDefinePropertiesProc(M)(Filer);

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
  AStream.Write(FFontData.Size, SizeOf(int64));
  if FFontData.Size > 0 then
    AStream.CopyFrom(FFontData, FFontData.Size);
end;

procedure TFontImageList.ReadFontData(AStream: TStream);
var
  ASize: int64;
begin
  ASize := AStream.ReadQWord;
  if ASize > 0 then
    FFontData.CopyFrom(AStream, ASize);
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
  CurrRes: TCustomImageListResolution;
  Res: array of integer;
  Bitmaps: array of TRasterImage;
  i: Integer;
begin
  if FIsLoading or (csLoading in ComponentState) then Exit;
  if FFontData.Size = 0 then
    exit;
  Clear;
  SetLength(Res, 3);
  SetLength(Bitmaps, 3);

  Res[0] := Height;
  Res[1] := trunc(Height * 1.5);
  Res[2] := Height * 2;
  RegisterResolutions(res);
  try
    IconRenderer := TIconRenderer.Create(FFontData);
    for item in FGlyphs do
    begin
      if IsSysColor(Item.Color) then
        IconRenderer.Color := GetSysColor(SysColorToSysColorIndex(Item.Color))
      else
        IconRenderer.Color := Item.Color;

      for i := 0 to 2 do
      begin
        //  IconRenderer.SetSize(Height, Width, Scaled); // Scaling occurs inside object, no need to do it here
        IconRenderer.SetSize(Res[I], Res[i], Scaled); // Scaling occurs inside object, no need to do it here

        bmp := TBitmap.Create;
        IconRenderer.getGlyph(Item.GliphIndex, Bmp); //;then
        Bitmaps[i] := bmp;
      end;
      AddMultipleResolutions(Bitmaps);
      for i := 0 to 2 do
        Bitmaps[i].Free;
    end;

  finally
    IconRenderer.Free;
  end;
end;

procedure TFontImageList.CustomRender(AImageList: TCustomImageList; const AColor: TColor; const Size: TSize;
  const CodeList: array of cardinal);
var
  iconRender: TIconRenderer;
begin
  iconRender := TIconRenderer.Create(FFontData);
  iconRender.Color := AColor;
  iconRender.SetSize(size.cx, Size.cy);
  iconRender.AddToImageList(AImageList, CodeList);
  iconRender.Free;

end;


end.
