unit ufrmBrowser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge;

type
  TCookieHandler = class(TInterfacedObject, ICoreWebView2GetCookiesCompletedHandler)
  public
    function Invoke(errorCode: HRESULT; const cookieList: ICoreWebView2CookieList): HRESULT; stdcall;
  end;

type
  TfrmBrowser = class(TForm)
    browser: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure browserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure browserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
  private
    { Private declarations }
    procedure SetupBrowser;
  public
    { Public declarations }
    FuMod_Session_Token: string;
  end;

var
  frmBrowser: TfrmBrowser;

function GetuModLoginSession: PWChar; stdcall;

implementation

uses
  System.IOUtils;

{$R *.dfm}

function GetuModLoginSession: PWChar; stdcall;
begin
  Result := '';

  Application.Initialize;
  frmBrowser := TfrmBrowser.Create(Application);
  try
    if frmBrowser.ShowModal = mrOk then
    begin
      Result := StrNew(PWChar(frmBrowser.FuMod_Session_Token));
    end;
  finally
    frmBrowser.Free;
  end;
end;

procedure TfrmBrowser.FormCreate(Sender: TObject);
begin
  FuMod_Session_Token := '';
  Self.SetupBrowser;
end;

procedure TfrmBrowser.browserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  if not AResult = S_OK then
    Exit;

  // Disable Dev Tools
  browser.DevToolsEnabled := False;
end;

procedure TfrmBrowser.browserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  Self.Caption := browser.LocationURL;

  if (browser.LocationURL <> 'https://umod.org/dashboard') and (browser.LocationURL <> 'https://umod.org/login') then
  begin
    browser.Navigate('https://umod.org/dashboard');
    Exit;
  end;

  if browser.LocationURL = 'https://umod.org/dashboard' then
  begin
    var core: ICoreWebView2;
    browser.ControllerInterface.Get_CoreWebView2(core);
    if not Assigned(core) then
    begin
      ShowMessage('core not assigned');
      Exit;
    end;

    var cookieManager: ICoreWebView2CookieManager;
    ICoreWebView2_2(core).Get_CookieManager(cookieManager);
    if not Assigned(cookieManager) then
    begin
      ShowMessage('cookieManager not assigned');
      Exit;
    end;

    var cookieHandler: ICoreWebView2GetCookiesCompletedHandler;
    cookieHandler := TCookieHandler.Create;
    cookieManager.GetCookies('https://umod.org', cookieHandler);
  end;
end;

{ TfrmBrowser }

procedure TfrmBrowser.SetupBrowser;
begin
  browser.UserDataFolder := TPath.Combine([ExtractFilePath(ParamStr(0)), 'webview2Data']);
  browser.Navigate('https://umod.org/login');
end;

{ TCookieHandler }

function TCookieHandler.Invoke(errorCode: HRESULT; const cookieList: ICoreWebView2CookieList): HRESULT;
begin
  Result := S_FALSE;

  var cooKieCount: LongWord;
  cookieList.Get_Count(cooKieCount);
  for var I := 0 to cooKieCount - 1 do
  begin
    var cookie: ICoreWebView2Cookie;
    cookieList.GetValueAtIndex(I, cookie);

    var cookieName: PWideChar;
    cookie.Get_name(cookieName);

    if cookieName = 'umod_session' then
    begin
      var cookieValue: PWideChar;
      cookie.Get_value(cookieValue);

      frmBrowser.FuMod_Session_Token := cookieValue;
      frmBrowser.ModalResult := mrOk;

      Break;
    end;
  end;

end;

end.

