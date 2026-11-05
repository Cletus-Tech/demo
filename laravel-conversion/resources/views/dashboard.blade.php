<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#07090c">
<title>Dashboard</title>
<style>
:root{--bg:#07090c;--panel:#0d1014;--line:#1a1f26;--text:#f2f5f8;--mute:#8b94a1;--blue:#2d9cff;--green:#0fb58a;--red:#c0392b;--r:14px}
*{box-sizing:border-box;margin:0}
body{background:var(--bg);color:var(--text);font:14px/1.4 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;min-height:100vh}
.app{display:grid;grid-template-columns:230px 1fr;gap:12px;padding:12px;min-height:100vh}
aside,.card{background:var(--panel);border:1px solid var(--line);border-radius:var(--r)}
aside{padding:14px 10px;display:flex;flex-direction:column;position:sticky;top:12px;height:calc(100vh - 24px);height:calc(100dvh - 24px);overflow:auto}
.logo{font-weight:700;font-size:18px;padding:6px 10px 16px;display:flex;align-items:center;gap:8px}
.logo i{display:inline-grid;place-items:center;width:26px;height:26px;border-radius:7px;background:var(--text);color:#000;font-style:normal;font-size:15px}
nav a{display:flex;gap:10px;padding:9px 10px;border-radius:10px;color:var(--mute);text-decoration:none;cursor:pointer;align-items:center;font-size:13px}
nav a.on,nav a:hover{background:#171b21;color:var(--text)}
nav a svg{width:15px;height:15px;flex:none}
nav .grp{display:flex;justify-content:space-between;align-items:center;padding:12px 10px 4px;color:#8b94a1;font-size:12px;cursor:pointer;user-select:none}
nav .grp svg{width:12px;height:12px;transition:transform .15s}
nav .grp.shut svg{transform:rotate(-90deg)}
nav .sub a{padding-left:16px;font-size:12.5px}
nav .sub[hidden]{display:none}
.ucard{margin-top:auto;display:flex;gap:10px;align-items:center;padding:10px;background:#12161b;border-radius:12px}
.ucard .av{width:34px;height:34px;border-radius:8px;background:#242a33;display:grid;place-items:center;font-weight:700;font-size:13px}
.ucard b{display:block;font-size:12.5px}.ucard small{color:var(--green);font-size:11px}
main{display:flex;flex-direction:column;gap:12px;min-width:0}
.top{display:flex;justify-content:space-between;align-items:center;padding:12px 18px;position:relative}
.top .l{display:flex;gap:8px;align-items:center;font-size:13px}.top .l svg{width:14px;height:14px}
.top .r{display:flex;gap:10px;align-items:center}
.ib{background:none;border:0;color:var(--text);cursor:pointer;width:32px;height:32px;border-radius:8px;display:grid;place-items:center;position:relative}
.ib:hover{background:#171b21}.ib svg{width:16px;height:16px}
.ib .dotn{position:absolute;top:6px;right:7px;width:7px;height:7px;border-radius:50%;background:#e5484d}
.badge{border:1px solid var(--line);border-radius:8px;padding:8px 12px;cursor:pointer;background:none;color:var(--text);display:flex;align-items:center;gap:6px}
.badge b{color:#f5b400;margin-left:2px;font-size:12px}
.badge small{font-size:9px;color:var(--mute)}
.avatar{width:32px;height:32px;border-radius:8px;background:#242a33;display:grid;place-items:center;font-size:11px;font-weight:700}
.menu{position:absolute;right:14px;top:56px;background:#12161b;border:1px solid var(--line);border-radius:12px;min-width:210px;padding:6px;z-index:30;display:none}
.menu.open{display:block}
.menu button,.menu div.it{display:block;width:100%;text-align:left;background:none;border:0;color:var(--text);padding:9px 10px;border-radius:8px;cursor:pointer;font-size:13px}
.menu button:hover{background:#1b2027}
.menu .e{color:var(--mute);padding:10px;font-size:12px}
.menu .it span{display:block;color:var(--mute);font-size:11px}
.grid{display:grid;grid-template-columns:1.3fr 1fr;overflow:hidden}
.grid>div{padding:20px}
.grid>div+div{border-left:1px solid var(--line)}
.lbl{color:var(--mute);font-size:13px}
.total{font-size:30px;font-weight:700;margin:2px 0 18px}
.hd{display:flex;justify-content:space-between;align-items:flex-start;position:relative}
.hd .acts2{display:flex;gap:8px;align-items:center}
.mm{background:#10283d;color:var(--blue);border:0;border-radius:8px;padding:8px 12px;font-weight:600;cursor:pointer;display:flex;gap:6px;align-items:center;font-size:13px}
.sq{background:#171b21;border:0;color:var(--mute);width:34px;height:34px;border-radius:8px;cursor:pointer;display:grid;place-items:center}
.sq:hover{color:var(--text)}.sq svg{width:15px;height:15px}
.eye{background:none;border:0;color:var(--mute);cursor:pointer;vertical-align:middle;margin-left:4px;padding:0}
.eye svg{width:13px;height:13px}
.va{background:none;border:0;color:var(--blue);cursor:pointer;font-size:13px}
.row{display:flex;align-items:center;gap:12px;padding:12px 0;border-top:1px solid var(--line)}
.ico{width:36px;height:36px;flex:none}
.row .n{flex:1}.row .n span,.row .v span{display:block;color:var(--mute);font-size:12px}
.row .v{text-align:right;font-weight:600}
.bar{display:flex;height:24px;gap:4px;margin:12px 0}
.bar i{display:block;border-radius:6px}
.legend{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:22px}
.legend b{display:block;font-size:16px;margin-top:2px}
.dot{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:6px}
.pr{display:flex;justify-content:space-between;align-items:center}
.pr b{font-size:13px}
.prog{height:12px;background:#1e2b27;border-radius:6px;margin:8px 0 20px;overflow:hidden}
.prog i{display:block;height:100%;background:#2f6b57;border-radius:6px;transition:width .4s}
.sig{display:grid;grid-template-columns:repeat(16,1fr);gap:4px;margin-top:8px}
.sig i{height:10px;border-radius:2px;background:#8b1f2b}
.sig i.f{background:#c0392b}.sig i.f.g{background:#0fb58a}.sig i.f.y{background:#f5b400}
.tabs{display:flex;padding:14px;gap:8px}
.tabs button{flex:1;padding:12px;border:0;border-radius:10px;background:#171b21;color:var(--mute);font-weight:600;cursor:pointer}
.tabs button.on{background:var(--green);color:#fff}
.trade{padding:0 14px 14px;display:flex;gap:10px;flex-wrap:wrap}
.trade select,.trade input{flex:1;min-width:120px}
button,select,input{font:inherit}
select,input{background:#12161b;color:var(--text);border:1px solid var(--line);border-radius:10px;padding:10px}
.btn{background:var(--blue);color:#fff;border:0;border-radius:10px;padding:10px 16px;font-weight:600;cursor:pointer}
.btn.ghost{background:#171b21;color:var(--text)}
button:focus-visible,input:focus-visible,select:focus-visible,a:focus-visible{outline:2px solid var(--blue);outline-offset:2px}
.modal{position:fixed;inset:0;background:#000a;display:none;place-items:center;padding:16px;z-index:50}
.modal.open{display:grid}
.sheet{background:var(--panel);border:1px solid var(--line);border-radius:var(--r);padding:20px;width:100%;max-width:380px}
.sheet h2{font-size:17px;margin-bottom:4px}
.sheet label{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-top:12px}
.sheet input{width:150px;text-align:right}
.acts{display:flex;gap:8px;margin-top:18px;justify-content:flex-end}
#msg{color:var(--mute);padding:0 14px 14px;min-height:20px}
@media(max-width:820px){.app{grid-template-columns:1fr}.grid{grid-template-columns:1fr}.grid>div+div{border-left:0;border-top:1px solid var(--line)}}
[hidden]{display:none!important}
.split{display:grid;grid-template-columns:1fr 300px;gap:12px}
.chartcard{padding:12px;min-width:0}
.ctop{display:flex;gap:6px;align-items:center;margin-bottom:8px;flex-wrap:wrap;font-size:12px}
.ctop select{padding:6px 8px;font-size:12px;border-radius:8px}
.sep{width:1px;height:18px;background:var(--line);margin:0 4px}
.tb{background:#171b21;color:var(--mute);border:0;border-radius:8px;padding:6px 10px;cursor:pointer;font-size:12px}
.tb.on{color:var(--text);background:#242a33}
.tb:hover{color:var(--text)}
#tf button{background:#171b21;color:var(--mute);border:0;border-radius:8px;padding:6px 10px;cursor:pointer;margin-right:2px}
#tf button.on{color:var(--text);background:#242a33}
.ctitle{display:flex;gap:10px;flex-wrap:wrap;align-items:baseline;padding:4px 4px 6px;font-size:12px}
.ctitle b{font-size:13px}
.ctitle .o span{color:var(--mute)}
.wrap{display:flex;gap:6px}
.tools{display:flex;flex-direction:column;gap:4px;flex:none}
.tools button{width:30px;height:30px;border:0;border-radius:8px;background:none;color:var(--mute);cursor:pointer;display:grid;place-items:center}
.tools button.on{background:#242a33;color:var(--text)}
.tools button:hover{color:var(--text)}.tools svg{width:15px;height:15px}
.cwrap{flex:1;min-width:0;position:relative}
canvas{width:100%;height:320px;display:block;cursor:crosshair;touch-action:pan-y}
.tp{padding:0 0 14px}
.tp>label,.tp>div:not(.tabs),.tp>button{margin:10px 14px 0}
.tp label{display:block;color:var(--mute);font-size:12px}
.tp select,.tp input:not([type=checkbox]){width:100%;margin-top:4px}
.tp input[type=range]{padding:0;accent-color:var(--blue)}
.kv{display:flex;justify-content:space-between;color:var(--mute);font-size:12px}
.kv b{color:var(--text)}.g{color:#4ade80!important}
.chk{display:flex!important;align-items:center;gap:8px}
.tprow{display:flex!important;justify-content:space-between;align-items:center}
.ai{background:none;border:1px solid var(--line);color:var(--text);border-radius:14px;padding:3px 10px;font-size:11px;cursor:pointer}
.ai:hover{background:#171b21}
#tpBox{display:flex;gap:8px}
.tp>button.btn{width:calc(100% - 28px)}
.note{margin-top:6px;font-size:12px}
.amtbox{display:flex;align-items:center;background:#12161b;border:1px solid var(--line);border-radius:10px;margin-top:4px}
.tp .amtbox input:not([type=checkbox]){border:0;margin:0;background:none;flex:1;min-width:0}
.tp .amtbox select{border:0;margin:0;width:auto;background:none;font-weight:600;padding-right:6px}
.levrow{display:flex;gap:10px;align-items:center;margin-top:4px}
.levrow .sl{flex:1}
.lvbox{background:#12161b;border:1px solid var(--line);border-radius:10px;padding:10px 14px;color:var(--text);min-width:52px;text-align:center;font-weight:600}
.ticks{height:8px;margin-top:2px;background:repeating-linear-gradient(90deg,#3a424d 0 1px,transparent 1px 8.25%);opacity:.8}
.tlab{display:flex;justify-content:space-between;font-size:10px;color:var(--mute);margin-top:2px}
@media(max-width:820px){.split{grid-template-columns:1fr}}
summary{cursor:pointer;padding:10px 12px;background:#12161b;border-radius:8px;margin-top:8px;list-style:none}
#hf button{padding:8px}#hf button.on{background:var(--blue)}
.fab{position:fixed;right:18px;bottom:18px;width:46px;height:46px;border-radius:50%;background:var(--blue);border:0;color:#fff;cursor:pointer;display:grid;place-items:center;z-index:40;box-shadow:0 6px 18px #0008}
.fab svg{width:20px;height:20px}
.chat{position:fixed;right:18px;bottom:74px;width:300px;max-width:calc(100vw - 36px);background:var(--panel);border:1px solid var(--line);border-radius:var(--r);z-index:40;display:none;flex-direction:column;overflow:hidden}
.chat.open{display:flex}
.chat h3{font-size:14px;padding:12px 14px;border-bottom:1px solid var(--line)}
.chat .log{padding:12px;height:200px;overflow:auto;display:flex;flex-direction:column;gap:8px;font-size:13px}
.chat .log div{padding:8px 10px;border-radius:10px;background:#171b21;max-width:85%}
.chat .log div.me{background:var(--blue);align-self:flex-end}
.chat form{display:flex;gap:6px;padding:10px;border-top:1px solid var(--line)}
.chat form input{flex:1;min-width:0}
.toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:#171b21;border:1px solid var(--line);padding:10px 16px;border-radius:10px;z-index:60;font-size:13px;display:none}
.toast.show{display:block}
/* ---------- responsive ---------- */
html{-webkit-text-size-adjust:100%}
body{overflow-x:hidden}
.app{max-width:1680px;margin:0 auto;width:100%}
.mbtn,.scrim{display:none}
.row .n{min-width:0;word-break:break-word}
.row .v{white-space:nowrap}
.sheet{max-height:90vh;max-height:90dvh;overflow:auto}
.ctop{max-width:100%}
@media(max-width:1100px){
 .app{grid-template-columns:200px 1fr}
 .split{grid-template-columns:1fr 270px}
}
@media(max-width:820px){
 .app{padding:8px;gap:8px;grid-template-columns:1fr}
 main{gap:8px}
 .split{grid-template-columns:1fr}
 aside{position:fixed;top:0;left:0;bottom:0;height:100vh;height:100dvh;width:250px;max-width:82vw;z-index:70;border-radius:0 var(--r) var(--r) 0;transform:translateX(-105%);transition:transform .2s;padding-top:max(14px,env(safe-area-inset-top))}
 body.nav-open aside{transform:none}
 body.nav-open .scrim{display:block;position:fixed;inset:0;background:#000a;z-index:65}
 .mbtn{display:grid}
 .top{padding:8px 10px;gap:6px}
 .top .l{gap:4px}
 .top .r{gap:2px}
 .badge{padding:6px 8px;font-size:12px}
 .grid>div{padding:14px}
 .total{font-size:24px;margin-bottom:12px}
 .hd{flex-wrap:wrap;gap:10px;margin-bottom:4px}
 .hd .acts2{width:100%;flex-wrap:wrap}
 .mm{flex:1;justify-content:center}
 .legend{grid-template-columns:repeat(2,1fr)}
 .chartcard{padding:10px}
 .ctop{flex-wrap:nowrap;overflow-x:auto;scrollbar-width:none;padding-bottom:4px}
 .ctop::-webkit-scrollbar{display:none}
 .ctop>*{flex:none}
 .ctop select{font-size:16px}
 .ctitle{font-size:11px;gap:6px}
 .wrap{flex-direction:column}
 .tools{flex-direction:row;overflow-x:auto}
 .tools button{width:36px;height:34px}
 select,input{font-size:16px}
 .tabs{padding:10px}
 .tabs button{padding:11px 6px}
 .tb,#tf button{padding:8px 11px}
 .ib{width:36px;height:36px}
 .sq{width:38px;height:38px}
 .va,.ai{padding:6px 10px}
 .row{gap:10px}
 .row .n{font-size:13px}
 summary{padding:12px}
 .fab{right:12px;bottom:calc(12px + env(safe-area-inset-bottom))}
 .chat{right:12px;bottom:calc(68px + env(safe-area-inset-bottom))}
 .menu{right:8px;max-width:calc(100vw - 16px)}
 .toast{bottom:calc(76px + env(safe-area-inset-bottom));max-width:calc(100vw - 24px);text-align:center}
}
@media(max-width:420px){
 .top .l>svg,#topAv{display:none}
 .badge small{display:none}
 .total{font-size:22px}
 .sig{gap:3px}
}
@media(max-height:480px) and (orientation:landscape){
 canvas{height:240px}
}
.demobar{background:#1a2230;border:1px solid #27405f;color:#9cc7f5;border-radius:10px;padding:8px 12px;font-size:12.5px;margin-bottom:12px}
</style>
</head>
<body>
<div class="app">
<div class="scrim" id="scrim"></div>
<aside>
 <div class="logo" id="brand"></div>
 <nav id="nav"></nav>
 <div class="ucard"><div class="av" id="uAv"></div><div><b id="uName"></b><small>Demo account</small></div></div>
</aside>
<main>
 <div class="demobar" role="note">Demo mode: practice funds and simulated prices. No real money is held or moved.</div>
 <div class="card top">
  <span class="l"><button class="ib mbtn" id="menuBtn" aria-label="Open menu"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px"><path d="M4 6h16M4 12h16M4 18h16"/></svg></button><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8v10H3z"/></svg>Dashboard</span>
  <span class="r">
   <button class="ib" id="globe" aria-label="Language"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/></svg></button>
   <button class="badge" id="acctBtn"><span id="topBal"></span><b>DEMO</b><small>&#9660;</small></button>
   <button class="ib" id="bell" aria-label="Notifications"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 17V11a6 6 0 0112 0v6l2 2H4zM10 21h4"/></svg><i class="dotn" id="bellDot" hidden></i></button>
   <span class="avatar" id="topAv"></span>
  </span>
  <div class="menu" id="acctMenu">
   <div class="it">Demo account<span id="mEmail">Practice funds only</span></div>
   <button id="mSettings">Profile settings</button>
   <button id="mAdmin" hidden>Administration</button>
   <button id="mReset">Reset demo account</button>
   <button id="mOut">Sign out</button>
  </div>
  <div class="menu" id="bellMenu"></div>
  <div class="menu" id="langMenu"><button data-l="English">English</button><button data-l="Francais">Fran&ccedil;ais</button><button data-l="Espanol">Espa&ntilde;ol</button></div>
 </div>

 <div class="card grid" id="secAssets">
  <div>
   <div class="hd">
    <div>
     <div class="lbl">Total balance (demo)<button class="eye" id="eyeBtn" aria-label="Hide balance"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg></button></div>
     <div class="total" id="total"></div>
    </div>
    <div class="acts2">
     <button class="mm" id="mmBtn">&#10022; Move money &#9662;</button>
     <button class="sq" id="editBtn" aria-label="Reset demo account" title="Reset demo account"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="6" width="18" height="14" rx="2"/><path d="M3 10h18"/></svg></button>
     <button class="sq" id="expBtn" aria-label="Export trades" title="Export trades (CSV)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 3h9l4 4v14H6zM14 3v5h5"/></svg></button>
     <div class="menu" id="mmMenu" style="top:40px;right:0"><button data-a="Deposit">Deposit</button><button data-a="Withdraw">Withdraw</button><button id="mmConv">Convert</button></div>
    </div>
   </div>
   <div style="display:flex;justify-content:space-between;align-items:center">
    <span class="lbl">Top assets</span>
    <button class="va" id="vaBtn">View all assets &#8250;</button>
   </div>
   <div id="assets"></div>
  </div>
  <div>
   <div class="lbl">Categories</div>
   <div class="bar" id="bar"></div>
   <div class="legend" id="legend"></div>
   <div class="pr"><span class="lbl">Trading progress</span><b id="progV">0%</b></div><div class="prog"><i id="progI" style="width:0"></i></div>
   <div class="pr"><span class="lbl">Signal strength</span><b id="sigV" style="color:#e5484d">0%</b></div><div class="sig" id="sig"></div>
  </div>
 </div>

 <div class="split" id="secTrade">
  <div class="card chartcard">
   <div class="ctop"><select id="cSym" aria-label="Chart symbol"></select>
    <span class="sep"></span>
    <span id="tf"><button data-n="40" data-l="1m">1m</button><button data-n="60" data-l="30m">30m</button><button data-n="75" data-l="1h">1h</button><button class="on" data-n="90" data-l="D">D</button></span>
    <span class="sep"></span>
    <button class="tb on" id="ctCandle">Candles</button><button class="tb" id="ctLine">Line</button>
    <button class="tb" id="indBtn">Indicators: MA</button>
    <button class="tb" id="shotBtn" aria-label="Save chart image">&#128247;</button>
    <button class="btn" id="hideChart" style="margin-left:auto;padding:6px 12px">Hide chart</button></div>
   <div id="chartBody">
    <div class="ctitle" id="cTitle"></div>
    <div class="wrap">
     <div class="tools" id="tools">
      <button class="on" data-t="cross" title="Crosshair"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v18M3 12h18"/></svg></button>
      <button data-t="trend" title="Trend line"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19L20 5"/><circle cx="4" cy="19" r="2"/><circle cx="20" cy="5" r="2"/></svg></button>
      <button data-t="hline" title="Horizontal line"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12h18"/></svg></button>
      <button data-t="clear" title="Remove drawings"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 7h14M9 7V4h6v3M7 7l1 13h8l1-13"/></svg></button>
     </div>
     <div class="cwrap"><canvas id="chart"></canvas></div>
    </div>
    <div class="lbl note">DEMO: current prices are simulated on the server. The chart history before today is generated for illustration and is not real market data.</div>
   </div>
  </div>
  <div class="card tp">
   <div class="tabs" id="tabs"><button class="on" data-m="Buy">Buy</button><button data-m="Sell">Sell</button><button data-m="Convert">Convert</button></div>
   <label>Trade type<select id="tType"></select></label>
   <label id="fromRow" hidden>From<select id="tFrom"></select></label>
   <label><span id="aLbl">Amount</span><div class="amtbox"><input id="tAmt" type="number" min="0" step="any" placeholder="100"><select id="tAsset" aria-label="Asset"></select></div></label>
   <div class="kv">Current USD balance <b id="kUsd"></b></div>
   <div class="kv">Current <span id="kSym" style="margin-left:4px"></span> price <b id="kPx" class="g"></b></div>
   <div id="levBox"><label>Leverage:<div class="levrow"><div class="sl"><input type="range" id="lev" min="1" max="100" value="1"><div class="ticks"></div><div class="tlab" id="tlab"></div></div><div class="lvbox" id="levV">1x</div></div></label></div>
   <label class="chk tprow"><span style="display:flex;gap:8px;align-items:center"><input type="checkbox" id="tpOn"> Use TP/SL</span><button type="button" class="ai" id="aiBtn">Set with AI</button></label>
   <div id="tpBox" hidden><input id="tp" type="number" step="any" placeholder="Take profit"><input id="sl" type="number" step="any" placeholder="Stop loss"></div>
   <label id="durBox">Duration (leveraged trades)<select id="dur"></select></label>
   <button class="btn" id="go">Buy</button>
   <div id="msg" style="padding:10px 14px 0"></div>
  </div>
 </div>
 <div class="card" style="padding:16px"><div style="font-weight:600;margin-bottom:10px">My trades</div>
 <div id="hf" class="tabs" style="padding:0 0 4px"><button class="on" data-f="All">All</button><button data-f="Swaps">Swaps</button><button data-f="Auto">Auto</button></div>
 <details open><summary id="openS">Open (0)</summary><div id="pos"></div></details>
 <details><summary id="closedS">Closed (0)</summary><div id="hist"></div></details></div>
</main>
</div>

<button class="fab" id="fab" aria-label="Support chat"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 5h16v11H9l-5 4z"/></svg></button>
<div class="chat" id="chat"><h3>Demo support</h3><div class="log" id="clog"><div>Hi! This is a demo chat. Ask about deposits, leverage or TP/SL.</div></div><form id="cform"><input id="cin" placeholder="Type a message" autocomplete="off"><button class="btn">Send</button></form></div>
<div class="toast" id="toast"></div>

<div class="modal" id="modal" role="dialog" aria-modal="true" aria-labelledby="mt">
 <div class="sheet">
  <h2 id="mt">Reset demo account</h2>
  <div class="lbl">This closes your open trades and restores your demo balances to the starting amounts. Your trade history is kept.</div>
  <div class="acts">
   <button class="btn ghost" id="cancel">Cancel</button>
   <button class="btn" id="reset">Reset demo account</button>
  </div>
 </div>
</div>

<div class="modal" id="money" role="dialog" aria-modal="true" aria-labelledby="moneyT">
 <div class="sheet">
  <h2 id="moneyT">Deposit</h2>
  <div class="lbl">Demo funds only. No real money moves.</div>
  <label>Amount (USD)<input id="moneyAmt" type="number" min="0" step="any" placeholder="100"></label>
  <div class="lbl" id="moneyErr" style="margin-top:8px;min-height:18px"></div>
  <div class="acts"><button class="btn ghost" id="moneyCancel">Cancel</button><button class="btn" id="moneyOk">Confirm</button></div>
 </div>
</div>

<div class="modal" id="serviceHub" role="dialog" aria-modal="true" aria-labelledby="serviceTitle">
 <div class="sheet" style="max-width:520px">
  <div style="display:flex;justify-content:space-between;align-items:center;gap:12px"><h2 id="serviceTitle">Services</h2><button class="sq" id="serviceClose" aria-label="Close">✕</button></div>
  <div class="lbl" id="serviceIntro" style="margin:8px 0 14px">Submit a demo service request. These are enquiries only; no real funds or assets are moved.</div>
  <div id="serviceBody"></div>
 </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js"></script>
<script src="{{ asset('js/config.js') }}"></script>
<script src="{{ asset('js/supabase-client.js') }}"></script>
<script src="{{ asset('js/api.js') }}"></script>
<script>
/* ============================================================
   CONFIG: edit everything here. No other code needs to change.
   ============================================================ */
const CONFIG={
 brand:"Demo Broker",                 // sidebar name and page title
 logoLetter:"D",                      // letter shown in the logo square
 userName:"Demo User",                // name shown in the sidebar card and avatar
 storageKey:"demo-dashboard-balances",// change per site so saved data doesn't clash
 currency:"$",                        // symbol shown before amounts
 maxLeverage:100,                     // leverage slider maximum
 tickMs:5000,                         // how often prices are fetched from the server (demo prices move every 5s)
 durations:[{label:"1 minute",sec:60},{label:"2 minutes",sec:120},{label:"5 minutes",sec:300},{label:"15 minutes",sec:900},{label:"No limit",sec:0}],
 defaultDuration:120,
 volatility:.003,                     // (unused: price movement is now simulated on the server)
 //                     // size of each simulated price move
 defaultSymbol:"AAPL",                // symbol the chart opens on
 tradeTypes:["Crypto","Stocks"],      // options in the Trade type dropdown (match asset "cat")
 topAssets:4,                         // rows shown before "View all assets"
 aiTpPct:.03, aiSlPct:.015,           // "Set with AI" take-profit / stop-loss distance
 nav:[                                // sidebar: {t,i,go} link, {g,items} collapsible group
  {t:"Dashboard",i:"home",on:1,go:"top"},{t:"Deposit",i:"plus",go:"Deposit"},{t:"Withdraw",i:"minus",go:"Withdraw"},{t:"Assets",i:"box",go:"assets"},{t:"Settings",i:"gear",go:"settings"},
  {g:"Services",items:[{t:"Cold Storage",i:"snow"},{t:"Cards",i:"card"},{t:"Subscribe",i:"stack"},{t:"Signals",i:"wifi"},{t:"Connect wallet",i:"link"}]},
  {g:"Earn",items:[{t:"Investing",i:"pie"},{t:"Copy trading",i:"copy"},{t:"Mining",i:"pick"},{t:"Real Estate",i:"home"},{t:"Stake",i:"coin"},{t:"Referrals",i:"user"}]},
  {g:"Trade",items:[{t:"Markets",i:"pie",go:"chart"},{t:"Trade",i:"arrow",go:"trade"}]}
 ],
 categories:[                         // category bar: [name, color]
  ["Crypto","#3b82f6"],["Stocks","#7cc8ff"],["Fiat","#6366f1"],["Real estate","#ff4d5a"]
 ],
 // price = starting price; icon = optional custom SVG inner markup (viewBox 0 0 32 32);
 // color is used for the fallback letter icon when no icon is set.
 assets:[
  {id:"BTC",name:"Bitcoin",cat:"Crypto",price:80000},
  {id:"ETH",name:"Ethereum",cat:"Crypto",price:2500},
  {id:"USD",name:"United States Dollar",cat:"Fiat",price:1},
  {id:"SOL",name:"Solana",cat:"Crypto",price:100},
  {id:"AAPL",name:"Apple",cat:"Stocks",price:200,color:"#7cc8ff"}
 ],
 startingBalances:{BTC:5000,ETH:2000,USD:3000,SOL:2000,AAPL:1000} // (unused: starting funds are set in the database, table platform_settings)
};
const ASSETS=CONFIG.assets;
const W="#fff";
const ICONS={
BTC:`<circle cx="16" cy="16" r="16" fill="#f7931a"/><g transform="rotate(14 16 16)" fill="${W}"><path d="M11.5 8.5h5.2c2.3 0 3.8 1.1 3.8 3 0 1.3-.7 2.2-1.9 2.6 1.6.3 2.6 1.4 2.6 3 0 2.1-1.7 3.4-4.3 3.4h-5.4zm2.6 4.6h2.3c.9 0 1.4-.4 1.4-1.1s-.5-1.1-1.4-1.1h-2.3zm0 5.3h2.6c1 0 1.6-.4 1.6-1.2s-.6-1.2-1.6-1.2h-2.6z"/><rect x="13.2" y="6" width="1.7" height="3.2"/><rect x="16.6" y="6" width="1.7" height="3.2"/><rect x="13.2" y="22.8" width="1.7" height="3.2"/><rect x="16.6" y="22.8" width="1.7" height="3.2"/></g>`,
ETH:`<circle cx="16" cy="16" r="16" fill="#627eea"/><g fill="${W}"><path d="M16 5.5v7.6l6.4 2.9z" opacity=".6"/><path d="M16 5.5 9.6 16l6.4-2.9z"/><path d="M16 21.4v5.1l6.4-8.9z" opacity=".6"/><path d="M16 26.5v-5.1l-6.4-3.8z"/><path d="M16 20.4l6.4-4.4-6.4-2.9z" opacity=".2"/><path d="M9.6 16l6.4 4.4v-7.3z" opacity=".6"/></g>`,
USD:`<circle cx="16" cy="16" r="16" fill="#1a73e8"/><text x="16" y="22.5" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="20" fill="${W}">$</text>`,
SOL:`<defs><linearGradient id="sg" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#9945ff"/><stop offset="1" stop-color="#7f8cf0"/></linearGradient></defs><circle cx="16" cy="16" r="16" fill="url(#sg)"/><g fill="${W}"><path d="M11 9.5h13.5l-3 3.6H8z"/><path d="M8 14.3h13.5l3 3.6H11z"/><path d="M11 19.1h13.5l-3 3.6H8z"/></g>`,
AAPL:`<circle cx="16" cy="16" r="16" fill="#7cc8ff"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="17" fill="#0b1b2b">A</text>`
};
const NI={ // sidebar icons (24x24, stroke)
home:"M3 11l9-8 9 8v10H3z",plus:"M12 7v10M7 12h10M12 3a9 9 0 100 18 9 9 0 000-18z",minus:"M7 12h10M12 3a9 9 0 100 18 9 9 0 000-18z",
box:"M4 5h16v4H4zM5 9h14v10H5z",gear:"M12 9a3 3 0 100 6 3 3 0 000-6zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2",
snow:"M12 3v18M4 7l16 10M20 7L4 17",card:"M3 6h18v12H3zM3 10h18",stack:"M4 5h16v5H4zM4 14h16v5H4z",wifi:"M4 9a12 12 0 0116 0M7 13a7 7 0 0110 0M11 17h2",link:"M10 14a4 4 0 005 0l3-3a4 4 0 00-6-5l-1 1M14 10a4 4 0 00-5 0l-3 3a4 4 0 006 5l1-1",
pie:"M12 3a9 9 0 109 9h-9zM15 3a9 9 0 016 6h-6z",copy:"M8 8h12v12H8zM4 4h12v3M4 4v12h3",pick:"M4 20L14 10M8 5c5-2 10 0 12 5-3-3-6-4-9-3z",coin:"M12 3a9 9 0 100 18 9 9 0 000-18zM9 12h6",user:"M12 4a4 4 0 100 8 4 4 0 000-8zM4 21c1-5 15-5 16 0",arrow:"M4 17l5-5 4 4 7-8"
};
const nIco=k=>`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${NI[k]||NI.box}"/></svg>`;
const DEFAULTS=CONFIG.startingBalances;
const CATS=CONFIG.categories;
const KEY=CONFIG.storageKey;
let bal={},units={};   // units = what the database says you hold; bal = that holding valued in USD
let mode="Buy",hidden=false,showAll=false;
const $=id=>document.getElementById(id);
const usd=n=>CONFIG.currency+n.toLocaleString("en-US",{minimumFractionDigits:2,maximumFractionDigits:2});
const mk=s=>hidden?"\u2022\u2022\u2022\u2022\u2022\u2022":s;
function save(){/* balances live in the database; nothing is saved in the browser */}
function toast(t){const e=$("toast");e.textContent=t;e.classList.add("show");clearTimeout(toast.t);toast.t=setTimeout(()=>e.classList.remove("show"),2200)}
let notes=[];
const esc=t=>String(t).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
async function refreshNotes(){try{const r=await API.loadNotifications();notes=r.map(n=>({t:n.title,at:new Date(n.created_at),unread:!n.read_at}));$("bellDot").hidden=!notes.some(n=>n.unread)}catch(e){}}
function notify(){refreshNotes()}   // the server writes the notification; we just reload the list
const syncBal=()=>ASSETS.forEach(a=>{bal[a.id]=(units[a.id]||0)*(px[a.id]||0)});
const mapPos=r=>({id:r.id,sym:r.symbol,side:r.side,margin:+r.margin_usd,lev:r.leverage,entry:+r.entry_price,tp:r.take_profit?+r.take_profit:0,sl:r.stop_loss?+r.stop_loss:0,exp:r.expires_at?Date.parse(r.expires_at):0});
const REASON={manual:"manual",take_profit:"take profit",stop_loss:"stop loss",liquidated:"liquidated",duration_ended:"duration ended"};
let currentProfile=null, referralRows=[];
function applyState(st){
 currentProfile=st.profile;referralRows=st.referrals||[];
 st.prices.forEach(p=>{px[p.symbol]=Number(p.price)});
 units=st.wallets;syncBal();
 pos=st.positions.map(mapPos);
 const h=[];
 st.orders.forEach(o=>h.push({kind:o.kind,t:o.kind==="swap"?`Swap ${o.from_symbol} to ${o.symbol}`:`${o.side==="sell"?"Sold":"Bought"} ${o.symbol}`,sub:usd(+o.amount_usd),pnl:0,at:new Date(o.created_at)}));
 st.closed.forEach(p=>h.push({kind:p.close_reason==="manual"?"manual":"auto",t:`${p.symbol} ${p.side} ${p.leverage}x (${REASON[p.close_reason]||p.close_reason})`,pnl:+p.pnl_usd,at:new Date(p.closed_at)}));
 (st.ledger||[]).forEach(x=>h.push({kind:"wallet",t:({demo_grant:"Demo starting funds",demo_deposit:"Demo deposit",demo_withdrawal:"Demo withdrawal",demo_reset:"Demo balance reset"}[x.entry_type]||x.entry_type),sub:`${x.symbol} ${Number(x.amount)>0?"+":""}${Number(x.amount).toFixed(6)}`,pnl:0,at:new Date(x.created_at)}));
 hist=h.sort((a,b)=>b.at-a.at).slice(0,100);
}
async function refreshState(){applyState(await API.loadState())}
function render(){
 const total=Object.values(bal).reduce((a,b)=>a+b,0);
 $("total").textContent=mk(usd(total));$("topBal").textContent=usd(total);
 const list=showAll?ASSETS:ASSETS.slice(0,CONFIG.topAssets);
 $("vaBtn").textContent=showAll?"Show less \u2039":"View all assets \u203A";$("vaBtn").hidden=ASSETS.length<=CONFIG.topAssets;
 $("assets").innerHTML=list.map(a=>{const v=bal[a.id]||0;return `<div class="row"><svg class="ico" viewBox="0 0 32 32" aria-hidden="true">${a.icon||ICONS[a.id]||`<circle cx="16" cy="16" r="16" fill="${a.color||"#555d6b"}"/><text x="16" y="21.5" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">${a.id[0]}</text>`}</svg><div class="n">${a.name}<span>${a.id}</span></div><div class="v">${mk(usd(v))}<span>${mk((v/(px[a.id]||a.price)).toFixed(4))} ${a.id}</span></div></div>`}).join("");
 const by={};ASSETS.forEach(a=>by[a.cat]=(by[a.cat]||0)+(bal[a.id]||0));
 $("bar").innerHTML=CATS.filter(c=>by[c[0]]>0).map(c=>`<i style="flex:${by[c[0]]};background:${c[1]}"></i>`).join("");
 $("legend").innerHTML=CATS.map(c=>{const p=total?((by[c[0]]||0)/total*100):0;return `<div class="lbl"><span class="dot" style="background:${c[1]}"></span>${c[0]}<b style="color:var(--text)">${p.toFixed(0)}%</b></div>`}).join("");
 if($("kUsd"))updK();
}
const px={};ASSETS.forEach(a=>px[a.id]=a.price);
let pos=[],hist=[],flt="All",cs=[],cn=90,tfl="D",uid=1,tk=0,ctype="candle",ma=false,tool="cross",hov=-1,pend=null,draws={};
function fillTrade(){
 const ty=$("tType").value;
 const list=ASSETS.filter(a=>mode==="Convert"||a.cat===ty);
 const opt=l=>l.map(a=>`<option value="${a.id}">${a.id}</option>`).join("");
 $("tAsset").innerHTML=opt(list);$("tFrom").innerHTML=ASSETS.map(a=>`<option value="${a.id}">${a.name}</option>`).join("");updK();
}
function updK(){
 const s=$("tAsset").value||"BTC",c=$("cSym").value;
 $("kUsd").textContent=usd(bal.USD);$("kPx").textContent=usd(px[s]);$("kSym").textContent=s;
 updTitle();updSignal();
}
function gen(){
 let p=px[$("cSym").value];cs=[];
 for(let i=0;i<cn;i++){
  const c=p,o=c*(1+(Math.random()-.48)*.014);
  cs.unshift({o,c,h:Math.max(o,c)*(1+Math.random()*.006),l:Math.min(o,c)*(1-Math.random()*.006),v:20+Math.random()*80});p=o;
 }
}
function updTitle(){
 const s=$("cSym").value,a=ASSETS.find(x=>x.id===s);if(!a||!cs.length)return;
 const k=cs[hov>=0&&hov<cs.length?hov:cs.length-1],ch=k.c-k.o,pc=ch/k.o*100,col=ch>=0?"#4ade80":"#e5484d",f=v=>v.toFixed(2);
 $("cTitle").innerHTML=`<b>${a.name} \u00B7 ${tfl} \u00B7 Demo</b><span class="o"><span>O</span> ${f(k.o)} <span>H</span> ${f(k.h)} <span>L</span> ${f(k.l)} <span>C</span> ${f(k.c)} <b style="color:${col}">${ch>=0?"+":""}${f(ch)} (${pc.toFixed(2)}%)</b></span>`;
}
function updSignal(){
 const n=Math.min(20,cs.length);if(n<2)return;
 const a=cs[cs.length-n].c,b=cs[cs.length-1].c,pct=Math.max(0,Math.min(100,Math.round(50+(b/a-1)*2500)));
 const f=Math.round(pct/100*16),cl=pct>=60?"g":pct>=35?"y":"";
 $("sig").innerHTML=Array.from({length:16},(_,i)=>`<i class="${i<f?"f "+cl:""}"></i>`).join("");
 $("sigV").textContent=pct+"%";$("sigV").style.color=pct>=60?"#4ade80":pct>=35?"#f5b400":"#e5484d";
}
const CH=()=>innerWidth<=820?(innerHeight<480?220:260):(innerHeight<480?240:320);
function sma(n){return cs.map((_,i)=>{if(i<n-1)return null;let s=0;for(let j=i-n+1;j<=i;j++)s+=cs[j].c;return s/n})}
function geom(){
 const cv=$("chart"),w=cv.clientWidth,h=CH(),pad=60;
 const hi=Math.max(...cs.map(k=>k.h)),lo=Math.min(...cs.map(k=>k.l)),rg=hi-lo||1;
 return{w,h,pad,hi,lo,rg,Y:v=>10+(hi-v)/rg*(h-90),V:y=>hi-(y-10)/(h-90)*rg,bw:(w-pad)/cs.length};
}
function draw(){
 const cv=$("chart"),d=window.devicePixelRatio||1,h=CH();cv.style.height=h+"px";const w=cv.clientWidth;
 if(!w||!cs.length)return;
 cv.width=w*d;cv.height=h*d;const x=cv.getContext("2d");x.scale(d,d);
 const G=geom(),{pad,hi,lo,rg,Y,bw}=G;
 x.font="11px system-ui";x.lineWidth=1;
 for(let i=0;i<5;i++){const v=lo+rg*i/4,y=Y(v);x.strokeStyle="#1a1f26";x.beginPath();x.moveTo(0,y);x.lineTo(w-pad,y);x.stroke();x.fillStyle="#8b94a1";x.fillText(v.toFixed(2),w-pad+6,y+4)}
 if(ctype==="candle"){
  cs.forEach((k,i)=>{
   const col=k.c>=k.o?"#0fb58a":"#e5484d",cx=i*bw+bw/2;
   x.strokeStyle=col;x.fillStyle=col;x.beginPath();x.moveTo(cx,Y(k.h));x.lineTo(cx,Y(k.l));x.stroke();
   const y1=Y(Math.max(k.o,k.c)),y2=Y(Math.min(k.o,k.c));x.fillRect(cx-bw*.35,y1,bw*.7,Math.max(1,y2-y1));x.globalAlpha=.35;x.fillRect(cx-bw*.35,h-5-k.v*.5,bw*.7,k.v*.5);x.globalAlpha=1;
  });
 }else{
  x.strokeStyle="#2d9cff";x.lineWidth=2;x.beginPath();
  cs.forEach((k,i)=>{const cx=i*bw+bw/2;i?x.lineTo(cx,Y(k.c)):x.moveTo(cx,Y(k.c))});x.stroke();x.lineWidth=1;
  cs.forEach((k,i)=>{x.fillStyle=k.c>=k.o?"#0fb58a":"#e5484d";x.globalAlpha=.35;x.fillRect(i*bw+bw*.15,h-5-k.v*.5,bw*.7,k.v*.5);x.globalAlpha=1});
 }
 if(ma){const m=sma(10);x.strokeStyle="#f5b400";x.lineWidth=1.5;x.beginPath();let st=false;m.forEach((v,i)=>{if(v==null)return;const cx=i*bw+bw/2;st?x.lineTo(cx,Y(v)):x.moveTo(cx,Y(v));st=true});x.stroke();x.lineWidth=1}
 const last=cs[cs.length-1].c;
 x.strokeStyle="#8b94a1";x.setLineDash([4,4]);x.beginPath();x.moveTo(0,Y(last));x.lineTo(w-pad,Y(last));x.stroke();x.setLineDash([]);
 x.fillStyle="#2d9cff";x.fillRect(w-pad,Y(last)-9,pad,18);x.fillStyle="#fff";x.fillText(last.toFixed(2),w-pad+6,Y(last)+4);
 /* open positions on this symbol */
 pos.filter(p=>p.sym===$("cSym").value).forEach(p=>{const y=Y(p.entry);if(y>0&&y<h){x.strokeStyle=p.side==="long"?"#0fb58a":"#e5484d";x.setLineDash([2,4]);x.beginPath();x.moveTo(0,y);x.lineTo(w-pad,y);x.stroke();x.setLineDash([])}});
 /* drawings */
 (draws[$("cSym").value]||[]).forEach(d=>{
  x.strokeStyle="#f5b400";x.lineWidth=1.5;x.beginPath();
  if(d.t==="hline"){x.moveTo(0,Y(d.p));x.lineTo(w-pad,Y(d.p));x.stroke();x.fillStyle="#f5b400";x.fillText(d.p.toFixed(2),4,Y(d.p)-4)}
  else{const ax=(cs.length+d.a.i)*bw+bw/2,bx=(cs.length+d.b.i)*bw+bw/2;x.moveTo(ax,Y(d.a.p));x.lineTo(bx,Y(d.b.p));x.stroke()}
  x.lineWidth=1;
 });
 if(pend){x.fillStyle="#f5b400";x.beginPath();x.arc((cs.length+pend.i)*bw+bw/2,Y(pend.p),3,0,7);x.fill()}
 /* crosshair */
 if(hov>=0&&hov<cs.length&&tool==="cross"&&draw.my!=null){
  const cx=hov*bw+bw/2;x.strokeStyle="#5d6673";x.setLineDash([3,3]);x.beginPath();x.moveTo(cx,0);x.lineTo(cx,h);x.moveTo(0,draw.my);x.lineTo(w-pad,draw.my);x.stroke();x.setLineDash([]);
  x.fillStyle="#242a33";x.fillRect(w-pad,draw.my-9,pad,18);x.fillStyle="#fff";x.fillText(G.V(draw.my).toFixed(2),w-pad+6,draw.my+4);
 }
}
const pnl=p=>p.margin*p.lev*(p.side==="long"?1:-1)*(px[p.sym]/p.entry-1);
async function closePos(id){
 try{
  const r=await API.closePosition(id);
  await refreshState();render();drawPos();
  $("msg").textContent=`${r.symbol} ${r.side} closed (manual), P&L ${usd(r.pnl)} (demo).`;
  notify();
 }catch(e){$("msg").textContent=e.message}
}
function drawPos(){
 const col=q=>q>0?"var(--green)":q<0?"#e5484d":"var(--text)";
 const row=(t,sub,q,extra)=>`<div class="row"><div class="n">${t}<span>${sub}</span></div><div class="v" style="color:${col(q)}">${usd(q)}${extra||""}</div></div>`;
 const showOpen=flt==="All";
 $("pos").innerHTML=showOpen&&pos.length?pos.map(p=>row(`${p.sym} ${p.side} ${p.lev}x`,`Entry ${p.entry.toFixed(2)} | Margin ${usd(p.margin)} | ${p.exp?Math.max(0,Math.ceil((p.exp-Date.now())/1000))+"s left":"no limit"}${p.tp?" | TP "+p.tp:""}${p.sl?" | SL "+p.sl:""}`,pnl(p),`<span><button class="btn ghost" data-c="${p.id}">Close</button></span>`)).join(""):'<div class="lbl" style="padding:10px 4px">No open trades.</div>';
 const hl=hist.filter(h=>flt==="All"||(flt==="Swaps"&&h.kind==="swap")||(flt==="Auto"&&h.kind==="auto")).slice(0,50);
 $("hist").innerHTML=hl.length?hl.map(h=>row(h.t,(h.sub?h.sub+" | ":"")+h.at.toLocaleTimeString(),h.pnl)).join(""):'<div class="lbl" style="padding:10px 4px">No closed trades.</div>';
 $("openS").textContent=`Open (${showOpen?pos.length:0})`;$("closedS").textContent=`Closed (${hl.length})`;
 const pr=Math.min(100,hist.length*10);$("progV").textContent=pr+"%";$("progI").style.width=pr+"%";
}
let ticking=false,tickErr=false;
async function tick(){
 if(ticking)return;ticking=true;
 try{
  await API.refreshPrices();
  (await API.loadPrices()).forEach(p=>{px[p.symbol]=Number(p.price)});
  syncBal();
  const k=cs[cs.length-1],p=px[$("cSym").value];
  if(k&&p){k.c=p;k.h=Math.max(k.h,p);k.l=Math.min(k.l,p);k.v=Math.min(100,k.v+Math.random()*3);
   if(++tk%2===0){cs.push({o:p,h:p,l:p,c:p,v:20});cs.shift()}}
  if(pos.length){
   const closed=await API.settle();
   if(closed.length){await refreshState();closed.forEach(c=>toast(`${c.symbol} ${c.side} closed (${REASON[c.reason]||c.reason}): ${usd(c.pnl)}`));notify()}
  }
  tickErr=false;
 }catch(e){if(!tickErr)toast("Connection problem: "+e.message);tickErr=true}
 finally{ticking=false}
 draw();drawPos();updK();render();
}
/* ---------- trade panel ---------- */
$("tabs").onclick=e=>{const b=e.target.closest("button");if(!b)return;mode=b.dataset.m;
 [...$("tabs").children].forEach(x=>x.classList.toggle("on",x===b));$("go").textContent=mode;$("msg").textContent="";
 $("fromRow").hidden=mode!=="Convert";$("levBox").hidden=mode==="Convert";$("durBox").hidden=mode==="Convert";$("aLbl").textContent=mode==="Convert"?"To / Amount":"Amount";fillTrade()};
$("tType").onchange=fillTrade;
$("tAsset").onchange=()=>{const v=$("tAsset").value;if(v!=="USD"){$("cSym").value=v;gen();draw()}updK()};
$("cSym").onchange=()=>{gen();draw();updK()};
$("tf").onclick=e=>{const b=e.target.closest("button");if(!b)return;cn=+b.dataset.n;tfl=b.dataset.l;
 [...$("tf").children].forEach(x=>x.classList.toggle("on",x===b));gen();draw();updTitle()};
$("lev").oninput=()=>{$("levV").textContent=$("lev").value+"x"};
$("tpOn").onchange=()=>{$("tpBox").hidden=!$("tpOn").checked};
$("aiBtn").onclick=()=>{
 const s=$("tAsset").value;if(!s||s==="USD"){$("msg").textContent="Pick a non-USD asset first.";return}
 const p=px[s],lg=mode!=="Sell",f=n=>+n.toFixed(p<10?4:2);
 $("tpOn").checked=true;$("tpBox").hidden=false;
 $("tp").value=f(lg?p*(1+CONFIG.aiTpPct):p*(1-CONFIG.aiTpPct));
 $("sl").value=f(lg?p*(1-CONFIG.aiSlPct):p*(1+CONFIG.aiSlPct));
 $("msg").textContent="TP/SL suggested from current demo price. Adjust as you like.";
};
$("pos").onclick=e=>{const b=e.target.closest("[data-c]");if(b)closePos(b.dataset.c)};
$("hf").onclick=e=>{const b=e.target.closest("button");if(!b)return;flt=b.dataset.f;[...$("hf").children].forEach(x=>x.classList.toggle("on",x===b));drawPos()};
$("hideChart").onclick=()=>{const h=$("chartBody").hidden=!$("chartBody").hidden;$("hideChart").textContent=h?"Show chart":"Hide chart";if(!h)draw()};
window.addEventListener("resize",draw);
$("go").onclick=async()=>{
 const id=$("tAsset").value,amt=parseFloat($("tAmt").value),lev=+$("lev").value,m=$("msg"),b=$("go");
 if(!(amt>0)){m.textContent="Enter an amount greater than 0.";return}
 b.disabled=true;
 try{
  if(mode==="Convert"){
   const f=$("tFrom").value;
   if(f===id){m.textContent="Pick two different assets.";return}
   await API.swap(f,id,amt);
   m.textContent=`Converted ${usd(amt)} from ${f} to ${id} (demo).`;
  }else if(id==="USD"){m.textContent="Pick a non-USD asset.";return}
  else if(lev>1){
   const on=$("tpOn").checked,tp=parseFloat($("tp").value),sl=parseFloat($("sl").value),side=mode==="Buy"?"long":"short";
   await API.openPosition(id,side,amt,lev,on&&tp>0?tp:0,on&&sl>0?sl:0,+$("dur").value);
   m.textContent=`Opened ${lev}x ${side} on ${id} (demo).`;
  }else{
   await API.spot(id,mode==="Sell"?"sell":"buy",amt);
   $("tAmt").value="";
   m.textContent=`${mode==="Sell"?"Sold":"Bought"} ${usd(amt)} of ${id} (demo).`;
  }
  await refreshState();render();drawPos();notify();
 }catch(e){m.textContent=e.message}
 finally{b.disabled=false}
};
/* ---------- chart toolbar ---------- */
$("ctCandle").onclick=()=>{ctype="candle";$("ctCandle").classList.add("on");$("ctLine").classList.remove("on");draw()};
$("ctLine").onclick=()=>{ctype="line";$("ctLine").classList.add("on");$("ctCandle").classList.remove("on");draw()};
$("indBtn").onclick=()=>{ma=!ma;$("indBtn").classList.toggle("on",ma);draw()};
$("shotBtn").onclick=()=>{$("chart").toBlob(b=>{const a=document.createElement("a");a.href=URL.createObjectURL(b);a.download=$("cSym").value+"-chart.png";a.click();setTimeout(()=>URL.revokeObjectURL(a.href),500)});toast("Chart image saved")};
$("tools").onclick=e=>{const b=e.target.closest("button");if(!b)return;const t=b.dataset.t;
 if(t==="clear"){draws[$("cSym").value]=[];pend=null;draw();return}
 tool=t;pend=null;[...$("tools").children].forEach(x=>x.classList.toggle("on",x===b));draw()};
const cv0=$("chart");
function pt(e){const r=cv0.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top}}
cv0.onpointermove=e=>{const q=pt(e),G=geom();hov=Math.max(0,Math.min(cs.length-1,Math.floor(q.x/G.bw)));draw.my=q.y;updTitle();draw()};
cv0.onpointerleave=()=>{hov=-1;draw.my=null;updTitle();draw()};
cv0.onclick=e=>{
 if(tool==="cross")return;
 const q=pt(e),G=geom(),i=Math.max(0,Math.min(cs.length-1,Math.floor(q.x/G.bw)))-cs.length,p=G.V(q.y),s=$("cSym").value;
 draws[s]=draws[s]||[];
 if(tool==="hline"){draws[s].push({t:"hline",p})}
 else if(!pend){pend={i,p}}
 else{draws[s].push({t:"trend",a:pend,b:{i,p}});pend=null}
 draw();
};
/* ---------- reset demo account ---------- */
function openEdit(){$("modal").classList.add("open")}
const close=()=>$("modal").classList.remove("open");
$("editBtn").onclick=openEdit;$("cancel").onclick=close;
$("reset").onclick=async()=>{
 try{await API.resetDemo();await refreshState();render();drawPos();toast("Demo account reset");notify()}
 catch(e){toast(e.message)}
 close();
};
$("modal").onclick=e=>{if(e.target===$("modal"))close()};
/* ---------- deposit / withdraw (demo funds only) ---------- */
let mAct="Deposit";
function openMoney(a){mAct=a;$("moneyT").textContent=a;$("moneyAmt").value="";$("moneyErr").textContent="";$("money").classList.add("open");$("moneyAmt").focus()}
const closeMoney=()=>$("money").classList.remove("open");
$("moneyCancel").onclick=closeMoney;$("money").onclick=e=>{if(e.target===$("money"))closeMoney()};
$("moneyOk").onclick=async()=>{
 const v=parseFloat($("moneyAmt").value);
 if(!(v>0)){$("moneyErr").textContent="Enter an amount greater than 0.";return}
 $("moneyOk").disabled=true;
 try{
  await (mAct==="Deposit"?API.deposit(v):API.withdraw(v));
  await refreshState();render();closeMoney();toast(`${mAct} of ${usd(v)} done (demo)`);notify();
 }catch(e){$("moneyErr").textContent=e.message}
 finally{$("moneyOk").disabled=false}
};
$("moneyAmt").onkeydown=e=>{if(e.key==="Enter")$("moneyOk").click()};
/* ---------- header, menus, misc ---------- */
const menus=["acctMenu","bellMenu","langMenu","mmMenu"];
function toggleMenu(id){const open=$(id).classList.contains("open");menus.forEach(m=>$(m).classList.remove("open"));if(!open)$(id).classList.add("open")}
$("acctBtn").onclick=e=>{e.stopPropagation();toggleMenu("acctMenu")};
$("globe").onclick=e=>{e.stopPropagation();toggleMenu("langMenu")};
$("mmBtn").onclick=e=>{e.stopPropagation();toggleMenu("mmMenu")};
$("bell").onclick=e=>{e.stopPropagation();
 $("bellMenu").innerHTML=notes.length?notes.map(n=>`<div class="it">${esc(n.t)}<span>${n.at.toLocaleTimeString()}</span></div>`).join(""):'<div class="e">No notifications yet.</div>';
 $("bellDot").hidden=true;toggleMenu("bellMenu");API.markNotificationsRead().then(()=>{notes.forEach(n=>n.unread=false)}).catch(()=>{})};
document.addEventListener("click",e=>{if(!e.target.closest(".menu"))menus.forEach(m=>$(m).classList.remove("open"))});
$("langMenu").onclick=e=>{const b=e.target.closest("button");if(b)toast("Language: "+b.dataset.l+" (demo)")};
$("mmMenu").onclick=e=>{const b=e.target.closest("button");if(!b)return;if(b.id==="mmConv"){mode="Convert";$("tabs").querySelector('[data-m="Convert"]').click();$("secTrade").scrollIntoView({behavior:"smooth"})}else openMoney(b.dataset.a)};
$("mReset").onclick=openEdit;
$("mSettings").onclick=editProfile;
$("mAdmin").onclick=()=>location.href="admin.html";
$("mOut").onclick=async()=>{await API.signOut();location.replace("login.html")};
$("eyeBtn").onclick=()=>{hidden=!hidden;render()};
$("vaBtn").onclick=()=>{showAll=!showAll;render()};
$("expBtn").onclick=()=>{
 const rows=[["Trade","Details","P&L","Time"],...hist.map(h=>[h.t,h.sub||"",h.pnl.toFixed(2),h.at.toISOString()])];
 const csv=rows.map(r=>r.map(c=>`"${String(c).replace(/"/g,'""')}"`).join(",")).join("\n");
 const a=document.createElement("a");a.href=URL.createObjectURL(new Blob([csv],{type:"text/csv"}));a.download="demo-trades.csv";a.click();setTimeout(()=>URL.revokeObjectURL(a.href),500);toast("Trades exported");
};
$("fab").onclick=()=>$("chat").classList.toggle("open");
$("cform").onsubmit=e=>{
 e.preventDefault();const t=$("cin").value.trim();if(!t)return;
 const L=$("clog"),add=(x,c)=>{const d=document.createElement("div");d.textContent=x;if(c)d.className=c;L.appendChild(d);L.scrollTop=L.scrollHeight};
 add(t,"me");$("cin").value="";
 const q=t.toLowerCase();
 const r=/deposit|withdraw/.test(q)?"Use Move money at the top of the page. Everything here is demo funds.":/lever/.test(q)?"Leverage multiplies both gains and losses. A trade is liquidated when its loss reaches your margin.":/tp|sl|stop|profit/.test(q)?"Tick Use TP/SL, or press Set with AI to fill suggested levels.":"This is a demo chat, so replies are canned. Try asking about deposits, leverage or TP/SL.";
 setTimeout(()=>add(r),500);
};
async function editProfile(){
 if(!currentProfile)return;
 const full_name=prompt("Full name",currentProfile.full_name||"");
 if(full_name===null)return;
 const phone=prompt("Phone number",currentProfile.phone||"");
 if(phone===null)return;
 const country=prompt("Country",currentProfile.country||"");
 if(country===null)return;
 try{
  const p=await API.updateProfile({full_name:full_name.trim(),phone:phone.trim(),country:country.trim()});
  currentProfile=p;CONFIG.userName=p.full_name||(p.email||"Account").split("@")[0];
  $("uName").textContent=CONFIG.userName;
  const ini=CONFIG.userName.split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase();
  $("uAv").textContent=ini;$("topAv").textContent=ini;
  toast("Profile updated successfully");
 }catch(e){toast("Could not update profile: "+e.message)}
}
async function showReferrals(){
 try{
  const rows=await API.loadReferrals();
  const code=currentProfile&&currentProfile.referral_code||"Not available";
  alert("Your referral code: "+code+"\nReferrals: "+rows.length+"\n\nReferral tracking is active; reward processing is not enabled in this demo.");
 }catch(e){toast(e.message)}
}
const SERVICE_META={
 "Cold Storage":["cold_storage","Request secure custody information","Custody is not connected to a live custodian. This form records an enquiry only."],
 "Cards":["cards","Request card programme information","No payment card is issued or connected. Submit an enquiry for the client team."],
 "Subscribe":["subscribe","Subscription interest","Subscription billing is not enabled. This records your interest only."],
 "Signals":["signals","Trading signals access","Signals shown here are not live investment advice. Request access information."],
 "Connect wallet":["connect_wallet","Wallet connection request","No wallet is connected and no private keys are requested. This records an assistance request."],
 "Investing":["investing","Investment programme enquiry","No investment products or returns are offered in this demo. Submit an enquiry only."],
 "Copy trading":["copy_trading","Copy trading interest","No trader is copied and no funds are allocated. This is an enquiry only."],
 "Mining":["mining","Mining information request","No mining contract or rewards are active. Request information only."],
 "Real Estate":["real_estate","Real estate enquiry","No property is listed for sale or investment through this demo. This records an enquiry."],
 "Stake":["stake","Staking information request","No staking or yield is active. No tokens will be locked."]
};
const SERVICE_LABEL={cold_storage:"Cold Storage",cards:"Cards",subscribe:"Subscribe",signals:"Signals",connect_wallet:"Connect wallet",investing:"Investing",copy_trading:"Copy trading",mining:"Mining",real_estate:"Real Estate",stake:"Stake"};
async function openServiceHub(name){
 const m=SERVICE_META[name];if(!m)return toast(name+" is not available yet");
 $("serviceTitle").textContent=m[1];$("serviceIntro").textContent=m[2];
 $("serviceBody").innerHTML='<label style="display:block;margin:8px 0;color:var(--mute)">Additional details (optional)<textarea id="serviceDetails" maxlength="2000" rows="3" style="display:block;width:100%;margin-top:6px;background:#12161b;color:var(--text);border:1px solid var(--line);border-radius:10px;padding:10px;resize:vertical"></textarea></label><div id="serviceMsg" class="lbl" style="min-height:20px"></div><div class="acts"><button class="btn ghost" id="serviceHistory">My requests</button><button class="btn" id="serviceSubmit">Submit enquiry</button></div>';
 $("serviceHub").classList.add("open");
 $("serviceClose").onclick=()=>$("serviceHub").classList.remove("open");
 $("serviceHistory").onclick=async()=>{const b=$("serviceBody");try{const rows=await API.loadMyServiceRequests();b.innerHTML='<h3 style="margin:10px 0">Your enquiries</h3>'+(rows.length?rows.map(x=>'<div class="row"><div class="n">'+esc(SERVICE_LABEL[x.service_key]||x.service_key)+'<span>'+esc(x.details||"No extra details")+'</span></div><div class="v">'+esc(x.status)+'</div></div>').join(""):'<div class="lbl">You have not submitted any enquiries yet.</div>')+'<div class="acts"><button class="btn ghost" id="serviceBack">Back</button></div>';$("serviceBack").onclick=()=>openServiceHub(name)}catch(e){$("serviceMsg").textContent=e.message}};
 $("serviceSubmit").onclick=async()=>{const b=$("serviceSubmit"),msg=$("serviceMsg");b.disabled=true;msg.textContent="Submitting…";try{await API.createServiceRequest(m[0],$("serviceDetails").value);msg.textContent="Your enquiry has been saved. The team can review it in the admin console.";b.textContent="Submitted";}catch(e){msg.textContent=e.message;b.disabled=false}};
}
$("serviceClose").onclick=()=>$("serviceHub").classList.remove("open");
$("serviceHub").onclick=e=>{if(e.target===$("serviceHub"))$("serviceHub").classList.remove("open")};
function goTo(g){
 if(g==="Deposit"||g==="Withdraw")openMoney(g);
 else if(g==="assets"){showAll=true;render();$("secAssets").scrollIntoView({behavior:"smooth"})}
 else if(g==="settings")editProfile();
 else if(g==="chart"||g==="trade")$("secTrade").scrollIntoView({behavior:"smooth"});
 else window.scrollTo({top:0,behavior:"smooth"});
}
document.addEventListener("keydown",e=>{if(e.key==="Escape"){close();closeMoney();document.body.classList.remove("nav-open")}});
/* ---------- boot ---------- */
(async function boot(){
 if(!window.AppSupabase||!AppSupabase.ready){location.replace("setup-check.html");return}
 if(!(await API.getSession())){location.replace("login.html");return}
 let st;
 try{st=await API.loadState()}
 catch(e){document.body.innerHTML='<div style="padding:30px;font:15px system-ui;color:#f2f5f8"><h2>Could not load your account</h2><p style="color:#8b94a1"></p><p><a style="color:#2d9cff" href="setup-check.html">Run the setup check</a> &middot; <a style="color:#2d9cff" href="login.html">Back to sign in</a></p></div>';document.body.querySelector("p").textContent=e.message;return}
 if(!st.profile){location.replace("setup-check.html");return}
 // the database decides which assets exist; CONFIG.assets only supplies icons and colours
 const CAT={crypto:"Crypto",stocks:"Stocks",fiat:"Fiat",real_estate:"Real estate",forex:"Forex",etf:"ETFs",commodity:"Commodities",other:"Other"};
 const merged=st.assets.map(a=>{const b=CONFIG.assets.find(x=>x.id===a.symbol)||{};return{...b,id:a.symbol,name:a.name,cat:CAT[a.category]||a.category,price:b.price||1}});
 ASSETS.splice(0,ASSETS.length,...merged);
 ASSETS.forEach(a=>{px[a.id]=a.price});
 CONFIG.userName=st.profile.full_name||(st.profile.email||"Account").split("@")[0];
 applyState(st);
 $("mEmail").textContent=st.profile.email||"Practice funds only";
 $("mAdmin").hidden=!["admin","superadmin"].includes(st.profile.role);
 document.title=CONFIG.brand+" | Dashboard";
$("brand").innerHTML=`<i>${CONFIG.logoLetter}</i>${CONFIG.brand}`;
const ini=CONFIG.userName.split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase();
$("uAv").textContent=ini;$("topAv").textContent=ini;$("uName").textContent=CONFIG.userName;
const link=n=>`<a${n.on?' class="on"':''} data-go="${n.go||""}" data-t="${n.t}">${nIco(n.i)}${n.t}</a>`;
$("nav").innerHTML=CONFIG.nav.map((n,i)=>n.g?`<div class="grp" data-g="${i}">${n.g}<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9l6 6 6-6"/></svg></div><div class="sub" id="sub${i}">${n.items.map(link).join("")}</div>`:link(n)).join("");
$("nav").onclick=e=>{
 const g=e.target.closest(".grp");
 if(g){g.classList.toggle("shut");$("sub"+g.dataset.g).hidden=g.classList.contains("shut");return}
 const a=e.target.closest("a");if(!a)return;
 document.body.classList.remove("nav-open");
 if(a.dataset.go)goTo(a.dataset.go);else if(a.dataset.t==="Referrals")showReferrals();else openServiceHub(a.dataset.t);
};
$("menuBtn").onclick=e=>{e.stopPropagation();document.body.classList.toggle("nav-open")};
$("scrim").onclick=()=>document.body.classList.remove("nav-open");
window.addEventListener("resize",()=>{if(innerWidth>820)document.body.classList.remove("nav-open")});
$("tType").innerHTML=CONFIG.tradeTypes.map(t=>`<option>${t}</option>`).join("");
$("lev").max=CONFIG.maxLeverage;
const ml=CONFIG.maxLeverage;$("tlab").innerHTML=[0,.25,.5,.75,1].map(f=>`<span>${Math.round(ml*f)}x</span>`).join("");
$("dur").innerHTML=CONFIG.durations.map(d=>`<option value="${d.sec}">${d.label}</option>`).join("");$("dur").value=CONFIG.defaultDuration;
$("cSym").innerHTML=ASSETS.filter(a=>a.id!=="USD").map(a=>`<option value="${a.id}">${a.id}</option>`).join("");
$("cSym").value=CONFIG.defaultSymbol;fillTrade();gen();render();drawPos();draw();updTitle();setInterval(tick,CONFIG.tickMs);refreshNotes();
})();
</script>
</body>
</html>
