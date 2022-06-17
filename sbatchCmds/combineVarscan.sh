#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/combineVarscan_%j.txt
#SBATCH --output=slurmOut/combineVarscan_%j.txt
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --job-name combineVarscan
#SBATCH --wait
#SBATCH --time=3-00:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME}

perl scripts/cmpVarscanCalls.pl \
    --binSize 10000 \
    --inputFiles "output/varscan/copycaller/*/*chr[0-9]*txt" \
        > output/varscan/combined_calls.txt