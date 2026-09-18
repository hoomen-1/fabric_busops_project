IF OBJECT_ID('dbo.DimFahrzeug', 'U') IS NULL
CREATE TABLE dbo.DimFahrzeug (
    fahrzeug_id VARCHAR(10) NOT NULL,
    typ VARCHAR(30),
    laenge_m INT,
    baujahr INT,
    antrieb VARCHAR(20),
    depot VARCHAR(30),
    start_km_stand INT
);

IF OBJECT_ID('dbo.DimWerkstatt', 'U') IS NULL
CREATE TABLE dbo.DimWerkstatt (
    werkstatt_id VARCHAR(10) NOT NULL,
    standort VARCHAR(60),
    hebebuehne INT,
    eigenbetrieb BIT
);

IF OBJECT_ID('dbo.DimBauteil', 'U') IS NULL
CREATE TABLE dbo.DimBauteil (
    bauteil VARCHAR(60) NOT NULL
);

IF OBJECT_ID('dbo.DimDate', 'U') IS NULL
CREATE TABLE dbo.DimDate (
    datum DATE NOT NULL,
    jahr INT,
    monat INT,
    quartal INT
);

IF OBJECT_ID('dbo.FactWartungsauftrag', 'U') IS NULL
CREATE TABLE dbo.FactWartungsauftrag (
    auftrag_id VARCHAR(20) NOT NULL,
    fahrzeug_id VARCHAR(10),
    werkstatt_id VARCHAR(10),
    bauteil VARCHAR(60),
    auftragsart VARCHAR(30),
    auftragsdatum DATE,
    beginn_ts DATETIME2(0),
    ende_ts DATETIME2(0),
    arbeitsstunden DECIMAL(10,1),
    materialkosten DECIMAL(12,2),
    lohnkosten DECIMAL(12,2),
    gesamtkosten DECIMAL(12,2),
    km_stand INT,
    status VARCHAR(20),
    ausfalltage DECIMAL(10,2),
    materialkosten_fehlen BIT,
    km_auffaellig BIT,
    zeitstempel_korrigiert BIT
);
