#!/bin/bash


function init() {
    rm -rf db/log.db
    local transaction="DROP TABLE IF EXISTS  log;
                        CREATE TABLE log
                        (   
                            Id INTEGER PRIMARY KEY AUTOINCREMENT,
                            Time TEXT,
                            SystemElem TEXT,
                            Info TEXT,
                            TargetId TEXT
                        );"
    sqlite3 db/log.db "$transaction"
}

function insert() {
    local Time=$1
    local SystemElem=$2
    local Info=$3
    local TargetId=$4
    local transaction="INSERT INTO log (Time,SystemElem,Info,TargetId) 
                 VALUES ('"$Time"','"$SystemElem"','"$Info"','"$TargetId"');"
    sqlite3 db/log.db "$transaction" 
}


Time1="2022-09-05 11:02:23"
Info1="RLS3 цель движется в направлении СПРО"
TargetId1="090b79"
la="zrdn"

init


insert "2022-09-06 11:02:23"  "$zrdn"  "$Info1"  "$TargetId1"








