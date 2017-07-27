{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Classe para gerenciar uma lista de Process.
}

unit Processes;

interface

uses
  Windows,
  TlHelp32,
  Classes,
  SysUtils,
  Process,
  Contnrs;
type
  TProcesses = class
  private
    FProcesses: TObjectList;

    function GetItem(Index: Integer): TProcess;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(pProcess: TProcess);
    function Del(Index: Integer): Boolean;
    function Find(const pID: Cardinal; var pProcess: TProcess): Boolean; overload;
    function Find(pName: string; var pProcess: TProcess): Boolean; overload;
    function IndexOf(const pID: Cardinal): Integer; overload;
    function IndexOf(pName: string): Integer; overload;
    function ToString(): string;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TProcess read GetItem; default;
  end;

  function IsRunning(pProcessName: string): Boolean;

implementation

function IsRunning(pProcessName: string): Boolean;
var
  S: string;
  vSnapshot: THandle;
  vProcessEntry: TProcessEntry32;
begin
  Result := False;
  pProcessName := UpperCase(pProcessName);

  vSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    vProcessEntry.dwSize := SizeOf(TProcessEntry32);

    if not Process32First(vSnapshot, vProcessEntry) then
      Exit;

    repeat
      S := UpperCase(vProcessEntry.szExeFile);
      Result := (S = pProcessName);

      if Result then
        Exit;

    until not Process32Next(vSnapshot, vProcessEntry);

  finally
    CloseHandle(vSnapshot);
  end;
end;

procedure TProcesses.Add(pProcess: TProcess);
begin
  FProcesses.Add(pProcess);
end;

function TProcesses.Del(Index: Integer): Boolean;
begin
  Result := False;

  if Index < Count then
  begin
     FProcesses.Delete(Index);
     Result := True;
  end;              
end;


constructor TProcesses.Create;
begin
  inherited Create;
  FProcesses := TObjectList.Create;
end;

destructor TProcesses.Destroy;
begin
  FProcesses.Free;
  inherited;
end; 

function TProcesses.Find(const pID: Cardinal; var pProcess: TProcess): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FProcesses.Count -1 do
  begin
    Result := TProcess(FProcesses.Items[i]).ID = pID;
    if Result then
    begin
      pProcess := TProcess(FProcesses.Items[i]);
      Exit;
    end;
  end;
end;

function TProcesses.Find(pName: string; var pProcess: TProcess): Boolean;
var
  i: Integer;
begin
  Result := False;
  pName := UpperCase(pName);
  for i := 0 to FProcesses.Count -1 do
  begin
    Result := TProcess(FProcesses.Items[i]).Name = pName;
    if Result then
    begin
      pProcess := TProcess(FProcesses.Items[i]);
      Exit;
    end;
  end;
end;

function TProcesses.GetCount: Integer;
begin
  Result := FProcesses.Count;
end;

function TProcesses.GetItem(Index: Integer): TProcess;
begin
  Result := TProcess(FProcesses.Items[Index]);
end;

function TProcesses.IndexOf(const pID: Cardinal): Integer;
begin
  for Result := 0 to FProcesses.Count -1 do
    if TProcess(FProcesses.Items[Result]).ID = pID then
      Exit;

  Result := -1;
end;

function TProcesses.IndexOf(pName: string): Integer;
begin
  pName := UpperCase(pName);
  for Result := 0 to FProcesses.Count -1 do
    if TProcess(FProcesses.Items[Result]).Name = pName then
      Exit;

  Result := -1;
end;

function TProcesses.ToString: string;
var
  i: integer;
  lResult : string;
  lPathFile : string;
begin
  lResult := '';

  for i := 0 to FProcesses.Count -1 do
  begin
     lPathFile := TProcess(FProcesses.Items[i]).PathFile;

     if Trim(lPathFile) = '' then
       lPathFile := 'Não alcançado';

    lResult := lResult + Format('Processo: %s; Local do arquivo: %s ',[TProcess(FProcesses.Items[i]).Name, lPathFile]);
  end;

  Result := lResult;
end;

end.
