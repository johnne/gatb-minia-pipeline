#!/bin/bash
#==============================================================================
#                    G A T B    P I P E L I N E
#==============================================================================
#
# History
#   2013-11-18: Change the quast command (contigs were evaluated, instead of scaffolds)
#
#==============================================================================
#
#------------------------------------------------------------------------------
# Job parameters
#------------------------------------------------------------------------------
#OAR -n gatb-p6
#OAR -l {cluster='bermuda'}/nodes=1,walltime=160:00:00
#OAR -O /temp_dd/igrida-fs1/cdeltel/bioinfo/gatb-pipeline-runs/p6/outjobs/run.%jobid%.out
#OAR -E /temp_dd/igrida-fs1/cdeltel/bioinfo/gatb-pipeline-runs/p6/outjobs/run.%jobid%.out

# we use IGRIDA the following IGRIDA clusters (see http://igrida.gforge.inria.fr/practices.html)
#	bermuda : 2 x 4 cores Gulftown		Intel(R) Xeon(R) CPU E5640 @ 2.67GHz		48GB


# TODOs
#   use *local* disk for the run (instead of the NFS dir. /temp_dd/...)
#	make this script more generic (currently only for cdeltel)
#	check the compilation options (O3, openmp, sse, etc.)
#	add md5sum check after transfering the data
#	synthetize results, send report


set -xv


PIP=p6   # pipeline name

source gatb-pipeline-common.sh

EXT_print_job_informations

EXT_send_starting_mail

EXT_define_paths


#------------------------------------------------------------------------------
# Prepare the data
#------------------------------------------------------------------------------
#rsync -uv genocluster2:$DATA_GENOUEST/*fastq $DATA_IGRIDA/

#for Quast validation
#rsync -uv genocluster2:/omaha-beach/Assemblathon1/speciesA.diploid.fa $DATA_IGRIDA/

#------------------------------------------------------------------------------
# Download the code
#------------------------------------------------------------------------------

mkdir -p $PIPELINE
cd $PIPELINE/
pwd

EXT_download_source_code

EXT_print_versioning_informations


#------------------------------------------------------------------------------
# Compile the codes
#------------------------------------------------------------------------------
cd $PIPELINE/git-gatb-pipeline/
#ln -sf ../specialk        kmergenie
#ln -sf ../superscaffolder superscaffolder
ln -sf ../debloom         minia

make

#------------------------------------------------------------------------------
# Default simple test
#------------------------------------------------------------------------------
#make test

#------------------------------------------------------------------------------
# Assemblathon-1 benchmark
#------------------------------------------------------------------------------
#FASTQ_LIST=`ls $DATA_IGRIDA/*fastq`
FASTQ_LIST=`ls $DATA_IGRIDA/*fastq*`     # gzip
 
echo "FASTQ list : $FASTQ_LIST"
echo "Check compatibility with the command below:"

mkdir $WORKDIR/run
cd $WORKDIR/run

date
START_TIME=`date +"%s"`

#time ls xxx

time $MEMUSED $GATB_SCRIPT \
	-p $DATA_IGRIDA/625E1AAXX.1_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.1_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.2_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.2_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.3_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.3_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.4_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.4_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.5_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.5_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.6_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.6_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.7_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.7_trim2.fastq.gz  \
	-p $DATA_IGRIDA/625E1AAXX.8_trim1.fastq.gz   		$DATA_IGRIDA/625E1AAXX.8_trim2.fastq.gz

CMD_EXIT_CODE=$?

END_TIME=`date +"%s"`

(( DURATION_TIME = END_TIME - START_TIME ))

date

EXT_non_regression_update_logbook


#------------------------------------------------------------------------------
# Job summary
#------------------------------------------------------------------------------
 
EXT_send_ending_mail


#------------------------------------------------------------------------------
# Synthetize results
#------------------------------------------------------------------------------

# Validation of the results

# ??? $QUAST_CMD assembly.scaffolds3.fa -R $DATA_IGRIDA/genome.fasta


# Non regression tests

EXT_non_regression_execution_time  # todo

EXT_non_regression_quast


#------------------------------------------------------------------------------
# Upload run reports to Genouest
#------------------------------------------------------------------------------


ssh genocluster2 mkdir -p $REPORTS_GENOUEST/outjobs
ssh genocluster2 mkdir -p $REPORTS_GENOUEST/quast

rsync -uv $TEMPDIR/bioinfo/gatb-pipeline-runs/outjobs-${PIP}/*	genocluster2:$REPORTS_GENOUEST/outjobs/
rsync -uv $WORKDIR/run/quast_results/results_*/report.txt		genocluster2:$REPORTS_GENOUEST/quast/report.$OAR_JOB_ID.txt

