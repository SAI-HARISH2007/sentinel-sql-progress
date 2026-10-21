#!/usr/bin/env python3
"""Generate the ER diagram documents from the frozen schema fingerprint, so they can never drift from the real schema.

    python3 scripts/gen_er_docs.py

Reads  reference/schema_fingerprint_week10.txt   (written by scripts/compare_to_reference.sh --update)
Writes week-01-intro-er-design/docs/er-diagram.md   (Mermaid diagram + entity table, renders on GitHub)
       week-01-intro-er-design/docs/er-diagram.dbml (paste into https://dbdiagram.io for a drawn diagram)

(The original one-shot project had a hand-written .dbml with enum values and column sizes that did not exist in
its own schema. Generating the file removes that whole class of mistake.)
"""
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FP = ROOT / "reference" / "schema_fingerprint_week10.txt"
OUT_MD = ROOT / "week-01-intro-er-design" / "docs" / "er-diagram.md"
OUT_DBML = ROOT / "week-01-intro-er-design" / "docs" / "er-diagram.dbml"

cols = defaultdict(list)          # table -> [(pos, name, type, nullable, default, extra)]
pk = defaultdict(list)            # table -> [col]
uniq = defaultdict(lambda: defaultdict(list))   # table -> index_name -> [col]
fks = []                          # (table, constraint, col, ref_table, ref_col, delete_rule)
views = set()
kind_of = {}

for line in FP.read_text(encoding="utf-8").splitlines():
    f = line.split("\t")
    k = f[0]
    if k == "VIEW":
        views.add(f[1])
    elif k == "COLUMN":
        cols[f[1]].append((int(f[2]), f[3], f[4], f[5], f[6], f[7]))
    elif k == "INDEX":
        _, table, idx, seq, col, non_unique = f[:6]
        if idx == "PRIMARY":
            pk[table].append(col)
        elif non_unique == "0":
            uniq[table][idx].append(col)
    elif k == "FK":
        fks.append((f[1], f[2], f[3], f[4], f[5], f[7] if len(f) > 7 else ""))
        # fingerprint FK row: kind, table, constraint, column, ref_table, ref_column, delete_rule, update_rule
        fks[-1] = (f[1], f[2], f[3], f[4], f[5], f[6])

tables = sorted(t for t in cols if t not in views)

def base(t):                      # "varchar(100)" -> "varchar"
    return t.split("(")[0].split(" ")[0]

fk_cols = {(t, c) for t, _, c, _, _, _ in fks}
single_unique = {(t, cs[0]) for t, d in uniq.items() for cs in d.values() if len(cs) == 1}

def nullable(table, col):
    return next(c[3] for c in cols[table] if c[1] == col) == "YES"

verbs = {
    ("users", "accounts"): "owns", ("accounts", "transactions"): "makes", ("merchants", "transactions"): "receives",
    ("devices", "transactions"): "used in", ("locations", "transactions"): "happens at",
    ("accounts", "account_devices"): "uses", ("devices", "account_devices"): "known on",
    ("transactions", "alerts"): "flagged as", ("accounts", "behaviour_baselines"): "has baseline",
    ("merchant_categories", "merchants"): "classifies", ("accounts", "login_history"): "logs in",
    ("devices", "login_history"): "used for", ("locations", "login_history"): "from",
}

# ------------------------------------------------------------------ Mermaid
m = ["erDiagram"]
for table, _cn, col, ref_t, _rc, _dr in sorted(fks):
    one_to_one = (table, col) in single_unique
    parent = "||" if not nullable(table, col) else "|o"
    child = "o|" if one_to_one else "o{"
    m.append(f'    {ref_t} {parent}--{child} {table} : "{verbs.get((ref_t, table), "has")}"')
