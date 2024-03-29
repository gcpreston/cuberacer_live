// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css";

// AlpineJS
import Alpine from 'alpinejs';
import howTo from './howTo';
import timer from './timer';
import room from './room';

Alpine.data('howTo', howTo);
Alpine.data('timer', timer);
Alpine.data('room', room);

Alpine.store('inputFocused', false);
Alpine.store('unreadChat', false);

window.Alpine = Alpine;
Alpine.start();

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let Hooks = {};

// http://blog.pthompson.org/alpine-js-and-liveview#calling-hook-code_3
Hooks.Timer = {
  mounted() {
    window.timerHook = this;
  },
  startSolving() {
    this.pushEvent('solving');
  },
  submitTime(time) {
    this.pushEvent('timer-submit', { time });
  }
};

Hooks.ChatInput = {
  mounted() {
    window.chatInputHook = this;
  },
  sendMessage(message) {
    this.pushEvent('send-message', { message });
  }
};

let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });

let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if(!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 120);
  };
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
