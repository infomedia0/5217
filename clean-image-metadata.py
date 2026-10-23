"""Remove synthetic Finder positions added by hdiutil makehybrid.

These positions otherwise invalidate strict code-signature verification on a
mounted app. This changes only the HFS+ catalog's 32-byte Finder info fields;
file contents, permissions, resource data, and code signatures are untouched.
"""
import pathlib
import struct
import sys

path = pathlib.Path(sys.argv[1])
image = bytearray(path.read_bytes())
u16 = lambda p: struct.unpack_from('>H', image, p)[0]
u32 = lambda p: struct.unpack_from('>I', image, p)[0]
assert image[512:514] == b'PM', 'Expected Apple partition map'
volume = None
for index in range(1, u32(516) + 1):
    entry = index * 512
    kind = image[entry + 48:entry + 80].split(b'\0')[0]
    if kind == b'Apple_HFS':
        volume = u32(entry + 8) * 512
        break
assert volume is not None, 'HFS+ partition missing'
header = volume + 1024
assert image[header:header + 2] == b'H+', 'Expected HFS+'
block_size = u32(header + 40)
fork = header + 272
catalog_size = struct.unpack_from('>Q', image, fork)[0]
extents = []
logical = 0
for index in range(8):
    start, count = struct.unpack_from('>II', image, fork + 16 + index * 8)
    if count:
        extents.append((logical, volume + start * block_size, count * block_size))
        logical += count * block_size
assert logical >= catalog_size, 'Overflow extents are not supported'

def physical(offset):
    for logical_start, disk_start, length in extents:
        if logical_start <= offset < logical_start + length:
            return disk_start + offset - logical_start
    raise ValueError('Catalog offset outside extents')

node_size = u16(physical(32))
total_nodes = u32(physical(36))
assert node_size >= 512 and total_nodes * node_size <= catalog_size
cleaned = 0
for node in range(total_nodes):
    base = node * node_size
    if image[physical(base + 8)] != 255:
        continue
    count = u16(physical(base + 10))
    for record in range(count):
        start = u16(physical(base + node_size - 2 * (record + 1)))
        key = base + start
        data = key + 2 + u16(physical(key))
        if u16(physical(data)) in (1, 2):
            for offset in range(48, 80):
                image[physical(data + offset)] = 0
            cleaned += 1
path.write_bytes(image)
print(f'Normalized Finder metadata on {cleaned} catalog entries.')
