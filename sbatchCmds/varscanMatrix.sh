#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/varmat_%j.txt
#SBATCH --output=slurmOut/varmat_%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=3
#SBATCH --job-name varmat
#SBATCH --wait
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=ALL
#SBATCH --partition=himem,general
#SBATCH --time=0-12:00:00

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

perl scripts/varscanToMatrix.pl \
     -v \
     --fileList "output/varscan/copycaller/S*/*chr*.txt" \
     > output/varscan/varscan_distMatrix.txt
