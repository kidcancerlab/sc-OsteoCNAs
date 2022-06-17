#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/copynumber2_%j.txt
#SBATCH --output=slurmOut/copynumber2_%j.txt
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name copynumber2
#SBATCH --wait
#SBATCH --array=0-32
#SBATCH --time=3-00:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            BCFtools/1.11

sampleArray=($(ls output/varscan/copynumber/))

sample=${sampleArray[${SLURM_ARRAY_TASK_ID}]}

echo $sample

cat output/varscan/copynumber/${sample}/*copynumber > \
    /gpfs0/scratch/mvc002/${sample}_temp.copynumber


if [ ! -d output/varscan/copycallerCombined/${sample}/ ]
then
    mkdir -p output/varscan/copycallerCombined/${sample}/
fi

java -jar ~/bin/VarScan.v2.4.2.jar copyCaller \
      /gpfs0/scratch/mvc002/${sample}_temp.copynumber \
      --output-file output/varscan/copycallerCombined/${sample}/${sample}.txt \
      --output-homdel-file output/varscan/copycallerCombined/${sample}/${sample}_dels.txt

