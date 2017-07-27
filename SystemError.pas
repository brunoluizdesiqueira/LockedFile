{
  Copyright (c) Alterdata Software.

  Autor: Bruno Luiz de Siqueira

  Data: 16/01/2017

  Descrição: Tratamento de exceções enviadas pelo System. 
}
unit SystemError;

interface

uses
  SysUtils;  
type
  ESystemError = class(Exception)
  public
    constructor Create(const pMensagem: string = ''); reintroduce;
  end;

implementation

constructor ESystemError.Create(const pMensagem: string);
begin
  if pMensagem = '' then
    inherited Create(SysErrorMessage(GetLastError))
  else
    inherited Create(pMensagem + #13#10'Mensagem enviada pelo sistema: ' + SysErrorMessage(GetLastError));
end;

end.
 