{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Interface básica da API do RestartManager compativel para Delphi 2 e superior
}
unit RestartManager;
{$IFNDEF VER90}
{$IFNDEF VER93}
  {$DEFINE Delphi3orHigher}
{$ENDIF}
{$ENDIF}

interface

uses
  {$IFNDEF Delphi3orHigher}
  OLE2,
  {$ELSE}
  ActiveX,
  {$ENDIF}
  Windows,
  SysUtils,
  Security,
  Process,
  Processes,
  RestartManagerExceptions;

const
  RESTART_MANAGER_LIB = 'Rstrtmgr.dll';
  RM_SESSION_KEY_LEN = SizeOf(TGUID);
  CCH_RM_SESSION_KEY = RM_SESSION_KEY_LEN*2;
  CCH_RM_MAX_APP_NAME = 255;
  CCH_RM_MAX_SVC_NAME = 63;
  RM_INVALID_TS_SESSION = -1;
  RM_INVALID_PROCESS = -1;

  RmUnknownApp = 0;
  RmMainWindow = 1;
  RmOtherWindow = 2;
  RmService = 3;
  RmExplorer = 4;
  RmConsole = 5;
  RmCritical = 1000;

  RmForceShutdown = $01;
  RmShutdownOnlyRegistered = $10;

  RmRebootReasonNone = $0;
  RmRebootReasonPermissionDenied = $1;
  RmRebootReasonSessionMismatch = $2;
  RmRebootReasonCriticalProcess = $4;
  RmRebootReasonCriticalService = $8;
  RmRebootReasonDetectedSelf = $10;

  ERROR_MORE_DATA = 234;

type
  RM_APP_TYPE = DWORD;
  RM_SHUTDOWN_TYPE = DWORD;
  RM_REBOOT_REASON = DWORD;

  RM_UNIQUE_PROCESS = record
    dwProcessId: DWORD;
    ProcessStartTime: TFileTime;
  end;

  RM_PROCESS_INFO = record
    Process: RM_UNIQUE_PROCESS;
    strAppName: array[0..CCH_RM_MAX_APP_NAME] of WideChar;
    strServiceShortName: array[0..CCH_RM_MAX_SVC_NAME] of WideChar;
    ApplicationType: RM_APP_TYPE;
    AppStatus: ULONG;
    TSSessionId: DWORD;
    bRestartable: BOOL;
  end;

Type
  TRestartManager = class(TObject)
  public
    class procedure Destruir;
    class procedure Finalizar;
    class function Inicializar: Boolean;
    class function UsandoRestartManager: Boolean;
    class function ListaProcessosBloqueadores(Path: string): TProcesses;
  end;

implementation

var
  RmStartSession: function (var pSessionHandle: DWORD; dwSessionFlags: DWORD; strSessionKey: LPWSTR): DWORD; stdcall;
  RmRegisterResources: function (dwSessionHandle: DWORD; nFiles: UINT; rgsFilenames: PPWideChar; nApplications: UINT; rgApplications: Pointer; nServices: UINT; rgsServiceNames: Pointer): DWORD; stdcall;
  RmGetList: function (dwSessionHandle: DWORD; pnProcInfoNeeded, pnProcInfo: PUINT; rgAffectedApps: Pointer; lpdwRebootReasons: LPDWORD): DWORD; stdcall;
  RmShutdown: function (dwSessionHandle: DWORD; lActionFlags: ULONG; fnStatus: Pointer): DWORD; stdcall;
  RmRestart: function (dwSessionHandle: DWORD; dwRestartFlags: DWORD; fnStatus: Pointer): DWORD; stdcall;
  RmEndSession: function (dwSessionHandle: DWORD): DWORD; stdcall;

  RestartManagerLibrary: THandle;
  ReferenceCount: Integer;  // Temos de acompanhar várias chamadas de carga / descarga.

class function TRestartManager.Inicializar: Boolean;
begin
  Inc(ReferenceCount);

  // Apenas tente carregar rstrtmgr.dll se estiver executando o Windows Vista ou posterior
  if (RestartManagerLibrary = 0) and (Lo(GetVersion) >= 6) then
  begin
    RestartManagerLibrary := LoadLibrary(RESTART_MANAGER_LIB);

    if RestartManagerLibrary <> 0 then
    begin
      RmStartSession := GetProcAddress(RestartManagerLibrary, 'RmStartSession');
      RmRegisterResources := GetProcAddress(RestartManagerLibrary, 'RmRegisterResources');
      RmGetList := GetProcAddress(RestartManagerLibrary, 'RmGetList');
      RmShutdown := GetProcAddress(RestartManagerLibrary, 'RmShutdown');
      RmRestart := GetProcAddress(RestartManagerLibrary, 'RmRestart');
      RmEndSession := GetProcAddress(RestartManagerLibrary, 'RmEndSession');
    end;
  end;
  Result := RestartManagerLibrary <> 0;
