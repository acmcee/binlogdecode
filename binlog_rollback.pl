#!usrlibperl -w

use strict;
use warnings;

use ClassStruct;
use GetoptLong qw(config no_ignore_case);					# GetOption
# register handler system signals
use sigtrap 'handler', &sig_int, 'normal-signals';

# catch signal
sub sig_int(){
	my ($signals) = @_;
	print STDERR # Caught SIG$signals.n;
	exit 1;
}

my %opt;
my $srcfile;
my $host = '127.0.0.1';
my $port = 3306;
my ($user,$pwd);
my ($MYSQL, $MYSQLBINLOG, $ROLLBACK_DML);
my $outfile = 'devnull';
my (%do_dbs,%do_tbs);

# tbname=tbcol, tbcol @n=colname,type
my %tbcol_pos;

my $SPLITER_COL = ',';
my $SQLTYPE_IST = 'INSERT';
my $SQLTYPE_UPD = 'UPDATE';
my $SQLTYPE_DEL = 'DELETE';
my $SQLAREA_WHERE = 'WHERE';
my $SQLAREA_SET = 'SET';

my $PRE_FUNCT = '========================== ';

# =========================================================
# ����rowģʽ��binlog������DML(insertupdatedelete)��rollback���
# ͨ��mysqlbinlog -v ����binlog���ɿɶ���sql�ļ�
# ��ȡ��Ҫ�������Чsql
# 	### ��ͷ����.��������start-positionλ��ĳ��event group�м䣬��ᵼ���޷�ʶ��event����
#
# ��INSERTUPDATEDELETE ��sql��ת,����1������sqlֻ��ռ1��
# 	INSERT INSERT INTO = DELETE FROM, SET = WHERE
# 	UPDATE WHERE = SET, SET = WHERE
# 	DELETE DELETE FROM = INSERT INTO, WHERE = SET
# �������滻λ��@{1,2,3}
# 	ͨ��desc table�����˳�򼰶�Ӧ������
# 	����������value���ر���
# ����
# 
# ע��
# 	��ṹ�����ڵı�ṹ������ͬ[����]
# 	����rowģʽ���ݵȵģ����һָ���һ���ԣ�����ֻ��ȡsql������ȡBEGINCOMMIT
# 	ֻ�ܶ�INSERTUPDATEDELETE���д���
# ========================================================
sub main{

	# get input option
	&get_options();

	# 
	&init_tbcol();

	#
	&do_binlog_rollback();
}

&main();


# ----------------------------------------------------------------------------------------
# Func  get options and set option flag 
# ----------------------------------------------------------------------------------------
sub get_options{
	#Get options info
	GetOptions(%opt,
		'help',					# OUT  print help info   
		'fsrcfile=s',			# IN   binlog file
		'ooutfile=s',			# out  output sql file
		'hhost=s',				# IN    host
		'uuser=s',             # IN    user
		'ppassword=s',         # IN    password
		'Pport=i',				# IN    port
		'start-datetime=s',		# IN    start datetime
		'stop-datetime=s',		# IN    stop datetime
		'start-position=i',		# IN    start position
		'stop-position=i',		# IN    stop position
		'ddatabase=s',			# IN    database, split comma
		'Ttable=s',			# IN    table, split comma
		'iignore',				# IN    ignore binlog check ddl and so on
		'debug',				# IN    print debug information
	  ) or print_usage();

	if (!scalar(%opt)) {
		&print_usage();
	}

	# Handle for options
	if ($opt{'f'}){
		$srcfile = $opt{'f'};
	}else{
		&merror(please input binlog file);
	}

	$opt{'h'} and $host = $opt{'h'};
	$opt{'u'} and $user = $opt{'u'};
	$opt{'p'} and $pwd = $opt{'p'};
	$opt{'P'} and $port = $opt{'P'};
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
		# ��� outfile
		`echo ''  $outfile`;
	}

	# 
	$MYSQL = qq{mysql -h$host -u$user -p'$pwd' -P$port};
	&mdebug(get_optionsMYSQLnt$MYSQL);

	# ��ȡbinlog,����Ҫ��ʾ�ж�����Ϣ����-v��������-vv
	$MYSQLBINLOG = qq{mysqlbinlog -v};
	$MYSQLBINLOG .=  --start-position=.$opt{'start-position'} if $opt{'start-position'};
	$MYSQLBINLOG .=  --stop-position=.$opt{'stop-position'} if $opt{'stop-postion'};
	$MYSQLBINLOG .=  --start-datetime='.$opt{'start-datetime'}.' if $opt{'start-datetime'};
	$MYSQLBINLOG .=  --stop-datetime='$opt{'stop-datetime'}' if $opt{'stop-datetime'};
	$MYSQLBINLOG .=  $srcfile;
	&mdebug(get_optionsMYSQLBINLOGnt$MYSQLBINLOG);

	# ���binlog���Ƿ��� ddl sql CREATEALTERDROPRENAME
	&check_binlog() unless ($opt{'i'});

	# ��ʹ��mysqlbinlog���ˣ�USE dbname;��ʽ���ܻ�©��ĳЩsql�����Բ���mysqlbinlog����
	# ָ�����ݿ�
	if ($opt{'d'}){
		my @dbs = split(,,$opt{'d'});
		foreach my $db (@dbs){
			$do_dbs{$db}=1;
		}
	}

	# ָ����
	if ($opt{'T'}){
		my @tbs = split(,,$opt{'T'});
		foreach my $tb (@tbs){
			$do_tbs{$tb}=1;
		}
	}

	# ��ȡ��ЧDML SQL
	$ROLLBACK_DML = $MYSQLBINLOG.  grep '^### ';
	# ȥ��ע�� '### ' - ''
	# ɾ����β�ո�
	$ROLLBACK_DML .=   sed 's###sg;ss$g';
	&mdebug(rollback dmlnt$ROLLBACK_DML);
	
	# ��������Ƿ�Ϊ��
	my $cmd = $ROLLBACK_DML  wc -l;
	&mdebug(check contain dml sqlnt$cmd);
	my $size = `$cmd`;
	chomp($size);
	unless ($size 0){
		&merror(binlog DML is empty$ROLLBACK_DML);
	};

}	


