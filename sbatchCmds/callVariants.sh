#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/callVars_%j.txt
#SBATCH --output=slurmOut/callVars_%j.txt
#SBATCH --mem=150G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name callVars
#SBATCH --wait
#SBATCH --array=0-54
#SBATCH --time=0-12:00:00
#SBATCH --partition=general,himem
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org


set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

module load GCC/9.3.0 \
            GCCcore/9.3.0 \
            SAMtools/1.15 \
            BCFtools/1.11

sampleArray=(input/*.bam)

for i in "${!sampleArray[@]}"
do
  stubArray[$i]="${sampleArray[$i]##*/}"
  stubArray[$i]="${stubArray[$i]%.bam}"
  stubArray[$i]="${stubArray[$i]%.WholeGenome}"
done

export sample=${sampleArray[${SLURM_ARRAY_TASK_ID}]}
export stub=${stubArray[${SLURM_ARRAY_TASK_ID}]}

if [ ! -d output/vcfs/${stub} ]
then
    mkdir output/vcfs/${stub}
fi

export scrDir=/gpfs0/scratch/mvc002/roberts/stjude/realigned

# find variants

parallel -j 15 --colsep '\t' \
    'bcftools mpileup \
        --threads 3 \
        --max-depth 2000 \
        -Ou \
        -f /reference/homo_sapiens/hg38/ucsc_assembly/illumina_download/Sequence/WholeGenomeFasta/genome.fa \
        -r {1} \
        ${scrDir}/${stub}_combined.bam | \
    bcftools call \
        --threads 3 \
        --ploidy GRCh38 \
        -m | \
    bcftools filter \
        --threads 3 \
        -g 10 \
        -e "QUAL<20 | DP<20" | \
    bcftools view \
        --threads 3 \
        --exclude-types indels \
        -O z \
        -o output/vcfs/${stub}/${stub}_{1}.vcf.gz' \
   :::: misc/chrList.txt

bcftools concat \
    --threads 10 \
    --output output/vcfs/${stub}.vcf.gz \
    -O z \
    output/vcfs/${stub}/${stub}_*.vcf.gz

rm output/vcfs/${stub}/${stub}_*.vcf.gz

