[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared stg_auftraege = let
  Quelle = Lakehouse.Contents(null),
  Navigation = Quelle{[workspaceId = "00000000-0000-0000-0000-000000000001"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "00000000-0000-0000-0000-000000000002"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "bronze_auftraege", ItemKind = "Table"]}[Data],
  #"Spaltentyp mit Gebietsschema geändert" = Table.TransformColumnTypes(#"Navigation 2", {{"lohnkosten", type number}, {"arbeitsstunden", type number}, {"materialkosten", type number}, {"beginn_ts", type datetime}, {"ende_ts", type datetime}, {"km_stand", Int64.Type}}, "en-US"),
  #"Abgeschnittener Text" = Table.TransformColumns(#"Spaltentyp mit Gebietsschema geändert", {{"bauteil", each Text.Trim(_), type nullable text}}),
  #"Text in Kleinbuchstaben" = Table.TransformColumns(#"Abgeschnittener Text", {{"bauteil", each Text.Lower(_), type nullable text}}),
  #"Ersetzter Wert" = Table.ReplaceValue(#"Text in Kleinbuchstaben", "bremsbelaege", "bremsbelag", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 1" = Table.ReplaceValue(#"Ersetzter Wert", "bremsbelag va", "bremsbelag", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 2" = Table.ReplaceValue(#"Ersetzter Wert 1", "türsteuerung", "tuersteuerung", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 3" = Table.ReplaceValue(#"Ersetzter Wert 2", "tuer-steuerung", "tuersteuerung", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 4" = Table.ReplaceValue(#"Ersetzter Wert 3", "bereifung", "reifen", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 5" = Table.ReplaceValue(#"Ersetzter Wert 4", "beleuchtung aussen", "beleuchtung", Replacer.ReplaceText, {"bauteil"}),
  #"Ersetzter Wert 6" = Table.ReplaceValue(#"Ersetzter Wert 5", "licht", "beleuchtung", Replacer.ReplaceValue, {"bauteil"}),
  #"Text in Kleinbuchstaben 1" = Table.TransformColumns(#"Ersetzter Wert 6", {{"status", each Text.Lower(_), type nullable text}})
in
  #"Text in Kleinbuchstaben 1";
shared silver_fahrzeuge = let
  Quelle = Lakehouse.Contents(null),
  Navigation = Quelle{[workspaceId = "00000000-0000-0000-0000-000000000001"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "00000000-0000-0000-0000-000000000002"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "bronze_fahrzeuge", ItemKind = "Table"]}[Data],
  #"Ersetzter Wert" = Table.ReplaceValue(#"Navigation 2", "South", "Süd", Replacer.ReplaceText, {"depot"}),
  #"Ersetzter Wert 1" = Table.ReplaceValue(#"Ersetzter Wert", "East", "Ost", Replacer.ReplaceText, {"depot"}),
  #"Geänderter Spaltentyp" = Table.TransformColumnTypes(#"Ersetzter Wert 1", {{"laenge_m", Int64.Type}, {"baujahr", Int64.Type}, {"start_km_stand", Int64.Type}})
in
  #"Geänderter Spaltentyp";
shared silver_werkstaetten = let
  Quelle = Lakehouse.Contents(null),
  Navigation = Quelle{[workspaceId = "00000000-0000-0000-0000-000000000001"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "00000000-0000-0000-0000-000000000002"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "bronze_werkstaetten", ItemKind = "Table"]}[Data],
  #"Ersetzter Wert" = Table.ReplaceValue(#"Navigation 2", "Hof South", "Hof Süd", Replacer.ReplaceText, {"standort"}),
  #"Ersetzter Wert 1" = Table.ReplaceValue(#"Ersetzter Wert", "Hof East", "Hof Ost", Replacer.ReplaceText, {"standort"}),
  #"Geänderter Spaltentyp" = Table.TransformColumnTypes(#"Ersetzter Wert 1", {{"hebebuehne", Int64.Type}, {"eigenbetrieb", Int64.Type}})
in
  #"Geänderter Spaltentyp";
shared silver_auftraege = let
    Quelle = stg_auftraege,

    KostenFlag = Table.AddColumn(
        Quelle, "materialkosten_fehlen",
        each [materialkosten] = null, type logical
    ),
    KilometerFlag = Table.AddColumn(
        KostenFlag, "km_auffaellig",
        each [km_stand] = null or [km_stand] < 20000,
        type logical
    ),
    ZeitFlag = Table.AddColumn(
        KilometerFlag, "zeitstempel_korrigiert",
        each [ende_ts] < [beginn_ts], type logical
    ),

    BeginnKorrigiert = Table.AddColumn(
        ZeitFlag, "beginn_neu",
        each List.Min({[beginn_ts], [ende_ts]}), type datetime
    ),
    EndeKorrigiert = Table.AddColumn(
        BeginnKorrigiert, "ende_neu",
        each List.Max({[beginn_ts], [ende_ts]}), type datetime
    ),
    AlteZeitspaltenEntfernt = Table.RemoveColumns(
        EndeKorrigiert, {"beginn_ts", "ende_ts"}
    ),
    ZeitspaltenUmbenannt = Table.RenameColumns(
        AlteZeitspaltenEntfernt,
        {{"beginn_neu", "beginn_ts"}, {"ende_neu", "ende_ts"}}
    ),

    Sortiert = Table.Sort(
        ZeitspaltenUmbenannt,
        {
            {"auftrag_id", Order.Ascending},
            {"km_auffaellig", Order.Ascending},
            {"materialkosten_fehlen", Order.Ascending},
            {"zeitstempel_korrigiert", Order.Ascending}
        }
    ),
    EindeutigeAuftraege = Table.Distinct(
        Table.Buffer(Sortiert), {"auftrag_id"}
    ),

    Auftragsdatum = Table.AddColumn(
        EindeutigeAuftraege, "auftragsdatum",
        each Date.From([beginn_ts]), type date
    ),
    Gesamtkosten = Table.AddColumn(
        Auftragsdatum, "gesamtkosten",
        each [materialkosten] + [lohnkosten], type number
    ),
    Ausfalltage = Table.AddColumn(
        Gesamtkosten, "ausfalltage",
        each if [status] = "abgeschlossen"
             then Duration.TotalDays([ende_ts] - [beginn_ts])
             else null,
        type number
    )
in
    Ausfalltage;
