# SQL Pipeline for MIMIC-IV: Early GPR After Delirium Onset

This repository provides a stepwise **SQL-only** pipeline to reproduce cohort construction and variable derivation from the **MIMIC-IV** database using **PostgreSQL**.

Study title:
**U-Shaped Association Between Early Glucose-Potassium Ratio and Short-Term Mortality after Delirium Onset in Critically Ill Patients**

No patient-level data are included in this repository.

## Requirements
- Credentialed access to MIMIC-IV
- PostgreSQL with MIMIC-IV loaded (schemas commonly used: `mimiciv_hosp`, `mimiciv_icu`, `mimiciv_derived`)
- `psql` command-line client

## How to run
From the repository root directory:

```bash
psql -d YOUR_DATABASE -f sql/99_build_all.sql
