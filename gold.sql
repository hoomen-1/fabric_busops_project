CREATE OR ALTER PROCEDURE dbo.sp_load_gold
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dbo.FactWartungsauftrag;
        TRUNCATE TABLE dbo.DimFahrzeug;
        TRUNCATE TABLE dbo.DimWerkstatt;
        TRUNCATE TABLE dbo.DimBauteil;
        TRUNCATE TABLE dbo.DimDate;

        INSERT INTO dbo.DimFahrzeug (
            fahrzeug_id, typ, laenge_m, baujahr,
            antrieb, depot, start_km_stand
        )
        SELECT
            fahrzeug_id, typ, laenge_m, baujahr,
            antrieb, depot, start_km_stand
        FROM busops_lh.dbo.silver_fahrzeuge;

        INSERT INTO dbo.DimWerkstatt (
            werkstatt_id, standort, hebebuehne, eigenbetrieb
        )
        SELECT
            werkstatt_id, standort, hebebuehne, eigenbetrieb
        FROM busops_lh.dbo.silver_werkstaetten;

        INSERT INTO dbo.DimBauteil (bauteil)
        SELECT DISTINCT bauteil
        FROM busops_lh.dbo.silver_auftraege
        WHERE bauteil IS NOT NULL;

        DECLARE @start DATE = '20230101';
        DECLARE @ende DATE = '20251231';

        INSERT INTO dbo.DimDate (datum, jahr, monat, quartal)
        SELECT
            datum,
            YEAR(datum),
            MONTH(datum),
            DATEPART(QUARTER, datum)
        FROM (
            SELECT DATEADD(DAY, value, @start) AS datum
            FROM GENERATE_SERIES(0, DATEDIFF(DAY, @start, @ende))
        ) AS kalender;

        INSERT INTO dbo.FactWartungsauftrag (
            auftrag_id, fahrzeug_id, werkstatt_id,
            bauteil, auftragsart, auftragsdatum,
            beginn_ts, ende_ts, arbeitsstunden,
            materialkosten, lohnkosten, gesamtkosten,
            km_stand, status, ausfalltage,
            materialkosten_fehlen, km_auffaellig,
            zeitstempel_korrigiert
        )
        SELECT
            auftrag_id, fahrzeug_id, werkstatt_id,
            bauteil, auftragsart, auftragsdatum,
            beginn_ts, ende_ts, arbeitsstunden,
            materialkosten, lohnkosten, gesamtkosten,
            km_stand, status, ausfalltage,
            materialkosten_fehlen, km_auffaellig,
            zeitstempel_korrigiert
        FROM busops_lh.dbo.silver_auftraege;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
