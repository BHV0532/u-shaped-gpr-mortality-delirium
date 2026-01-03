-- Step 6: Delirium onset timing categories based on hours from ICU admission

DROP TABLE IF EXISTS z_onset_timing;

CREATE TABLE z_onset_timing AS
SELECT
    stay_id,
    delirium_onset_hour,
    CASE
        WHEN delirium_onset_hour <= 24 THEN 'Early-onset Delirium'
        WHEN delirium_onset_hour BETWEEN 24 AND 72 THEN 'Intermediate-onset Delirium'
        ELSE 'Late-onset Delirium'
    END AS delirium_onset_type
FROM z_final_analysis;

ALTER TABLE z_final_analysis
ADD COLUMN IF NOT EXISTS delirium_onset_type VARCHAR(50);

UPDATE z_final_analysis fa
SET delirium_onset_type = ot.delirium_onset_type
FROM z_onset_timing ot
WHERE fa.stay_id = ot.stay_id;
