/*
    Endianness conversion.

    Copyright (C) 2014           Hraban Luyat

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#ifndef ENDIANNESS_H
#define ENDIANNESS_H

#include "scanmem.h"
#include "value.h"
#include "config.h"

/* True if host is big endian */
#ifdef WORDS_BIGENDIAN
static const bool big_endian = true;
#else
static const bool big_endian = false;
#endif

void fix_endianness(globals_t *vars, value_t *data_value);
void swap_bytes_var(void *p, size_t num);

#endif /* ENDIANNESS_H */
