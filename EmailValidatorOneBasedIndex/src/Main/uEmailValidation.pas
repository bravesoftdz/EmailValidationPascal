unit uEmailValidation;

{$IFNDEF FPC}
{$IF CompilerVersion >= 23}  // XE2 and Above
{$DEFINE SCOPEDUNITNAMES}
{$IFEND}
{$IF CompilerVersion >= 24}  // XE3 and Above
{$ZEROBASEDSTRINGS OFF}
{$IFEND}
{$ENDIF}

interface

uses

{$IFNDEF FPC}
{$IFDEF SCOPEDUNITNAMES}
  System.SysUtils;
{$ELSE}
  SysUtils;
{$ENDIF}
{$ELSE}
SysUtils;
{$ENDIF FPC}

type
  /// <summary>
  /// An Email validator.
  /// </summary>
  /// <remarks>
  /// An Email validator.
  /// </remarks>
  TEmailValidator = class
  strict private

  class var
  const
    atomCharacters: String = '!#$%&''*+-/=?^_`{|}~';

  type

    TSubDomainType = (None = 0, Alphabetic = 1, Numeric = 2, AlphaNumeric = 3);

  class function MyIndexOf(C: Char; const InString: String): Integer; static;
  class function IsDigit(C: Char): Boolean; static;
  class function IsLetter(C: Char): Boolean; static;
  class function IsLetterOrDigit(C: Char): Boolean; static;
  class function IsAtom(C: Char; allowInternational: Boolean): Boolean; static;
  class function IsDomain(C: Char; allowInternational: Boolean;
    var dtype: TSubDomainType): Boolean; static;
  class function IsDomainStart(C: Char; allowInternational: Boolean;
    out dtype: TSubDomainType): Boolean; static;
  class function SkipAtom(const Text: String; var Index: Integer;
    allowInternational: Boolean): Boolean; static;
  class function SkipSubDomain(const Text: String; var Index: Integer;
    allowInternational: Boolean; out dtype: TSubDomainType): Boolean; static;
  class function SkipDomain(const Text: String; var Index: Integer;
    allowTopLevelDomains, allowInternational: Boolean): Boolean; static;
  class function SkipQuoted(const Text: String; var Index: Integer;
    allowInternational: Boolean): Boolean; static;
  class function SkipIPv4Literal(const Text: String; var Index: Integer)
    : Boolean; static;
  class function IsHexDigit(C: Char): Boolean; static;
  class function SkipIPv6Literal(const Text: String; var Index: Integer)
    : Boolean; static;

  public

    /// <summary>
    /// Validate the specified email address.
    /// </summary>
    /// <remarks>
    /// <para>Validates the syntax of an email address.</para>
    /// <para>If <paramref name="allowInternational"/> is <value>true</value>, then the validator
    /// will use the newer International Email standards for validating the email address.</para>
    /// </remarks>
    /// <returns><c>true</c> if the email address is valid; otherwise <c>false</c>.</returns>
    /// <param name="Email">An email address.</param>
    /// <param name="allowTopLevelDomains"><value>true</value> if the validator should allow addresses at top-level domains; otherwise, <value>false</value>.</param>
    /// <param name="allowInternational"><value>true</value> if the validator should allow international characters; otherwise, <value>false</value>.</param>
    /// <exception cref="System.SysUtils.EArgumentNilException">
    /// <paramref name="Email"/> is <c>Empty</c>.
    /// </exception>

    class function Validate(const Email: String;
      allowTopLevelDomains: Boolean = False;
      allowInternational: Boolean = False): Boolean; static;

  end;

  EArgumentNilException = class(Exception);

implementation

class function TEmailValidator.MyIndexOf(C: Char;
  const InString: String): Integer;

begin
  Result := Pos(C, InString) - 1;
end;

class function TEmailValidator.IsDigit(C: Char): Boolean;
begin
  Result := ((C >= '0') and (C <= '9'));
end;

class function TEmailValidator.IsLetter(C: Char): Boolean;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z'));
end;

