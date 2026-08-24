
## 📃 **Scripts**  
- Ensuring **data reliability and efficiency** is critical in a **Modern Data Warehouse**.  
- This section describes **scripts, procedures, and transformations** used in the **ETL pipeline** to maintain **high-quality, structured, and efficient data.**
  
---

![data_layer](https://github.com/user-attachments/assets/d298da24-6a18-4476-93d9-d4709a33b6af)

---

## 📂 **File Structure**  

```
scripts/                                    # Contains SQL scripts for data processing  
│  
├──  init_database.sql                      # Initializes and sets up the PostgreSQL database  
│  
├──  bronze/                                # Handles raw data ingestion  
│   ├──  ddl_bronze.sql                     # Defines the DDL structure for the Bronze layer  
│   ├──  proc_load_bronze.sql               # Procedure for loading raw data from CSV files  
│  
├──  silver/                                # Cleanses & standardizes data for analysis  
│   ├──  ddl_silver.sql                     # Defines the DDL structure for the Silver layer  
│   ├──  proc_load_silver.sql               # ETL procedure for transforming Bronze → Silver  
│  
├──  gold/                                  # Stores final business-ready datasets  
│   ├──  ddl_gold.sql                       # Creates views for star schema analytics  
```  

---

## 🟤 **Bronze Layer (Raw Data Storage)**  
📌 The **Bronze Layer** holds raw, unprocessed data from external sources before any transformation.  

### ➡️ **`scripts/bronze/ddl_bronze.sql`**  
✔️ Creates tables in the **Bronze schema**, ensuring **fresh data ingestion**.  
✔️ Drops existing tables (if they exist) to maintain **schema consistency**.  
✔️ Run this script **before loading new raw data**.  

### ➡️ **`scripts/bronze/proc_load_bronze.sql`**  
✔️ A **stored procedure** to load raw data from **CSV files** into the Bronze schema.  
✔️ **Key Features:**  
- 🗑️ **Truncates** existing Bronze tables before inserting new data.  
- 📥 Uses the **`COPY` command** for **fast, bulk data ingestion**.  
- ⏳ **Logs the time taken** for each table and **batch load time**.  

---

## ⚪ **Silver Layer (Clean & Structured Data)**  
📌 The **Silver Layer** applies **data validation, standardization, and transformations**.  

### ➡️ **`scripts/silver/ddl_silver.sql`**  
✔️ Defines tables in the **Silver schema** for structured, clean data.  
✔️ Drops existing tables **to maintain an up-to-date schema**.  

### ➡️ **`scripts/silver/proc_load_silver.sql`**  
✔️ A **stored procedure** that performs **ETL (Extract, Transform, Load)** to move data from **Bronze → Silver**.  
✔️ **Key Features:**  
- 📤 **Extracts** data from Bronze tables.  
- 🔄 **Cleans and transforms** data (fixes missing values, removes duplicates, applies business rules).  
- 📥 **Loads the refined data** into the Silver schema for structured analysis.  

---

## 🟡 **Gold Layer (Business-Ready Analytics)**  
📌 The **Gold Layer** provides **aggregated, analytics-ready data** for BI & reporting.  

### ➡️ **`scripts/gold/ddl_gold.sql`**  
✔️ **Creates views** that structure data into **fact and dimension tables** (Star Schema).  
✔️ **Key Features:**  
- 🏆 Generates **business-ready datasets** combining multiple Silver tables.  
- 📊 **Optimized for reporting** with KPIs, aggregations, and calculated fields.  
- 🔍 Ensures **referential integrity** and removes redundant information.  

---

## 🚀 **Why This Structure?**  
✅ **Efficient Data Management** – Organizes data into structured layers.  
✅ **Faster Query Performance** – Optimized views for analytics.  
✅ **Scalability** – Easily adapts to new data sources.  
✅ **Data Integrity** – Quality checks at each stage ensure accurate reporting.  

---
###  ℹ️ More Details
➡️ [Naming Conventions](https://github.com/Hiral-G-23/SQL-Data-Warehouse-Project/blob/main/docs/warehouse/naming_conventions.md)

➡️ [Data Catalog For the Gold Layer](https://github.com/Hiral-G-23/SQL-Data-Warehouse-Project/blob/main/docs/gold/data_catalog.md)

➡️ [Tests](https://github.com/Hiral-G-23/SQL-Data-Warehouse-Project/tree/main/tests)
