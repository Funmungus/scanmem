/*
 $Id:

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include <stdlib.h>

#include "getline.h"

ssize_t getline(char **lineptr, size_t *n, FILE *stream)
{
    char *ptr;

    ptr = fgetln(stream, n);

    if (ptr == NULL) {
        return -1;
    }

    /* Free the original ptr */
    if (*lineptr != NULL) free(*lineptr);

    /* Add one more space for '\0' */
    size_t len = n[0] + 1;

    /* Update the length */
    n[0] = len;

    /* Allocate a new buffer */
    *lineptr = malloc(len);

    /* Copy over the string */
    memcpy(*lineptr, ptr, len-1);

    /* Write the NULL character */
    (*lineptr)[len-1] = '\0';

    /* Return the length of the new buffer */
    return len;
}
