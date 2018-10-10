var proto;
if (window.location.protocol == "https:")
{
  proto = "wss://";
}
else
{
  proto = "ws://";
}

var host = proto + window.location.host;

hterm.defaultStorage = new lib.Storage.Memory();

function setupHterm() {
  const t = new hterm.Terminal("default");

  t.onTerminalReady = function() {
    const io = t.io.push();
    io.print("Connecting...\n\r");
    t.setCursorVisible(true);
    var sock = new WebSocket(host);

    sock.onclose = (event) => {
      io.print("-- Connection closed. Releasing keyboard. --");
      t.uninstallKeyboard();
      io.onVTKeystroke = (str) => {};
      io.sendString = (str) => {};
      t.setCursorVisible(false);
    };

    sock.onopen = (event) => {
      io.onVTKeystroke = (str) => {
        sock.send("\1" + str);
      };
      io.sendString = io.onVTKeystroke;
      t.installKeyboard();
      io.onTerminalResize = (w,h) => {
        var buffer = new ArrayBuffer(5);
        var view = new DataView(buffer);
        view.setInt8(0,0);
        view.setUint16(1,w);
        view.setUint16(3,h);
        sock.send(view);
      };
      io.onTerminalResize(t.screenSize.width, t.screenSize.height);
    };

    sock.onmessage = function (event) {
      t.io.print(event.data);
    };
  };
  t.decorate(document.querySelector("#terminal"));
}

window.onload = function() {
  lib.init(setupHterm);
};
