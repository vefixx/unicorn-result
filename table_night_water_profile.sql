CREATE TABLE IF NOT EXISTS night_water_profile
(
    apartment_id INTEGER NOT NULL REFERENCES apartment (apartment_id),
    apartment_no TEXT    NOT NULL,
    code         TEXT    NOT NULL,
    hour_of_day  INTEGER NOT NULL,
    m3_p95       REAL    NOT NULL,
    rows_used    INTEGER NOT NULL,
    UNIQUE (apartment_id, code, hour_of_day)
)