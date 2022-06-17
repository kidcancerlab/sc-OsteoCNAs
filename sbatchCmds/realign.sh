#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/realign_%j.txt
#SBATCH --output=slurmOut/realign_%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --job-name realign
#SBATCH --wait
#SBATCH --array=0-54
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=ALL
#SBATCH --partition=himem,general
#SBATCH --time=0-12:00:00

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            BCFtools/1.11 \
            HISAT2/2.2.1 \
            SAMtools/1.15

export PATH="${PATH}:~/bin/samtools-1.15/bin/"

sampleArray=(input/*.bam)

for i in "${!sampleArray[@]}"
do
  stubArray[$i]="${sampleArray[$i]##*/}"
  stubArray[$i]="${stubArray[$i]%.bam}"
  stubArray[$i]="${stubArray[$i]%.WholeGenome}"
done

export sample=${sampleArray[${SLURM_ARRAY_TASK_ID}]}
export inName=${stubArray[${SLURM_ARRAY_TASK_ID}]}

#samtools index -@ 10 ${sample}

if [ ! -d output/vcfs/${stub} ]
then
    mkdir output/vcfs/${stub}
fi

export scrDir=/gpfs0/scratch/mvc002/roberts/stjude/realigned


### Re-align the reads to a reference genome with both human and mouse

# Convert the bam file to fastq
samtools cat \
    --output-fmt=SAM \
    ${sample} | \
    samtools collate \
        -O \
        --threads 10 \
        - \
        /gpfs0/scratch/mvc002/roberts/${inName} | \
    samtools fastq \
        --threads 10 \
        -n \
        -0 /dev/null \
        -s /dev/null \
        -1 ${scrDir}/${inName}_1.fq.gz \
        -2 ${scrDir}/${inName}_2.fq.gz

# Align fastq files to the mixed reference genome and filter out PCR duplicates
# Filter out the mm10 aligned reads
# I'm also re-adjusting the chromosome names to be consistent with the reference
# Used --no-temp-splicesite due to a known bug in hisat2 that caused excessive memory usage
# https://github.com/DaehwanKimLab/hisat2/issues/297
hisat2 \
    -x /home/gdrobertslab/lab/GenRef/HsMm-mixed/hisat2/hg38_mm10_mixed \
    -1 ${scrDir}/${inName}_1.fq.gz \
    -2 ${scrDir}/${inName}_2.fq.gz \
    --threads 30 \
    -k 1 \
    --no-temp-splicesite \
    --summary-file output/align/${sample}Summary.txt | \
    grep -v "mm10_chr" | \
    perl -pe 's/hg38_chr/chr/g' | \
    samtools fixmate -@ 10 -m - - | \
    samtools sort \
        -T /gpfs0/scratch/mvc002/roberts/ \
        -@ 10 \
        -m 15G \
        -O BAM | \
    samtools markdup -@ 10 -r - - | \
    samtools view -@ 10 -b - \
        > ${scrDir}/${inName}_combined.bam

samtools index ${scrDir}/${inName}_combined.bam

#rm  ${scrDir}/${inName}_[12].fq.gz
