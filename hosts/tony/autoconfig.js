// Appended to the Firefox wrapper's mozilla.cfg, so it runs privileged once at startup.
//
// New tabs open the landing page. browser.newtab.url died in Firefox 41 and no pref or
// policy replaced it; AboutNewTab.newTabURL is the only switch left, and it has to be
// set from privileged code like this.
//
// Kiosk mode hides every toolbar, so getting back to the tiles took a Home key (Alt+Home,
// or a remote that sends XF86HomePage). The Home button below fades in when the air mouse
// moves and out after a few idle seconds, so it never sits over a film. It hides on the
// landing page itself, and under DOM fullscreen the player covers it.

const LANDING = "@landing@";
const IDLE_MS = 3000;

const CSS = `
  #tony-home {
    position: fixed;
    top: 3vmin;
    left: 3vmin;
    z-index: 2147483647;
    display: flex;
    align-items: center;
    gap: 1.5vmin;
    padding: 1.6vmin 3vmin 1.6vmin 2.4vmin;
    border: 0.4vmin solid rgba(232, 234, 237, 0.25);
    border-radius: 2vmin;
    background: rgba(11, 13, 16, 0.85);
    color: #e8eaed;
    font: 600 4vmin system-ui, sans-serif;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.25s ease, border-color 0.12s ease;
  }
  #tony-home.shown { opacity: 1; pointer-events: auto; }
  #tony-home:hover { border-color: #4da3ff; }
  #tony-home svg { width: 5vmin; height: 5vmin; fill: currentColor; }
`;

function log(e) {
  Services.console.logStringMessage("tony autoconfig: " + e);
}

function addHomeButton(win) {
  const doc = win.document;
  if (!win.gBrowser || doc.getElementById("tony-home")) {
    return;
  }
  win.windowUtils.loadSheetUsingURIString(
    "data:text/css," + encodeURIComponent(CSS),
    win.windowUtils.AUTHOR_SHEET
  );

  const btn = doc.createElementNS("http://www.w3.org/1999/xhtml", "button");
  btn.id = "tony-home";
  const svg = doc.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  const house = doc.createElementNS("http://www.w3.org/2000/svg", "path");
  house.setAttribute("d", "M12 3 2 12h3v8h5v-6h4v6h5v-8h3z");
  svg.append(house);
  btn.append(svg, "Home");
  (doc.body || doc.documentElement).append(btn);

  let timer = 0;
  const hide = () => btn.classList.remove("shown");
  btn.addEventListener("click", () => {
    hide();
    win.BrowserCommands.home();
  });
  // Capture phase on the chrome window sees pointer motion over web content too.
  win.addEventListener(
    "mousemove",
    () => {
      win.clearTimeout(timer);
      if (win.gBrowser.currentURI.spec === LANDING) {
        hide();
        return;
      }
      btn.classList.add("shown");
      if (!btn.matches(":hover")) {
        timer = win.setTimeout(hide, IDLE_MS);
      }
    },
    true
  );
}

try {
  ChromeUtils.importESModule(
    "resource:///modules/AboutNewTab.sys.mjs"
  ).AboutNewTab.newTabURL = LANDING;
} catch (e) {
  log(e);
}

Services.obs.addObserver(win => {
  try {
    addHomeButton(win);
  } catch (e) {
    log(e);
  }
}, "browser-delayed-startup-finished");
