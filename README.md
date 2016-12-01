# binlogdecode
����rowģʽ��binlog������binlog������������ݺͻع�����


[1.binlog_rollback](#1) 
[2.binlog_explain](#2) 

<h2 id="1">1.binlog_rollback.pl</h2>

����rowģʽ��binlog������DML(insert/update/delete)��rollback���
<br/>
ͨ��mysqlbinlog -v ����binlog���ɿɶ���sql�ļ�
<br/>
��ȡ��Ҫ�������Чsql
<br/>
*  "### "��ͷ����.��������start-positionλ��ĳ��event group�м䣬��ᵼ��"�޷�ʶ��event"����
<br/>
*��INSERT/UPDATE/DELETE ��sql��ת,����1������sqlֻ��ռ1��
<br/>
*  INSERT: INSERT INTO => DELETE FROM, SET => WHERE
  <br/>
*  UPDATE: WHERE => SET, SET => WHERE
  <br/>
*  DELETE: DELETE FROM => INSERT INTO, WHERE => SET
  <br/>
*  �������滻λ��@{1,2,3}
  <br/>
*  ͨ��desc table�����˳�򼰶�Ӧ������
  <br/>
*  ����������value���ر���
  <br/>
*  ����
  <br/>

## ע��:
*  ��ṹ�����ڵı�ṹ������ͬ[����]
  <br/>
*  ����rowģʽ���ݵȵģ����һָ���һ���ԣ�����ֻ��ȡsql������ȡBEGIN/COMMIT
  <br/>
*  ֻ�ܶ�INSERT/UPDATE/DELETE���д���
  <br/>
  
<pre>
  ʹ�÷���
  
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

 ����rowģʽ��binlog������DML(insert/update/delete)���������
 <br/>
 ͨ��mysqlbinlog -v ����binlog���ɿɶ���sql�ļ�
 <br/>
 ��ȡ��Ҫ�������Чsql
 <br/>
*    "### "��ͷ����.��������start-positionλ��ĳ��event group�м䣬��ᵼ��"�޷�ʶ��event"����
 <br/>
 ��INSERT/UPDATE/DELETE ��sql��ת,����1������sqlֻ��ռ1��
 <br/>
*     INSERT: INSERT INTO => INSERT INTO, SET => SET
     <br/>
*     UPDATE: WHERE => WHERE, SET => SET,��Ҫ�� WHERE ����׷�ӵ����
     <br/>
*    DELETE: DELETE FROM => DELETE FROM, WHERE => WHERE
     <br/>
* �������滻λ��@{1,2,3}/
 <br/>
*     ͨ��desc table�����˳�򼰶�Ӧ������
     <br/>
*     ����������value���ر���
     <br/>
 <br/><br/>
 
## ע��:
*     ��ṹ�����ڵı�ṹ������ͬ[����]
     <br/>
*     ����rowģʽ���ݵȵģ����һָ���һ���ԣ�����ֻ��ȡsql������ȡBEGIN/COMMIT
     <br/>
*     ֻ�ܶ�INSERT/UPDATE/DELETE���д���
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