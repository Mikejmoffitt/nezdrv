//
// Nezumi FM patch file converter
//

#include <stdio.h>
#include <stdint.h>
#include <string.h>

enum
{
	FILETYPE_FUI,
	FILETYPE_DMP,
	FILETYPE_COUNT,
};

static const char *k_str_for_filetype[FILETYPE_COUNT] =
{
	[FILETYPE_FUI] = "fui",
	[FILETYPE_DMP] = "dmp",
};

static int filetype_from_filename(const char *fname)
{
	const int fname_len = strlen(fname);
	for (int i = 0; i < FILETYPE_COUNT; i++)
	{
		const char *type_str = k_str_for_filetype[i];
		const int type_str_len = strlen(type_str);
		if (type_str_len > fname_len) continue;
		const char *check_str = &fname[fname_len-type_str_len];
		if (strcmp(type_str, check_str) == 0) return i;
	}
	return -1;
}

static int parse_dmf(FILE *f)
{
	const uint8_t file_version = fgetc(f);
	const uint8_t system = fgetc(f);
	const uint8_t instrument_mode = fgetc(f);
	if (file_version != 0x0B)
	{
		fprintf(stderr, "DMP file version $%02X unhandled\n", file_version);
		return -1;
	}
	if (system != 0x02)
	{
		fprintf(stderr, "DMP system $%02X != GENESIS\n", system);
		return -1;
	}
	if (instrument_mode != 0x01)
	{
		fprintf(stderr, "DMP instrument mode $%02X != FM\n", system);
		return -1;
	}
	const uint8_t pms = fgetc(f);
	const uint8_t fb = fgetc(f);
	const uint8_t alg = fgetc(f);
	const uint8_t ams = fgetc(f);

	// NEZDRV treats these as runtime parameters.
	(void)pms;
	(void)ams;

	uint8_t mul[4];
	uint8_t tl[4];
	uint8_t ar[4];
	uint8_t dr[4];
	uint8_t sl[4];
	uint8_t rr[4];
	uint8_t am[4];
	uint8_t rs[4];
	uint8_t dt[4];
	uint8_t d2r[4];
	uint8_t ssg_eg[4];
	for (int i = 0; i < 4; i++)
	{
		mul[i] = fgetc(f);
		tl[i] = fgetc(f);
		ar[i] = fgetc(f);
		dr[i] = fgetc(f);
		sl[i] = fgetc(f);
		rr[i] = fgetc(f);
		am[i] = fgetc(f);
		rs[i] = fgetc(f);
		dt[i] = fgetc(f);
		d2r[i] = fgetc(f);
		ssg_eg[i] = fgetc(f);
	}

	// Emit data
	fputc(alg | (fb << 3), stdout);
	for (int i = 0; i < 4; i++) fputc(mul[i] | (dt[i]<<4), stdout);
	for (int i = 0; i < 4; i++) fputc(tl[i], stdout);
	for (int i = 0; i < 4; i++) fputc(ar[i] | (rs[i]<<6), stdout);
	for (int i = 0; i < 4; i++) fputc(dr[i] | (am[i]<<7), stdout);
	for (int i = 0; i < 4; i++) fputc(d2r[i], stdout);
	for (int i = 0; i < 4; i++) fputc(rr[i] | (sl[i]<<4), stdout);
	for (int i = 0; i < 4; i++) fputc(ssg_eg[i], stdout);
	return 0;
}

