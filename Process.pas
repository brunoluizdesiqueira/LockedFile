{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Classe que mantem informações sobre o processo bloqueador de recurso.
}

unit Process;

interface

uses
  Windows,
  TlHelp32,
  Classes,
  SysUtils,
  StrUtils,
  FileUtils,
  SystemError,
  PsApi;
type
  PTokenUser = ^TTokenUser;
  TTokenUser = record
    User: TSIDAndAttributes;
  end;

  TProcess = class
  private
    FID: Cardinal;
    FPathFile: string;
    FPath: string;
    FName: string;
    FServiceShortName : string;
    FAppType: Cardinal;
    FUser: string;
    FDomain: string;

    procedure FinalizarDLL();
    function InicializarDLL(): Boolean;
    function GetFullName(): string;
    function GetAttributes(): string;
    function GetPathProcess(): string;
    function QueryImagePath(): string;

  protected
    procedure GetUserInformation();

  public
    constructor Create(const AID: Cardinal; const AName: string);

    // Recupera mais informações sobre o processo, usando o ID de processo já fornecido
    procedure Query;
    // ID do pocesso, atribuído pelo sistema Windows
    property ID: Cardinal read FID;
    // Local do executavel do processo
    property PathProcess: string read GetPathProcess;
    // Local do arquivo em processamento
    property PathFile: string read FPathFile write FPathFile;
    // Local do executavel do processo recuperado usando outro recurso do windows
    property Path: string read FPath write FPath;
    // Nome do processo, normalmente é o nome do executável
    property Name: string read FName write FName;
    // Retorna o nome abreviado do serviço apenas no caso em que o processo for um serviço
    property ServiceShortName: string read FServiceShortName write FServiceShortName;
    // Especifica o tipo de aplicativo
    property AppType: Cardinal read FAppType write FAppType;
    // Combinação do caminho e do nome
    property Fullname: string read GetFullName;
    // Nome do usuário que cria o processo (executa seu executável)
    property User: string read FUser;
    // Domínio de rede do usuário
    property Domain: string read FDomain;
    // Retorna os tríbutos do arquivo: readonly, Hidden e etc
    property Attributes: string read GetAttributes;
  end;

implementation

const
  KERNEL32_LIB = 'KERNEL32.dll';
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  MAXLEN: integer = 4096;

var
  _QueryFullProcessImageName: function (hProcess: THandle; dwFlags: DWORD; lpFilename: LPCWSTR; var nSize: DWORD): BOOL; stdcall;
  _QueryFullProcessImageNameA: function (hProcess: THandle; dwFlags: DWORD; lpFilename: LPCSTR; var nSize: DWORD): BOOL; stdcall;
  _QueryFullProcessImageNameW: function (hProcess: THandle; dwFlags: DWORD; lpFilename: LPCWSTR; var nSize: DWORD): BOOL; stdcall;

   KERNEL32Library: THandle;

function TProcess.InicializarDLL: Boolean;
begin
  // Apenas tente carregar KERNEL32.dll se estiver executando o Windows Vista ou posterior
  if (Lo(GetVersion) >= 6) then
  begin
    KERNEL32Library := LoadLibrary(KERNEL32_LIB);

    if (KERNEL32Library <> 0) then
    begin
      _QueryFullProcessImageName := GetProcAddress(KERNEL32Library, 'QueryFullProcessImageNameW');
      _QueryFullProcessImageNameA := GetProcAddress(KERNEL32Library, 'QueryFullProcessImageNameA');
      _QueryFullProcessImageNameW := GetProcAddress(KERNEL32Library, 'QueryFullProcessImageNameW');
    end;
  end;
  Result := KERNEL32Library <> 0;
end;

procedure TProcess.FinalizarDLL;
begin
  if KERNEL32Library <> 0 then
  begin
    FreeLibrary(KERNEL32Library);

    KERNEL32Library := 0;

    _QueryFullProcessImageName  := nil;
    _QueryFullProcessImageNameA := nil;
    _QueryFullProcessImageNameW := nil;
  end;
end;

function TProcess.QueryImagePath(): string;
var
  p: THandle;
  l: DWORD;
  DesiredAccess: cardinal;
  Found : Boolean;
