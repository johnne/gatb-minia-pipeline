GATB-Pipeline
-------------

GATB-Pipeline is a de novo assembly pipeline for llumina data. 
It can assemble genomes and metagenomes.
The pipeline consists of:
- Bloocoo (error correction)
- Minia (contigs assembly)
- BESST (scaffolding)

Prerequisites
-------------

- Linux 64 bits (for Minia binary)

- bwa (for BESST)

- Python >= 2.7 with the following modules (for BESST). See next section on how to install them.

    * mathstats
    * scipy
    * networkx
    * pysam


Installation
------------

    pip install --user mathstats pysam networkx scipy pyfasta

    git clone --recursive https://github.com/GATB/gatb-minia-pipeline

    make test

Usage
-----

Command line arguments are similar to SPAdes.

Paired reads assembly:

    ./gatb -1 read_1.fastq -2 read_2.fastq

paired-end reads given in a single file:

    ./gatb --12 interleaved_reads.fastq

Unpaired reads:

    ./gatb -s single_reads.fastq

More input options are available. Type `./gatb` for extended usage.

Since the pipeline is multi-k, it is unnecessary to specify a kmer size.


FAQ
---

Can't install scipy? (because e.g. cannot sudo) 

A solution is to install a python distribution that doesn't require root (it's not that hard).

Conda: 

    wget https://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
    sh Miniconda-latest-Linux-x86_64.sh
    . ~/.bashrc
    conda install scipy pysam networkx
    pip install mathstats

Read more on conda : http://lh3.github.io/2015/12/07/bioconda-the-best-package-manager-so-far/

http://conda.pydata.org/miniconda.html

Alternative: activestate python (http://www.activestate.com/activepython/downloads then type `pypm install scipy`)

Support
-------

To contact an author directly: rayan.chikhi@ens-cachan.org
Community support: https://www.biostars.org/t/GATB/
