unit Tools;

interface

uses TlHelp32;

type
  TInfo = record
  pe32: PROCESSENTRY32;
  end;

  { EnumerateProcesses, GetIntegrityLevel etc }
  TProcess = class
  public
      TOnProcess = reference to procedure(const AInfo: TInfo);
      TThreadInfo = record
        t32: TThreadEntry32;
      end;
      TOnThread = reference to procedure(const AInfo: TThreadInfo);
      TWindowInfo = record
        Wnd: hwnd;
      end;
      TOnWindow = reference to procedure(const AInfo: TWindowInfo);
      TIntegrityLevel = (ilUntrusted, ilLow, ilMedium, ilHigh, ilSystem, ilProtectedProcess, ilUnknown);
    const
      Integrities: array[TIntegrityLevel] of String = (
        'Untrusted', 'Low', 'Medium', 'High', 'System', 'ProtectedProcess', 'Unknown'
      );

  protected
    type
      PEnumWndRec = ^TEnumWndRec;
      TEnumWndRec = record
        Callback: TOnWindow;
      end;

    class function EnumerateProcessThreads(pid: DWORD; ASkipCurrProcess: boolean;
      AOnThread: TOnThread): Boolean; static;

  public

    { Usually you need to call TSecurity.AddDbgPrivileges to read info about
      system processes, otherwise QueryImagePath may return "" for example. }
    class function EnumerateProcesses(ASkipCurrProcess: boolean;
      AOnProcess: TOnProcess):Boolean; static;
    class function EnumerateThreads(pid: DWORD; AOnThread: TOnThread):Boolean; overload; static;
    class function EnumerateThreads(ASkipCurrProcess: boolean; AOnThread: TOnThread):Boolean; overload; static;
    class function QueryImagePath(AProcessId: DWORD; AMaxLen: integer = 4096):String; static;
    class function ListByName(ASkipCurrProcess: boolean;
      const AProcessNameMask: string): TList<TInfo>; static;
    class function EnumerateThreadWindows(AThreadId: DWORD; AOnWindow: TOnWindow):Boolean; static;
    class function GetIntegrityLevel(AProcessId: DWORD; var Integrity: DWORD):Boolean; overload; static;
    class function GetIntegrityLevel(AProcessId: DWORD; var Integrity: TIntegrityLevel):Boolean; overload; static;
    class function GetIntegrityLevel(var Integrity: TIntegrityLevel):Boolean; overload; static;
    class function GetIntegrityLevel: String; overload; static;

    class function GetProcessesLockingFile(const FileName: string): boolean; static;
  end;


  TRestartManager = class
  protected
    class destructor Destroy;

  public
    class var
      RestartManagerLibrary: THandle;
      InitCount: int64;

    type
      RM_APP_TYPE      = DWORD;
      RM_SHUTDOWN_TYPE = DWORD;
      RM_REBOOT_REASON = DWORD;

      RM_UNIQUE_PROCESS = record
        dwProcessId: DWORD;
        ProcessStartTime: TFileTime;
      end;
      PRM_UNIQUE_PROCESS = ^RM_UNIQUE_PROCESS;

    const
      CCH_RM_MAX_APP_NAME   = 255;
      CCH_RM_MAX_SVC_NAME   = 63;

    type
      RM_PROCESS_INFO = record
        Process             : RM_UNIQUE_PROCESS;
        strAppName          : array[0..CCH_RM_MAX_APP_NAME] of WideChar;
        strServiceShortName : array[0..CCH_RM_MAX_SVC_NAME] of WideChar;
        ApplicationType     : RM_APP_TYPE;
        AppStatus           : ULONG;
        TSSessionId         : DWORD;
        bRestartable        : BOOL;
      end;
      PRM_PROCESS_INFO = ^RM_PROCESS_INFO;

    const
      restartmanagerlib = 'Rstrtmgr.dll';

      RM_SESSION_KEY_LEN    = SizeOf(TGUID);
      CCH_RM_SESSION_KEY    = RM_SESSION_KEY_LEN*2;
      RM_INVALID_TS_SESSION = -1;
      RM_INVALID_PROCESS    = -1;

      RmUnknownApp  = 0;
      RmMainWindow  = 1;
      RmOtherWindow = 2;
      RmService     = 3;
      RmExplorer    = 4;
      RmConsole     = 5;
      RmCritical    = 1000;

      RmForceShutdown          = $01;
      RmShutdownOnlyRegistered = $10;

      RmRebootReasonNone             = $0;
      RmRebootReasonPermissionDenied = $1;
      RmRebootReasonSessionMismatch  = $2;
      RmRebootReasonCriticalProcess  = $4;
      RmRebootReasonCriticalService  = $8;
      RmRebootReasonDetectedSelf     = $10;

    class var
      RmStartSession:
        function(
          var pSessionHandle : DWORD;
              dwSessionFlags : DWORD;
              strSessionKey  : LPWSTR): DWORD; stdcall;

      RmRegisterResources:
        function(
          dwSessionHandle : DWORD;
          nFiles          : UINT;
          rgsFilenames    : PPWideChar;
          nApplications   : UINT;
          rgApplications  : PRM_UNIQUE_PROCESS;
          nServices       : UINT;
          rgsServiceNames : PPWideChar): DWORD; stdcall;

      RmGetList:
        function(
          dwSessionHandle   : DWORD;
          pnProcInfoNeeded  : PUINT;
          pnProcInfo        : PUINT;
          rgAffectedApps    : PRM_PROCESS_INFO;
          lpdwRebootReasons : LPDWORD): DWORD; stdcall;

      RmShutdown:
        function(
          dwSessionHandle : DWORD;
          lActionFlags    : ULONG;
          fnStatus        : Pointer): DWORD; stdcall;

      RmRestart:
        function(
          dwSessionHandle : DWORD;
          dwRestartFlags  : DWORD;
          fnStatus        : Pointer): DWORD; stdcall;

      RmEndSession:
        function(dwSessionHandle: DWORD): DWORD; stdcall;

    class function Initialize: Boolean; static;
    class procedure Uninitialize; static;

    class function GetProcessesLockingFile(FileName: string): boolean; static;
  end;