# ----------------------------------------------------------------------------------------
# Func   check binlog contain DDL
# ----------------------------------------------------------------------------------------
sub check_binlog{
	&mdebug($PRE_FUNCT check_binlog);
	my $cmd = $MYSQLBINLOG ;
	$cmd .=   grep -E -i '^(CREATEALTERDROPRENAME)' ;
	&mdebug(check binlog has DDL cmdnt$cmd);
	my $ddlcnt = `$cmd`;
	chomp($ddlcnt);

	my $ddlnum = `$cmd  wc -l`;
	chomp($ddlnum);
	my $res = 0;
	if ($ddlnum0){
		# ��ddl sqlǰ�����ǰ׺DDL
		$ddlcnt = `echo '$ddlcnt'  sed 's^DDLg'`;
		&merror(binlog contain $ddlnum DDL$MYSQLBINLOG. ddl sqln$ddlcnt);
	}

	return $res;
}


# ----------------------------------------------------------------------------------------
# Func  init all table column order
#		if input --database --table params, only get set table column order
# ----------------------------------------------------------------------------------------
sub init_tbcol{
	&mdebug($PRE_FUNCT init_tbcol);
	# ��ȡDML���
	my $cmd .= $ROLLBACK_DML  grep -E '^(INSERTUPDATEDELETE)';
	# ��ȡ��������ȥ��
	#$cmd .=   awk '{if ($1 ~ ^UPDATE) {print $2}else {print $3}}'  uniq ;
	$cmd .=   awk '{if ($1 ~ ^UPDATE) {print $2}else {print $3}}'  sort  uniq ;
	&mdebug(get table name cmdnt$cmd);
	open ALLTABLE, $cmd   or die can't open file$cmdn;

	while (my $tbname = ALLTABLE){
		chomp($tbname);
		#if (exists $tbcol_pos{$tbname}){
		#	next;
		#}
		&init_one_tbcol($tbname) unless (&ignore_tb($tbname));
		
	}
	close ALLTABLE or die can't close file$cmdn;

	# init tb col
	foreach my $tb (keys %tbcol_pos){
		&mdebug(tbname-$tb);
		my %colpos = %{$tbcol_pos{$tb}};
		foreach my $pos (keys %colpos){
			my $col = $colpos{$pos};
			my ($cname,$ctype) = split($SPLITER_COL, $col);
			&mdebug(tpos-$pos,cname-$cname,ctype-$ctype);
		}
	}
};