m.append("")
for t in tables:
    m.append(f"    {t} {{")
    for _pos, name, ctype, nul, _d, extra in sorted(cols[t]):
        tags = []
        if name in pk[t]:
            tags.append("PK")
        if (t, name) in fk_cols:
            tags.append("FK")
        if (t, name) in single_unique and name not in pk[t]:
            tags.append("UK")
        comment = '"' + ("optional" if nul == "YES" and name not in pk[t] else "") + '"' if (nul == "YES" and name not in pk[t]) else ""
        m.append(f"        {base(ctype)} {name} {','.join(tags)} {comment}".rstrip())
    m.append("    }")
mermaid = "\n".join(m)

table_rows = ["| Table | Primary key | Columns | Foreign keys |", "|---|---|---|---|"]
for t in tables:
    fk_list = ", ".join(f"`{c}` → `{rt}`" for tt, _n, c, rt, _rc, _d in sorted(fks) if tt == t) or "—"
    table_rows.append(f"| `{t}` | {', '.join('`'+c+'`' for c in pk[t])} | {len(cols[t])} | {fk_list} |")

rule_rows = ["| Foreign key | Parent → child | ON DELETE |", "|---|---|---|"]
for t, name, c, rt, rc, dr in sorted(fks):
    rule_rows.append(f"| `{name}` | `{rt}.{rc}` ← `{t}.{c}` | {dr} |")

OUT_MD.write_text(f"""# ER diagram — Sentinel

> **Generated** by `scripts/gen_er_docs.py` from the real schema (`reference/schema_fingerprint_week10.txt`). Do not edit by hand;
> change the schema, rebuild, run `scripts/compare_to_reference.sh --update`, then `python3 scripts/gen_er_docs.py`.
> Reading the diagram: `||` exactly one, `o|` zero or one, `o{{` zero or many. `PK` primary key, `FK` foreign key, `UK` unique key.
> In the lab you will *draw* this in the notation your faculty uses (rectangles, ellipses, diamonds - see `materials/src/NOTES/Key_features of ER.jpeg`
> in your DBMS study folder). This is the same content in a machine-drawn form. For the exam notation, translate it by hand.

```mermaid
{mermaid}
```

## The 13 entities

{chr(10).join(table_rows)}

## Foreign keys and their delete rules

{chr(10).join(rule_rows)}

`CASCADE` = deleting the parent deletes the children. `RESTRICT` = the parent cannot be deleted while children exist.
How each rule turned into a table is explained in [`er-to-relational.md`](er-to-relational.md).
""", encoding="utf-8")

# ------------------------------------------------------------------ DBML
d = ["// Sentinel — generated by scripts/gen_er_docs.py from the real schema. Paste into https://dbdiagram.io", ""]
for t in tables:
    d.append(f"Table {t} {{")
    for _pos, name, ctype, nul, default, extra in sorted(cols[t]):
        attrs = []
        if name in pk[t] and len(pk[t]) == 1:
            attrs.append("pk")
        if "auto_increment" in extra:
            attrs.append("increment")
        if nul == "NO" and name not in pk[t]:
            attrs.append("not null")
        if (t, name) in single_unique and name not in pk[t]:
            attrs.append("unique")
        if default not in ("<NULL>",) and "auto_increment" not in extra:
            if default.upper().startswith("CURRENT_TIMESTAMP"):
                attrs.append("default: `now()`")
            elif default.replace(".", "", 1).lstrip("-").isdigit():
                attrs.append(f"default: {default}")
            else:
                attrs.append(f"default: '{default}'")
        d.append(f"  {name} {ctype}" + (f" [{', '.join(attrs)}]" if attrs else ""))
    if len(pk[t]) > 1:
        d.append("")
        d.append("  indexes {")
        d.append(f"    ({', '.join(pk[t])}) [pk]")
        d.append("  }")
    d.append("}")
    d.append("")
for t, _n, c, rt, rc, dr in sorted(fks):
    d.append(f"Ref: {t}.{c} > {rt}.{rc} [delete: {dr.lower()}]")
OUT_DBML.write_text("\n".join(d) + "\n", encoding="utf-8")
print("wrote", OUT_MD.relative_to(ROOT), "and", OUT_DBML.relative_to(ROOT))