implementation

class function TRestartManager.Initialize: Boolean;
begin
  Inc(InitCount);
  if InitCount <> 1 then
    Result := RestartManagerLibrary <> 0
  else
  begin
    Result := System.SysUtils.Win32MajorVersion >= 6; { Windows Vista or higher }
    if not Result then
      Exit;
    RestartManagerLibrary := LoadLibrary(PChar(GetSystemDir + restartmanagerlib));
    Result := RestartManagerLibrary <> 0;
    if not Result then
      Exit;
    RmStartSession      := GetProcAddress(RestartManagerLibrary, 'RmStartSession');
    RmRegisterResources := GetProcAddress(RestartManagerLibrary, 'RmRegisterResources');
    RmGetList           := GetProcAddress(RestartManagerLibrary, 'RmGetList');
    RmShutdown          := GetProcAddress(RestartManagerLibrary, 'RmShutdown');
    RmRestart           := GetProcAddress(RestartManagerLibrary, 'RmRestart');
    RmEndSession        := GetProcAddress(RestartManagerLibrary, 'RmEndSession');
  end;
end;

class procedure TRestartManager.Uninitialize;
begin
  if InitCount <= 0 then
    Exit;
  Dec(InitCount);
  if (InitCount = 0) and (RestartManagerLibrary <> 0) then
  begin
    FreeLibrary(RestartManagerLibrary);
    RestartManagerLibrary := 0;

    RmStartSession      := nil;
    RmRegisterResources := nil;
    RmGetList           := nil;
    RmShutdown          := nil;
    RmRestart           := nil;
    RmEndSession        := nil;
  end;
end;

class function TRestartManager.GetProcessesLockingFile(FileName: string): boolean;
var
  ErrorCode: DWord;
  SessionHandle: DWORD;
  SessionKey: string;
  PFileName: PWideChar;
  ProcInfoNeededCount: UINT;
  ProcInfoCount: UINT;
  ProcessInfoArr: array of RM_PROCESS_INFO;
  RebootReason: DWORD;
  i: Integer;
  ProcessNames: Array of string;
begin

  { RmStartSession }
  SetLength(ProcessNames, 0);
  result := False;
  if not TRestartManager.Initialize then
    Exit;
  SessionKey := StringOfChar(#0, CCH_RM_SESSION_KEY);
  ErrorCode := RmStartSession(SessionHandle, 0, PChar(SessionKey));
  if ErrorCode <> ERROR_SUCCESS then
    Exit;

  try

    { RmRegisterResources }
    FileName := FileName + #0#0;
    PFileName := PChar(FileName);
    ErrorCode := RmRegisterResources(SessionHandle, 1, @PFileName, 0, nil, 0, nil);
    if ErrorCode <> ERROR_SUCCESS then
      Exit;

    { RmGetList }
    ProcInfoNeededCount := 0;
    ProcInfoCount := 0;
    SetLength(ProcessInfoArr, ProcInfoCount);
    ErrorCode := RmGetList(SessionHandle, @ProcInfoNeededCount, @ProcInfoCount, nil, @RebootReason);
    case ErrorCode of
      ERROR_SUCCESS:
        begin
          Result := True;
          Exit;
        end;
      ERROR_MORE_DATA:
        ;
      else
        Exit;
    end;
    ProcInfoCount := ProcInfoNeededCount + 10;
    SetLength(ProcessInfoArr, ProcInfoCount);
    ProcInfoNeededCount := 0;
    ErrorCode := RmGetList(SessionHandle, @ProcInfoNeededCount, @ProcInfoCount, @ProcessInfoArr[0], @RebootReason);
    if ErrorCode <> ERROR_SUCCESS then
      Exit;

    { fill ProcessNames }
    SetLength(ProcessNames, ProcInfoCount);
    for i := 0 to ProcInfoCount-1 do
    begin
      ProcessNames[i] := TProcess.QueryImagePath(ProcessInfoArr[i].Process.dwProcessId);
      if ProcessNames[i] = '' then
        ProcessNames[i] := ProcessInfoArr[i].strAppName;
      ProcessNames[i] := ProcessNames[i] + format('[%d]', [ProcessInfoArr[i].Process.dwProcessId]);
    end;

    Result := True;

  finally
    RmEndSession(SessionHandle);
  end;
end;

class destructor TRestartManager.Destroy;
begin
  if RestartManagerLibrary <> 0 then
  begin
    InitCount := 1;
    Uninitialize;
  end;
end;

end.