# ----------------------------------------------------------------------------------------
# Func  init one table column order
# ----------------------------------------------------------------------------------------
sub init_one_tbcol{
	my $tbname = shift;
	&mdebug($PRE_FUNCT init_one_tbcol);
	# ��ȡ��ṹ����˳��
	my $cmd = $MYSQL. --skip-column-names --silent -e 'desc $tbname';
	# ��ȡ��������ƴ��
	$cmd .=   awk -F't' '{print NR$SPLITER_COL`$1`$SPLITER_COL$2}';
	&mdebug(get table column infor cmdnt$cmd);
	open TBCOL,$cmd   or die can't open desc $tbname;;

	my %colpos;
	while (my $line = TBCOL){
		chomp($line);
		my ($pos,$col,$coltype) = split($SPLITER_COL,$line);
		&mdebug(linesss=$linenttpos=$posnttcol=$colntttype=$coltype);
		$colpos{$pos} = $col.$SPLITER_COL.$coltype;
	}
	close TBCOL or die can't colse desc $tbname;

	$tbcol_pos{$tbname} = %colpos;
}


# ----------------------------------------------------------------------------------------
# Func   rollback sql	INSERTUPDATEDELETE
# ----------------------------------------------------------------------------------------
sub do_binlog_rollback{
	my $binlogfile = $ROLLBACK_DML ;
	&mdebug($PRE_FUNCT do_binlog_rollback);

	# INSERTUPDATEDELETE
	my $sqltype;
	# WHERESET
	my $sqlarea;
	
	my ($tbname, $sqlstr) = ('', '');
	my ($notignore, $isareabegin) = (0,0);

	# output sql file
	open SQLFILE,  $outfile or die Can't open sql file$outfile;

	# binlog file
	open BINLOG, $binlogfile  or die Can't open file $binlogfile;
	while (my $line = BINLOG){
		chomp($line);
		if ($line =~ ^(INSERTUPDATEDELETE)){
			# export sql
			if ($sqlstr ne ''){
				$sqlstr .= ;n;
				print SQLFILE $sqlstr;
				&mdebug(export sqlnt.$sqlstr);
				$sqlstr = '';
			}

			if ($line =~ ^INSERT){
				$sqltype = $SQLTYPE_IST;
				$tbname = `echo '$line'  awk '{print $3}'`;
				chomp($tbname);
				$sqlstr = qq{DELETE FROM $tbname};
			}elsif ($line =~ ^UPDATE){
				$sqltype = $SQLTYPE_UPD;
				$tbname = `echo '$line'  awk '{print $2}'`;
				chomp($tbname);
				$sqlstr = qq{UPDATE $tbname};
			}elsif ($line =~ ^DELETE){
				$sqltype = $SQLTYPE_DEL;	
				$tbname = `echo '$line'  awk '{print $3}'`;
				chomp($tbname);
				$sqlstr = qq{INSERT INTO $tbname};
			}

			# check ignore table
			if(&ignore_tb($tbname)){
				$notignore = 0;
				&mdebug(BINLOG#IGNORE#line.$line);
				$sqlstr = '';
			}else{
				$notignore = 1;
				&mdebug(BINLOG#DO#line.$line);
			}
		}else {
			if($notignore){
				&merror(can't get tbname) unless (defined($tbname));
				if ($line =~ ^WHERE){
					$sqlarea = $SQLAREA_WHERE;
					$sqlstr .= qq{ SET};
					$isareabegin = 1;
				}elsif ($line =~ ^SET){
					$sqlarea = $SQLAREA_SET;
					$sqlstr .= qq{ WHERE};
					$isareabegin = 1;
				}elsif ($line =~ ^@){
					$sqlstr .= &deal_col_value($tbname, $sqltype, $sqlarea, $isareabegin, $line);
					$isareabegin = 0;
				}else{
					&mdebug(unknown sql.$line);
				}
			}
		}
	}
	# export last sql
	if ($sqlstr ne ''){
		$sqlstr .= ;n;
		print SQLFILE $sqlstr;
		&mdebug(export sqlnt.$sqlstr);
	}
	
	close BINLOG or die Can't close binlog file $binlogfile;

	close SQLFILE or die Can't close out sql file $outfile;

	# ����
	# 1!G ֻ�е�һ�в�ִ��G, ��hold space�е�����append�ص�pattern space
	# h ��pattern space ������hold space
	# $!d �����һ�ж�ɾ��
	my $invert = sed -i '1!G;h;$!d' $outfile;
	my $res = `$invert`;
	&mdebug(inverter order sqlfile $invert);
}

# ----------------------------------------------------------------------------------------
# Func   transfer column pos to name
#	deal column value
#
#  &deal_col_value($tbname, $sqltype, $sqlarea, $isareabegin, $line);
# ----------------------------------------------------------------------------------------
sub deal_col_value($$$$$){
	my ($tbname, $sqltype, $sqlarea, $isareabegin, $line) = @_;
	&mdebug($PRE_FUNCT deal_col_value);
	&mdebug(inputtbname-$tbname,type-$sqltype,area-$sqlarea,areabegin-$isareabegin,line-$line);
	my @vals = split(=, $line);
	my $pos = substr($vals[0],1);
	my $valstartpos = length($pos)+2;
	my $val = substr($line,$valstartpos);
	my %tbcol = %{$tbcol_pos{$tbname}};
	my ($cname,$ctype) = split($SPLITER_COL,$tbcol{$pos});
	&merror(can't get $tbname column $cname type) unless (defined($cname)  defined($ctype));
	&mdebug(column inforcname-$cname,type-$ctype);

	# join str
	my $joinstr;
	if ($isareabegin){
		$joinstr = ' ';
	}else{
		# WHERE ���滻Ϊ SET, ʹ�� ,  ����
		if ($sqlarea eq $SQLAREA_WHERE){
			$joinstr = ', ';
		# SET ���滻Ϊ WHERE ʹ�� AND ����
		}elsif ($sqlarea eq $SQLAREA_SET){
			$joinstr = ' AND ';
		}else{
			&merror(!!!!!!The scripts error);
		}
	}
	
	# 
	my $newline = $joinstr;

	# NULL value
	if (($val eq 'NULL') && ($sqlarea eq $SQLAREA_SET)){
		$newline .= qq{ $cname IS NULL};
	}else{
		# timestamp record seconds
		if ($ctype eq 'timestamp'){
			$newline .= qq{$cname=from_unixtime($val)};
		# datetime @n=yyyy-mm-dd hhiiss
		}elsif ($ctype eq 'datetime'){
			$newline .= qq{$cname='$val'};
		}else{
			$newline .= qq{$cname=$val};
		}
	}
	&mdebug(told$linentnew$newline);
	
	return $newline;
}

# ----------------------------------------------------------------------------------------
# Func   check is ignore table
# params IN table full name #  format`dbname`.`tbname`
# RETURN��
#		0 not ignore
#		1 ignore
# ----------------------------------------------------------------------------------------
sub ignore_tb($){
	my $fullname = shift;
	# ɾ��`
	$fullname =~ s`g;
	my ($dbname,$tbname) = split(.,$fullname);
	my $res = 0;
	
	# ָ�������ݿ�
	if ($opt{'d'}){
		# ��ָ������ͬ
		if ($do_dbs{$dbname}){
			# ָ����
			if ($opt{'T'}){
				# ��ָ����ͬ
				unless ($do_tbs{$tbname}){
					$res = 1;
				}
			}
		# ��ָ���ⲻͬ
		}else{
			$res = 1;
		}
	}
	#&mdebug(Table check ignore$fullname-$res);
	return $res;
}


# ----------------------------------------------------------------------------------------
# Func   print debug msg
# ----------------------------------------------------------------------------------------
sub mdebug{
	my (@msg) = @_;
	print DEBUG@msgn if ($opt{'debug'});
}


# ----------------------------------------------------------------------------------------
# Func   print error msg and exit
# ----------------------------------------------------------------------------------------
sub merror{
	my (@msg) = @_;
	print Error@msgn;
	&print_usage();
	exit(1);
}

# ----------------------------------------------------------------------------------------
# Func   print usage
# ----------------------------------------------------------------------------------------
sub print_usage{
	print EOF;
==========================================================================================
Command line options 
	--help				# OUT  print help info   
	-f, --srcfile			# IN   binlog file. [required]
	-o, --outfile			# OUT  output sql file. [required]
	-h, --host			# IN   host. default '127.0.0.1'
	-u, --user			# IN   user. [required]
	-p, --password			# IN   password. [required] 
	-P, --port			# IN   port. default '3306'
	--start-datetime		# IN   start datetime
	--stop-datetime			# IN   stop datetime
	--start-position		# IN   start position
	--stop-position			# IN   stop position
	-d, --database			# IN   database, split comma
	-T, --table			# IN   table, split comma. [required] set -d
	-i, --ignore			# IN   ignore binlog check contain DDL(CREATEALTERDROPRENAME)
	--debug				# IN    print debug information

Sample 
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' 
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' -i
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' --debug
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -h '192.168.1.2' -u 'user' -p 'pwd' -P 3307
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' --start-position=107
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' --start-position=107 --stop-position=10000
   shell perl binlog-rollback.pl -f 'mysql-bin.000001' -o 'tmpt.sql' -u 'user' -p 'pwd' -d 'db1,db2'
   shell perl binlog-rollback.pl -f 'mysql-bin.0000' -o 'tmpt.sql' -u 'user' -p 'pwd' -d 'db1,db2' -T 'tb1,tb2'
==========================================================================================
EOF
	exit;   
}


1;