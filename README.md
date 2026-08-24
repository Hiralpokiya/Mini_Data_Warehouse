# Mini Data Warehouse

A SQL-based Data Warehouse project built using **Medallion Architecture**
(Bronze → Silver → Gold) with PostgreSQL.

## Architecture
```
CSV Files → Bronze (Raw) → Silver (Cleaned) → Gold (Analytics Ready)
```

## Project Structure

- `scripts/bronze/` - DDL and stored procedure to load raw CSV data
- `scripts/silver/` - DDL and stored procedure to clean and transform data
- `scripts/gold/`   - Views for Star Schema (dim + fact tables)
- `datasets/`       - Source CSV files (CRM and ERP data)

## How to Run

1. Run `scripts/bronze/ddl_bronze.sql`
2. Run `scripts/silver/ddl_silver.sql`
3. Run `scripts/bronze/proc_load_bronze.sql`
4. Run `scripts/silver/proc_load_silver.sql`
5. Execute `CALL bronze.load_bronze();`
6. Execute `CALL silver.load_silver();`
7. Run `scripts/gold/ddl_gold.sql`

## Tools Used

- PostgreSQL 16
- pgAdmin 4
- Git & GitHub
```

---

## STEP 6 — Create .gitignore File

Inside your folder create a file called `.gitignore` and paste this:
```
# Ignore system files
.DS_Store
Thumbs.db

# Ignore sensitive config files
*.env
config.ini

# Ignore any local test files
*.log
*.tmp