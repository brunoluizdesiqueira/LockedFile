object frmPrincipal: TfrmPrincipal
  Left = 413
  Top = 281
  Width = 903
  Height = 234
  Caption = 'Arquivo em processamento'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 155
    Width = 887
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 0
    DesignSize = (
      887
      41)
    object btnVerificar: TButton
      Left = 728
      Top = 12
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Verificar'
      TabOrder = 2
      OnClick = btnVerificarClick
    end
    object btnCancelar: TButton
      Left = 805
      Top = 12
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Cancelar'
      TabOrder = 3
      OnClick = btnCancelarClick
    end
    object btnMonitorar: TButton
      Left = 650
      Top = 12
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Monitorar'
      TabOrder = 1
      OnClick = btnMonitorarClick
    end
    object btnTerminarProcesso: TButton
      Left = 544
      Top = 12
      Width = 103
      Height = 25
      Anchors = [akTop]
      Caption = '&Terminar processo'
      TabOrder = 0
      OnClick = btnTerminarProcessoClick
    end
  end
  object dbgrdProcessos: TDBGrid
    Left = 0
    Top = 0
    Width = 887
    Height = 155
    Align = alClient
    DataSource = dtsProcessos
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'Name'
        Width = 60
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PID'
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PathFilie'
        Width = 240
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Path'
        Width = 240
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'User'
        Width = 105
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Domain'
        Width = 99
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Attributes'
        Title.Caption = 'Atributos'
        Width = 51
        Visible = True
      end>
  end
  object cdsProcessos: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 10
    Top = 140
    object cdsProcessosPID: TStringField
      DisplayWidth = 50
      FieldName = 'PID'
      Size = 255
    end
    object cdsProcessosPath: TStringField
      DisplayLabel = 'Local do processo'
      DisplayWidth = 255
      FieldName = 'Path'
      Size = 255
    end
    object cdsProcessosName: TStringField
      DisplayLabel = 'Processo'
      DisplayWidth = 100
      FieldName = 'Name'
      Size = 255
    end
    object cdsProcessosFullName: TStringField
      DisplayLabel = 'Nome completo'
      DisplayWidth = 255
      FieldName = 'FullName'
      Size = 255
    end
    object cdsProcessosUser: TStringField
      DisplayLabel = 'Usu'#225'rio'
      DisplayWidth = 100
      FieldName = 'User'
      Size = 255
    end
    object cdsProcessosDomain: TStringField
      DisplayLabel = 'Dom'#237'nio'
      DisplayWidth = 100
      FieldName = 'Domain'
      Size = 255
    end
    object cdsProcessosPathFilie: TStringField
      DisplayLabel = 'Local do arquivo'
      FieldName = 'PathFilie'
      Size = 255
    end
    object cdsProcessosAttributes: TStringField
      FieldName = 'Attributes'
      Size = 255
    end
  end
  object dtsProcessos: TDataSource
    DataSet = cdsProcessos
    Left = 40
    Top = 140
  end
  object tmMonitor: TTimer
    Enabled = False
    OnTimer = tmMonitorTimer
    Left = 72
    Top = 140
  end
end