end;

class procedure TRestartManager.Finalizar;
begin
  if ReferenceCount > 0 then
    Dec(ReferenceCount);

  if (RestartManagerLibrary <> 0) and (ReferenceCount = 0) then
  begin
    FreeLibrary(RestartManagerLibrary);
    RestartManagerLibrary := 0;

    RmStartSession := nil;
    RmRegisterResources := nil;
    RmGetList := nil;
    RmShutdown := nil;
    RmRestart := nil;
    RmEndSession := nil;
  end;
end;

class function TRestartManager.UsandoRestartManager: Boolean;
begin
  Result := RestartManagerLibrary <> 0;
end;

class function TRestartManager.ListaProcessosBloqueadores(Path: string): TProcesses;
var
  handle: DWORD;
  i: integer;
  lError: integer;
  pnProcInfoNeeded: UINT;
  pnProcInfo: UINT;
  lpdwRebootReasons: DWord;
  RmSessionKey: array[0..CCH_RM_SESSION_KEY] of WideChar;
  ProcessInfoArr: array of RM_PROCESS_INFO;
  PFileName: PWideChar;
  lProcessos : TProcesses;
  lProcesso : TProcess;
  lGuid : TGUID;
begin
  Result := nil;

  // Para usar esse metodo, será obrigatorio executar o Inicializar.
  if (not UsandoRestartManager) and (not Inicializar()) then
    Exit;

  lProcessos := TProcesses.Create;

  pnProcInfoNeeded := 0;
  pnProcInfo := 0;
  lpdwRebootReasons := RmRebootReasonNone;

  CreateGUID(lGuid);

  StringToWideChar(GUIDToString(lGuid), RmSessionKey, CCH_RM_SESSION_KEY);

  lError := RmStartSession(handle, 0, RmSessionKey);

  if (lError <> ERROR_SUCCESS) then
    raise ESessaoNaoIniciada.Create();

  try
    Path := Path;

    GetMem(PFileName, MAX_PATH);
    try
      StringToWideChar(Path, PFileName, MAX_PATH);
      lError := RmRegisterResources(handle, 1, @PFileName, 0, nil, 0, nil);
    finally
      FreeMem(PFileName);
    end;

    if (lError <> ERROR_SUCCESS) then
      raise ERegistroRecursoNaoRealizado.Create();

     // Há uma condição de corrida aqui:
     // A primeira chamada de RmGetList() retorna o número total de processos. No entanto, quando chamamos RmGetList()
     // novamente para obter os processos reais, este número pode ter aumentado.
     pnProcInfoNeeded := 0;
     pnProcInfo := 0;
     SetLength(ProcessInfoArr, pnProcInfo);
     lError := RmGetList(handle, @pnProcInfoNeeded, @pnProcInfo, nil, @lpdwRebootReasons);

     if (lError = ERROR_MORE_DATA) then
       begin
         pnProcInfo := pnProcInfoNeeded + 10;
         SetLength(ProcessInfoArr, pnProcInfo);
         pnProcInfoNeeded := 0;

         // Obtém a lista de processos bloqueadores do recurso
         lError := RmGetList(handle, @pnProcInfoNeeded, @pnProcInfo, @ProcessInfoArr[0], @lpdwRebootReasons);

         if lError <> ERROR_SUCCESS then
           raise EProcessosBloqueadoresNaoListados.Create();

         for i := 0 to pnProcInfo -1 do
         begin
           // Podera ser preciso executar SeDebugPrivilege para abrir qualquer processo (quase).
           // Podera ser preciso executar SeImpersonatePrivilege para representar o segmento atual no contexto de segurança do usuário conectado.
           TSecurity.AddDbgPrivileges;

           lProcesso := TProcess.Create(ProcessInfoArr[i].Process.dwProcessId, ProcessInfoArr[i].strAppName);
           lProcesso.ServiceShortName := WideCharToString(ProcessInfoArr[i].strServiceShortName);
          // lProcesso.PathProcess := Format('%s', [PWideChar(PChar(QueryImagePath(ProcessInfoArr[i].Process.dwProcessId)))]);
           lProcesso.AppType := ProcessInfoArr[i].ApplicationType;
           lProcesso.PathFile := Path;

           lProcessos.Add(lProcesso);
         end;
       end
     else
       if (lError <> 0) then
         raise ETamanhoResultadoNaoObtido.Create();
  finally
    Result := lProcessos;
    RmEndSession(handle);
  end;
end;

class procedure TRestartManager.Destruir;
begin
  if UsandoRestartManager then
  begin
    ReferenceCount := 1;
    Finalizar;
  end;
end;

end.
