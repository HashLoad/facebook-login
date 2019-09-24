program FacebookLoginSample;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {Form6},
  FMX.FacebookLogin in '..\Src\FMX.FacebookLogin.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm6, Form6);
  Application.Run;
end.
