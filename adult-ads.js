/* مولّد آليًا بواسطة ADULT-WIRE — إعلانات البالغين */
(function(){
var A={exoclick:"736982376",juicyads:"1000",plugrush:"",
adsterra:"",smartlink:""};
function s(src){var e=document.createElement("script");e.async=true;e.src=src;e.setAttribute("data-cinehub","adult");(document.body||document.documentElement).appendChild(e);}
function box(id){var d=document.createElement("div");d.id=id;d.style.cssText="margin:14px auto;text-align:center;max-width:100%";(document.body||document.documentElement).appendChild(d);return d;}
try{
 if(A.exoclick){box("exo-"+A.exoclick);s("https://syndication.exoclick.com/splash.php?idzone="+A.exoclick);}
 if(A.juicyads){s("https://js.juicyads.com/jp.php?u="+A.juicyads);}
 if(A.plugrush){s("https://js.plugrush.com/"+A.plugrush);}
 if(A.adsterra){box("adt-"+A.adsterra);var f=document.createElement("iframe");f.style.cssText="width:100%;max-width:728px;height:90px;border:0";
   f.setAttribute("data-src","adsterra");box("adt-wrap").appendChild(f);}
 if(A.smartlink){var a=document.createElement("a");a.href=A.smartlink;a.textContent="عرض خاص 🔥";a.style.cssText="display:inline-block;margin:10px;padding:8px 16px;background:#e11d48;color:#fff;border-radius:9px;text-decoration:none";document.body.appendChild(a);}
}catch(e){console.warn("adult-ads",e);}
window.CINEHUB_ADULT=A;
})();
