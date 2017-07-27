{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Exceções para as rotinas que envolvem a classe TRestartManager
}

unit RestartManagerExceptions;

interface

uses
  SysUtils,
  StrUtils;

type
  ESessaoNaoIniciada = class(Exception)
  public
    constructor Create(pMensagem: string = '');
  end;

  ERegistroRecursoNaoRealizado = class(Exception)
  public
    constructor Create(pMensagem: string = '');
  end;

  EProcessosBloqueadoresNaoListados = class(Exception)
  public
    constructor Create(pMensagem: string = '');
  end;

  ETamanhoResultadoNaoObtido = class(Exception)
  public
    constructor Create(pMensagem: string = '');
  end;

implementation

const
  SESSAO_NAO_INICIADA = 'Não foi possível iniciar a sessão.';
  REGISTRO_RECURSO_NAO_REALIZADO = 'Não foi possível registrar o recurso.';
  PROCESSOS_BLOQUEADORES_NAO_LISTADOS = 'Não foi possível listar o(s) processo(s) bloqueador(es).';
  TAMANHO_RESULTADO_NAO_OBTIDO = 'Não foi possível obter o tamanho do resultado. Não foi possível listar o(s) processo(s) bloqueador(es).';

  constructor ESessaoNaoIniciada.Create(pMensagem: string);
  begin
    inherited Create(IFThen(Trim(pMensagem) <> '', pMensagem, SESSAO_NAO_INICIADA));
  end;

  constructor ERegistroRecursoNaoRealizado.Create(pMensagem: string);
  begin
    inherited Create(IFThen(Trim(pMensagem) <> '', pMensagem, REGISTRO_RECURSO_NAO_REALIZADO));
  end;

  constructor EProcessosBloqueadoresNaoListados.Create(pMensagem: string);
  begin
    inherited Create(IFThen(Trim(pMensagem) <> '', pMensagem, PROCESSOS_BLOQUEADORES_NAO_LISTADOS));
  end;

  constructor ETamanhoResultadoNaoObtido.Create(pMensagem: string);
  begin
    inherited Create(IFThen(Trim(pMensagem) <> '', pMensagem, TAMANHO_RESULTADO_NAO_OBTIDO));
  end;
end.
