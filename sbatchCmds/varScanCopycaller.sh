#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/copynumber_%j.txt
#SBATCH --output=slurmOut/copynumber_%j.txt
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name copynumber
#SBATCH --wait
#SBATCH --array=0-949
#SBATCH --time=1-00:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=ALL
#SBATCH --partition=general,himem


set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            BCFtools/1.11

sampleArray=(output/varscan/copynumber/*/*copynumber)

sample=${sampleArray[${SLURM_ARRAY_TASK_ID}]}
baseName=${sample##*/}
baseName=${baseName%.copynumber}
baseSample=${baseName%_chr[0-9MXY]*}

echo $sample $baseName

if [ ! -d output/varscan/copycaller/${baseSample}/ ]
then
    mkdir -p output/varscan/copycaller/${baseSample}/
fi

java -jar ~/bin/VarScan.v2.4.2.jar copyCaller \
      ${sample} \
      --output-file output/varscan/copycaller/${baseSample}/${baseName}.txt \
      --output-homdel-file output/varscan/copycaller/${baseSample}/${baseName}_dels.txt

