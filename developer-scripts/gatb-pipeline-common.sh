#!/bin/bash

echo
echo "Sourcing gatb-pipeline-common.sh ..."
echo

PATH="/udd/cdeltel/bioinfo/bwa-0.7.10/:.:$PATH"
PATH="/udd/cdeltel/bioinfo/seqtk/:.:$PATH"

MAIL_DST_ALL_MESG=charles.deltel@inria.fr
MAIL_DST_ERR_ONLY="cdeltel@laposte.net rchikhi@gmail.com"

MAIL_CMD="ssh igrida-oar-frontend mail "

#LOGBOOK=/udd/cdeltel/bioinfo/anr-gatb/logbook-${PIP}.txt   => Currently read-only file system!
LOGBOOK_ROOT=logbook-${PIP}
LOGBOOK_TXT=/temp_dd/igrida-fs1/cdeltel/bioinfo/${LOGBOOK_ROOT}.txt
LOGBOOK_POS=/temp_dd/igrida-fs1/cdeltel/bioinfo/${LOGBOOK_ROOT}.ps

TODAY=`date +'%Y/%m/%d'`

#------------------------------------------------------------------------------
# Data paths
#------------------------------------------------------------------------------
DATA_GENOUEST=   

case "$PIP" in
        p1) DATA_NAME=Assemblathon1/data ;;
        p2) DATA_NAME=chr14-gage ;; 
        p3) DATA_NAME=Staphylococcus_aureus/Data/original ;; 
        p4) DATA_NAME=Rhodobacter_sphaeroides/Data/original ;; 
        p5) DATA_NAME=Bombus_impatiens/Data/original ;;   # données à vérifier ???
        p6) DATA_NAME=Assemblathon2/fish/fastq ;; 
		*)  echo Error; exit 1; ;;
esac

DATA_IGRIDA=/temp_dd/igrida-fs1/cdeltel/bioinfo/${DATA_NAME}/
REPORTS_GENOUEST=/home/symbiose/cdeltel/anr-gatb/reports/igrida/gatb-${PIP}/

#------------------------------------------------------------------------------
# Host infos
#------------------------------------------------------------------------------
lstopo --of txt

#------------------------------------------------------------------------------
# Tools
#------------------------------------------------------------------------------
duration() {
	local dt=${1}
	((h=dt/3600))
	((m=dt%3600/60))
	((s=dt%60))
	printf "%03dh:%02dm:%0ds\n" $h $m $s
}

#------------------------------------------------------------------------------
# Job infos
#------------------------------------------------------------------------------
EXT_print_job_informations() {
	echo "hostname        : " `hostname`
	echo "TODAY           : $TODAY"
	echo "OAR_JOB_NAME    : $OAR_JOB_NAME"
	echo "OAR_JOB_ID      : $OAR_JOB_ID"
	echo "OAR_ARRAY_ID    : $OAR_ARRAY_ID"
	echo "OAR_ARRAY_INDEX : $OAR_ARRAY_INDEX"
}

EXT_send_starting_mail() {
	SUBJECT="[gatb-${PIP}]-job$OAR_JOB_ID-starts"
	$MAIL_CMD $MAIL_DST_ALL_MESG -s "$SUBJECT" << EOF
OAR_JOB_ID: $OAR_JOB_ID - hostname: `hostname`
EOF
}

#------------------------------------------------------------------------------
# Send an e-mail when job starts/ends
#------------------------------------------------------------------------------
EXT_send_ending_mail() {
	echo "JOB_SUMMARY"
	SUBJECT="[gatb-${PIP}]-job$OAR_JOB_ID-ends-`duration $DURATION_TIME`"
	$MAIL_CMD $MAIL_DST_ALL_MESG -s "$SUBJECT" << EOF
$JOB_SUMMARY
EOF
	if [ $CMD_EXIT_CODE -ne 0 ] || [ $MAKE_EXIT_CODE -ne 0 ]; then
		SUBJECT="[gatb-${PIP}]-job$OAR_JOB_ID-ends-Error"
		$MAIL_CMD $MAIL_DST_ALL_MESG $MAIL_DST_ERR_ONLY -s "$SUBJECT" << EOF
This is to inform you that the GATB ${PIP} pipeline exited with error: 
	MAKE_EXIT_CODE: $MAKE_EXIT_CODE
	CMD_EXIT_CODE:  $CMD_EXIT_CODE
EOF
	fi
}

