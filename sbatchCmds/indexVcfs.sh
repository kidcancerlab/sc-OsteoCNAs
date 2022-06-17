#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/indexVcf_%j.txt
#SBATCH --output=slurmOut/indexVcf_%j.txt
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --job-name indexVcf
#SBATCH --wait
#SBATCH --array=0-54
#SBATCH --time=0-10:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            BCFtools/1.11

sampleArray=(output/vcfs/*.vcf.gz)

bcftools index --threads 10 ${sampleArray[${SLURM_ARRAY_TASK_ID}]}
