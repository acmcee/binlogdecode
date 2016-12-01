# binlogdecode
基于row模式的binlog，生成binlog的正向解析内容和回滚内容


[1.binlog_rollback](#1) 
[2.binlog_explain](#2) 

<h2 id="1">1.binlog_rollback.pl</h2>

基于row模式的binlog，生成DML(insert/update/delete)的rollback语句
<br/>
通过mysqlbinlog -v 解析binlog生成可读的sql文件
<br/>
提取需要处理的有效sql
<br/>
*  "### "开头的行.如果输入的start-position位于某个event group中间，则会导致"无法识别event"错误
<br/>
*将INSERT/UPDATE/DELETE 的sql反转,并且1个完整sql只能占1行
<br/>
*  INSERT: INSERT INTO => DELETE FROM, SET => WHERE
  <br/>
*  UPDATE: WHERE => SET, SET => WHERE
  <br/>
*  DELETE: DELETE FROM => INSERT INTO, WHERE => SET
  <br/>
*  用列名替换位置@{1,2,3}
  <br/>
*  通过desc table获得列顺序及对应的列名
  <br/>
*  特殊列类型value做特别处理
  <br/>
*  逆序
  <br/>

## 注意:
*  表结构与现在的表结构必须相同[谨记]
  <br/>
*  由于row模式是幂等的，并且恢复是一次性，所以只提取sql，不提取BEGIN/COMMIT
  <br/>
*  只能对INSERT/UPDATE/DELETE进行处理
  <br/>
  
<pre>
  使用方法
  
  Command line options :
    --help                   # OUT : print help info   
    -f, --srcfile            # IN  : binlog file. [required]
    -o, --outfile            # OUT : output sql file. [required]
    -h, --host               # IN  : host. default '127.0.0.1'
    -u, --user               # IN  : user. [required]
    -p, --password           # IN  : password. [required] 
    -P, --port               # IN  : port. default '3306'
    --start-datetime         # IN  : start datetime
    --stop-datetime          # IN  : stop datetime
    --start-position         # IN  : start position
    --stop-position          # IN  : stop position
    -d, --database           # IN  : database, split comma
    -T, --table              # IN  : table, split comma. [required] set -d
    -i, --ignore             # IN  : ignore binlog check contain DDL(CREATE|ALTER|DROP|RENAME)
    --debug                  # IN  : print debug information

Sample :
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' 
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' -i
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --debug
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -h '192.168.1.2' -u 'user' -p 'pwd' -P 3307
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --start-position=107
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --start-position=107 --stop-position=10000
   shell> perl binlog-rollback.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' -d 'db1,db2'
   shell> perl binlog-rollback.pl -f 'mysql-bin.0000*' -o '/tmp/t.sql' -u 'user' -p 'pwd' -d 'db1,db2' -T 'tb1,tb2'
   
</pre>

<h2 id="2">2.binlog_explain.pl</h2>

 基于row模式的binlog，生成DML(insert/update/delete)的正向语句
 <br/>
 通过mysqlbinlog -v 解析binlog生成可读的sql文件
 <br/>
 提取需要处理的有效sql
 <br/>
*    "### "开头的行.如果输入的start-position位于某个event group中间，则会导致"无法识别event"错误
 <br/>
 将INSERT/UPDATE/DELETE 的sql反转,并且1个完整sql只能占1行
 <br/>
*     INSERT: INSERT INTO => INSERT INTO, SET => SET
     <br/>
*     UPDATE: WHERE => WHERE, SET => SET,需要将 WHERE 部分追加到最后
     <br/>
*    DELETE: DELETE FROM => DELETE FROM, WHERE => WHERE
     <br/>
* 用列名替换位置@{1,2,3}/
 <br/>
*     通过desc table获得列顺序及对应的列名
     <br/>
*     特殊列类型value做特别处理
     <br/>
 <br/><br/>
 
## 注意:
*     表结构与现在的表结构必须相同[谨记]
     <br/>
*     由于row模式是幂等的，并且恢复是一次性，所以只提取sql，不提取BEGIN/COMMIT
     <br/>
*     只能对INSERT/UPDATE/DELETE进行处理
     <br/>
     
     
<pre>
     
     Command line options :
    --help                   # OUT : print help info   
    -f, --srcfile            # IN  : binlog file. [required]
    -o, --outfile            # OUT : output sql file. [required]
    -h, --host               # IN  : host. default '127.0.0.1'
    -u, --user               # IN  : user. [required]
    -p, --password           # IN  : password. [required] 
    -P, --port               # IN  : port. default '3306'
    --start-datetime         # IN  : start datetime
    --stop-datetime          # IN  : stop datetime
    --start-position         # IN  : start position
    --stop-position          # IN  : stop position
    -d, --database           # IN  : database, split comma
    -T, --table              # IN  : table, split comma. [required] set -d
    -i, --ignore             # IN  : ignore binlog check contain DDL(CREATE|ALTER|DROP|RENAME)
    --debug                  # IN  : print debug information

Sample :
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' 
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' -i
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --debug
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -h '192.168.1.2' -u 'user' -p 'pwd' -P 3307
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --start-position=107
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' --start-position=107 --stop-position=10000
   shell> perl binlog-explain.pl -f 'mysql-bin.000001' -o '/tmp/t.sql' -u 'user' -p 'pwd' -d 'db1,db2'
   shell> perl binlog-explain.pl -f 'mysql-bin.0000*' -o '/tmp/t.sql' -u 'user' -p 'pwd' -d 'db1,db2' -T 'tb1,tb2'
   
   </pre>