/*
 * efone - Distributed internet phone system.
 *
 * (c) 1999,2000 Krzysztof Dabrowski
 * (c) 1999,2000 ElysiuM deeZine
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version
 * 2 of the License, or (at your option) any later version.
 *
 */

/* based on implementation by Finn Yannick Jacobs */

#include <stdio.h>
#include <stdlib.h>

/* crc_tab[] -- this crcTable is being build by chksum_crc32GenTab().
 *		so make sure, you call it before using the other
 *		functions!
 */
static u_int32_t crc_tab[256];
static int init_table = 0;

typedef struct {
   unsigned long crc;
} crc32_context_t;


void chksum_crc32gentab ()
{
   unsigned long crc, poly;
   int i, j;

   poly = 0xEDB88320L;
   for (i = 0; i < 256; i++)
   {
      crc = i;
      for (j = 8; j > 0; j--)
      {
	 if (crc & 1)
	 {
	    crc = (crc >> 1) ^ poly;
	 }
	 else
	 {
	    crc >>= 1;
	 }
      }
      crc_tab[i] = crc;
   }
}



void crc32_init(crc32_context_t *c)
{
    if (!init_table) chksum_crc32gentab();
    c->crc = 0xFFFFFFFF;
}

void crc32_update (crc32_context_t *c, unsigned char *block, unsigned int length)
{
   unsigned long crc = c->crc;
   unsigned long i;

   for (i = 0; i < length; i++)
   {
      crc = ((crc >> 8) & 0x00FFFFFF) ^ crc_tab[(crc ^ *block++) & 0xFF];
   }
   c->crc = crc;
}

u_int32_t crc32_finish (crc32_context_t *c)
{
   return (c->crc ^ 0xFFFFFFFF);
}


int main(void)
{
	unsigned char block[8192];
	crc32_context_t ctxt;
	int nr;

	crc32_init(&ctxt);

	nr = fread(block, 1, sizeof(block), stdin);
	while (nr > 0) {
		crc32_update(&ctxt, block, nr);
		nr = fread(block, 1, sizeof(block), stdin);
	}
	u_int32_t crc = crc32_finish(&ctxt);
	printf("CRC32=%08X\n", crc);
	return 0;
}
