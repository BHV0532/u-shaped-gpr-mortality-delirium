-- Run all scripts in order (psql required)

\i sql/00_setup.sql
\i sql/01_cohort.sql
\i sql/02_camicu_features.sql
\i sql/03_camicu_positive.sql
\i sql/04_outcomes.sql
\i sql/05_analysis_table.sql
\i sql/06_onset_timing.sql
\i sql/07_exposures_and_gpr.sql
