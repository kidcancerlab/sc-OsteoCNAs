#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/clinVar_%j.txt
#SBATCH --output=slurmOut/clinVar_%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name clinVar
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

sampleArray=(output/vcfs/p53Char/*.vcf.gz)

sampleName=${sampleArray[$SLURM_ARRAY_TASK_ID]}
baseName=${sampleName%.vcf.gz}
baseName=${baseName##*/}

python scripts/mergeVariantInfo.py \
    --sampleVcf ${sampleName} \
    --clinvar misc/clinvar_TP53.vcf.gz \
        > output/vcfs/p53Char/clinVar/${baseName}.txt