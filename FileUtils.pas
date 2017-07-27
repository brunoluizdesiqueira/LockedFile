{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Wrapper de recursos da API do Windows voltados para tratamentos de arquivos para ser usada em outras classes.
}
unit FileUtils;

interface

uses
  Windows,
  SysUtils,
  StrUtils,
  PsAPI,
  TLHelp32,
  SystemError;
Type
  TFileUtils = class(TObject)
  public
    class function TerminarProcesso(pFile: String): Boolean;
    class function GetAttributes(pPathFile: string): string;
    class function LockedFile(pFileName: TFileName): Boolean;
    class function IsItLockedRead(pFileName: TFileName): Boolean;
    class function IsItLocked(pFileName: TFileName): Boolean;
  end;

implementation
const
  SOMENTE_LEITURA = 'Somente leitura';
  OCULTO = 'Oculto';
  ARQUIVO_SISTEMA = 'Arquivo de sistema';
  ROTULO_DISCO = 'Rótulo de disco';
  FICHEIRO_ARQUIVO = 'Arquivo';
  DIRETORIO = 'Diretório';
  PONTEIRO_SIMBOLICO = 'Ponteiro simbólico';
  NAO_DISPONIVEL = 'N/A';

class function TFileUtils.TerminarProcesso(pFile: String): Boolean;
var
  verSystem: TOSVersionInfo;
  hdlSnap,hdlProcess: THandle;
  bPath,bLoop: Bool;
  peEntry: TProcessEntry32;
  arrPid: Array [0..1023] of DWORD;
  iC: DWord;
  k, iCount: Integer;
  arrModul: Array [0..299] of Char;
  hdlModul: HMODULE;
begin
  Result := False;
  bPath := True;

  if ExtractFileName(pFile) = pFile then
    bPath := False;

  verSystem.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);

  GetVersionEx(verSystem);

  if verSystem.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
    begin
      hdlSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
      peEntry.dwSize := Sizeof(peEntry);
      bLoop := Process32First(hdlSnap, peEntry);

      while Integer(bLoop) <> 0 do
      begin
        if bPath then
          begin
            if CompareText(peEntry.szExeFile, pFile) = 0 then
            begin
              TerminateProcess(OpenProcess(PROCESS_TERMINATE, False, peEntry.th32ProcessID), 0);
              Result := True;
            end;
          end
        else
        begin
          if CompareText(ExtractFileName(peEntry.szExeFile), pFile) = 0 then
          begin
            TerminateProcess(OpenProcess(PROCESS_TERMINATE, False, peEntry.th32ProcessID), 0);
            Result := True;
          end;
        end;
        bLoop := Process32Next(hdlSnap, peEntry);
      end;
      CloseHandle(hdlSnap);
    end
  else
  if verSystem.dwPlatformId = VER_PLATFORM_WIN32_NT then
    begin
      EnumProcesses(@arrPid, SizeOf(arrPid), iC);
      iCount := iC div SizeOf(DWORD);

      for k := 0 to Pred(iCount) do
      begin
        hdlProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, arrPid [k]);

        if (hdlProcess <> 0) then
        begin
          EnumProcessModules(hdlProcess, @hdlModul, SizeOf(hdlModul), iC);
          GetModuleFilenameEx(hdlProcess, hdlModul, arrModul, SizeOf(arrModul));

          if bPath then
            begin
              if CompareText(arrModul, pFile) = 0 then
              begin
                TerminateProcess(OpenProcess(PROCESS_TERMINATE or PROCESS_QUERY_INFORMATION, False, arrPid [k]), 0);
                Result := True;
              end;
            end
          else
            begin
              if CompareText(ExtractFileName(arrModul), pFile) = 0 then
              begin
                TerminateProcess(OpenProcess(PROCESS_TERMINATE or PROCESS_QUERY_INFORMATION, False, arrPid [k]), 0);
                Result := True;
              end;
            end;
          CloseHandle(hdlProcess);
        end;
      end;
    end;
end;

class function TFileUtils.LockedFile(pFileName: TFileName): Boolean;
begin
  Result := (IsItLocked(pFileName) or IsItLockedRead(pFileName));
end;

class function TFileUtils.IsItLockedRead(pFileName: TFileName): Boolean;
var
  H: THandle;
begin
  H := Windows.CreateFile(PChar(pFileName),
                          GENERIC_READ, FILE_SHARE_READ,
                          nil,
                          OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL, 0);
  Result := (h = INVALID_HANDLE_VALUE);

  if not Result then CloseHandle(h);
end;

class function TFileUtils.IsItLocked(pFileName: TFileName): Boolean;
var
  H: THandle;
begin
  H := Windows.CreateFile(PChar(pFileName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (H = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(h);
end;

class function TFileUtils.GetAttributes(pPathFile: string): string;
var
  lAttributes: Longint;
  lResult : string;
begin
  lResult := '';
  lAttributes := FileGetAttr(pPathFile);

  if (lAttributes <> -1) then
    begin
      if (lAttributes and faArchive) = faArchive then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + FICHEIRO_ARQUIVO, FICHEIRO_ARQUIVO);

      if (lAttributes and faDirectory) = faDirectory then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + DIRETORIO, DIRETORIO);

      if (lAttributes and faReadOnly) = faReadOnly then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + SOMENTE_LEITURA, SOMENTE_LEITURA);

      if (lAttributes and faHidden) = faHidden then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + OCULTO, OCULTO);

      if (lAttributes and faSysFile) = faSysFile then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + ARQUIVO_SISTEMA, ARQUIVO_SISTEMA);

      if (lAttributes and faVolumeID) = faVolumeID then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + ROTULO_DISCO, ROTULO_DISCO);

      if (lAttributes and faSymLink) = faSymLink then
        lResult := IfThen((lResult <> ''),  lResult + ', ' + PONTEIRO_SIMBOLICO, PONTEIRO_SIMBOLICO);
    end
  else
    lResult := NAO_DISPONIVEL;

  Result := lResult;
end;

end.
