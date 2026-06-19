#!/usr/bin/env python3
import hashlib
import os
import sys

def calculate_checksum(path: str) -> str:
    if not os.path.exists(path):
        print(f"Error: File not found: {path}", file=sys.stderr)
        sys.exit(1)
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: checksum.py <path-to-file>", file=sys.stderr)
        sys.exit(1)
    
    path = sys.argv[1]
    checksum = calculate_checksum(path)
    print(checksum)

if __name__ == "__main__":
    main()
