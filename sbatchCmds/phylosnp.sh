#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/phylosnp_%j.txt
#SBATCH --output=slurmOut/phylosnp_%j.txt
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --job-name phylosnp
#SBATCH --wait
#SBATCH --time=3-00:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=FAIL,REQUEUE,TIME_LIMIT_80

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

mkdir -p /gpfs0/scratch/mvc002/phylosnp
cp output/vcfs/*vcf.gz /gpfs0/scratch/mvc002/phylosnp/

parallel -j 10 gunzip -f {} ::: /gpfs0/scratch/mvc002/phylosnp/*vcf.gz

timeout -m 9999999999999 ~/bin/PhyloSNP_Unix/phylosnp.pl \
    --pos POS \
    --output-dir output/vcfs/phylosnp \
    /gpfs0/scratch/mvc002/phylosnp/*vcf
