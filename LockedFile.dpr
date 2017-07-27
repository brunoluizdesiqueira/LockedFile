program LockedFile;

uses
  ExceptionLog,
  Forms,
  MidasLib,
  Principal in 'Principal.pas' {frmPrincipal},
  Security in 'Security.pas',
  Process in 'Process.pas',
  Processes in 'Processes.pas',
  SystemError in 'SystemError.pas',
  RestartManager in 'RestartManager.pas',
  RestartManagerExceptions in 'RestartManagerExceptions.pas',
  FileUtils in 'FileUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
