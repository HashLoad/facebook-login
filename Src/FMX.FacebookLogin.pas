unit FMX.FacebookLogin;

interface

uses
  System.SysUtils, System.Classes, FMX.WebBrowser,
  System.Net.HttpClientComponent, System.JSON;

type
  TFacebookLoginUser = class
  private
    FName: string;
    FPicture: TStream;
    FId: string;
  published
    property Id: string read FId;
    property Name: string read FName;
    property Picture: TStream read FPicture;
  end;

  TFacebookLogin = class(TComponent)
  private
    FWebBrowser: TWebBrowser;
    FClientId: string;
    FOnDidFinishLoad: TNotifyEvent;
    FAccessToken: string;
    FUser: TFacebookLoginUser;
    FOnLoginSuccess: TNotifyEvent;
    FOnLoginFailed: TNotifyEvent;
    procedure DoOnDidFinishLoad(ASender: TObject);
    procedure SetWebBrowser(const Value: TWebBrowser);
    procedure LoginSuccess;
    procedure GetUserInfo;
    procedure GetPicture;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    procedure Execute;
    destructor Destroy; override;
    constructor Create(AOwner: TComponent); override;
  published
    property OnLoginFailed: TNotifyEvent read FOnLoginFailed
      write FOnLoginFailed;
    property OnLoginSuccess: TNotifyEvent read FOnLoginSuccess
      write FOnLoginSuccess;
    property User: TFacebookLoginUser read FUser write FUser;
    property AccessToken: string read FAccessToken;
    property ClientId: string read FClientId write FClientId;
    property WebBrowser: TWebBrowser read FWebBrowser write SetWebBrowser;
  end;

procedure Register;

const
  API_URL_USER = 'https://graph.facebook.com/me';
  API_URL_PICTURE = 'https://graph.facebook.com/%s/picture?type=large';
  AUTH_URL = 'https://www.facebook.com/v4.0/dialog/oauth';
  AUTH_TYPE = 'token';
  AUTH_SUCCESS = 'https://www.facebook.com/connect/login_success.html';

implementation

uses
  System.Net.URLClient;

procedure Register;
begin
  RegisterComponents('HashLoad', [TFacebookLogin]);
end;

{ TFacebookLogin }

constructor TFacebookLogin.Create(AOwner: TComponent);
begin
  inherited;
  FUser := TFacebookLoginUser.Create;
end;

procedure TFacebookLogin.GetPicture;
var
  LResponse: TStream;
  LHTTPClient: TNetHTTPClient;
  LAuthorization: TNameValuePair;
begin
  LHTTPClient := TNetHTTPClient.Create(nil);
  try
    LAuthorization := TNameValuePair.Create('Authorization',
      'Bearer ' + FAccessToken);

    LResponse := TStringStream.Create;
    try
      LHTTPClient.Get(Format(API_URL_PICTURE, [User.FId]), LResponse,
        [LAuthorization]);
      User.FPicture := LResponse;
    finally
//      LResponse.Free;
    end;
  finally
    LHTTPClient.Free;
  end;
end;

procedure TFacebookLogin.GetUserInfo;
var
  LResponse: TStringStream;
  LJSONResponse: TJSONObject;
  LHTTPClient: TNetHTTPClient;
  LAuthorization: TNameValuePair;
begin
  LHTTPClient := TNetHTTPClient.Create(nil);
  try
    LAuthorization := TNameValuePair.Create('Authorization',
      'Bearer ' + FAccessToken);

    LResponse := TStringStream.Create;
    try
      LHTTPClient.Get(API_URL_USER, LResponse, [LAuthorization]);
      LJSONResponse :=
        TJSONObject(TJSONObject.ParseJSONValue(LResponse.DataString));
      try
        User.FName := LJSONResponse.GetValue('name').Value;
        User.FId := LJSONResponse.GetValue('id').Value;
      finally
        LJSONResponse.Free;
      end;
    finally
      LResponse.Free;
    end;
  finally
    LHTTPClient.Free;
  end;
end;

procedure TFacebookLogin.LoginSuccess;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      GetUserInfo;
      GetPicture;

      TThread.Synchronize(nil,
        procedure
        begin
          if Assigned(FOnLoginSuccess) then
            FOnLoginSuccess(Self);
        end);

    end).Start;
end;

destructor TFacebookLogin.Destroy;
begin
  FUser.Free;
  inherited;
end;

procedure TFacebookLogin.DoOnDidFinishLoad(ASender: TObject);
const
  PAYLOAD_INDEX = 1;
var
  LAccessTokenStart, LAccessTokenSize: Integer;
  LQuery, LPayLoad: string;
  LQueryList: TArray<string>;
begin
  if WebBrowser.URL.Contains('access_token') and FAccessToken.IsEmpty then
  begin
    LQueryList := WebBrowser.URL.Split(['&']);

    for LQuery in LQueryList do
    begin
      LAccessTokenStart := LQuery.IndexOf('access_token') +
        'access_token='.Length;
      LAccessTokenSize := LQuery.Length - LAccessTokenStart;
      FAccessToken := LQuery.Substring(LAccessTokenStart, LAccessTokenSize);

      if not FAccessToken.IsEmpty then
        break;
    end;

    if FAccessToken.IsEmpty then
    begin
      if Assigned(FOnLoginFailed) then
        FOnLoginFailed(Self);
    end
    else
      LoginSuccess;
  end;

  if Assigned(FOnDidFinishLoad) then
    FOnDidFinishLoad(ASender);
end;

procedure TFacebookLogin.Execute;
const
  URL = '%s?client_id=%s&redirect_uri=%s&response_type=%s';
begin
  if FWebBrowser <> nil then
    FWebBrowser.URL := Format(URL, [AUTH_URL, FClientId, AUTH_SUCCESS,
      AUTH_TYPE]);
end;

procedure TFacebookLogin.Notification(AComponent: TComponent;
Operation: TOperation);
begin
  inherited;

  if (AComponent = FWebBrowser) and (Operation = opRemove) then
    FWebBrowser := nil;
end;

procedure TFacebookLogin.SetWebBrowser(const Value: TWebBrowser);
begin
  if FWebBrowser <> Value then
  begin
    FWebBrowser := Value;
    if FWebBrowser <> nil then
    begin
      FOnDidFinishLoad := FWebBrowser.OnDidFinishLoad;
      FWebBrowser.OnDidFinishLoad := DoOnDidFinishLoad;
    end;
  end;
end;

end.
