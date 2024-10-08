unit uFrmPedido.View;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.DBGrids, Datasnap.DBClient, Vcl.Mask, Vcl.StdCtrls, uPedido.Control, System.Rtti,
  uAttributeEntity, uPedido.Model, Vcl.ComCtrls, uClientes.Model, uProdutos.Model,
  uConstant, uFunctions, System.UITypes;

type
  TFrmPedido = class(TForm)
    PnlAddProduto: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    edtCodProduto: TEdit;
    edtDescricao: TEdit;
    btnAdicionar: TButton;
    edtUnitario: TMaskEdit;
    edtTotal: TMaskEdit;
    edtQtd: TEdit;
    Panel1: TPanel;
    lbTotalPedido: TLabel;
    btnCancelarPedido: TButton;
    BtnGravarPedido: TButton;
    Panel2: TPanel;
    GridPedProd: TStringGrid;
    PnlPedido: TPanel;
    Bevel1: TBevel;
    Label1: TLabel;
    Label6: TLabel;
    edtNomeCliente: TEdit;
    edtCodCliente: TEdit;
    BtnBuscarPedido: TButton;
    edtNumeroPedido: TEdit;
    edtCodigoPedido: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    edtDataPedido: TDateTimePicker;
    btnNovoPedido: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAdicionarClick(Sender: TObject);
    procedure OnLocateObj(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure OnChange(Sender: TObject);
    procedure OnChangeDecimal(Sender: TObject);
    procedure edtUnitarioExit(Sender: TObject);
    procedure btnCancelarPedidoClick(Sender: TObject);
    procedure BtnGravarPedidoClick(Sender: TObject);
    procedure BtnBuscarPedidoClick(Sender: TObject);
    procedure GridPedProdKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GridPedProdSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure btnNovoPedidoClick(Sender: TObject);
  private
    PedidoProdutos: TPedidoProdutosModel;
    FPedidoControl: TPedidoControl;
    FPedidoModel: TPedidoModel;
    FRow: Integer;
    FPedidoStateMode: TStateMode;
    { Private declarations }
    procedure AddProduto;
    procedure EditProduto;
    procedure MappFrmToObj;
    procedure MappObjToFrm(AEdicao: Boolean);
    procedure ClearForm;
    procedure ClearProduto;
    procedure CarregaPedido(ANumPedido: Integer);
    procedure CtrlTela;
  public
    { Public declarations }
  end;

var
  FrmPedido: TFrmPedido;

implementation

uses udmConnection, printers;

{$R *.dfm}

{ TFrmPedido }

procedure TFrmPedido.AddProduto;
begin
  FPedidoStateMode := smInsert;

  if (FPedidoModel.IsPersisted) then
  begin
    FPedidoStateMode := smEdit;
    CtrlTela;
  end;

  PedidoProdutos := TPedidoProdutosModel.Create;
  MappFrmToObj;
  try
    FPedidoControl.AddPedidoProduto(PedidoProdutos);

    ClearProduto;

    if StrToIntDef(edtCodigoPedido.Text, 0) > 0 then
      edtCodigoPedido.Text := PedidoProdutos.IDPedido.ToString;

    edtCodProduto.SetFocus;
    BtnGravarPedido.Enabled := True;
    MappObjToFrm(False);
  except
    on E: exception do
    begin
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
      PedidoProdutos.Free;
    end;
  end;
end;

procedure TFrmPedido.EditProduto;
begin
  FPedidoStateMode := smEdit;
  MappFrmToObj;
  FPedidoModel.Total := FPedidoControl.TotalPedido;
  MappObjToFrm(false);
  BtnGravarPedido.Enabled := true;
end;

procedure TFrmPedido.btnAdicionarClick(Sender: TObject);
begin
  if edtCodProduto.ReadOnly then
    EditProduto
  else
    AddProduto;
end;

procedure TFrmPedido.CarregaPedido(ANumPedido: Integer);
begin
  if ANumPedido = 0 then
    exit;

  FPedidoModel := TPedidoModel(FPedidoControl.LocateCadastro(csPedido, ANumPedido));
  if (FPedidoModel <> nil) and (FPedidoModel.Codigo > 0) then
  begin
    MappObjToFrm(false);
  end
  else begin
    MessageDlg('Pedido n�o localizado', mtWarning, [mbOK], 0);
    ClearForm;
  end;
end;

procedure TFrmPedido.BtnBuscarPedidoClick(Sender: TObject);
begin
  if FPedidoStateMode = smBrowse then
    CarregaPedido(StrToIntDef(edtNumeroPedido.Text, 0));
end;

procedure TFrmPedido.btnCancelarPedidoClick(Sender: TObject);
var
  NumPed: string;
begin
  if StrToUIntDef(edtCodigoPedido.Text, 0) = 0 then
    exit;

  case FPedidoStateMode of
    smBrowse:
      begin
        if (StrToIntDef(edtCodigoPedido.Text, 0) = 0) then
          NumPed := InputBox('Cancelamento de Pedido', 'N�mero Pedido:', '')
        else
          NumPed := edtCodigoPedido.Text;

        if (StrToIntDef(NumPed, 0) > 0) and (MessageDlg('Deseja cancelar o pedido ' + NumPed + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
          if FPedidoControl.Delete(StrToIntDef(NumPed, 0)) then
          begin
            MessageDlg('Pedido deletado com sucesso!', mtInformation, [mbOK], 0);
            ClearForm;
            FPedidoStateMode := smBrowse;
          end;
        end;
      end;
    smInsert:
      begin
        if (MessageDlg('Deseja cancelar o pedido ' + NumPed + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
          FPedidoControl.Cancel;
          ClearForm;
          FPedidoControl.ChangeGrid();
          FPedidoStateMode := smBrowse;
        end;
      end;
    smEdit:
      begin
        if (MessageDlg('Deseja cancelar a edi��o do pedido ' + edtCodigoPedido.Text + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
          CarregaPedido(StrToIntDef(edtCodigoPedido.Text, 0));
          FPedidoModel.StateMode := smBrowse;
          FPedidoStateMode := smBrowse;
        end;
      end;
  end;
  CtrlTela;
end;

procedure TFrmPedido.BtnGravarPedidoClick(Sender: TObject);
begin
  try
    if FPedidoControl.Save then
    begin
      MessageDlg('Pedido salvo com sucesso!', mtInformation, [mbOK], 0);
      BtnGravarPedido.Enabled := false;
      FPedidoStateMode := smBrowse;
    end;
  except
    on E: exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TFrmPedido.btnNovoPedidoClick(Sender: TObject);
begin
  FPedidoControl.Clear;
  ClearForm;
end;

procedure TFrmPedido.ClearForm;
begin
  edtCodCliente.Text := EmptyStr;
  edtCodigoPedido.Text := EmptyStr;
  edtDataPedido.Date := Date;
  edtNomeCliente.Text := EmptyStr;

  ClearProduto;

  edtNumeroPedido.Text := EmptyStr;

  edtDataPedido.SetFocus;
  FPedidoStateMode := smBrowse;
  lbTotalPedido.Caption := 'Total Pedido: 0,00';

  FPedidoControl.LoadGrid;
  CtrlTela;
end;

procedure TFrmPedido.ClearProduto;
begin
  edtCodProduto.Text := EmptyStr;
  edtQtd.Text := '1';
  edtUnitario.Text := '0,00';
  edtTotal.Text := '0,00';
  edtDescricao.Text := EmptyStr;
end;

procedure TFrmPedido.CtrlTela;
begin
  edtCodProduto.ReadOnly := false;
  edtCodProduto.Color := clWindow;
  btnAdicionar.Caption := 'ADICIONAR';
  btnCancelarPedido.Caption := 'CANCELAR PEDIDO';
  if FPedidoStateMode = smEdit then
  begin
    btnCancelarPedido.Caption := 'CANCELAR EDI��O';
  end;
  BtnGravarPedido.Enabled := FPedidoStateMode in [smEdit, smInsert];
  btnNovoPedido.Enabled := not (FPedidoStateMode in [smEdit, smInsert]);
end;

procedure TFrmPedido.OnChangeDecimal(Sender: TObject);
begin
  TCustomEdit(Sender).Text := GetStrNumberDecimal(TCustomEdit(Sender).Text);
end;

procedure TFrmPedido.edtUnitarioExit(Sender: TObject);
begin
  edtUnitario.Text := FormatFloat('###,##0.00', StrToFloatDef(edtUnitario.Text, 0));
  edtTotal.Text := FormatFloat('###,##0.00', StrToFloatDef(edtUnitario.Text, 0) * StrToFloatDef(edtQtd.Text, 0));
end;

procedure TFrmPedido.OnChange(Sender: TObject);
begin
  TCustomEdit(Sender).Text := GetStrNumberInt(TCustomEdit(Sender).Text);
end;

procedure TFrmPedido.FormCreate(Sender: TObject);
begin
  FPedidoModel := TPedidoModel.Create;
  FPedidoControl := TPedidoControl.Create(FPedidoModel, GridPedProd);
end;

procedure TFrmPedido.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPedidoControl);
  FreeAndNil(FPedidoModel)
end;

procedure TFrmPedido.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    Key := #0;
    Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmPedido.FormShow(Sender: TObject);
begin
  if not dm.Conectar then
  begin
    MessageDlg('N�o foi possivel estabelecer uma conex�o com o banco de dados.', mtError, [mbOK], 0);
    Application.Terminate;
  end;
  FPedidoControl.LoadGrid;
  ClearForm;
end;

procedure TFrmPedido.GridPedProdKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (FRow = 0) then
    exit;

  if Key = VK_RETURN then
  begin
    PedidoProdutos := TPedidoProdutosModel(GridPedProd.Objects[0, FRow]);
    MappObjToFrm(True);
  end;
  if Key = VK_DELETE then
  begin
    if (MessageDlg('Deseja deletar o produto?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    begin
      PedidoProdutos := TPedidoProdutosModel(GridPedProd.Objects[0, FRow]);
      FPedidoControl.DeletePedidoProduto(PedidoProdutos);
      MappObjToFrm(false);
      FPedidoStateMode := smEdit;
      CtrlTela;
    end;
  end;
end;

procedure TFrmPedido.GridPedProdSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  FRow := ARow;
end;

procedure TFrmPedido.MappFrmToObj;
begin
  FPedidoModel.IdCliente := StrToIntDef(edtCodCliente.Text, 0);
  FPedidoModel.Codigo := StrToIntDef(edtCodigoPedido.Text, 0);
  FPedidoModel.Data := edtDataPedido.Date;

  PedidoProdutos.IDPedido := FPedidoModel.Codigo;
  PedidoProdutos.IDProduto := StrToIntDef(edtCodProduto.Text, 0);
  PedidoProdutos.Quantidade := StrToFloatDef(edtQtd.Text, 0);
  PedidoProdutos.Unitario := StrToFloatDef(edtUnitario.Text, 0);
  PedidoProdutos.Total := PedidoProdutos.Quantidade * PedidoProdutos.Unitario;
end;

procedure TFrmPedido.MappObjToFrm(AEdicao: Boolean);
begin
  edtCodCliente.Text := FPedidoModel.IdCliente.ToString;
  edtCodigoPedido.Text := FPedidoModel.Codigo.ToString;
  edtDataPedido.Date := FPedidoModel.Data;
  edtNomeCliente.Text := FPedidoModel.Cliente.Nome;

  if AEdicao then
  begin
    edtCodProduto.ReadOnly := True;
    edtCodProduto.Color := clBtnFace;
    edtCodProduto.Text := PedidoProdutos.IDProduto.ToString;
    edtQtd.Text := PedidoProdutos.Quantidade.ToString;
    edtUnitario.Text := PedidoProdutos.Unitario.ToString;
    edtTotal.Text := PedidoProdutos.Total.ToString;
    edtDescricao.Text := PedidoProdutos.Produto.Descricao;
    edtCodProduto.SetFocus;
    btnAdicionar.Caption := 'ALTERAR ITEM';
    btnCancelarPedido.Caption := 'CANCELAR EDI��O';
  end
  else begin
    FRow := 0;
    FPedidoControl.ChangeGrid();
    ClearProduto;
  end;
  lbTotalPedido.Caption := 'Total Pedido: ' + FormatFloat('###,##0.00', FPedidoModel.Total);
  CtrlTela;
end;

procedure TFrmPedido.OnLocateObj(Sender: TObject);
var
  Consulta: TConsulta;
  FObj: TObject;
begin
  try
    if StrToIntDef(TEdit(Sender).Text, 0) = 0 then
      exit;

    Consulta := TConsulta(TEdit(Sender).Tag);
    FObj := FPedidoControl.LocateCadastro(Consulta, StrToIntDef(TEdit(Sender).Text, 0));
    try
      if FObj <> nil then
      begin
        case Consulta of
          csCliente:
            edtNomeCliente.Text := TClienteModel(FObj).Nome;
          csProduto:
            begin
              edtDescricao.Text := TProdutoModel(FObj).Descricao;
              edtUnitario.Text := FormatFloat('###,##0.00', TProdutoModel(FObj).PrecoVenda);
            end;
        end;
      end;
    finally
      FObj.Free;
    end;
  except
    On E: exception do
    begin
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
      TEdit(Sender).SetFocus;
    end;
  end;
end;

end.
