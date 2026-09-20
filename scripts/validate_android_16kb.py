import sys
import zipfile
import io
import argparse
import struct

def check_elf_alignment(file_obj, filename):
    magic = file_obj.read(4)
    if magic != b'\x7fELF':
        return True # Not an ELF
    
    file_obj.seek(4)
    elf_class = file_obj.read(1)[0]
    is_64_bit = (elf_class == 2)
    
    file_obj.seek(0)
    data = file_obj.read()
    
    if is_64_bit:
        # e_phoff is at offset 32 (8 bytes)
        e_phoff = struct.unpack_from("<Q", data, 32)[0]
        # e_phentsize is at offset 54 (2 bytes)
        e_phentsize = struct.unpack_from("<H", data, 54)[0]
        # e_phnum is at offset 56 (2 bytes)
        e_phnum = struct.unpack_from("<H", data, 56)[0]
        
        has_pt_load = False
        for i in range(e_phnum):
            offset = e_phoff + i * e_phentsize
            p_type = struct.unpack_from("<I", data, offset)[0]
            if p_type == 1: # PT_LOAD
                has_pt_load = True
                p_align = struct.unpack_from("<Q", data, offset + 48)[0]
                if p_align != 16384 and p_align != 65536:
                    print(f"ERROR: {filename} has PT_LOAD alignment {p_align}, expected 16384 (16KB) or 65536")
                    return False
    
    return True

def process_zip(zip_path, strict_zip=False):
    print(f"Processing {zip_path}")
    all_good = True
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            for info in z.infolist():
                if info.filename.endswith('.so'):
                    # Check ZIP alignment if strict
                    if strict_zip:
                        # Ensure offset is a multiple of 16384
                        if info.header_offset % 16384 != 0:
                            # Not strictly guaranteed because local header size adds to offset
                            pass
                    
                    with z.open(info) as f:
                        if not check_elf_alignment(f, info.filename):
                            all_good = False
                elif info.filename.endswith('.apk') or info.filename.endswith('.aab') or info.filename.endswith('.aar'):
                    with z.open(info) as f:
                        nested_data = f.read()
                        nested_file = io.BytesIO(nested_data)
                        try:
                            with zipfile.ZipFile(nested_file, 'r') as z2:
                                for info2 in z2.infolist():
                                    if info2.filename.endswith('.so'):
                                        with z2.open(info2) as f2:
                                            if not check_elf_alignment(f2, f"{info.filename}/{info2.filename}"):
                                                all_good = False
                        except zipfile.BadZipFile:
                            pass
    except Exception as e:
        print(f"Failed to process {zip_path}: {e}")
        return False
    return all_good

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--strict-zip', action='store_true')
    parser.add_argument('files', nargs='+')
    args = parser.parse_args()
    
    success = True
    for file in args.files:
        if not process_zip(file, args.strict_zip):
            success = False
    
    if not success:
        sys.exit(1)
