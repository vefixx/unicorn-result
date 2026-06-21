create table if not exists complex
(
    complex_id         INTEGER
        primary key,
    name               TEXT    not null,
    city               TEXT    not null,
    management_company TEXT    not null,
    commissioning_year INTEGER not null
);

create table if not exists building
(
    building_id  INTEGER
        primary key,
    complex_id   INTEGER not null
        references complex,
    name         TEXT    not null,
    address      TEXT    not null,
    floors       INTEGER not null,
    entrances    INTEGER not null,
    has_elevator INTEGER not null
);

create table if not exists device_type
(
    device_type_id INTEGER
        primary key,
    code           TEXT not null
        unique,
    display_name   TEXT not null,
    device_group   TEXT not null,
    location_scope TEXT not null,
    description    TEXT not null
);

create table if not exists metric_type
(
    metric_type_id          INTEGER
        primary key,
    code                    TEXT not null
        unique,
    display_name            TEXT not null,
    unit                    TEXT not null,
    data_kind               TEXT not null,
    source_device_type_code TEXT not null,
    description             TEXT not null
);

create table if not exists section
(
    section_id     INTEGER
        primary key,
    building_id    INTEGER not null
        references building,
    name           TEXT    not null,
    elevator_count INTEGER not null
);

create table if not exists apartment
(
    apartment_id    INTEGER
        primary key,
    building_id     INTEGER not null
        references building,
    section_id      INTEGER not null
        references section,
    apartment_no    TEXT    not null,
    floor           INTEGER not null,
    area_m2         REAL    not null,
    rooms_count     INTEGER not null,
    residents_count INTEGER not null,
    apartment_class TEXT    not null
);

create table if not exists incident
(
    incident_id   INTEGER
        primary key,
    ts            TEXT    not null,
    building_id   INTEGER not null
        references building,
    apartment_id  INTEGER
        references apartment,
    severity      TEXT    not null,
    incident_type TEXT    not null,
    title         TEXT    not null,
    description   TEXT    not null,
    source_rule   TEXT    not null
);

create index if not exists idx_incident_ts
    on incident (ts);

create table if not exists night_water_profile
(
    apartment_id INTEGER not null
        references apartment,
    apartment_no TEXT    not null,
    code         TEXT    not null,
    hour_of_day  INTEGER not null,
    m3_p95       REAL    not null,
    rows_used    INTEGER not null,
    unique (apartment_id, code, hour_of_day)
);

create table if not exists resident_profile
(
    resident_profile_id INTEGER
        primary key,
    apartment_id        INTEGER not null
        references apartment,
    profile_name        TEXT    not null,
    wakeup_hour         INTEGER not null,
    sleep_hour          INTEGER not null,
    works_office_hours  INTEGER not null,
    has_children        INTEGER not null
);

create table if not exists room
(
    room_id        INTEGER
        primary key,
    apartment_id   INTEGER
        references apartment,
    building_id    INTEGER           not null
        references building,
    room_name      TEXT              not null,
    room_type      TEXT              not null,
    is_common_area INTEGER default 0 not null
);

create table if not exists device
(
    device_id      INTEGER
        primary key,
    device_type_id INTEGER not null
        references device_type,
    building_id    INTEGER not null
        references building,
    apartment_id   INTEGER
        references apartment,
    room_id        INTEGER
        references room,
    serial_no      TEXT    not null
        unique,
    vendor         TEXT    not null,
    model          TEXT    not null,
    installed_at   TEXT    not null,
    is_active      INTEGER not null
);

create table if not exists measurement
(
    measurement_id INTEGER
        primary key,
    ts             TEXT              not null,
    device_id      INTEGER           not null
        references device,
    metric_type_id INTEGER           not null
        references metric_type,
    value_num      REAL,
    value_text     TEXT,
    value_bool     INTEGER,
    quality_flag   TEXT default 'ok' not null
);

create index if not exists idx_measurement_device_ts
    on measurement (device_id, ts);

create index if not exists idx_measurement_metric_ts
    on measurement (metric_type_id, ts);

create index if not exists idx_measurement_ts
    on measurement (ts);