class function TEmailValidator.IsLetterOrDigit(C: Char): Boolean;
begin

  Result := (IsLetter(C)) or (IsDigit(C));
end;

class function TEmailValidator.IsAtom(C: Char;
  allowInternational: Boolean): Boolean;

begin
  if Ord(C) < 128 then
    Result := ((IsLetterOrDigit(C)) or (MyIndexOf(C, atomCharacters) <> -1))
  else
    Result := allowInternational;
end;

class function TEmailValidator.IsDomain(C: Char; allowInternational: Boolean;
  var dtype: TSubDomainType): Boolean;

begin

  if (Ord(C) < 128) then
  begin
    if (IsLetter(C) or (C = '-')) then
    begin
      dtype := TSubDomainType(Ord(dtype) or Ord(TSubDomainType.Alphabetic));
      Result := true;
      Exit;
    end;

    if (IsDigit(C)) then
    begin
      dtype := TSubDomainType(Ord(dtype) or Ord(TSubDomainType.Numeric));
      Result := true;
      Exit;
    end;

    Result := False;
    Exit;
  end;

  if (allowInternational) then
  begin
    dtype := TSubDomainType(Ord(dtype) or Ord(TSubDomainType.Alphabetic));
    Result := true;
    Exit;
  end;

  Result := False;
end;

class function TEmailValidator.IsDomainStart(C: Char;
  allowInternational: Boolean; out dtype: TSubDomainType): Boolean;

begin

  if (Ord(C) < 128) then
  begin
    if (IsLetter(C)) then
    begin
      dtype := TSubDomainType.Alphabetic;
      Result := true;
      Exit;
    end;

    if (IsDigit(C)) then
    begin
      dtype := TSubDomainType.Numeric;
      Result := true;
      Exit;
    end;

    Result := False;
    Exit;
  end;

  if (allowInternational) then
  begin
    dtype := TSubDomainType.Alphabetic;
    Result := true;
    Exit;
  end;

  dtype := TSubDomainType.None;

  Result := False;
end;

class function TEmailValidator.SkipAtom(const Text: String; var Index: Integer;
  allowInternational: Boolean): Boolean;
var
  startIndex: Integer;

begin
  startIndex := Index;
  while ((Index < Length(Text)) and (IsAtom(Text[Index + 1],
    allowInternational))) do
  begin
    Inc(Index);
  end;
  Result := Index > startIndex;
end;

class function TEmailValidator.SkipSubDomain(const Text: String;
  var Index: Integer; allowInternational: Boolean;
  out dtype: TSubDomainType): Boolean;
var
  startIndex: Integer;

begin
  startIndex := Index;
  if (not IsDomainStart(Text[Index + 1], allowInternational, dtype)) then
  begin
    Result := False;
    Exit;
  end;
  Inc(Index);
  while ((Index < Length(Text)) and IsDomain(Text[Index + 1],
    allowInternational, dtype)) do
  begin
    Inc(Index);
  end;

  Result := ((Index - startIndex) < 64) and (Text[Index] <> '-');
end;

class function TEmailValidator.SkipDomain(const Text: String;
  var Index: Integer; allowTopLevelDomains, allowInternational
  : Boolean): Boolean;

var
  dtype: TSubDomainType;

begin

  if (not SkipSubDomain(Text, Index, allowInternational, dtype)) then
  begin
    Result := False;
    Exit;
  end;
  if ((Index < Length(Text)) and ((Text[Index + 1]) = '.')) then
  begin

    while (Index < Length(Text)) and ((Text[Index + 1]) = '.') do
    begin
      Inc(Index);
      if (Index = Length(Text)) then
      begin
        Result := False;
        Exit;
      end;

      if (not SkipSubDomain(Text, Index, allowInternational, dtype)) then
      begin
        Result := False;
        Exit;
      end;

    end;

  end
  else if (not allowTopLevelDomains) then

  begin
    Result := False;
    Exit;
  end;

  // Note: by allowing AlphaNumeric, we get away with not having to support punycode.
  if (dtype = TSubDomainType.Numeric) then
  begin
    Result := False;
    Exit;
  end;

  Result := true;
