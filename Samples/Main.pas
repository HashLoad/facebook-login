unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.FacebookLogin, FMX.WebBrowser, FMX.Objects, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts;

type
  TForm6 = class(TForm)
    WebBrowser1: TWebBrowser;
    FacebookLogin1: TFacebookLogin;
    LabelName: TLabel;
    LabelId: TLabel;
    Layout1: TLayout;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FacebookLogin1LoginSuccess(Sender: TObject);
    procedure FacebookLogin1LoginFailed(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.fmx}
{$R *.iPhone55in.fmx IOS}

procedure TForm6.FacebookLogin1LoginFailed(Sender: TObject);
begin
  ShowMessage('Login Failed');
end;

procedure TForm6.FacebookLogin1LoginSuccess(Sender: TObject);
begin
  LabelId.Text := FacebookLogin1.User.Id;
  LabelName.Text := FacebookLogin1.User.Name;
  Image1.Bitmap.LoadFromStream(FacebookLogin1.User.Picture);
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  FacebookLogin1.Execute;
end;

end.
