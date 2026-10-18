(function(){ function t(){ var v=+(localStorage.getItem('ch_visits')||0); if(!sessionStorage.getItem('ch_v')){sessionStorage.setItem('ch_v','1');localStorage.setItem('ch_visits',v+1);} }
t(); setInterval(function(){ document.dispatchEvent(new Event('ch:tick')); }, 30000); })();
