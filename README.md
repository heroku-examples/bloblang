# blobl.sh

A simple, flexible Bash script to run [Bloblang](https://www.benthos.dev/docs/bloblang/about) mappings using [Benthos](https://www.benthos.dev).

It supports:
- Reading input from stdin or a file (.json or .jsonl)
- Writing output to stdout or a file
- Inline mapping strings
- Mapping from a .blobl file
- Auto-compacting pretty-printed JSON files
- Clean handling of partial JSON line inputs

---

## Installation

1. **Install Benthos**

On macOS:

```bash
brew install benthos
```

Or manually download a binary from [Benthos GitHub releases](https://github.com/benthosdev/benthos/releases).

Check installation:

```bash
benthos -v
```

Make sure you have version 4.x or later.

2. **Install blobl.sh**

Save the script `blobl.sh` locally and make it executable:

```bash
chmod +x blobl.sh
```

---

## Usage

```bash
./blobl.sh [-m mapping_string | -f mapping_file] [-i input_file] [-o output_file]
```

### Options:

| Flag | Description |
|:--|:--|
| `-m`, `--mapping` | **(Required)** Inline Bloblang mapping string |
| `-f`, `--mapping-file` | **(Required)** Path to a .blobl file containing a mapping |
| `-i`, `--input` | Input file (.json or .jsonl). Defaults to stdin |
| `-o`, `--output` | Output file. Defaults to stdout |
| `-h`, `--help` | Show help and usage information |

---

## Help Output

Run:

```bash
./blobl.sh -h
```

Outputs:

```
Usage: blobl.sh [-m mapping_string | -f mapping_file] [-i input_file] [-o output_file]

Options:
  -m, --mapping       Inline Bloblang mapping string.
  -f, --mapping-file  Path to a .blobl file containing a mapping.
  -i, --input         Input file (.json or .jsonl). Defaults to stdin.
  -o, --output        Output file. Defaults to stdout.
  -h, --help          Show this help message.

Notes:
  - Either -m or -f must be specified, but not both.
  - If input is a .json file, it will be automatically converted to .jsonl internally.
  - The script automatically cleans up temporary files created during conversion.
```

---

## Why .jsonl Files?

**.jsonl (JSON Lines)** format means each line contains exactly **one complete JSON object**.

Example `.jsonl` file:

```
{"foo": "bar"}
{"foo": "baz"}
{"foo": "qux"}
```

Each line is treated as a separate message by `benthos blobl`.

- ✅ Correct: One JSON object per line
- ❌ Incorrect: A single large array `[ {...}, {...} ]`

If you provide a `.json` file instead of `.jsonl`, `blobl.sh` will automatically compact it line-by-line using `jq`.

---

## Examples

### 1. Read from stdin, output to stdout

```bash
printf '{"foo":"bar"}\n' | ./blobl.sh -m 'root = this.foo.uppercase()'
```

Output:

```json
"BAR"
```

---

### 2. Read from .jsonl file, output to stdout

```bash
./blobl.sh -m 'root = this.foo.uppercase()' -i events.jsonl
```

---

### 3. Read from .json (pretty-printed) file, output to stdout

```bash
./blobl.sh -m 'root = this.foo.uppercase()' -i event.json
```

The script will auto-compact the input behind the scenes.

---

### 4. Read from stdin, write to a file

```bash
printf '{"foo":"bar"}\n' | ./blobl.sh -m 'root = this.foo.uppercase()' -o output.jsonl
```

---

### 5. Read from a file, write to another file

```bash
./blobl.sh -m 'root = this.foo.uppercase()' -i events.jsonl -o output.jsonl
```

---

## Complex Example: Modifying a Field

In this example, we use the provided sample files:

- **event.json** — Pretty-printed JSON input
- **events.jsonl** — Compact one-line JSON input
- **event.blobl** — Mapping file to modify `CreatedById`

The goal is to update the `CreatedById` field while preserving the rest of the data.

---

### Input JSON (event.json or events.jsonl):

```json
{
  "Account__c": { "string": "Dickenson plc" },
  "Amount__c": { "double": 15000 },
  "CreatedById": "005bm00000AWUWfAAP",
  "CreatedDate": 1736968069554,
  "Subsidiary__c": { "string": "ACME UK Ltd" }
}
```

---

### (A) Using the `event.json` file

Run:

```bash
./blobl.sh -i event.json -f event.blobl
```

✅ The `.json` file will be auto-compacted internally.

---

### (B) Using the `events.jsonl` file

Run:

```bash
./blobl.sh -i events.jsonl -f event.blobl
```

✅ The `.jsonl` file is already compact, so no transformation is needed.

---

### Mapping (event.blobl):

```bloblang
root = this
root.CreatedById = "005bm00000ZZZZZ"
```

✅ This mapping copies the original event and replaces `CreatedById` with the new ID.

---

## About the Sleep Hack

A tiny `sleep 0.1` is inserted after the input command to **force a proper EOF signal** into Benthos.

Without it:
- Benthos might wait indefinitely for more input.
- Particularly when piping very short inputs.

This ensures:
- Benthos flushes and processes the message immediately.
- Outputs appear without needing manual Enter presses.

---

Enjoy piping JSON through Bloblang!
