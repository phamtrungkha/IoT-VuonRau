"""
MySQL schema / table inspector for local ops and debugging.

Purpose:
  - List tables and approximate row counts from information_schema (InnoDB counts are approximate).
  - Dump column definitions for a quick comparison with Flyway migrations in backend-java.

Not used by the Spring Boot backend at runtime. Requires: pip install pymysql

Environment (all optional; see get_config() for defaults):
  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
  EXACT_COUNT=1  -> run COUNT(*) per table (slow on large tables)
"""

import os
import sys
from dataclasses import dataclass

import pymysql


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int
    user: str
    password: str
    database: str


def env(name: str, default: str | None = None) -> str | None:
    v = os.environ.get(name)
    if v is None or v == "":
        return default
    return v


def get_config() -> DbConfig:
    host = env("DB_HOST", "192.168.1.92") or "192.168.1.92"
    port = int(env("DB_PORT", "3306") or "3306")
    user = env("DB_USER", "vuonrau") or "vuonrau"
    password = env("DB_PASSWORD", "vuonrau") or "vuonrau"
    database = env("DB_NAME", "vuonrau") or "vuonrau"
    return DbConfig(host=host, port=port, user=user, password=password, database=database)


def q(conn: pymysql.connections.Connection, sql: str, args=None):
    with conn.cursor() as cur:
        cur.execute(sql, args)
        return cur.fetchall()


def main() -> int:
    cfg = get_config()
    try:
        conn = pymysql.connect(
            host=cfg.host,
            port=cfg.port,
            user=cfg.user,
            password=cfg.password,
            database=cfg.database,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=5,
            read_timeout=10,
            write_timeout=10,
        )
    except Exception as e:
        print(f"ERROR: cannot connect to MySQL {cfg.host}:{cfg.port}/{cfg.database} as {cfg.user}: {e}", file=sys.stderr)
        return 2

    with conn:
        tables = q(
            conn,
            """
            SELECT
              t.TABLE_NAME AS table_name,
              t.ENGINE AS engine,
              t.TABLE_ROWS AS approx_rows,
              t.DATA_LENGTH AS data_bytes,
              t.INDEX_LENGTH AS index_bytes,
              t.CREATE_TIME AS create_time,
              t.UPDATE_TIME AS update_time
            FROM information_schema.TABLES t
            WHERE t.TABLE_SCHEMA = %s
              AND t.TABLE_TYPE = 'BASE TABLE'
            ORDER BY (t.DATA_LENGTH + t.INDEX_LENGTH) DESC, t.TABLE_NAME ASC
            """,
            (cfg.database,),
        )

        print("== Tables (from information_schema.TABLES; TABLE_ROWS is approximate for InnoDB) ==")
        for t in tables:
            total = (t.get("data_bytes") or 0) + (t.get("index_bytes") or 0)
            print(
                f"- {t['table_name']}: approx_rows={t.get('approx_rows')}, size_bytes={total}, engine={t.get('engine')}, updated={t.get('update_time')}"
            )

        print("\n== Columns ==")
        cols = q(
            conn,
            """
            SELECT
              c.TABLE_NAME AS table_name,
              c.COLUMN_NAME AS column_name,
              c.COLUMN_TYPE AS column_type,
              c.IS_NULLABLE AS is_nullable,
              c.COLUMN_DEFAULT AS column_default,
              c.EXTRA AS extra,
              c.COLUMN_KEY AS column_key
            FROM information_schema.COLUMNS c
            WHERE c.TABLE_SCHEMA = %s
            ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION
            """,
            (cfg.database,),
        )
        current_table = None
        for c in cols:
            if c["table_name"] != current_table:
                current_table = c["table_name"]
                print(f"\n[{current_table}]")
            print(
                f"  - {c['column_name']}: {c['column_type']}, nullable={c['is_nullable']}, default={c['column_default']}, key={c['column_key']}, extra={c['extra']}"
            )

        print("\n== Sample counts (fast path) ==")
        # For tiny tables you can optionally force exact counts by setting EXACT_COUNT=1.
        exact = env("EXACT_COUNT", "0") == "1"
        if exact:
            for t in tables:
                name = t["table_name"]
                try:
                    row = q(conn, f"SELECT COUNT(*) AS cnt FROM `{name}`")[0]
                    print(f"- {name}: count={row['cnt']}")
                except Exception as e:
                    print(f"- {name}: count_failed: {e}")
        else:
            print("Set EXACT_COUNT=1 to run COUNT(*) per table (can be slow on big tables).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