end;

class function TEmailValidator.SkipQuoted(const Text: String;
  var Index: Integer; allowInternational: Boolean): Boolean;
var
  Escaped: Boolean;

begin
  Escaped := False;
  // skip over leading '"'
  Inc(Index);
  while (Index < Length(Text)) do
  begin
    if (Ord(Text[Index + 1]) >= 128) and (not allowInternational) then
    begin
      Result := False;
      Exit;
    end;
    if ((Text[Index + 1]) = '\') then
    begin
      Escaped := not Escaped;
    end

    else if (not Escaped) then
    begin
      if ((Text[Index + 1]) = '"') then
        Break;
    end
    else
    begin
      Escaped := False;
    end;
    Inc(Index);
  end;

  if ((Index >= Length(Text)) or ((Text[Index + 1]) <> '"')) then
  begin
    Result := False;
    Exit;
  end;

  Inc(Index);

  Result := true;

end;

class function TEmailValidator.SkipIPv4Literal(const Text: String;
  var Index: Integer): Boolean;
var
  Groups, startIndex, Value: Integer;

begin
  Groups := 0;
  while ((Index < Length(Text)) and (Groups < 4)) do
  begin
    startIndex := Index;
    Value := 0;
    while ((Index < Length(Text)) and ((Text[Index + 1]) >= '0') and
      ((Text[Index + 1]) <= '9')) do
    begin
      Value := (Value * 10) + Ord(Text[Index + 1]) - Ord('0');
      Inc(Index);

    end;

    if ((Index = startIndex) or (Index - startIndex > 3) or (Value > 255)) then
    begin
      Result := False;
      Exit;
    end;

    Inc(Groups);
    if ((Groups < 4) and (Index < Length(Text)) and ((Text[Index + 1]) = '.'))
    then
      Inc(Index);
  end;
  Result := Groups = 4;
end;

class function TEmailValidator.IsHexDigit(C: Char): Boolean;
begin

  Result := ((C >= 'A') and (C <= 'F')) or ((C >= 'a') and (C <= 'f')) or
    ((C >= '0') and (C <= '9'));

end;

// This needs to handle the following forms:
//
// IPv6-addr = IPv6-full / IPv6-comp / IPv6v4-full / IPv6v4-comp
// IPv6-hex  = 1*4HEXDIG
// IPv6-full = IPv6-hex 7(":" IPv6-hex)
// IPv6-comp = [IPv6-hex *5(":" IPv6-hex)] "::" [IPv6-hex *5(":" IPv6-hex)]
// ; The "::" represents at least 2 16-bit groups of zeros
// ; No more than 6 groups in addition to the "::" may be
// ; present
// IPv6v4-full = IPv6-hex 5(":" IPv6-hex) ":" IPv4-address-literal
// IPv6v4-comp = [IPv6-hex *3(":" IPv6-hex)] "::"
// [IPv6-hex *3(":" IPv6-hex) ":"] IPv4-address-literal
// ; The "::" represents at least 2 16-bit groups of zeros
// ; No more than 4 groups in addition to the "::" and
// ; IPv4-address-literal may be present

class function TEmailValidator.SkipIPv6Literal(const Text: String;
  var Index: Integer): Boolean;
var
  Compact: Boolean;
  Colons, startIndex, Count: Integer;
begin
  Compact := False;
  Colons := 0;
  while (Index < Length(Text)) do
  begin
    startIndex := Index;
    while ((Index < Length(Text)) and (IsHexDigit(Text[Index + 1]))) do
    begin
      Inc(Index);

    end;
    if (Index >= Length(Text)) then
      Break;

    if (((Index > startIndex) and (Colons > 2) and (Text[Index + 1] = '.')))
    then
    begin
      // IPv6v4
      Index := startIndex;

      if (not SkipIPv4Literal(Text, Index)) then
      begin
        Result := False;
        Exit;
      end;

      if Compact then
      begin
        Result := Colons < 6;
        Exit;
      end
      else
      begin
        Result := Colons = 6;
        Exit;

      end;
    end;

    Count := Index - startIndex;
    if (Count > 4) then
    begin
      Result := False;
      Exit;
    end;

    if (Text[Index + 1] <> ':') then
      Break;

    startIndex := Index;
    while ((Index < Length(Text)) and (Text[Index + 1] = ':')) do
    begin
      Inc(Index);
    end;
    Count := Index - startIndex;
    if (Count > 2) then
    begin
      Result := False;
      Exit;
    end;

    if (Count = 2) then
    begin
      if (Compact) then
      begin
        Result := False;
        Exit;
      end;
      Compact := true;
      Colons := Colons + 2;
    end
    else
    begin
      Inc(Colons);
    end;

  end;

  if (Colons < 2) then
  begin
    Result := False;
    Exit;
  end;

  if (Compact) then
  begin
    Result := Colons < 7;
    Exit;
  end
  else
  begin
    Result := Colons = 7;
    Exit;
  end;

end;

class function TEmailValidator.Validate(const Email: String;
  allowTopLevelDomains: Boolean = False;
  allowInternational: Boolean = False): Boolean;
var
  Index: Integer;
  ipv6: String;
begin
  Index := 0;
  if (Email = '') then
    raise EArgumentNilException.Create('Email');
  if ((Length(Email) = 0) or (Length(Email) >= 255)) then
  begin
    Result := False;
    Exit;
  end;

  // Local-part = Dot-string / Quoted-string
  // ; MAY be case-sensitive
  //
  // Dot-string = Atom *("." Atom)
  //
  // Quoted-string = DQUOTE *qcontent DQUOTE
  if (Email[Index + 1] = '"') then
  begin
    if (not SkipQuoted(Email, Index, allowInternational) or
      (Index >= Length(Email))) then
    begin
      Result := False;
      Exit;
    end;
  end
  else
  begin
    if (not SkipAtom(Email, Index, allowInternational) or
      (Index >= Length(Email))) then
    begin
      Result := False;
      Exit;
    end;

    while (Email[Index + 1] = '.') do
    begin
      Inc(Index);

      if (Index >= Length(Email)) then
      begin
        Result := False;
        Exit;
      end;

      if (not SkipAtom(Email, Index, allowInternational)) then
      begin
        Result := False;
        Exit;
      end;

      if (Index >= Length(Email)) then
      begin
        Result := False;
        Exit;
      end;
    end;

  end;

  if ((Index + 1 >= Length(Email)) or (Index > 64) or (Email[Index + 1] <> '@'))
  then
  begin
    Result := False;
    Exit;
  end;

  Inc(Index);
  if (Email[Index + 1] <> '[') then
  begin
    // domain
    if (not SkipDomain(Email, Index, allowTopLevelDomains, allowInternational))
    then
    begin
      Result := False;
      Exit;
    end;

    Result := Index = Length(Email);
    Exit;
  end;
  // address literal
  Inc(Index);
  // we need at least 8 more characters
  if (Index + 8 >= Length(Email)) then
  begin
    Result := False;
    Exit;
  end;

  ipv6 := Copy(Email, Index + 1, 5);

  if (AnsiLowerCase(ipv6) = 'ipv6:') then
  begin
    Index := Index + Length('IPv6:');
    if (not SkipIPv6Literal(Email, Index)) then
    begin
      Result := False;
      Exit;
    end;
  end
  else
  begin
    if (not SkipIPv4Literal(Email, Index)) then
    begin
      Result := False;
      Exit;
    end;
  end;

  if ((Index >= Length(Email)) or (Email[Index + 1] <> ']')) then
  begin
    Result := False;
    Exit;
  end;
  Inc(Index);
  Result := Index = Length(Email);

end;

end.
