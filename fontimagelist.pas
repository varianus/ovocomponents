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

  TFontImageList = class;

  TFontImageDataArray = array of TFontImageData;

  TFontImageDataArrayHelper = record helper for  TFontImageDataArray
    function AddGlyph(AGliphIndex: integer; AColor: TColor): integer;
    procedure RemoveGlyph(AIndex: integer);
    procedure MoveGlyphUp(AIndex: integer);
    procedure MoveGlyphDown(AIndex: integer);
  end;

  { TFontImageResItem }

  TFontImageResItem = class(TCollectionItem)
  private
    FResolution: integer;
    procedure SetResolution(AValue: integer);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Resolution: integer read FResolution write SetResolution default 16;
  end;

  { TFontImageResCollection }

  TFontImageResCollection = class(TOwnedCollection)
  private
    FImageList: TFontImageList;
    function GetItem(AIndex: integer): TFontImageResItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AImageList: TFontImageList); reintroduce;
    function Add(AResolution: integer): TFontImageResItem; reintroduce;
    property Items[AIndex: integer]: TFontImageResItem read GetItem; default;
    function GetUniqueSortedResolutions: TIntegerDynArray;
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
    FDefaultResolution: integer;
    FIsLoading: boolean;
    FGlyphs: TFontImageDataArray;
    FOnInitialize: TNotifyEvent;
    FSize: TSize;
    FFontData: TMemoryStream;
    FDummy: string;
    FResolutions: TFontImageResCollection;
    procedure SetDefaultResolution(AValue: integer);
    procedure SetGlyphs(AValue: TFontImageDataArray);
    procedure SetOnInitialize(AValue: TNotifyEvent);
    procedure SetResolutions(AValue: TFontImageResCollection);
    procedure SetSize(AValue: TSize);
  protected
    procedure Loaded; override;
    procedure DefineProperties(Filer: TFiler); override;
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
    property DefaultResolution: integer read FDefaultResolution write SetDefaultResolution;
    property Resolutions: TFontImageResCollection read FResolutions write SetResolutions;
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

{ TFontImageResItem }

procedure TFontImageResItem.SetResolution(AValue: integer);
begin
  // Clamped rather than raising, so a hand-edited LFM still loads
  if AValue < 1 then AValue := 1;
  if FResolution = AValue then Exit;

  FResolution := AValue;
  Changed(False);
end;

function TFontImageResItem.GetDisplayName: string;
begin
  Result := Format('%0:d x %0:d', [FResolution]);
end;

constructor TFontImageResItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FResolution := 16;
end;

procedure TFontImageResItem.Assign(Source: TPersistent);
begin
  if Source is TFontImageResItem then
    Resolution := TFontImageResItem(Source).Resolution
  else
    inherited Assign(Source);
end;

{ TFontImageResCollection }

function TFontImageResCollection.GetItem(AIndex: integer): TFontImageResItem;
begin
  Result := TFontImageResItem(inherited Items[AIndex]);
end;

procedure TFontImageResCollection.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FImageList) then
    FImageList.RegenerateImages;

end;

constructor TFontImageResCollection.Create(AImageList: TFontImageList);
begin
  inherited Create(AImageList, TFontImageResItem);
  FImageList := AImageList;
end;

function TFontImageResCollection.Add(AResolution: integer): TFontImageResItem;
begin
  Result := TFontImageResItem(inherited Add);
  Result.Resolution := AResolution;
end;

function TFontImageResCollection.GetUniqueSortedResolutions: TIntegerDynArray;
var
  I, J, CurrentValue, UniqueCount: integer;
  Exists: boolean;
begin
  SetLength(Result, Count);
  UniqueCount := 0;

  for I := 0 to Count - 1 do
  begin
    CurrentValue := TFontImageResItem(Items[I]).Resolution;
    Exists := False;
    for J := 0 to UniqueCount - 1 do
      if Result[J] = CurrentValue then
      begin
        Exists := True;
        Break;
      end;

    if not Exists then
    begin
      Result[UniqueCount] := CurrentValue;
      Inc(UniqueCount);
    end;
  end;

  SetLength(Result, UniqueCount);

  for i := 1 to UniqueCount - 1 do
  begin
    CurrentValue := Result[i];
    j := i - 1;
    while (j >= 0) and (Result[j] > CurrentValue) do
    begin
      Result[j + 1] := Result[j];
      Dec(j);
    end;
    Result[j + 1] := CurrentValue;
  end;
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
  FResolutions := TFontImageResCollection.Create(self);
  SetLength(FGlyphs, 0);
end;

destructor TFontImageList.Destroy;
begin
  SetLength(FGlyphs, 0);
  FFontData.Free;
  FResolutions.Free;
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

procedure TFontImageList.SetGlyphs(AValue: TFontImageDataArray);
begin
  if FGlyphs = AValue then Exit;
  FGlyphs := AValue;
  RegenerateImages;
end;

procedure TFontImageList.SetDefaultResolution(AValue: integer);
begin
  if FDefaultResolution = AValue then Exit;
  FDefaultResolution := AValue;
  if FResolutions.Count = 0 then
    RegenerateImages;
end;

procedure TFontImageList.SetOnInitialize(AValue: TNotifyEvent);
begin
  FOnInitialize := AValue;
end;

procedure TFontImageList.SetResolutions(AValue: TFontImageResCollection);
begin
  if FResolutions = AValue then Exit;
  FResolutions := AValue;
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
  Res: TIntegerDynArray;
  Bitmaps: array of TRasterImage;
  i: integer;
begin
  if FIsLoading or (csLoading in ComponentState) then Exit;
  if FFontData.Size = 0 then
    exit;
  Clear;
  if FResolutions.Count = 0 then
  begin
    SetLength(Res, 1);
    SetLength(Bitmaps, 1);
    Res[0] := DefaultResolution;
  end
  else
  begin
    Res := FResolutions.GetUniqueSortedResolutions;
    SetLength(Bitmaps, Length(Res));
  end;

  RegisterResolutions(res);
  try
    IconRenderer := TIconRenderer.Create(FFontData);
    for item in FGlyphs do
    begin
      if IsSysColor(Item.Color) then
        IconRenderer.Color := GetSysColor(SysColorToSysColorIndex(Item.Color))
      else
        IconRenderer.Color := Item.Color;

      for i := 0 to Length(res) - 1 do
      begin
        //  IconRenderer.SetSize(Height, Width, Scaled); // Scaling occurs inside object, no need to do it here
        IconRenderer.SetSize(Res[I], Res[i], Scaled); // Scaling occurs inside object, no need to do it here

        bmp := TBitmap.Create;
        IconRenderer.getGlyph(Item.GliphIndex, Bmp); //;then
        Bitmaps[i] := bmp;
      end;
      AddMultipleResolutions(Bitmaps);
      for i := 0 to Length(res) - 1 do
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
