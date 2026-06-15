-- SQL-файл для создания основных таблиц
create table measurement
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

create index idx_measurement_device_ts
    on measurement (device_id, ts);

create index idx_measurement_metric_ts
    on measurement (metric_type_id, ts);

create table device
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

create table apartment
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

create table building
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

create table complex
(
    complex_id         INTEGER
        primary key,
    name               TEXT    not null,
    city               TEXT    not null,
    management_company TEXT    not null,
    commissioning_year INTEGER not null
);

create table device_type
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

create table metric_type
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