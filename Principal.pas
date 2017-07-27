unit Principal;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  RestartManager,
  Processes,
  SystemError,
  RestartManagerExceptions,
  FileUtils,
  DB,
  DBClient,
  ExtCtrls,
  Grids,
  DBGrids;
type
  TfrmPrincipal = class(TForm)
    cdsProcessos: TClientDataSet;
    cdsProcessosPath: TStringField;
    cdsProcessosPID: TStringField;
    cdsProcessosName: TStringField;
    cdsProcessosFullName: TStringField;
    cdsProcessosUser: TStringField;
    cdsProcessosDomain: TStringField;
    dtsProcessos: TDataSource;
    Panel1: TPanel;
    cdsProcessosPathFilie: TStringField;
    btnVerificar: TButton;
    btnCancelar: TButton;
    btnMonitorar: TButton;
    tmMonitor: TTimer;
    btnTerminarProcesso: TButton;
    cdsProcessosAttributes: TStringField;
    dbgrdProcessos: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnVerificarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnMonitorarClick(Sender: TObject);
    procedure tmMonitorTimer(Sender: TObject);
    procedure btnTerminarProcessoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FPath : string;
    function Validar: Boolean;
    function VerificarProcessosBloqueadores(): Integer;
    procedure TratarExcecao(Excecao: Exception);
  public
    { Public declarations }
    property Path: string read FPath write FPath;
  end;

const
  TITULO = 'Arquivo em processamento';
  MSG = ' - Arquivo %s não encontrado.';
var
  frmPrincipal: TfrmPrincipal;

implementation

uses Process, StrUtils;

{$R *.dfm}

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FPath := 'C:\nfe.PDF';
  cdsProcessos.CreateDataSet;
end;

function TfrmPrincipal.Validar: Boolean;
var lCaption : string;
begin
  Result := True;

  lCaption := TITULO + MSG;

  if not FileExists(FPath) then
  begin
    if not (Self.Caption = Format(lCaption, [FPath])) then
      Self.Caption := (Format(lCaption, [FPath]));

    Result := False;  
    Exit;
  end;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  cdsProcessos.Close;
end;

procedure TfrmPrincipal.btnVerificarClick(Sender: TObject);
var
  lNrProcessos : integer;
begin
  InputQuery('Informe o arquivo', 'Path:', FPath);

  lNrProcessos := VerificarProcessosBloqueadores();

  if (lNrProcessos <= 0) and (cdsProcessos.IsEmpty) then
    ShowMessage('Nenhum processo verificado!');    
end;

function TfrmPrincipal.VerificarProcessosBloqueadores(): Integer;
var
  lProcessos : TProcesses;
  i : Integer;
begin
  Result := -1;
  Validar();
  cdsProcessos.EmptyDataSet;

  if TFileUtils.LockedFile(FPath) then
  begin  
    try
      try
        TRestartManager.Inicializar;
        try
          lProcessos := TRestartManager.ListaProcessosBloqueadores(FPath);
        Except
          On E: Exception do
            TratarExcecao(E);
        end;
      finally
        TRestartManager.Destruir;
      end;

      if lProcessos <> nil then
      begin
        for i := 0 to lProcessos.Count -1 do
        begin
          cdsProcessos.Append;

          cdsProcessosPID.AsString := IntToStr(lProcessos.Items[i].ID);
          cdsProcessosPath.AsString := lProcessos.Items[i].PathProcess;
          cdsProcessosName.AsString := lProcessos.Items[i].Name;
          cdsProcessosFullName.AsString := lProcessos.Items[i].Fullname;
          cdsProcessosPathFilie.AsString := lProcessos.Items[i].PathFile;
          cdsProcessosUser.AsString := lProcessos.Items[i].User;
          cdsProcessosDomain.AsString := lProcessos.Items[i].Domain;
          cdsProcessosAttributes.AsString := lProcessos.Items[i].Attributes;

          cdsProcessos.Post;
        end;

        Result := lProcessos.Count;
      end;
      // Testando o metodo ToString()
      //if lProcessos.Count <> 0 then
      //  ShowMessage(lProcessos.ToString());
    finally
      if lProcessos <> nil then
        FreeAndNil(lProcessos);
    end;

    if cdsProcessos.IsEmpty then
    begin
      cdsProcessos.Append;
      cdsProcessosPathFilie.AsString := FPath;
      cdsProcessosAttributes.AsString := TFileUtils.GetAttributes(FPath);
      cdsProcessos.Post;
    end;
  end;
end;

procedure TfrmPrincipal.btnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPrincipal.btnMonitorarClick(Sender: TObject);
begin
  InputQuery('Informe o arquivo', 'Path:', FPath);
  if tmMonitor.Enabled then
    tmMonitor.Enabled := False
  else
    tmMonitor.Enabled := True;
end;

procedure TfrmPrincipal.tmMonitorTimer(Sender: TObject);
begin
  VerificarProcessosBloqueadores();
end;

procedure TfrmPrincipal.btnTerminarProcessoClick(Sender: TObject);
begin
  if TFileUtils.TerminarProcesso(cdsProcessosPath.AsString) then
    ShowMessage('Processo ' + cdsProcessosPath.AsString + ' finalizado!');
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
   if btnVerificar.CanFocus then
    btnVerificar.SetFocus;
end;

procedure TfrmPrincipal.TratarExcecao(Excecao: Exception); //Wrapper
var
  lErro: string;
begin
  if Excecao is ESystemError then
  begin
    lErro := IfThen(Trim(lErro) = '', Excecao.Message, lErro + ', ' +  Excecao.Message);
    // tratamento
  end;

  if Excecao is ESessaoNaoIniciada then
  begin
    lErro := IfThen(Trim(lErro) = '', Excecao.Message, lErro + ', ' +  Excecao.Message);
    // tratamento
  end;

  if Excecao is ERegistroRecursoNaoRealizado then
  begin
    lErro := IfThen(Trim(lErro) = '', Excecao.Message, lErro + ', ' +  Excecao.Message);
    // tratamento
  end;

  if Excecao is EProcessosBloqueadoresNaoListados then
  begin
    lErro := IfThen(Trim(lErro) = '', Excecao.Message, lErro + ', ' +  Excecao.Message);
    // tratamento
  end;

  if Excecao is ETamanhoResultadoNaoObtido then
  begin
    lErro := IfThen(Trim(lErro) = '', Excecao.Message, lErro + ', ' +  Excecao.Message);
    // tratamento
  end;
end;

end.
