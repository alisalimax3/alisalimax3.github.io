#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js");
const DBF=path.join(U.A,"app.db"),JF=path.join(U.A,"app.json");
const hasSqlite=()=>{try{execFileSync("sqlite3",["-version"],{stdio:"pipe"});return true;}catch(e){return false;}}();
const TABLES=["events","metrics","findings","fixes","tests","audit_log"];
const SCHEMA=`CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY,kind TEXT,payload TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS metrics(id INTEGER PRIMARY KEY,name TEXT,value REAL,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS findings(id INTEGER PRIMARY KEY,sev TEXT,rule TEXT,file TEXT,msg TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS fixes(id INTEGER PRIMARY KEY,rule TEXT,file TEXT,ok INTEGER,evidence TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS tests(id INTEGER PRIMARY KEY,name TEXT,ok INTEGER,status INTEGER,ms INTEGER,note TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS audit_log(id INTEGER PRIMARY KEY,phase TEXT,ok INTEGER,detail TEXT,at TEXT DEFAULT (datetime('now')));`;
const esc=v=>v==null?"NULL":(typeof v==="number"?v:"'"+String(v).replace(/'/g,"''")+"'");
const run=s=>execFileSync("sqlite3",[DBF,s],{stdio:["pipe","pipe","pipe"]}).toString();
const query=s=>{try{return JSON.parse(execFileSync("sqlite3",["-json",DBF,s],{stdio:"pipe"}).toString()||"[]");}catch(e){return[];}};
function init(){if(hasSqlite){run("PRAGMA journal_mode=WAL;");run(SCHEMA);return{engine:"sqlite",path:DBF};}
  if(!fs.existsSync(JF))U.jw(JF,Object.fromEntries(TABLES.map(t=>[t,[]])));
  return{engine:"json",path:JF};}
function insert(t,obj){if(!fs.existsSync(DBF)&&!fs.existsSync(JF))init();
  if(hasSqlite){const k=Object.keys(obj);run("INSERT INTO "+t+"("+k.join(",")+") VALUES("+k.map(x=>esc(obj[x])).join(",")+");");return true;}
  const j=U.jr(JF,{});j[t]=j[t]||[];j[t].push(Object.assign({at:new Date().toISOString()},obj));U.jw(JF,j);return true;}
function count(t){if(hasSqlite&&fs.existsSync(DBF)){const r=query("SELECT COUNT(*) c FROM "+t+";");return (r[0]||{}).c||0;}
  return (U.jr(JF,{})[t]||[]).length;}
function health(){const t={};let ok=true;for(const x of TABLES){try{t[x]=count(x);}catch(e){t[x]=0;ok=false;}}
  return{ok,engine:hasSqlite?"sqlite":"json",path:hasSqlite?DBF:JF,tables:t,at:new Date().toISOString()};}
module.exports={init,insert,count,health,query,hasSqlite};
if(require.main===module){const c=process.argv[2]||"init";const r=init();
  if(c==="init")console.log("  ✔ قاعدة البيانات: "+r.engine+" → "+U.rel(r.path));
  else if(c==="health")console.log("  "+JSON.stringify(health()));
  else if(c==="seed"){insert("metrics",{name:"audit_score",value:0});console.log("  ✔ بُذرت القاعدة");}}
