#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/p53Char_%j.txt
#SBATCH --output=slurmOut/p53Char_%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --job-name p53Char
#SBATCH --wait
#SBATCH --array=0-54
#SBATCH --time=0-10:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            BCFtools/1.11

sampleArray=(output/vcfs/*.vcf.gz)
sampleName=${sampleArray[$SLURM_ARRAY_TASK_ID]}
baseName=${sampleName%.vcf.gz}
baseName=${baseName##*/}

scrDir=/gpfs0/scratch/mvc002/roberts

bcftools mpileup \
    --threads 3 \
    --max-depth 2000 \
    -Ou \
    -f /reference/homo_sapiens/hg38/ucsc_assembly/illumina_download/Sequence/WholeGenomeFasta/genome.fa \
    -r chr17:7600000-7690000 \
    ${scrDir}/stjude/realigned/${baseName}_combined.bam \
    | bcftools call \
        --threads 3 \
        --ploidy GRCh38 \
        -m \
    | bcftools filter \
        --threads 3 \
        -g 10 \
        -e "QUAL<20 | DP<20" \
    | bcftools view \
        --threads 3 \
        > /gpfs0/scratch/mvc002/roberts/${baseName}.vcf

ml purge
module load rstudio/1.4.1717 R/4.1.0

java -jar \
    ~/bin/snpEff/snpEff.jar \
    GRCh38.105 \
    /gpfs0/scratch/mvc002/roberts/${baseName}.vcf \
    | gzip \
        > output/vcfs/p53Char/${baseName}.vcf.gz

rm /gpfs0/scratch/mvc002/roberts/${baseName}.vcf