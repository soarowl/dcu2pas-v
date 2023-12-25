program hello;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UEmpty in 'UEmpty.pas';

begin
  try
    write('Hello from delphi!');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
