{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Classe que ativa privilégios em um token de acesso.

  Um token de acesso contém as informações de segurança para uma sessão de logon.
  O sistema cria um token de acesso quando um usuário faz logon e cada processo
  executado em nome do usuário tem uma cópia do token. O token identifica o usuário,
  os grupos do usuário e os privilégios do usuário. O sistema utiliza o token para
  controlar o acesso a objetos de segurança e controlar a capacidade do usuário para
  executar várias operações relacionadas com o sistema no computador local.
}
unit Security;

interface

uses
  Types,
  TlHelp32,
  Windows,
  Messages,
  PsAPI,
  Masks,
  SysUtils,
  SyncObjs,
  Math,
  Classes;

type
  TPrivilege = (
    SE_CREATE_TOKEN_NAME, SE_ASSIGNPRIMARYTOKEN_NAME, SE_LOCK_MEMORY_NAME,
    SE_INCREASE_QUOTA_NAME, SE_UNSOLICITED_INPUT_NAME, SE_MACHINE_ACCOUNT_NAME,
    SE_TCB_NAME, SE_SECURITY_NAME, SE_TAKE_OWNERSHIP_NAME,
    SE_LOAD_DRIVER_NAME, SE_SYSTEM_PROFILE_NAME, SE_SYSTEMTIME_NAME,
    SE_PROF_SINGLE_PROCESS_NAME, SE_INC_BASE_PRIORITY_NAME, SE_CREATE_PAGEFILE_NAME,
    SE_CREATE_PERMANENT_NAME, SE_BACKUP_NAME, SE_RESTORE_NAME,
    SE_SHUTDOWN_NAME, SE_DEBUG_NAME, SE_AUDIT_NAME,
    SE_SYSTEM_ENVIRONMENT_NAME, SE_CHANGE_NOTIFY_NAME, SE_REMOTE_SHUTDOWN_NAME,
    SE_UNDOCK_NAME, SE_SYNC_AGENT_NAME, SE_ENABLE_DELEGATION_NAME,
    SE_MANAGE_VOLUME_NAME, SE_INTERACTIVE_LOGON_NAME, SE_NETWORK_LOGON_NAME,
    SE_BATCH_LOGON_NAME, SE_SERVICE_LOGON_NAME, SE_DENY_INTERACTIVE_LOGON_NAME,
    SE_DENY_NETWORK_LOGON_NAME, SE_DENY_BATCH_LOGON_NAME, SE_DENY_SERVICE_LOGON_NAME,
    SE_REMOTE_INTERACTIVE_LOGON_NAME, SE_DENY_REMOTE_INTERACTIVE_LOGON_NAME
  );

  TDescrAttr = record
        Descriptor: TSecurityDescriptor;
        Attrs: TSecurityAttributes;
      end;

{ AddDbgPrivileges / AddPrivilege / NullDACL etc }
  TSecurity = class
  public
    // Example: addPrivilege('SeDebugPrivilege'); addPrivilege('SeImpersonatePrivilege');
    class function AddDbgPrivileges: Boolean;
    class function AddPrivilege(tok: THandle; const AName: string): Boolean; overload;
    class function AddPrivilege(const AName: string; pid: DWORD): Boolean; overload;
    class function AddPrivilege(const AName: string): Boolean; overload;
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa379286(v=vs.85).aspx
    // NullDACL  - grant access to any user
    // EmptyDACL - grnt no access
    class function NullDACL(var s: TDescrAttr): Boolean;
  end;

const
      Privileges: array[TPrivilege] of string =
      (
        'SeCreateTokenPrivilege', 'SeAssignPrimaryTokenPrivilege', 'SeLockMemoryPrivilege',
        'SeIncreaseQuotaPrivilege', 'SeUnsolicitedInputPrivilege', 'SeMachineAccountPrivilege',
        'SeTcbPrivilege', 'SeSecurityPrivilege', 'SeTakeOwnershipPrivilege',
        'SeLoadDriverPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege',
        'SeProfileSingleProcessPrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeCreatePagefilePrivilege',
        'SeCreatePermanentPrivilege', 'SeBackupPrivilege', 'SeRestorePrivilege',
        'SeShutdownPrivilege', 'SeDebugPrivilege', 'SeAuditPrivilege',
        'SeSystemEnvironmentPrivilege', 'SeChangeNotifyPrivilege', 'SeRemoteShutdownPrivilege',
        'SeUndockPrivilege', 'SeSyncAgentPrivilege', 'SeEnableDelegationPrivilege',
        'SeManageVolumePrivilege', 'SeInteractiveLogonRight', 'SeNetworkLogonRight',
        'SeBatchLogonRight', 'SeServiceLogonRight', 'SeDenyInteractiveLogonRight',
        'SeDenyNetworkLogonRight', 'SeDenyBatchLogonRight', 'SeDenyServiceLogonRight',
        'SeRemoteInteractiveLogonRight', 'SeDenyRemoteInteractiveLogonRight'
      );

implementation

class function TSecurity.AddDbgPrivileges: Boolean;
var
  b1,b2: Boolean;
begin
  b1 := addPrivilege('SeDebugPrivilege');
  b2 := addPrivilege('SeImpersonatePrivilege');
  Result := b1 and b2;
end;

class function TSecurity.AddPrivilege(tok: THandle; const AName: string): Boolean;
var
  t: PTokenPrivileges;
  l, n: cardinal;
begin
  Result := False;
  n := SizeOf(TTokenPrivileges) + SizeOf(TLUIDAndAttributes);
  t := AllocMem(n);
  try
    t.PrivilegeCount := 1;
    t.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

    if not LookupPrivilegeValue('', PChar(AName), t.Privileges[0].Luid) then
      Exit;

    Result := AdjustTokenPrivileges(tok, False, t^, 0, nil, l);
  finally
    ReallocMem(t, 0);
  end;
end;

class function TSecurity.AddPrivilege(const AName: string; pid: DWORD): Boolean;
var
  h, tok: THandle;
begin
  h := OpenProcess(process_all_access, False, pid);
  Result := h <> 0;

  if Result then
    try
      Result := OpenProcessToken(h, TOKEN_ADJUST_PRIVILEGES, tok);
      if Result then
        try
          Result := AddPrivilege(tok, AName);
        finally
          CloseHandle(tok);
        end;
    finally
      CloseHandle(h);
    end;
end;

class function TSecurity.AddPrivilege(const AName: string): Boolean;
begin
  result := AddPrivilege(GetCurrentProcessId, AName);
end;

class function TSecurity.NullDACL(var s: TDescrAttr): Boolean;
begin
  Result := InitializeSecurityDescriptor(@s.Descriptor, SECURITY_DESCRIPTOR_REVISION) and
            SetSecurityDescriptorDacl(@s.Descriptor, True, nil, False);

  if not Result then
    Exit;

  s.Attrs.nLength := SizeOf(s.Attrs);
  s.Attrs.lpSecurityDescriptor := @s.Descriptor;
  s.Attrs.bInheritHandle := False;
end;

end.
