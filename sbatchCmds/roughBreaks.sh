#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/breakRough_%j.txt
#SBATCH --output=slurmOut/breakRough_%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name breakRough
#SBATCH --wait
#SBATCH --array=0-54
#SBATCH --time=0-12:00:00
#SBATCH --partition=general
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

module load SAMtools/1.15 

sampleArray=(input/*.bam)

for i in "${!sampleArray[@]}"
do
  stubArray[$i]="${sampleArray[$i]##*/}"
  stubArray[$i]="${stubArray[$i]%.bam}"
  stubArray[$i]="${stubArray[$i]%.WholeGenome}"
done

export stub=${stubArray[${SLURM_ARRAY_TASK_ID}]}

export scrDir=/gpfs0/scratch/mvc002/roberts/stjude/realigned

samtools view -f 0x0040 ${scrDir}/${stub}_combined.bam | \
    awk '$7 != "=" {print $3, int($4 / 10000) * 10000, $7, int($8 / 10000) * 10000}' | \
    grep -v "chrM|random" | \
    perlUnique.pl -c | \
    sort -k5rn | \
    awk '$5 > 10 {print}' | \
    gzip \
        > output/roughBreakpoint/${stub}.txt