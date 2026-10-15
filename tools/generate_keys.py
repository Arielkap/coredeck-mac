#!/usr/bin/env python3
"""
CoreDeck Pro License Key Generator
Mints valid cryptographic format license keys and saves them to licenses.json.
"""

import sys
import os
import json
import secrets
import string

DIR = os.path.dirname(os.path.abspath(__file__))
PROJECTS_DIR = os.path.abspath(os.path.join(DIR, "..", ".."))
LICENSES_FILE = os.path.join(PROJECTS_DIR, "licenses.json")

def generate_key(prefix="CORE-PRO"):
    chars = string.ascii_uppercase + string.digits
    part1 = ''.join(secrets.choice(chars) for _ in range(4))
    part2 = ''.join(secrets.choice(chars) for _ in range(4))
    part3 = ''.join(secrets.choice(chars) for _ in range(4))
    return f"{prefix}-{part1}-{part2}-{part3}"

def mint_keys(count=10, prefix="CORE-PRO"):
    existing = {"keys": []}
    if os.path.exists(LICENSES_FILE):
        try:
            with open(LICENSES_FILE, "r") as f:
                existing = json.load(f)
        except Exception:
            existing = {"keys": []}
            
    keys_set = set(existing.get("keys", []))
    new_keys = []
    
    for _ in range(count):
        k = generate_key(prefix)
        while k in keys_set:
            k = generate_key(prefix)
        keys_set.add(k)
        new_keys.append(k)
        
    existing["keys"] = list(keys_set)
    with open(LICENSES_FILE, "w") as f:
        json.dump(existing, f, indent=2)
        
    return new_keys

if __name__ == "__main__":
    qty = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    pref = sys.argv[2] if len(sys.argv) > 2 else "CORE-PRO"
    minted = mint_keys(qty, pref)
    print(f"✨ Minted {len(minted)} new CoreDeck Pro keys:")
    for k in minted:
        print(f"  {k}")
