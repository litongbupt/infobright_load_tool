# VERIFY INPUT PARAMETERS3if [ $# != 7 ]; then
if [ $# != 7 ]; then
	echo "            <host> "
	echo "            <username> "
	echo "            <password> "
    echo "            <target Infobright database> "
    echo "            <table name> "
    echo "            <source file>"
	echo "            <sql of create table>"
    exit 2 
fi

# assign parameters
  HOST=$1
  USER=$2
  PASSWD=$3
  TGTDB=$4
  table=$5
  OFILE=$6
  SQL=$7
  
  

# MYSQL CONNECTION STRINGS
TGTMYSQL="mysql -h" $HOST "-u" $USER "-p" $PASSWD "-P 5029"

#
echo ICE Breaker for MySQL - V 0.1 ALPHA
echo

# VERIFY CONNECTIVITY TO INFOBRIGHT
echo "show tables" | $TGTMYSQL -D $TGTDB >> /dev/null
if [ $? != 0 ]; then
   echo Unable to connect to target database
   exit 3
fi


echo Processing the following tables from the source file
echo 
echo Starting - date 
echo DROP TABLE IF EXISTS " $table "
echo DROP TABLE IF EXISTS " $table "| $TGTMYSQL -D $TGTDB

echo $SQL
echo $SQL| $TGTMYSQL -D $TGTDB


# start loader
echo "load data infile '"${OFILE}"'  IGNORE into table" $table " fields terminated by '\t' ; "
echo "SHOW VARIABLES like 'character_set_database'" | $TGTMYSQL -D $TGTDB 
echo $TGTMYSQL -D $TGTDB 
#echo "set character_set_database=utf8;set character_set_client=utf8; set character_set_connection=utf8; set names utf8; load data infile '"${OFILE}"'  IGNORE into table" $table " fields terminated by '\t' ; " | $TGTMYSQL -D $TGTDB 
echo "load data LOCAL infile '"${OFILE}"' into table" $table " fields terminated by '\t' ; " | $TGTMYSQL -D $TGTDB 
#rm $OFILE

# get record count from source 
TGTCNT=$TGTMYSQL -D $TGTDB --skip-column_names << EOF5
 select count(*) 
   from $table ;
EOF5
echo $table $TGTCNT " rows written to target" - date
echo ICE Breaker Complete
