#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/forceDownload2_%j.txt
#SBATCH --output=slurmOut/forceDownload2_%j.txt
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name forceDownload2
#SBATCH --wait
#SBATCH --array=0-999%30
#SBATCH --time=1-09:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

linkArray=($(cut -d " " -f 1 misc/batch2DownloadFile.txt))
md5Array=($(cut -d " " -f 2 misc/batch2DownloadFile.txt))

currentLink=${linkArray[$SLURM_ARRAY_TASK_ID]}
currentMd5=${md5Array[$SLURM_ARRAY_TASK_ID]}

cd input/split/

perl ~/scripts/dnaNexusDl.pl \
    --link ${currentLink} \
    --md5 ${currentMd5}
