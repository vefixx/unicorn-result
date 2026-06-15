CREATE TABLE IF NOT EXISTS electricity_profile
(
    apartment_id INTEGER NOT NULL REFERENCES apartment (apartment_id),
    apartment_no TEXT    NOT NULL,
    code         TEXT    NOT NULL,
    hour_of_day  INTEGER NOT NULL,
    kwh_p70       REAL    NOT NULL,
    rows_used    INTEGER NOT NULL,
    UNIQUE (apartment_id, hour_of_day)
)