#------------------------------------------------------------------------------
# Download the code
#------------------------------------------------------------------------------
EXT_download_source_code() {
	git clone git+ssh://cdeltel@scm.gforge.inria.fr//gitroot/gatb-pipeline/gatb-pipeline.git git-gatb-pipeline
	[ $? -ne 0 ] && { echo "git clone error"; exit 1;}
	cd git-gatb-pipeline
	git submodule init
	git submodule update
	[ $? -ne 0 ] && { echo "git submodule error"; exit 1;}
	git submodule status
	cd ..
	svn co svn+ssh://scm.gforge.inria.fr/svnroot/projetssymbiose/superscaffolder             superscaffolder
	[ $? -ne 0 ] && { echo "svn co error"; exit 1;}
	svn co svn+ssh://scm.gforge.inria.fr/svnroot/projetssymbiose/minia/trunk                 debloom
	[ $? -ne 0 ] && { echo "svn co error"; exit 1;}
	svn co svn+ssh://scm.gforge.inria.fr/svnroot/projetssymbiose/specialk                    specialk
	[ $? -ne 0 ] && { echo "svn co error"; exit 1;}
}

#------------------------------------------------------------------------------
# Code versioning informations
#------------------------------------------------------------------------------
EXT_print_versioning_informations() {
	INFOS_GATB_PIPELINE=$PIPELINE/git-gatb-infos.txt
	INFOS_SUPERSCAFFOLDER=$PIPELINE/svn-superscaffolder-infos.txt
	INFOS_DEBLOOM=$PIPELINE/svn-debloom-infos.txt
	INFOS_SPECIALK=$PIPELINE/svn-specialk-infos.txt

	#..............................................................................
	cd $PIPELINE/git-gatb-pipeline
	git log --max-count=1 > $INFOS_GATB_PIPELINE
	cat $INFOS_GATB_PIPELINE
	#..............................................................................
	cd $PIPELINE/superscaffolder
	svn info > $INFOS_SUPERSCAFFOLDER
	svn log --limit 10 >> $INFOS_SUPERSCAFFOLDER
	cat $INFOS_SUPERSCAFFOLDER
	#..............................................................................
	cd $PIPELINE/specialk
	svn info > $INFOS_SPECIALK
	svn log --limit 10 >> $INFOS_SPECIALK
	cat $INFOS_SPECIALK
	#..............................................................................
	cd $PIPELINE/debloom
	svn info > $INFOS_DEBLOOM
	svn log --limit 10 >> $INFOS_DEBLOOM
	cat $INFOS_DEBLOOM
	#..............................................................................
}

#------------------------------------------------------------------------------
# Define where the run will take place
#------------------------------------------------------------------------------
EXT_define_paths() {
	#NOW=$(date +"%Y-%m-%d-%H:%M:%S")

	#WORKDIR=/temp_dd/igrida-fs1/cdeltel/bioinfo/gatb-pipeline-runs/p2/2013-07-29-17:50:29
 	WORKDIR=/temp_dd/igrida-fs1/cdeltel/bioinfo/gatb-pipeline-runs/${PIP}/$OAR_JOB_ID
	
	PIPELINE=$WORKDIR/gatb-pipeline
	GATB_SCRIPT=$PIPELINE/git-gatb-pipeline/gatb
	MEMUSED=$PIPELINE/git-gatb-pipeline/tools/memused
	chmod a+x $MEMUSED
	QUAST_PATH=/udd/cdeltel/bioinfo/quast-2.2/
	QUAST_CMD="python $QUAST_PATH/quast.py "
}


#------------------------------------------------------------------------------
# Non regression tests
#------------------------------------------------------------------------------