begin
  Result := '';
  Found := False;

  try
    if InicializarDLL() then
    begin
      // QueryFullProcessImageName é mais confiável do que: GetModuleFileNameEx
      if SysUtils.Win32MajorVersion >= 6 then
        DesiredAccess := PROCESS_QUERY_LIMITED_INFORMATION // Windows Vista ou superior
      else
        DesiredAccess := PROCESS_QUERY_INFORMATION;

      p := OpenProcess(DesiredAccess, False, FID);

      if (SysUtils.Win32MajorVersion >= 6) and
         (KERNEL32Library <> 0) and
         (p <> 0) then
      begin
        try
          SetLength(Result, MAXLEN);
          l := length(Result) -1;

          if _QueryFullProcessImageName(p, 0, PWideChar(PChar(Result)), l) then
          begin
            SetLength(Result, length(Result) - 1);
            Found := True;
          end;
        finally
          CloseHandle(p);
        end;
      end;

      // Caso não tenha encontrado o Path do processo, tenta retornar com a GetModuleFileNameEx
      if (not Found) then
      begin
        p := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, FID);

        if p <> 0 then
        begin
          try
            SetLength(Result, MAXLEN);
            l := length(Result) -1;
            SetLength(Result, GetModuleFileNameEx(p, 0, PChar(Result), length(Result) - 1));
          finally
            CloseHandle(p);
          end;
        end;
      end;

      Result := Format('%s', [PWideChar(PChar(Result))]);
    end;
  finally
    FinalizarDLL;
  end;
end;

constructor TProcess.Create(const AID: Cardinal; const AName: string);
begin
  FID := AID;
  FName := AName;
  Query;
end;

procedure TProcess.Query;
begin
  GetUserInformation;
  GetFullName;
end;

function TProcess.GetPathProcess: string;
var
  vSnapshot: THandle;
  vModuleEntry: TModuleEntry32;
begin
  Result := QueryImagePath();

  if (Trim(Result) = '') or (not FileExists(Result)) then
  begin
    Result := '';
    vSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, FID);

    if (vSnapShot = 0) or (vSnapshot = INVALID_HANDLE_VALUE) then
      Exit;

    try
      vModuleEntry.dwSize := SizeOf(TModuleEntry32);

      if not Module32First(vSnapshot, vModuleEntry) then
        raise ESystemError.Create;

      Result := vModuleEntry.szExePath;
    finally
      CloseHandle(vSnapshot);
    end;
  end;
end;

procedure TProcess.GetUserInformation;
var
  vHandle: THandle;
  vToken : THandle;
  vUserName: array[0..255] of char;
  vDomainName: array[0..255] of char;
  vUserNameSize: DWORD;
  vDomainNameSize: DWORD;
  vTokenUser: PTokenUser;
  vInfoSize: Cardinal;
  vUse: SID_NAME_USE;
begin
  FUser := '';
  FDomain := '';

  vHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, FID);
  if vHandle > 0 then
  try
    if OpenProcessToken(vHandle, TOKEN_QUERY, vToken) then
    try
      GetTokenInformation(vToken, TokenUser, nil, 0, vInfoSize);
      vUserNameSize := SizeOf(vUserName);
      vDomainNameSize := SizeOf(vDomainName);
      vUse := SidTypeUser;
      GetMem(vTokenUser, vInfoSize);
      try
        if not GetTokenInformation(vToken, TokenUser, vTokenUser, vInfoSize, vInfoSize) then
          raise ESystemError.Create;

        LookupAccountSid(nil, vTokenUser.User.Sid, @vUserName, vUserNameSize, @vDomainName, vDomainNameSize, vUse);
        FUser := vUserName;
        FDomain := vDomainName;
      finally
        FreeMem(vTokenUser);
      end;
    finally
      CloseHandle(vToken);
    end;
  finally
    CloseHandle(vHandle);
  end;
end;

function TProcess.GetFullName: string;
begin
  if FPath = '' then
    Result := FName
  else
    Result := FPath + '\' + FName;
end;

function TProcess.GetAttributes: string;
begin
  Result := TFileUtils.GetAttributes(PathFile);
end;

end.
