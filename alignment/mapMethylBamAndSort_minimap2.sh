#!/bin/bash

set -x 
set -e

source /opt/miniconda/etc/profile.d/conda.sh; 
conda activate /public/home/mcechova/conda/methylation/

in_cores=180 #number of processors to be used

unaligned_methyl_bam=$1
DIR="$(dirname "${unaligned_methyl_bam}")" #output in the same directory where the input file is
sample="$(basename ${unaligned_methyl_bam} .bam)"

ref_file=$2 #"/public/groups/migalab/mcechova/chm13v2.0.fa" #"GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"
ref_name="$(basename -- $ref_file)"
ref_name="${ref_name%.*}"

in_args="-y -x map-ont -a --eqx -k 17 -K 10g" #minimap parameters appropriate for nanopore reads

method="minimap2"

#script based on the wdl file by Melissa Meredith
#https://github.com/meredith705/ont_methylation/blob/32095600428d21bf53aef8a7ccc401b0f10a9145/tasks/minimap2.wdl

index_file="index.minimap2.${ref_name}.mmi"
if [ -f "$index_file" ]; then
    echo "$index_file exists."
else 
    echo "$index_file does not exist."
    #generate minimap index file
	minimap2 -k 17 -I 8G -d ${index_file} ${ref_file}
fi

#do the mapping with methylation tags
samtools fastq -T MM,ML ${unaligned_methyl_bam} | minimap2 --MD --cs=long -t ${in_cores} ${in_args} ${index_file} - | samtools view -@ ${in_cores} -bh - | samtools sort -@ ${in_cores} - > ${DIR}/${sample}.fastq.cpg.${method}.${ref_name}.bam
samtools index ${DIR}/${sample}.fastq.cpg.${method}.${ref_name}.bam

echo "Done."
