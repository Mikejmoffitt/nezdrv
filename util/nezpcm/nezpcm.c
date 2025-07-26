//
// Nezumi PCM file preparation tool
//
// 8-bit unsigned PCM files are massaged such that $FF bytes become $FE, and
// an $FF end marker is inserted.
//

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
	if (argc < 1)
	{
		printf("Usage: %s data.bin <type>\n", argv[0]);
		return 0;
	}

	const char *fname = argv[1];

	FILE *f = fopen(fname, "rb");
	if (!f)
	{
		fprintf(stderr, "Couldn't open \"%s\"\n", fname);
		return -1;
	}

	// Read original PCM data
	fseek(f, 0, SEEK_END);
	const size_t pcm_bytes = ftell(f);

	uint8_t *data = malloc(pcm_bytes);
	if (!data)
	{
		fprintf(stderr, "Couldn't allocate PCM buffer!\n");
		return -1;
	}
	fseek(f, 0, SEEK_SET);
	fread(data, sizeof(uint8_t), pcm_bytes, f);
	fclose(f);

	// Process PCM data
	for (unsigned int i = 0; i < pcm_bytes; i++)
	{
		if (data[i] == 0xFF) data[i] = 0xFE;
	}

	// Reopen file for rewriting
	f = fopen(fname, "wb");
	fwrite(data, sizeof(data[0]), pcm_bytes, f);
	fputc(0xFF, f);  // end marker
	fclose(f);
	return 0;
}
