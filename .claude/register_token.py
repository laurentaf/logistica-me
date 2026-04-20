#!/usr/bin/env python3
"""Quick executable to incrementally register token usage."""
import sys
from datetime import datetime

def register_token(operation, tokens):
    """Append a single token usage row to tokens.md."""
    date = datetime.now().strftime("%Y-%m-%d")
    line = f"| {date} | {operation} | {tokens} |\n"

    with open(".claude/tokens.md", "a") as f:
        f.write(line)

    print(f"Registered: {line.strip()}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: register_token.py '<operation>' <tokens>")
        print("Example: register_token.py 'Download CSV' 2500")
        sys.exit(1)

    operation = sys.argv[1]
    tokens = sys.argv[2]
    register_token(operation, tokens)