static int parse_fui(FILE *f)
{
	char header_str[4];
	fread(header_str, sizeof(char), 4, f);
	if (header_str[0] != 'F' ||
	    header_str[1] != 'I' ||
	    header_str[2] != 'N' ||
	    header_str[3] != 'S')
	{
		fprintf(stderr, "FUI header absent\n");
		return -1;
	}
	int16_t engine_version;
	fread(&engine_version, sizeof(int16_t), 1, f);
	const uint8_t type = fgetc(f);
	const uint8_t pad = fgetc(f);
	(void)pad;
	if (type != 0x01)
	{
		fprintf(stderr, "Unexpected type $%02X\n", type);
		return -1;
	}
	char feature_str[2];
	fread(feature_str, sizeof(char), 2, f);
	if (feature_str[0] != 'F' ||
	    feature_str[1] != 'M')
	// TODO: Identify and seek past other features that could be packed in.
	{
		fprintf(stderr, "Only FM feature is supported\n");
		return -1;
	}
	int16_t pad2;
	fread(&pad2, sizeof(int16_t), 1, f);
	(void)pad2;

	const uint8_t op_enable_bitfield = fgetc(f);
	(void)op_enable_bitfield;  // No intent to support this.
	if (op_enable_bitfield & 0x0F != 4)
	{
		fprintf(stderr, "Only 4-op patches are supported (data = $%02X)\n", op_enable_bitfield);
		return -1;
	}
	const uint8_t alg_fb_data = fgetc(f);  // Why are they swapped? OPM style?
	const uint8_t alg = alg_fb_data >> 4;
	const uint8_t fb = alg_fb_data & 0x03;

	const uint8_t mod0 = fgetc(f);
	const uint8_t mod1 = fgetc(f);
	const uint8_t block = fgetc(f);
	(void)block;
	(void)mod0;
	(void)mod1;

	// Why do all these tracker programs have their own "creative" storage
	// order for operator data? This is somehow worse than deflemask's

	uint8_t mul[4];
	uint8_t tl[4];
	uint8_t ar[4];
	uint8_t dr[4];
	uint8_t sl[4];
	uint8_t rr[4];
	uint8_t am[4];
	uint8_t rs[4];
	uint8_t dt[4];
	uint8_t d2r[4];
	uint8_t ssg_eg[4];

	for (int i = 0; i < 4; i++)
	{
		const uint8_t dtmul_byte = fgetc(f);
		dt[i] = (dtmul_byte >> 4);
		mul[i] = dtmul_byte & 0xF;
		const uint8_t tlbyte = fgetc(f);
		tl[i] = tlbyte & 0x7F;
		const uint8_t arbyte = fgetc(f);
		ar[i] = arbyte & 0x1F;
		rs[i] = arbyte >> 6;
		const uint8_t drbyte = fgetc(f);
		dr[i] = drbyte & 0x1F;
		rs[i] = (drbyte >> 5) & 0x03;
		am[i] = drbyte >> 7;
		const uint8_t d2rbyte = fgetc(f);
		d2r[i] = d2rbyte & 0x1F;
		const uint8_t rrbyte = fgetc(f);
		rr[i] = rrbyte & 0xF;
		sl[i] = rrbyte >> 4;
		const uint8_t ssgbyte = fgetc(f);
		ssg_eg[i] = ssgbyte & 0xF;
		const uint8_t discard = fgetc(f);
		(void)discard;
	}

	// Emit data
	fputc(alg | (fb << 3), stdout);
	for (int i = 0; i < 4; i++) fputc(mul[i] | (dt[i]<<4), stdout);
	for (int i = 0; i < 4; i++) fputc(tl[i], stdout);
	for (int i = 0; i < 4; i++) fputc(ar[i] | (rs[i]<<6), stdout);
	for (int i = 0; i < 4; i++) fputc(dr[i] | (am[i]<<7), stdout);
	for (int i = 0; i < 4; i++) fputc(d2r[i], stdout);
	for (int i = 0; i < 4; i++) fputc(rr[i] | (sl[i]<<4), stdout);
	for (int i = 0; i < 4; i++) fputc(ssg_eg[i], stdout);
	return 0;
}

int main(int argc, char **argv)
{
	if (argc < 2)
	{
		printf("Usage: %s fmfile <type>\n");
		printf("Type can be inferred from the filename if not specified.\n");
		printf("Valid types:\n");
		for (int i = 0; i < FILETYPE_COUNT; i++)
		{
			printf("    \"%s\"\n", k_str_for_filetype);
		}
		return 0;
	}

	int ftype = -1;
	const char *fname = argv[1];
	const char *ftype_str_src = fname;
	if (argc >= 3) ftype_str_src = argv[2];
	ftype = filetype_from_filename(ftype_str_src);

	FILE *f = fopen(fname, "rb");
	if (!f)
	{
		fprintf(stderr, "Couldn't open \"%s\"\n", fname);
		return -1;
	}

	switch (ftype)
	{
		case FILETYPE_DMP:
			return parse_dmf(f);
		case FILETYPE_FUI:
			return parse_fui(f);
		default:
			fprintf(stderr, "Unrecognized filetype fpr \"%s\"\n", fname);
			return -1;
	}

	return 0;
}
