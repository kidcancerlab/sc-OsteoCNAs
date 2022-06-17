#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --error=slurmOut/pileupVarscan_%j.txt
#SBATCH --output=slurmOut/pileupVarscan_%j.txt
#SBATCH --mem=200G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name pileupVarscan
#SBATCH --wait
#SBATCH --array=0-0
#SBATCH --time=0-12:00:00
#SBATCH --mail-user=matthew.cannon@nationwidechildrens.org
#SBATCH --mail-type=ALL
#SBATCH --partition=general,himem


set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

module purge

module load GCC/9.3.0 \
    GCCcore/9.3.0 \
    SAMtools/1.15 \
    BCFtools/1.11

# Arrays matching the germline and reference files
sampleArray=(
    S0113
    S0114
    S0115
    S0116
    S0126
    S0127
    S0128
    SJOS001101_M1
    SJOS001101_M2
    SJOS001101_M3
    SJOS001101_M4
    SJOS001105_D1
    SJOS001105_R1
    SJOS001111_M1
    SJOS001116_M2
    SJOS001116_X2
    SJOS001121_D2
    SJOS001121_X2
    SJOS001126_D1b
    SJOS001126_X1
    SJOS013768_D1
    SJOS013768_M1
    SJOS013768_X1
    SJOS013768_X3
    SJOS016016_D1
    SJOS016016_X1
    SJOS030101_D1
    SJOS030101_D2
    SJOS030101_R1
    SJOS030101_X1
    SJOS030645_D1
    SJOS030645_D2
    SJOS030645_X2
    SJOS031478_D1
    SJOS031478_D2
    SJOS031478_D3
    SJOS046149_R1
    SJOS046149_R2
    SJOS046149_X1
)

germlineArray=(
    SJOS046149_Gx
    SJOS031478_G1
    SJOS046149_Gx
    SJOS031478_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS001101_G1
    SJOS001101_G1
    SJOS001101_G1
    SJOS001101_G1
    SJOS001105_G1
    SJOS001105_G1
    SJOS001111_G1
    SJOS001116_G1
    SJOS001116_G1
    SJOS001121_G1
    SJOS001121_G1
    SJOS001126_G1
    SJOS001126_G1
    SJOS013768_G1
    SJOS013768_G1
    SJOS013768_G1
    SJOS013768_G1
    SJOS016016_G1
    SJOS016016_G1
    SJOS030101_G1
    SJOS030101_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS030645_G1
    SJOS031478_G1
    SJOS031478_G1
    SJOS031478_G1
    SJOS046149_Gx
    SJOS046149_Gx
    SJOS046149_Gx
)

export sample=${sampleArray[${SLURM_ARRAY_TASK_ID}]}
export germline=${germlineArray[${SLURM_ARRAY_TASK_ID}]}

# Scratch directory
export scrDir=/gpfs0/scratch/mvc002/roberts/stjude/realigned

# Calculate the ratio of reads between the two samples
export ratio=$(
    perl scripts/getDataRatio.pl \
    --normal ${scrDir}/${germline}_combined.bam \
    --tumor ${scrDir}/${sample}_combined.bam \
    --viewThreads 10
    )

echo "The varscan ratio is: " $ratio

if [ ! -d output/varscan/copynumber/${sample} ]; then
    mkdir output/varscan/copynumber/${sample}
fi

# Do variant calling and then pipe output into varscan
parallel -j 25 --colsep '\t' \
    'samtools mpileup \
        -d 20000 \
        -q 20 \
        -f /reference/homo_sapiens/hg38/ucsc_assembly/illumina_download/Sequence/WholeGenomeFasta/genome.fa \
        ${scrDir}/${germline}_combined.bam \
        ${scrDir}/${sample}_combined.bam \
        -r {1} | \
    java -jar ~/bin/VarScan.v2.4.2.jar copynumber \
        - \
        output/varscan/copynumber/${sample}/${sample}_{1} \
        --mpileup 1 \
        --data-ratio ${ratio}' \
    :::: misc/chrList.txt

