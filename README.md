# BusOps – Werkstattdaten in Microsoft Fabric

Das Projekt verarbeitet Wartungs- u. Reparaturaufträge einer Busflotte. Die Daten kommen aus 3 generierten CSV-Dateien und werden über Bronze & Silver bis in ein Gold-Warehouse geladen (Medallionarchitektur). 
Dort werden Kosten, Reparaturen und Ausfallzeiten nach Fahrzeug, Werkstatt, Bauteil ausgewertet.

Die Testdaten werden im Notebook mit Python generiert: 180 Busse, 6 Werkstätte und 95000 Aufträge im  Zeitraum 2023 bis 2025. Absichtlich eingebaute Duplikate erhöhen die Auftragsdatei auf 96710 Zeilen. Es gibt fehlende Materialkosten, vertauschte Zeitstempel, unterschiedliche Schreibweisen und auffällige Kilometerstände.

## Ablauf
Das Notebook schreibt die CSV-Dateien nach Files/raw im Fabric Lakehouse busops_lh. Es wird separat ausgeführt. Danach übernimmt die Masterpipeline die 3 Schritte Bronze loading, Silver cleaning und Gold loading. Der nächste Schritt startet erst, wenn der vorherige erfolgreich abgeschlossen ist.
Die Bronze-Pipeline bekommt über den Parameter files die Namen fahrzeuge, werkstaetten und auftraege. Eine ForEach-Schleife verarbeitet die Dateien nacheinander.
Im Dataflow Gen2 werden Datentypen angepasst, Depotnamen vereinheitlicht und verschiedene Bauteilbezeichnungen zusammengeführt. Vertauschte Start- und Endzeiten werden korrigiert. Fehlende Materialkosten und auffällige Kilometerstände bleiben gekennzeichnet, statt ersetzt zu werden.
Zusätzlich berechnet der Dataflow das Auftragsdatum, die Gesamtkosten und die Ausfalltage abgeschlossener Aufträge. Fehlen Materialkosten, bleiben auch die Gesamtkosten leer.
Final ruft die Masterpipeline dbo.sp_load_gold auf. Die Stored Procedure lädt die Silver-Daten in DimFahrzeug, DimWerkstatt, DimBauteil, DimDate und FactWartungsauftrag. Gold wird dabei vollständig neu befüllt. Der Ladevorgang läuft in einer Transaktion und wird bei einem Fehler zurückgerollt.

## Dateien
- [generate_raw_data.ipynb](generate_raw_data.ipynb): erzeugt Rohdaten.
- [ingest_bronze_pipeline.json](ingest_bronze_pipeline.json): lädt CSV-Dateien in die Bronze-Tabellen.
- [DataFlow_MashupDocument.pq](DataFlow_MashupDocument.pq): enthält die Power-Query-Abfragen für die Bereinigung.
- [1_create_gold_tables.sql](1_create_gold_tables.sql): legt die Gold-Tabellen an.
- [gold.sql](gold.sql): enthält die gespeicherte Prozedur zum Laden von Gold.
- [masterpipeline.json](masterpipeline.json): verbindet die Verarbeitungsschritte.

## Ausführen
Benötigt werden ein Fabric-Workspace, das Lakehouse busops_lh und das Warehouse busops_wh_gold. Die Fabric-IDs sind durch Platzhalter im Format 00000000-0000-0000-0000-00000000000x ersetzt. WAREHOUSE_ENDPOINT ist ebenfalls ein Platzhalter. Vor dem Ausführen müssen eigene IDs und eigene Endpunkt eingetragen werden.
Zuerst Notebook importieren, das Lakehouse als Standard zuordnen und NB ausführen. Danach die Bronze Pipeline einrichten und einmal starten, damit die Bronze-Tabellen vorhanden sind.
Anschließend den Dataflow mit den Abfragen einrichten. Die drei Silverabfragen brauchen jeweils eine Zieltabelle im Lakehouse. Die Datenziele müssen in Fabric eingerichtet werden. 
Im Warehouse zuerst 1_create_gold_tables.sql und danach gold.sql ausführen. Bei einem anderen Lakehouse-Namen müssen auch die Quellen in der Prozedur angepasst werden. In der Masterpipeline die Bronze-Pipeline, den Dataflow und die Warehouse-Verbindung zuordnen, dann die Masterpipeline starten.
Nach der Bereinigung sollten 95000 eindeutige Aufträge übrig bleiben. Die Anzahl lässt sich in Silver und Gold vergleichen.

## Screenshots

Pipeline-Lauf in Fabric samt SQL-Prüfung mit 95000 eindeutigen Aufträgen.

<img width="1765" height="601" alt="Screenshot 2026-09-17 004422" src="https://github.com/user-attachments/assets/d9f40727-0beb-4ee0-8b6c-18330e8da254" />

<img width="1762" height="650" alt="Screenshot 2026-09-17 004318" src="https://github.com/user-attachments/assets/57a44b7d-5247-4f27-b465-9300923824dd" />

<img width="685" height="542" alt="Screenshot 2026-09-17 003950" src="https://github.com/user-attachments/assets/3a4256a8-574c-4cd1-92fc-eca33683bc60" />

<img width="732" height="188" alt="image" src="https://github.com/user-attachments/assets/f85fdc14-cc4b-4748-be84-4c8f5568e3a1" />
