#!/usr/bin/env python3
"""Verificador y simulador determinista para ep3_sonido_vivo.js (BDY1103 EP3 - MongoDB)."""

from __future__ import annotations

import copy
import datetime as dt
from decimal import Decimal
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any


BASE_DIR = Path(__file__).resolve().parent
SCRIPT_PATH = BASE_DIR / "ep3_sonido_vivo.js"
OUTPUT_PATH = BASE_DIR / "salida_verificacion_ep3.txt"


class Int32(int):
    """Representa explícitamente un entero BSON de 32 bits (NumberInt)."""


class SchemaValidationError(Exception):
    """Error lanzado cuando un documento incumple el validador $jsonSchema."""


class DuplicateKeyError(Exception):
    """Error lanzado al violar un índice único."""


# ---------------------------------------------------------------------------
# Parser ligero de literales y sentencias mongosh desde ep3_sonido_vivo.js
# ---------------------------------------------------------------------------

def strip_js_comments(source: str) -> str:
    """Elimina comentarios // y /* */ respetando literales de cadena."""
    out: list[str] = []
    i = 0
    n = len(source)
    in_str: str | None = None
    while i < n:
        ch = source[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(source[i + 1])
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
        else:
            if ch in ('"', "'"):
                in_str = ch
                out.append(ch)
                i += 1
            elif ch == "/" and i + 1 < n and source[i + 1] == "/":
                while i < n and source[i] != "\n":
                    i += 1
            elif ch == "/" and i + 1 < n and source[i + 1] == "*":
                i += 2
                while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
                    i += 1
                i += 2
            else:
                out.append(ch)
                i += 1
    return "".join(out)


def tokenize_js(expr: str) -> list[tuple[str, str]]:
    """Tokeniza expresiones de objetos/arreglos de mongosh."""
    tokens: list[tuple[str, str]] = []
    i = 0
    n = len(expr)
    while i < n:
        ch = expr[i]
        if ch.isspace():
            i += 1
            continue
        if ch in ('"', "'"):
            quote = ch
            i += 1
            buf: list[str] = []
            while i < n:
                c = expr[i]
                if c == "\\" and i + 1 < n:
                    nxt = expr[i + 1]
                    escapes = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'"}
                    buf.append(escapes.get(nxt, nxt))
                    i += 2
                    continue
                if c == quote:
                    i += 1
                    break
                buf.append(c)
                i += 1
            tokens.append(("STRING", "".join(buf)))
            continue
        if ch in "{}[]():,.":
            tokens.append((ch, ch))
            i += 1
            continue
        if ch == "-" or ch.isdigit():
            j = i
            if expr[j] == "-":
                j += 1
            has_dot = False
            while j < n and (expr[j].isdigit() or (expr[j] == "." and not has_dot)):
                if expr[j] == ".":
                    has_dot = True
                j += 1
            tokens.append(("NUMBER", expr[i:j]))
            i = j
            continue
        if ch.isalpha() or ch in ("_", "$"):
            j = i
            while j < n and (expr[j].isalnum() or expr[j] in ("_", "$")):
                j += 1
            tokens.append(("IDENT", expr[i:j]))
            i = j
            continue
        raise ValueError(f"Token JS inesperado '{ch}' cerca de: {expr[max(0, i-20):i+20]}")
    return tokens


class JsLiteralParser:
    """Convierte argumentos literales de mongosh a estructuras Python tipadas."""

    def __init__(self, tokens: list[tuple[str, str]]) -> None:
        self.tokens = tokens
        self.pos = 0

    def peek(self, offset: int = 0) -> tuple[str, str] | None:
        idx = self.pos + offset
        return self.tokens[idx] if idx < len(self.tokens) else None

    def consume(self, expected_kind: str | None = None) -> tuple[str, str]:
        tok = self.peek()
        if tok is None:
            raise ValueError("Fin inesperado de expresión JS")
        if expected_kind is not None and tok[0] != expected_kind:
            raise ValueError(f"Se esperaba {expected_kind}, se obtuvo {tok}")
        self.pos += 1
        return tok

    def parse_arg_list(self) -> list[Any]:
        args: list[Any] = []
        while self.peek() is not None:
            args.append(self.parse_value())
            nxt = self.peek()
            if nxt and nxt[0] == ",":
                self.consume(",")
            else:
                break
        return args

    def parse_value(self) -> Any:
        tok = self.peek()
        if tok is None:
            raise ValueError("Se esperaba un valor JS")
        kind, val = tok
        if kind == "{":
            return self.parse_object()
        if kind == "[":
            return self.parse_array()
        if kind == "STRING":
            self.consume()
            return val
        if kind == "NUMBER":
            self.consume()
            return float(val) if "." in val else int(val)
        if kind == "IDENT":
            if val == "true":
                self.consume()
                return True
            if val == "false":
                self.consume()
                return False
            if val == "null":
                self.consume()
                return None
            if val in ("NumberDecimal", "NumberInt"):
                self.consume()
                self.consume("(")
                inner = self.parse_value()
                self.consume(")")
                return Decimal(str(inner)) if val == "NumberDecimal" else Int32(int(inner))
            if val == "new":
                self.consume()
                cls_tok = self.consume("IDENT")
                if cls_tok[1] != "Date":
                    raise ValueError(f"Constructor no soportado: new {cls_tok[1]}")
                self.consume("(")
                iso_str = self.parse_value()
                self.consume(")")
                return dt.datetime.fromisoformat(str(iso_str).replace("Z", "+00:00"))
        raise ValueError(f"Valor JS no soportado: {tok}")

    def parse_object(self) -> dict[str, Any]:
        obj: dict[str, Any] = {}
        self.consume("{")
        while self.peek() and self.peek()[0] != "}":
            key_tok = self.consume()
            if key_tok[0] not in ("IDENT", "STRING"):
                raise ValueError(f"Clave de objeto inválida: {key_tok}")
            self.consume(":")
            obj[key_tok[1]] = self.parse_value()
            if self.peek() and self.peek()[0] == ",":
                self.consume(",")
        self.consume("}")
        return obj

    def parse_array(self) -> list[Any]:
        arr: list[Any] = []
        self.consume("[")
        while self.peek() and self.peek()[0] != "]":
            arr.append(self.parse_value())
            if self.peek() and self.peek()[0] == ",":
                self.consume(",")
        self.consume("]")
        return arr


def parse_js_args(arg_src: str) -> list[Any]:
    tokens = tokenize_js(arg_src)
    parser = JsLiteralParser(tokens)
    return parser.parse_arg_list()


def find_matching_paren(text: str, open_idx: int) -> int:
    """Encuentra el paréntesis de cierre respetando cadenas."""
    depth = 0
    i = open_idx
    n = len(text)
    in_str: str | None = None
    while i < n:
        ch = text[i]
        if in_str:
            if ch == "\\" and i + 1 < n:
                i += 2
                continue
            if ch == in_str:
                in_str = None
        else:
            if ch in ('"', "'"):
                in_str = ch
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    raise ValueError("Paréntesis sin cierre en script JS")


def extract_db_calls(clean_js: str) -> list[dict[str, Any]]:
    """Extrae en orden secuencial todas las llamadas db.<obj>.<metodo>(...) o db.createCollection(...)."""
    calls: list[dict[str, Any]] = []
    pattern = re.compile(r"\bdb\.([a-zA-Z0-9_]+)(?:\.([a-zA-Z0-9_]+))?\s*\(")
    pos = 0
    while True:
        m = pattern.search(clean_js, pos)
        if not m:
            break
        first = m.group(1)
        second = m.group(2)
        open_idx = m.end() - 1
        close_idx = find_matching_paren(clean_js, open_idx)
        arg_src = clean_js[open_idx + 1 : close_idx]

        # Ignorar db.getSiblingDB(...)
        if first == "getSiblingDB" and second is None:
            pos = close_idx + 1
            continue

        # Detectar encadenamiento .sort({...}) tras find(...)
        tail = clean_js[close_idx + 1 : close_idx + 150]
        sort_spec = None
        sort_match = re.match(r"\s*\.sort\s*\(", tail)
        if sort_match:
            sort_open = close_idx + 1 + sort_match.end() - 1
            sort_close = find_matching_paren(clean_js, sort_open)
            sort_spec = parse_js_args(clean_js[sort_open + 1 : sort_close])[0]
            pos = sort_close + 1
        else:
            pos = close_idx + 1

        if second is None:
            calls.append({
                "collection": None,
                "method": first,
                "args": parse_js_args(arg_src),
                "sort": sort_spec,
            })
        else:
            calls.append({
                "collection": first,
                "method": second,
                "args": parse_js_args(arg_src),
                "sort": sort_spec,
            })
    return calls


# ---------------------------------------------------------------------------
# Motor simulador MongoDB (Validador $jsonSchema, CRUD, Índices, Aggregation)
# ---------------------------------------------------------------------------

def check_bson_type(val: Any, expected: str | list[str]) -> bool:
    types = [expected] if isinstance(expected, str) else expected
    for t in types:
        if t == "object" and isinstance(val, dict):
            return True
        if t == "array" and isinstance(val, list):
            return True
        if t == "string" and isinstance(val, str):
            return True
        if t == "bool" and isinstance(val, bool):
            return True
        if t == "int" and isinstance(val, int) and not isinstance(val, bool):
            return True
        if t == "long" and isinstance(val, int) and not isinstance(val, bool):
            return True
        if t == "double" and isinstance(val, float):
            return True
        if t == "decimal" and isinstance(val, Decimal):
            return True
        if t == "date" and isinstance(val, dt.datetime):
            return True
    return False


def validate_json_schema(value: Any, schema: dict[str, Any], path: str = "$") -> None:
    if "bsonType" in schema:
        if not check_bson_type(value, schema["bsonType"]):
            raise SchemaValidationError(
                f"Campo '{path}' esperaba bsonType {schema['bsonType']}, recibió {type(value).__name__}"
            )
    if "enum" in schema and value not in schema["enum"]:
        raise SchemaValidationError(
            f"Campo '{path}'='{value}' no pertenece a enum permitido {schema['enum']}"
        )
    if isinstance(value, str):
        if "minLength" in schema and len(value) < schema["minLength"]:
            raise SchemaValidationError(
                f"Campo '{path}' tiene longitud menor a minLength={schema['minLength']}"
            )
        if "pattern" in schema and not re.search(schema["pattern"], value):
            raise SchemaValidationError(
                f"Campo '{path}'='{value}' no cumple patrón /{schema['pattern']}/"
            )
    if isinstance(value, (int, float, Decimal)) and not isinstance(value, bool):
        num = Decimal(str(value))
        if "minimum" in schema and num < Decimal(str(schema["minimum"])):
            raise SchemaValidationError(
                f"Campo '{path}'={value} es menor al mínimo permitido ({schema['minimum']})"
            )
        if "maximum" in schema and num > Decimal(str(schema["maximum"])):
            raise SchemaValidationError(
                f"Campo '{path}'={value} supera el máximo permitido ({schema['maximum']})"
            )
    if isinstance(value, list):
        if "minItems" in schema and len(value) < schema["minItems"]:
            raise SchemaValidationError(
                f"Arreglo '{path}' requiere al menos {schema['minItems']} elemento(s)"
            )
        if "items" in schema:
            for idx, elem in enumerate(value):
                validate_json_schema(elem, schema["items"], f"{path}[{idx}]")
    if isinstance(value, dict):
        for req in schema.get("required", []):
            if req not in value:
                raise SchemaValidationError(f"Falta campo obligatorio '{path}.{req}'")
        props = schema.get("properties", {})
        for k, subschema in props.items():
            if k in value:
                validate_json_schema(value[k], subschema, f"{path}.{k}")


def get_by_dot(doc: dict[str, Any], path: str) -> tuple[bool, Any]:
    """Obtiene valor mediante Dot Notation. Soporta campos anidados y arrays."""
    parts = path.split(".")
    curr: Any = doc
    for p in parts:
        if isinstance(curr, dict) and p in curr:
            curr = curr[p]
        else:
            return False, None
    return True, curr


def set_by_dot(doc: dict[str, Any], path: str, value: Any) -> None:
    parts = path.split(".")
    curr = doc
    for p in parts[:-1]:
        if p not in curr or not isinstance(curr[p], dict):
            curr[p] = {}
        curr = curr[p]
    curr[parts[-1]] = value


def cmp_values(a: Any, b: Any) -> int:
    if isinstance(a, (int, float, Decimal)) and isinstance(b, (int, float, Decimal)):
        da, db_val = Decimal(str(a)), Decimal(str(b))
        return -1 if da < db_val else (1 if da > db_val else 0)
    return -1 if a < b else (1 if a > b else 0)


def match_condition(val: Any, cond: Any) -> bool:
    if isinstance(cond, dict):
        for op, target in cond.items():
            if op == "$gt":
                if val is None or cmp_values(val, target) <= 0:
                    return False
            elif op == "$gte":
                if val is None or cmp_values(val, target) < 0:
                    return False
            elif op == "$lt":
                if val is None or cmp_values(val, target) >= 0:
                    return False
            elif op == "$lte":
                if val is None or cmp_values(val, target) > 0:
                    return False
            elif op == "$in":
                if isinstance(val, list):
                    if not any(v in target for v in val):
                        return False
                elif val not in target:
                    return False
            elif op == "$elemMatch":
                if not isinstance(val, list):
                    return False
                if not any(isinstance(elem, dict) and match_query(elem, target) for elem in val):
                    return False
            else:
                raise ValueError(f"Operador de consulta no soportado: {op}")
        return True
    if isinstance(val, list):
        return cond in val
    return val == cond


def match_query(doc: dict[str, Any], query: dict[str, Any]) -> bool:
    for k, cond in query.items():
        if k == "$or":
            if not any(match_query(doc, subq) for subq in cond):
                return False
        else:
            found, val = get_by_dot(doc, k)
            if not found:
                return False
            if not match_condition(val, cond):
                return False
    return True


def project_doc(doc: dict[str, Any], proj: dict[str, Any] | None) -> dict[str, Any]:
    if not proj:
        return copy.deepcopy(doc)
    include_keys = [k for k, v in proj.items() if v == 1]
    exclude_id = proj.get("_id") == 0
    if include_keys:
        out: dict[str, Any] = {}
        if not exclude_id and "_id" in doc:
            out["_id"] = doc["_id"]
        for k in include_keys:
            found, val = get_by_dot(doc, k)
            if found:
                set_by_dot(out, k, copy.deepcopy(val))
        return out
    out = copy.deepcopy(doc)
    for k, v in proj.items():
        if v == 0 and k in out:
            del out[k]
    return out


class MongoCollection:
    def __init__(self, name: str, schema: dict[str, Any] | None = None) -> None:
        self.name = name
        self.schema = schema
        self.docs: list[dict[str, Any]] = []
        self.indexes: list[dict[str, Any]] = [{"name": "_id_", "key": {"_id": 1}, "unique": True}]
        self._id_seq = 1

    def create_index(self, keys: dict[str, int], options: dict[str, Any] | None = None) -> None:
        opts = options or {}
        self.indexes.append({
            "name": opts.get("name", "_".join(keys.keys())),
            "key": keys,
            "unique": bool(opts.get("unique", False)),
        })

    def _validate_doc(self, doc: dict[str, Any]) -> None:
        if self.schema:
            validate_json_schema(doc, self.schema)
        for idx in self.indexes:
            if idx.get("unique") and idx["name"] != "_id_":
                fields = list(idx["key"].keys())
                sig = tuple(get_by_dot(doc, f)[1] for f in fields)
                for existing in self.docs:
                    if existing.get("_id") == doc.get("_id"):
                        continue
                    ex_sig = tuple(get_by_dot(existing, f)[1] for f in fields)
                    if sig == ex_sig:
                        raise DuplicateKeyError(f"Índice único '{idx['name']}' duplicado: {sig}")

    def insert_one(self, doc: dict[str, Any]) -> None:
        d = copy.deepcopy(doc)
        if "_id" not in d:
            d["_id"] = f"oid_{self.name}_{self._id_seq:04d}"
            self._id_seq += 1
        self._validate_doc(d)
        self.docs.append(d)

    def insert_many(self, docs: list[dict[str, Any]]) -> None:
        for d in docs:
            self.insert_one(d)

    def find(
        self,
        query: dict[str, Any] | None = None,
        proj: dict[str, Any] | None = None,
        sort_spec: dict[str, int] | None = None,
    ) -> list[dict[str, Any]]:
        q = query or {}
        matched = [copy.deepcopy(d) for d in self.docs if match_query(d, q)]
        if sort_spec:
            for field, direction in reversed(list(sort_spec.items())):
                matched.sort(
                    key=lambda x: Decimal(str(get_by_dot(x, field)[1]))
                    if isinstance(get_by_dot(x, field)[1], (int, float, Decimal))
                    else get_by_dot(x, field)[1],
                    reverse=(direction == -1),
                )
        return [project_doc(d, proj) for d in matched]

    def _apply_update(self, doc: dict[str, Any], update: dict[str, Any]) -> bool:
        updated = copy.deepcopy(doc)
        changed = False
        if "$inc" in update:
            for k, delta in update["$inc"].items():
                _, cur = get_by_dot(updated, k)
                if cur is None:
                    cur = 0
                if isinstance(cur, Decimal) or isinstance(delta, Decimal):
                    new_val: Any = Decimal(str(cur)) + Decimal(str(delta))
                elif isinstance(cur, Int32) or isinstance(delta, Int32):
                    new_val = Int32(int(cur) + int(delta))
                else:
                    new_val = cur + delta
                set_by_dot(updated, k, new_val)
                changed = True
        if "$set" in update:
            for k, val in update["$set"].items():
                set_by_dot(updated, k, copy.deepcopy(val))
                changed = True
        if "$addToSet" in update:
            for k, val in update["$addToSet"].items():
                _, arr = get_by_dot(updated, k)
                if arr is None:
                    arr = []
                    set_by_dot(updated, k, arr)
                if val not in arr:
                    arr.append(copy.deepcopy(val))
                    changed = True
        if "$push" in update:
            for k, val in update["$push"].items():
                _, arr = get_by_dot(updated, k)
                if arr is None:
                    arr = []
                    set_by_dot(updated, k, arr)
                arr.append(copy.deepcopy(val))
                changed = True
        self._validate_doc(updated)
        doc.clear()
        doc.update(updated)
        return changed

    def update_one(self, query: dict[str, Any], update: dict[str, Any]) -> tuple[int, int]:
        for d in self.docs:
            if match_query(d, query):
                mod = 1 if self._apply_update(d, update) else 0
                return 1, mod
        return 0, 0

    def update_many(self, query: dict[str, Any], update: dict[str, Any]) -> tuple[int, int]:
        matched = 0
        modified = 0
        for d in self.docs:
            if match_query(d, query):
                matched += 1
                if self._apply_update(d, update):
                    modified += 1
        return matched, modified

    def delete_one(self, query: dict[str, Any]) -> int:
        for i, d in enumerate(self.docs):
            if match_query(d, query):
                self.docs.pop(i)
                return 1
        return 0

    def delete_many(self, query: dict[str, Any]) -> int:
        before = len(self.docs)
        self.docs = [d for d in self.docs if not match_query(d, query)]
        return before - len(self.docs)


class MongoSimulator:
    def __init__(self) -> None:
        self.collections: dict[str, MongoCollection] = {}

    def drop(self, name: str) -> None:
        self.collections.pop(name, None)

    def create_collection(self, name: str, opts: dict[str, Any]) -> None:
        schema = opts.get("validator", {}).get("$jsonSchema")
        self.collections[name] = MongoCollection(name, schema)

    def aggregate(self, coll_name: str, pipeline: list[dict[str, Any]]) -> list[dict[str, Any]]:
        docs = copy.deepcopy(self.collections[coll_name].docs)
        for stage in pipeline:
            if "$match" in stage:
                docs = [d for d in docs if match_query(d, stage["$match"])]
            elif "$unwind" in stage:
                field = stage["$unwind"].lstrip("$")
                new_docs: list[dict[str, Any]] = []
                for d in docs:
                    arr = d.get(field, [])
                    for elem in arr:
                        nd = copy.deepcopy(d)
                        nd[field] = copy.deepcopy(elem)
                        new_docs.append(nd)
                docs = new_docs
            elif "$lookup" in stage:
                spec = stage["$lookup"]
                foreign_docs = self.collections[spec["from"]].docs
                for d in docs:
                    lval = get_by_dot(d, spec["localField"])[1]
                    matches = [
                        copy.deepcopy(fd)
                        for fd in foreign_docs
                        if get_by_dot(fd, spec["foreignField"])[1] == lval
                    ]
                    d[spec["as"]] = matches
            elif "$group" in stage:
                spec = stage["$group"]
                id_expr = spec["_id"]
                groups: dict[Any, list[dict[str, Any]]] = {}
                for d in docs:
                    key = get_by_dot(d, id_expr.lstrip("$"))[1] if isinstance(id_expr, str) and id_expr.startswith("$") else id_expr
                    groups.setdefault(key, []).append(d)
                grouped: list[dict[str, Any]] = []
                for gkey, gdocs in groups.items():
                    row: dict[str, Any] = {"_id": gkey}
                    for out_field, acc in spec.items():
                        if out_field == "_id":
                            continue
                        if "$first" in acc:
                            src = acc["$first"].lstrip("$")
                            row[out_field] = get_by_dot(gdocs[0], src)[1]
                        elif "$sum" in acc:
                            expr = acc["$sum"]
                            if expr == 1:
                                row[out_field] = len(gdocs)
                            else:
                                src = expr.lstrip("$")
                                vals = [get_by_dot(gd, src)[1] for gd in gdocs]
                                if any(isinstance(v, Decimal) for v in vals):
                                    row[out_field] = sum((Decimal(str(v)) for v in vals), Decimal("0"))
                                else:
                                    row[out_field] = sum(vals)
                        elif "$avg" in acc:
                            src = acc["$avg"].lstrip("$")
                            vals = [float(get_by_dot(gd, src)[1]) for gd in gdocs]
                            row[out_field] = sum(vals) / len(vals)
                    grouped.append(row)
                docs = grouped
            elif "$project" in stage:
                spec = stage["$project"]
                projected: list[dict[str, Any]] = []
                for d in docs:
                    row: dict[str, Any] = {}
                    for k, expr in spec.items():
                        if k == "_id" and expr == 0:
                            continue
                        if expr == 1 and k in d:
                            row[k] = copy.deepcopy(d[k])
                        elif isinstance(expr, str) and expr.startswith("$"):
                            row[k] = get_by_dot(d, expr.lstrip("$"))[1]
                        elif isinstance(expr, dict) and "$round" in expr:
                            target_f, prec = expr["$round"]
                            row[k] = round(float(get_by_dot(d, target_f.lstrip("$"))[1]), int(prec))
                    projected.append(row)
                docs = projected
            elif "$sort" in stage:
                for field, direction in reversed(list(stage["$sort"].items())):
                    docs.sort(
                        key=lambda x: Decimal(str(get_by_dot(x, field)[1]))
                        if isinstance(get_by_dot(x, field)[1], (int, float, Decimal))
                        else get_by_dot(x, field)[1],
                        reverse=(direction == -1),
                    )
            else:
                raise ValueError(f"Etapa de agregación no soportada: {list(stage.keys())}")
        return docs


def json_default(obj: Any) -> Any:
    if isinstance(obj, Decimal):
        return f"NumberDecimal('{obj}')"
    if isinstance(obj, dt.datetime):
        return obj.isoformat()
    return str(obj)


def main() -> int:
    log_lines: list[str] = []

    def log(msg: str = "") -> None:
        print(msg)
        log_lines.append(msg)

    log("=========================================================================")
    log("  VERIFICACION DETERMINISTA EP3 BDY1103 - SONIDO VIVO (MONGODB 7.x)")
    log("=========================================================================")

    if not SCRIPT_PATH.exists():
        log(f"[FAIL] No existe {SCRIPT_PATH}")
        return 1

    raw_js = SCRIPT_PATH.read_text(encoding="utf-8")

    # 1. Verificación de sintaxis JS con Node.js si está disponible
    node_bin = shutil.which("node")
    syntax_ok = False
    if node_bin:
        proc = subprocess.run([node_bin, "--check", str(SCRIPT_PATH)], capture_output=True, text=True)
        if proc.returncode == 0:
            syntax_ok = True
            log(f"[OK] Sintaxis JavaScript validada con Node.js ({node_bin})")
        else:
            log(f"[FAIL] Error de sintaxis en ep3_sonido_vivo.js:\n{proc.stderr}")
            return 1
    else:
        log("[WARN] node.exe no encontrado; usando validación estructural Python")
        syntax_ok = True

    # Verificar presencia de las 7 fases
    missing_phases = [f"FASE {i}:" for i in range(1, 8) if f"FASE {i}:" not in raw_js]
    if missing_phases:
        log(f"[FAIL] Faltan fases en el script: {missing_phases}")
        return 1
    log("[OK] Estructura completa verificada: FASE 1 a FASE 7 presentes.")

    # 2. Extraer y ejecutar todas las operaciones reales del script
    clean_js = strip_js_comments(raw_js)
    calls = extract_db_calls(clean_js)
    log(f"[INFO] Sentencias mongosh extraidas y parseadas: {len(calls)}")

    sim = MongoSimulator()
    captured_reads: list[tuple[str, list[dict[str, Any]]]] = []
    captured_updates: list[tuple[str, tuple[int, int]]] = []
    captured_deletes: list[tuple[str, int]] = []
    negative_test_caught = False
    captured_aggs: list[list[dict[str, Any]]] = []

    for call in calls:
        coll_name = call["collection"]
        method = call["method"]
        args = call["args"]

        if coll_name is None and method == "createCollection":
            sim.create_collection(args[0], args[1])
            log(f"[FASE 1] Colección '{args[0]}' creada con validador $jsonSchema.")
        elif method == "drop":
            sim.drop(coll_name)
        elif method == "createIndex":
            opts = args[1] if len(args) > 1 else {}
            sim.collections[coll_name].create_index(args[0], opts)
            log(f"[FASE 1] Índice '{opts.get('name')}' creado en '{coll_name}'.")
        elif method == "insertMany":
            sim.collections[coll_name].insert_many(args[0])
            log(f"[FASE 2] insertMany en '{coll_name}': {len(args[0])} documentos insertados.")
        elif method == "insertOne":
            try:
                sim.collections[coll_name].insert_one(args[0])
                log(f"[CREATE] insertOne en '{coll_name}': código='{args[0].get('codigo') or args[0].get('codigo_pedido')}'.")
            except SchemaValidationError as exc:
                negative_test_caught = True
                log(f"[FASE 6 OK] Validador $jsonSchema rechazó documento inválido en '{coll_name}': {exc}")
        elif method == "find":
            q = args[0] if len(args) > 0 else {}
            proj = args[1] if len(args) > 1 else None
            res = sim.collections[coll_name].find(q, proj, call["sort"])
            captured_reads.append((coll_name, res))
            log(f"\n[READ #{len(captured_reads)}] db.{coll_name}.find(...) -> {len(res)} documento(s):")
            log(json.dumps(res, ensure_ascii=False, indent=2, default=json_default))
        elif method == "updateOne":
            res_u = sim.collections[coll_name].update_one(args[0], args[1])
            captured_updates.append((f"{coll_name}.updateOne", res_u))
            log(f"[UPDATE] {coll_name}.updateOne -> matched={res_u[0]}, modified={res_u[1]}")
        elif method == "updateMany":
            res_u = sim.collections[coll_name].update_many(args[0], args[1])
            captured_updates.append((f"{coll_name}.updateMany", res_u))
            log(f"[UPDATE] {coll_name}.updateMany -> matched={res_u[0]}, modified={res_u[1]}")
        elif method == "deleteOne":
            del_n = sim.collections[coll_name].delete_one(args[0])
            captured_deletes.append((f"{coll_name}.deleteOne", del_n))
            log(f"[DELETE] {coll_name}.deleteOne -> deletedCount={del_n}")
        elif method == "deleteMany":
            del_n = sim.collections[coll_name].delete_many(args[0])
            captured_deletes.append((f"{coll_name}.deleteMany", del_n))
            log(f"[DELETE] {coll_name}.deleteMany -> deletedCount={del_n}")
        elif method == "aggregate":
            agg_res = sim.aggregate(coll_name, args[0])
            captured_aggs.append(agg_res)
            log(f"\n[AGGREGATE #{len(captured_aggs)}] db.{coll_name}.aggregate(...) -> {len(agg_res)} fila(s):")
            log(json.dumps(agg_res, ensure_ascii=False, indent=2, default=json_default))

    # 3. Assertions finales de calidad (Checks CHK-01 .. CHK-08)
    checks: list[tuple[str, bool, str]] = []
    checks.append(("CHK-01", syntax_ok, "Sintaxis JS válida y 7 fases completas"))

    colls_ok = (
        set(sim.collections.keys()) == {"productos", "pedidos", "resenas_clientes"}
        and sum(len(c.indexes) - 1 for c in sim.collections.values()) == 6
    )
    checks.append(("CHK-02", colls_ok, "3 colecciones con $jsonSchema y 6 índices creados"))

    counts_ok = (
        len(sim.collections["productos"].docs) == 10
        and len(sim.collections["pedidos"].docs) == 5
        and len(sim.collections["resenas_clientes"].docs) == 6
    )
    checks.append(("CHK-03", counts_ok, "Estado final tras CRUD: 10 productos, 5 pedidos, 6 reseñas"))

    reads_ok = (
        len(captured_reads) == 4
        and len(captured_reads[0][1]) == 3   # GE001, GE002 (trastes:22) + AP001 (Cardioide)
        and len(captured_reads[1][1]) == 3   # GE002, GE001, AP002 (> 150000 en Eléctricas/Audio)
        and len(captured_reads[2][1]) == 2   # $elemMatch: PED-2026-5002 y PED-2026-5004
        and len(captured_reads[3][1]) == 5   # multikey estudio/fender: GA002, GE001, BA001, AP001, AP002
    )
    checks.append(("CHK-04", reads_ok, "Consultas READ (Dot Notation=3, Compuesta=3, $elemMatch=2, Multikey=5)"))

    ap001 = sim.collections["productos"].find({"codigo": "AP001"})[0]
    ge001 = sim.collections["productos"].find({"codigo": "GE001"})[0]
    ped5004 = sim.collections["pedidos"].find({"codigo_pedido": "PED-2026-5004"})[0]
    ap002 = sim.collections["productos"].find({"codigo": "AP002"})[0]
    updates_ok = (
        ap001["stock"] == 10
        and "alta-demanda" in ge001["etiquetas"]
        and len(ped5004["items"]) == 3
        and Decimal(str(ped5004["total"])) == Decimal("173950")
        and ap001["especificaciones"].get("garantia_meses") == 12
        and ap002["especificaciones"].get("garantia_meses") == 12
    )
    checks.append(("CHK-05", updates_ok, "Updates atómicos ($inc stock 12->10, $addToSet, $push+$inc total 173950, updateMany)"))

    deletes_ok = (
        len(captured_deletes) == 2
        and captured_deletes[0][1] == 1
        and captured_deletes[1][1] == 1
    )
    checks.append(("CHK-06", deletes_ok, "Eliminaciones deleteOne (TE002) y deleteMany (CANCELADO)"))

    checks.append(("CHK-07", negative_test_caught, "Prueba negativa $jsonSchema rechazó documento corrupto BAD01"))

    aggs_ok = (
        len(captured_aggs) == 2
        and len(captured_aggs[0]) == 6
        and sum(Decimal(str(r["ingresos_acumulados"])) for r in captured_aggs[0]) == Decimal("2351920")
        and len(captured_aggs[1]) == 5
        and captured_aggs[1][0]["calificacion_promedio"] == 5.0
    )
    checks.append(("CHK-08", aggs_ok, "Aggregation Pipelines (Ranking 6 productos = 2.351.920 CLP; Lookup 5 reseñas)"))

    log("\n=========================================================================")
    log("  RESUMEN DE CHECKS DE VERIFICACION")
    log("=========================================================================")
    all_passed = True
    for code, status, desc in checks:
        tag = "OK" if status else "FAIL"
        if not status:
            all_passed = False
        log(f"[{tag}] {code}: {desc}")

    OUTPUT_PATH.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    log(f"\nEvidencia guardada en: {OUTPUT_PATH.name}")
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
