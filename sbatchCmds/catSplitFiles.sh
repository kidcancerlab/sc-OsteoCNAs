#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/catSplit_%j.txt
#SBATCH --output=slurmOut/catSplit_%j.txt
#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name catSplit
#SBATCH --wait
#SBATCH --array=0-40
#SBATCH --time=1-09:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

# pull file with md5sums into a bash array

IFS=$'\n'
md5LineArray=($(cat misc/rawBamMd5s.txt))

# pull md5 and file name from array element based on $SLURM_ARRAY_TASK_ID

currentLine=${md5LineArray[$SLURM_ARRAY_TASK_ID]}

md5=${currentLine% *}
fileName=${currentLine##*/}

# cat sub files
cat input/split/${fileName}* \
    > /gpfs0/scratch/mvc002/${fileName}

# compare md5sum to md5 variable
calcMd5=$(md5sum /gpfs0/scratch/mvc002/${fileName})
calcMd5=${calcMd5% *}

if [ ${calcMd5} == ${md5} ]
then
    echo "Md5 correct"
    mv /gpfs0/scratch/mvc002/${fileName} \
        input/${fileName}
    rm input/split/${fileName}*
else
    echo "Md5 incorrect: " $calcMd5
fi
