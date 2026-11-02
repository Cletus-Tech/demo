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
 tickMs:1500,                         // how often simulated prices update
 durations:[{label:"1 minute",sec:60},{label:"2 minutes",sec:120},{label:"5 minutes",sec:300},{label:"15 minutes",sec:900},{label:"No limit",sec:0}],
 defaultDuration:120,
 volatility:.003,                     // size of each simulated price move
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
 startingBalances:{BTC:5000,ETH:2000,USD:3000,SOL:2000,AAPL:1000} // values in USD
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
let bal;
try{bal=JSON.parse(localStorage.getItem(KEY))||{...DEFAULTS}}catch(e){bal={...DEFAULTS}}
let mode="Buy",hidden=false,showAll=false;
const $=id=>document.getElementById(id);
const usd=n=>CONFIG.currency+n.toLocaleString("en-US",{minimumFractionDigits:2,maximumFractionDigits:2});
const mk=s=>hidden?"\u2022\u2022\u2022\u2022\u2022\u2022":s;
function save(){try{localStorage.setItem(KEY,JSON.stringify(bal))}catch(e){}}
function toast(t){const e=$("toast");e.textContent=t;e.classList.add("show");clearTimeout(toast.t);toast.t=setTimeout(()=>e.classList.remove("show"),2200)}
let notes=[];
function notify(t){notes.unshift({t,at:new Date()});notes=notes.slice(0,20);$("bellDot").hidden=false}
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
function closePos(id,why){
 const i=pos.findIndex(p=>p.id===id);if(i<0)return;
 const p=pos[i],v=Math.max(0,p.margin+pnl(p));
 bal.USD+=v;pos.splice(i,1);hist.unshift({kind:why==="manual"?"manual":"auto",t:`${p.sym} ${p.side} ${p.lev}x (${why})`,pnl:v-p.margin,at:new Date()});save();render();drawPos();
 $("msg").textContent=`${p.sym} ${p.side} closed (${why}), P&L ${usd(v-p.margin)} (demo).`;
 notify(`${p.sym} ${p.side} closed (${why}): ${usd(v-p.margin)}`);
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
function tick(){
 ASSETS.forEach(a=>{if(a.id!=="USD")px[a.id]*=1+(Math.random()-.5)*CONFIG.volatility});
 const k=cs[cs.length-1],p=px[$("cSym").value];
 k.c=p;k.h=Math.max(k.h,p);k.l=Math.min(k.l,p);k.v=Math.min(100,k.v+Math.random()*3);
 if(++tk%8===0){cs.push({o:p,h:p,l:p,c:p,v:20});cs.shift()}
 pos.slice().forEach(q=>{
  const c=px[q.sym],lg=q.side==="long";
  if(q.exp&&Date.now()>=q.exp)closePos(q.id,"duration ended");
  else if(pnl(q)<=-q.margin)closePos(q.id,"liquidated");
  else if(q.tp&&(lg?c>=q.tp:c<=q.tp))closePos(q.id,"take profit");
  else if(q.sl&&(lg?c<=q.sl:c>=q.sl))closePos(q.id,"stop loss");
 });
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
$("pos").onclick=e=>{const b=e.target.closest("[data-c]");if(b)closePos(+b.dataset.c,"manual")};
$("hf").onclick=e=>{const b=e.target.closest("button");if(!b)return;flt=b.dataset.f;[...$("hf").children].forEach(x=>x.classList.toggle("on",x===b));drawPos()};
$("hideChart").onclick=()=>{const h=$("chartBody").hidden=!$("chartBody").hidden;$("hideChart").textContent=h?"Show chart":"Hide chart";if(!h)draw()};
window.addEventListener("resize",draw);
$("go").onclick=()=>{
 const id=$("tAsset").value,amt=parseFloat($("tAmt").value),lev=+$("lev").value,m=$("msg");
 if(!(amt>0)){m.textContent="Enter an amount greater than 0.";return}
 if(mode==="Convert"){
  const f=$("tFrom").value;
  if(f===id){m.textContent="Pick two different assets.";return}
  if(bal[f]<amt){m.textContent="Not enough "+f+" in your demo balance.";return}
  bal[f]-=amt;bal[id]+=amt;hist.unshift({kind:"swap",t:`Swap ${f} to ${id}`,sub:usd(amt),pnl:0,at:new Date()});save();render();drawPos();m.textContent=`Converted ${usd(amt)} from ${f} to ${id} (demo).`;notify(`Converted ${usd(amt)} ${f} to ${id}`);return;
 }
 if(id==="USD"){m.textContent="Pick a non-USD asset.";return}
 if(lev>1){
  if(bal.USD<amt){m.textContent="Not enough USD in your demo balance.";return}
  const on=$("tpOn").checked,tp=parseFloat($("tp").value),sl=parseFloat($("sl").value);
  bal.USD-=amt;
  pos.push({id:uid++,sym:id,side:mode==="Buy"?"long":"short",margin:amt,lev,entry:px[id],tp:on&&tp>0?tp:0,sl:on&&sl>0?sl:0,exp:+$("dur").value?Date.now()+$("dur").value*1000:0});
  save();render();drawPos();m.textContent=`Opened ${lev}x ${mode==="Buy"?"long":"short"} on ${id} (demo).`;notify(`Opened ${lev}x ${mode==="Buy"?"long":"short"} on ${id}`);return;
 }
 if(mode==="Sell"){if(bal[id]<amt){m.textContent="Not enough "+id+" in your demo balance.";return}bal[id]-=amt;bal.USD+=amt}
 else{if(bal.USD<amt){m.textContent="Not enough USD in your demo balance.";return}bal.USD-=amt;bal[id]+=amt}
 hist.unshift({kind:"spot",t:`${mode==="Sell"?"Sold":"Bought"} ${id}`,sub:usd(amt),pnl:0,at:new Date()});save();render();drawPos();$("tAmt").value="";m.textContent=`${mode==="Sell"?"Sold":"Bought"} ${usd(amt)} of ${id} (demo).`;notify(`${mode==="Sell"?"Sold":"Bought"} ${usd(amt)} of ${id}`);
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
/* ---------- balances modal ---------- */
function openEdit(){
 $("fields").innerHTML=ASSETS.map(a=>`<label>${a.name}<input type="number" min="0" step="any" data-id="${a.id}" value="${bal[a.id]||0}"></label>`).join("");
 $("modal").classList.add("open");$("fields").querySelector("input").focus();
}
const close=()=>$("modal").classList.remove("open");
$("editBtn").onclick=openEdit;$("cancel").onclick=close;
$("save").onclick=()=>{$("fields").querySelectorAll("input").forEach(i=>{const v=parseFloat(i.value);bal[i.dataset.id]=v>=0?v:0});save();render();close()};
$("reset").onclick=()=>{bal={...DEFAULTS};save();render();close()};
$("modal").onclick=e=>{if(e.target===$("modal"))close()};
/* ---------- deposit / withdraw ---------- */
let mAct="Deposit";
function openMoney(a){mAct=a;$("moneyT").textContent=a;$("moneyAmt").value="";$("moneyErr").textContent="";$("money").classList.add("open");$("moneyAmt").focus()}
const closeMoney=()=>$("money").classList.remove("open");
$("moneyCancel").onclick=closeMoney;$("money").onclick=e=>{if(e.target===$("money"))closeMoney()};
$("moneyOk").onclick=()=>{
 const v=parseFloat($("moneyAmt").value);
 if(!(v>0)){$("moneyErr").textContent="Enter an amount greater than 0.";return}
 if(mAct==="Withdraw"&&v>bal.USD){$("moneyErr").textContent="Not enough USD in your demo balance.";return}
 bal.USD+=mAct==="Deposit"?v:-v;save();render();closeMoney();toast(`${mAct} of ${usd(v)} done (demo)`);notify(`${mAct} ${usd(v)} (demo)`);
};
$("moneyAmt").onkeydown=e=>{if(e.key==="Enter")$("moneyOk").click()};
/* ---------- header, menus, misc ---------- */
const menus=["acctMenu","bellMenu","langMenu","mmMenu"];
function toggleMenu(id){const open=$(id).classList.contains("open");menus.forEach(m=>$(m).classList.remove("open"));if(!open)$(id).classList.add("open")}
$("acctBtn").onclick=e=>{e.stopPropagation();toggleMenu("acctMenu")};
$("globe").onclick=e=>{e.stopPropagation();toggleMenu("langMenu")};
$("mmBtn").onclick=e=>{e.stopPropagation();toggleMenu("mmMenu")};
$("bell").onclick=e=>{e.stopPropagation();
 $("bellMenu").innerHTML=notes.length?notes.map(n=>`<div class="it">${n.t}<span>${n.at.toLocaleTimeString()}</span></div>`).join(""):'<div class="e">No notifications yet.</div>';
 $("bellDot").hidden=true;toggleMenu("bellMenu")};
document.addEventListener("click",e=>{if(!e.target.closest(".menu"))menus.forEach(m=>$(m).classList.remove("open"))});
$("langMenu").onclick=e=>{const b=e.target.closest("button");if(b)toast("Language: "+b.dataset.l+" (demo)")};
$("mmMenu").onclick=e=>{const b=e.target.closest("button");if(!b)return;if(b.id==="mmConv"){mode="Convert";$("tabs").querySelector('[data-m="Convert"]').click();$("secTrade").scrollIntoView({behavior:"smooth"})}else openMoney(b.dataset.a)};
$("mReset").onclick=()=>{bal={...DEFAULTS};save();render();toast("Demo balances reset")};
$("mEdit").onclick=openEdit;
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
function goTo(g){
 if(g==="Deposit"||g==="Withdraw")openMoney(g);
 else if(g==="assets"){showAll=true;render();$("secAssets").scrollIntoView({behavior:"smooth"})}
 else if(g==="settings")openEdit();
 else if(g==="chart"||g==="trade")$("secTrade").scrollIntoView({behavior:"smooth"});
 else window.scrollTo({top:0,behavior:"smooth"});
}
document.addEventListener("keydown",e=>{if(e.key==="Escape"){close();closeMoney();document.body.classList.remove("nav-open")}});
/* ---------- boot ---------- */
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
 if(a.dataset.go)goTo(a.dataset.go);else toast(a.dataset.t+" is not available in the demo");
};
$("menuBtn").onclick=e=>{e.stopPropagation();document.body.classList.toggle("nav-open")};
$("scrim").onclick=()=>document.body.classList.remove("nav-open");
window.addEventListener("resize",()=>{if(innerWidth>820)document.body.classList.remove("nav-open")});
$("tType").innerHTML=CONFIG.tradeTypes.map(t=>`<option>${t}</option>`).join("");
$("lev").max=CONFIG.maxLeverage;
const ml=CONFIG.maxLeverage;$("tlab").innerHTML=[0,.25,.5,.75,1].map(f=>`<span>${Math.round(ml*f)}x</span>`).join("");
$("dur").innerHTML=CONFIG.durations.map(d=>`<option value="${d.sec}">${d.label}</option>`).join("");$("dur").value=CONFIG.defaultDuration;
$("cSym").innerHTML=ASSETS.filter(a=>a.id!=="USD").map(a=>`<option value="${a.id}">${a.id}</option>`).join("");
$("cSym").value=CONFIG.defaultSymbol;fillTrade();gen();render();drawPos();draw();updTitle();setInterval(tick,CONFIG.tickMs);
