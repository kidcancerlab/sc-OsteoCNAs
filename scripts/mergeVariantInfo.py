import argparse
import gzip


parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--sampleVcf',
                    type=str,
                    help='VCF file with sample variants')
parser.add_argument('--clinvar',
                    type=str,
                    help='clinvar vcf file')

args = parser.parse_args()

################################################################################
### Global variables
vcf_dict = {}
sample_dict = {}
info_type_dict = {}

################################################################################
### Code

########
# Read in the clinvar VCF file and store in a dictionary
if args.clinvar.endswith('.gz'):
    clinvar_file = gzip.open(args.clinvar, mode = 'r')
else:
    clinvar_file = open(args.clinvar, 'r')

for line in clinvar_file:
    line = line.decode('utf-8').strip()
    if not line.startswith('#'):
        chrom, pos, id, ref, alt, qual, filter, info = line.split('\t')
        vcf_dict[(chrom + "\t" +
                  pos + "\t" +
                  ref + "\t" +
                  alt)] = info

clinvar_file.close()

########
# Read in the samples VCF and add on any entry present in the clinvar file
if args.sampleVcf.endswith('.gz'):
    sample_file = gzip.open(args.sampleVcf, 'r')
else:
    sample_file = open(args.sampleVcf, 'r')

for line in sample_file:
    line = line.decode('utf-8').strip()
    if not line.startswith('#'):
        chrom, pos, id, ref, alt, qual, filter, info, *others = line.split('\t')
        if ((alt != '.') or 'INDEL' in info):
            dict_key = (chrom + "\t" +
                            pos + "\t" +
                            ref + "\t" +
                            alt)
            if dict_key in vcf_dict:
                info = info + ';' + vcf_dict[dict_key]

            sample_dict[dict_key] = {}

            # Store info in a dictionary by the value in front of "=" so that I can
            # write each type of into to a separate column later
            # Make a dict of the info fields so I can use that to make sure I write
            # matching columns for each line
            info_list = info.split(';')
            for entry in info_list:
                if entry == 'INDEL':
                    info_type = 'INDEL'
                    info_value = 'TRUE'
                else:
                    info_type, info_value = entry.split('=')
                info_type_dict[info_type] = 1
                sample_dict[dict_key][info_type] = info_value

sample_file.close()

print("chr", "pos", "ref", "alt", *list(info_type_dict.keys()), sep = '\t')

for sample_line in sample_dict.keys():
    print_line = sample_line
    for info_column in info_type_dict.keys():
        if info_column in sample_dict[sample_line]:
            print_line = print_line + '\t' + sample_dict[sample_line][info_column]
        else:
            print_line = print_line + '\t' + 'NA'
    print(print_line)
    print_line = ''
