#!/bin/bash
###########################################################
###                   Infobright 2009                   ###
###           Developed by: Client Services             ###
###           Authors: Carl Gelbart, David Lutz         ###
###                     Version 0.1                     ###
###                                                     ###
#
#
# 
# The MIT License
# 
# Copyright (c) 2009 Infobright Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
#
###########################################################
# Usage: ib.sh
#        <table name or all>
#        <target Infobright database> 
#        <source MySQL database>
#        <source MySQL user>
#        <source MySQL password>
#        <source MySQL server> 
#        <source MySQL port> 
#
# Ice Breaker for MySQL will copy all the tables in MYSQL 
# schema on the same serer or remote server. 
#
# The script must be run on the Infobright server and logged
# in as the mysql account.  
#
# Script expects fo find that source and target tables exist
# and permissions are in place to allow for access.
#
###########################################################
#
# VERIFY INPUT PARAMETERS
if [ $# != 7 ]; then
    echo; echo "syntax: ib.sh "
    echo "            <all or table name> "
    echo "            <target Infobright database> "
    echo "            <source MySQL database>"
    echo "            <source MySQL user>"
    echo "            <source MySQL password>"
    echo "            <source MySQL server>" 
    echo "            <source MySQL port> (usually 3306)" 
    echo 
    exit 2 
fi

# assign parameters
  ALLORTBL=$1
  TGTDB=$2
  SRCDB=$3
  SRCUSER=$4
  SRCPW=$5
  SRCSRVR=$6
  SRCPORT=$7

  TBLFILE=/tmp/tbl.txt
  OFILEDIR=/tmp

# MYSQL CONNECTION STRINGS
SRCMYSQL="mysql --user="${SRCUSER}" --password="${SRCPW}" --skip-column-names --socket=/tmp/mysql-ib.sock --port="${SRCPORT}" --host="${SRCSRVR} 
TGTMYSQL="mysql --user=root --socket=/tmp/mysql-ib.sock"

#
echo ICE Breaker for MySQL - V 0.1 ALPHA
echo

# VERIFY CONNECTIVITY TO INFOBRIGHT
echo "show tables" | $TGTMYSQL -D $TGTDB >> /dev/null
if [ $? != 0 ]; then
   echo Unable to connect to target database
   exit 3
fi

# GET LIST OF TABLES AND VERIFY CONNECTIVITY TO SOURCE
echo "show tables" | $SRCMYSQL -D $SRCDB > $TBLFILE
if [ $? != 0 ]; then
   echo Unable to connect to source database 
   exit 4
fi 

if [ "$ALLORTBL" != "all" ]; then
   echo $ALLORTBL > $TBLFILE
fi

echo Processing the following tables from the source database
cat $TBLFILE
echo 
echo Starting - `date` 
echo


# LOOP THROUGH TABLE LIST
while read table; do 
${a::3}
if [ "${table::10}" = 'Tables_in_' ]; then
	continue
fi
OFILE=$OFILEDIR/$table.pipe

# TRUNCATE TABLE AND VERIFY TABLE EXISTS
TGTTRUNC=`$TGTMYSQL -D $TGTDB << EOF1
 truncate table $table;  
EOF1`
if [ $? != 0 ]; then
    echo
    continue
fi

# GET COLUMN COUNTS 
SRCCOL=`$SRCMYSQL -D $SRCDB << EOF2
 select max(ordinal_position)  
   from information_schema.columns 
  where table_name = '$table' ;
EOF2`
TGTCOL=`$TGTMYSQL -D $TGTDB --skip-column-names << EOF3
 select max(ordinal_position)  
   from information_schema.columns 
  where table_name = '$table' ;
EOF3`

if [ $TGTCOL != $SRCCOL ]; then
   echo $table ": source and target table columns do not match...skipping"
   echo
   continue
fi

# get record count from source 
SRCCNT=`$SRCMYSQL -D $SRCDB << EOF4
 select count(*) 
   from $table ;
EOF4`
# get the file
echo "select * from " $table " ;" | $SRCMYSQL -D $SRCDB > $OFILE

# start loader
echo "load data infile '"${OFILE}"' into table" $table "; " | $TGTMYSQL -D $TGTDB 
rm $OFILE

# get record count from source 
TGTCNT=`$TGTMYSQL -D $TGTDB --skip-column_names << EOF5
 select count(*) 
   from $table ;
EOF5`
echo $table ":" $SRCCNT "rows read from source. " $TGTCNT " rows written to target" - `date`
echo
done < $TBLFILE 
echo
echo ICE Breaker Complete
rm $TBLFILE 
