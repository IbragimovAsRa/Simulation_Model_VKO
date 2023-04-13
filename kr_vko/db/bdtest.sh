#!/bin/bash


function init() {
    rm -rf log.db
    transaction="DROP TABLE IF EXISTS  log;
                 CREATE TABLE log
                 (   
                    Id INTEGER PRIMARY KEY AUTOINCREMENT,
                    Time TEXT,
                    Info TEXT,
                    TargetId TEXT
                 );"
    sqlite3 log.db "$transaction"
}

function insert() {
    Time=$1
    Info=$2
    TargetId=$3
    transaction="INSERT INTO log (Time,Info,TargetId) 
                 VALUES ('"$Time"','"$Info"','"$TargetId"');"
    sqlite3 log.db "$transaction" 
}


Time1="2022-09-05 11:02:23"
Info1="RLS3 цель движется в направлении СПРО"
TargetId1="090b79"


init
insert "2022-09-05 11:02:23" "$Info1" "$TargetId1"


insert "2022-09-06 11:02:23" "$Info1  afsvafvv  afva"  "$TargetId1"

insert "2022-09-07 11:02:23" "$Info1" "$TargetId1"

insert "2022-09-08 11:02:23" "$Info1" "$TargetId1"

insert "2022-09-09 11:02:23" "$Info1" "$TargetId1"