EXT_non_regression_update_logbook(){
	OAR_JOB_ID_PREVIOUS="`tail -1 $LOGBOOK|awk '{print $2}'`"
	START_TIME_PREVIOUS="`tail -1 $LOGBOOK|awk '{print $8}'`"
	END_TIME_PREVIOUS="`tail -1 $LOGBOOK|awk '{print $11}'`"

	(( DURATION_TIME_PREVIOUS = END_TIME_PREVIOUS - START_TIME_PREVIOUS ))
	(( DT_WITH_PREVIOUS = DURATION_TIME - DURATION_TIME_PREVIOUS ))

	JOB_SUMMARY="TODAY: $TODAY - OAR_JOB_ID: $OAR_JOB_ID - hostname: `hostname` - START_TIME: $START_TIME - END_TIME: $END_TIME - DURATION: `duration $DURATION_TIME` - CMD_EXIT_CODE: $CMD_EXIT_CODE - DT_WITH_PREVIOUS: $DT_WITH_PREVIOUS"
	echo "$JOB_SUMMARY" >> $LOGBOOK_TXT
}

EXT_non_regression_quast() {
	echo "EXT_non_regression_quast: Not ready"

	quast_latest=$WORKDIR/../$OAR_JOB_ID_PREVIOUS/run/quast_results/latest/quast.log
	quast_current=$WORKDIR/run/quast_results/latest/quast.log

	echo 
	echo We compare $quast_latest and $quast_current
	echo

	diff $quast_latest $quast_current

	echo

	if [ $? -ne 0 ]; then
		echo
		echo "WARNING: Quast results differ from previous run!"
		echo
	fi
}

EXT_non_regression_execution_time() {
	echo "EXT_non_regression_execution_time: TODO"
}

EXT_non_regression_plot() {
	echo "EXT_non_regression_plot: "
	pwd
	
	awk '{ print $2  }' $LOGBOOK_TXT > c0
	awk '{ print $17 }' $LOGBOOK_TXT |cut -c1-3 > c1
	awk '{ print $17 }' $LOGBOOK_TXT |cut -c6-7 > c2
	awk '{ print $17 }' $LOGBOOK_TXT |cut -c10-|cut -ds -f1 > c3
	paste c0 c1 c2 c3 > tmp
	
	awk '{ printf("%10.2f\n",  $2+$3/60.+$4/60./60.)      }' tmp > in_hours
	awk '{ printf("%10.2f\n", ($2+$3/60.+$4/60./60.)*60.) }' tmp > in_minutes

	paste tmp in_hours in_minutes > ${LOGBOOK_ROOT}_processed.txt

	rm -f c0 c1 c2 c3 tmp in_hours in_minutes
	
	COLUMN_HOURS=5
	COLUMN_MINUT=6
	
	case "$PIP" in
        p1) COL=$COLUMN_HOURS ; UNITS="hours";;
        p2) COL=$COLUMN_HOURS ; UNITS="hours";;
        p3) COL=$COLUMN_MINUT ; UNITS="minutes";;
        p4) COL=$COLUMN_MINUT ; UNITS="minutes";;
        p5) COL=$COLUMN_HOURS ; UNITS="hours";;
        p6) COL=$COLUMN_HOURS ; UNITS="hours";;
		*)  echo Error; exit 1; ;;
	esac
							
	gnuplot << EOF
set terminal postscript
set output "$LOGBOOK_POS"
set grid
plot "${LOGBOOK_ROOT}_processed.txt" u $COL w boxes title "${LOGBOOK_ROOT} (in $UNITS)"
EOF

}

#------------------------------------------------------------------------------
# Upload run reports to Genouest
#------------------------------------------------------------------------------

EXT_transfer_reports_to_genouest() {

	ssh genocluster2 mkdir -p $REPORTS_GENOUEST/outjobs
	ssh genocluster2 mkdir -p $REPORTS_GENOUEST/quast

	rsync -uv $WORKDIR/../outjobs/*									genocluster2:$REPORTS_GENOUEST/outjobs/
	rsync -uv $WORKDIR/run/quast_results/results_*/report.txt		genocluster2:$REPORTS_GENOUEST/quast/report.$OAR_JOB_ID.txt
	
	rsync -uv $LOGBOOK_TXT											genocluster2:$REPORTS_GENOUEST/outjobs/${LOGBOOK_ROOT}.txt
	rsync -uv $LOGBOOK_POS											genocluster2:$REPORTS_GENOUEST/outjobs/${LOGBOOK_ROOT}.ps
	
}

