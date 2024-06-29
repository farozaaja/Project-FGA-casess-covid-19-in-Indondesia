-- Covid-19 new active cases in Indonesia
WITH FIRST_TIME_JOURNAL AS (
  SELECT 
  MIN(Date) AS First_Time_Journal,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  LTRIM(RTRIM(Location)) AS Provinsi
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 2,3
),
FIRST_JOURNAL AS(
  SELECT
  Date,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  New_Cases,
  New_Deaths,
  New_Recovered,
  Total_Cases,
  Total_Deaths,
  Total_Recovered
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
),
OLD_CASES AS(
  SELECT
  a.Kode_Provinsi AS Kode_Provinsi,
  a.Provinsi,
  (b.Total_Cases - b.New_Cases) AS Kasus_Aktif_Awal,
  (b.Total_Deaths - b.New_Deaths) AS Kematian_Awal,
  (b.Total_Recovered - b.New_Recovered) AS Sembuh_Awal,
  FROM FIRST_TIME_JOURNAL AS a
  LEFT JOIN FIRST_JOURNAL AS b
  ON a.First_Time_Journal = b.Date AND a.Kode_Provinsi = b.Kode_Provinsi
),
NEW_CASES AS(
    SELECT
    LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
    LTRIM(RTRIM(Location)) AS Provinsi,
    SUM(New_Cases) AS Kasus_Baru,
    SUM(New_Deaths) AS Kematian_Baru,
    SUM(New_Recovered) AS Sembuh_Baru,
    FROM `Covid19_Cases.Case`
    WHERE Location_ISO_Code != 'IDN'
    GROUP BY 1,2
)
SELECT
    Kode_Provinsi,
    Provinsi,
    (Total_Kasus - Total_Kematian - Total_Sembuh) AS Jumlah_Kasus_Aktif
FROM(
  SELECT
    a.Kode_Provinsi AS Kode_Provinsi,
    a.Provinsi AS Provinsi,
    (a.Kasus_Baru + c.Kasus_Aktif_Awal + c.Kematian_Awal + c.Sembuh_Awal) AS Total_Kasus,
    (a.Kematian_Baru + c.Kematian_Awal) AS Total_Kematian,
    (a.Sembuh_Baru + c.Sembuh_Awal) AS Total_Sembuh,
    FROM NEW_CASES AS a
    LEFT JOIN OLD_CASES AS c
    ON a.Kode_Provinsi = c.Kode_Provinsi
  )
ORDER BY Jumlah_Kasus_Aktif DESC;

-- Location code with fewest deaths
WITH FIRST_TIME_JOURNAL AS (
  SELECT 
  MIN(Date) AS First_Time_Journal,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  LTRIM(RTRIM(Location)) AS Provinsi
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 2,3
),
FIRST_JOURNAL AS(
  SELECT
  Date,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  New_Deaths,
  Total_Deaths
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
),
MENINGGAL_LAMA AS(
  SELECT
  a.Kode_Provinsi AS Kode_Provinsi,
  a.Provinsi,
  (b.Total_Deaths - b.New_Deaths) AS Kematian_Sebelumnya
  FROM FIRST_TIME_JOURNAL AS a
  LEFT JOIN FIRST_JOURNAL AS b
  ON a.First_Time_Journal = b.Date AND a.Kode_Provinsi = b.Kode_Provinsi
),
MENINGGAL_BARU AS(
    SELECT
    LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
    LTRIM(RTRIM(Location)) AS Provinsi,
    SUM(New_Deaths) AS Jumlah_Kematian_Baru
    FROM `Covid19_Cases.Case`
    WHERE Location_ISO_Code != 'IDN'
    GROUP BY 1,2
)
SELECT Kode_Provinsi, Total_Kematian
FROM(
  SELECT
    a.Kode_Provinsi AS Kode_Provinsi,
    a.Provinsi,
    a.Jumlah_Kematian_Baru,
    b.Kematian_Sebelumnya,
    (a.Jumlah_Kematian_Baru + b.Kematian_Sebelumnya) AS Total_Kematian
    FROM MENINGGAL_BARU AS a
    LEFT JOIN MENINGGAL_LAMA AS b
    ON a.Kode_Provinsi = b.Kode_Provinsi
  )
ORDER BY Total_Kematian ASC
LIMIT 2;

-- Date of The Best Case Recovery Rate
WITH CRR AS(
  SELECT
  Date,
  SUM(Total_Recovered) AS Jumlah_Sembuh,
  SUM(Total_Deaths) AS Jumlah_Kematian
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 1
)
SELECT Date, ROUND(((Jumlah_Sembuh/(Jumlah_Sembuh + Jumlah_Kematian))*100), 2) AS Case_Recovery_Rate
FROM CRR
ORDER BY Case_Recovery_Rate DESC;

-- The best Case Fatality Rate and Case Recovery Rate by Province
WITH FIRST_TIME_JOURNAL AS (
  SELECT 
  MIN(Date) AS First_Time_Journal,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  LTRIM(RTRIM(Location)) AS Provinsi
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 2,3
),
FIRST_JOURNAL AS(
  SELECT
  Date,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  New_Cases AS Kasus_Baru,
  New_Deaths AS Kematian_Baru,
  New_Recovered AS Sembuh_Baru,
  Total_Cases AS Total_Kasus,
  Total_Deaths AS Total_Kematian,
  Total_Recovered AS Total_Sembuh
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
),
OLD_CASES AS(
  SELECT
  a.Kode_Provinsi,
  a.Provinsi,
  (b.Total_Kematian - b.Kematian_Baru) AS Kematian_Awal,
  (b.Total_Sembuh - b.Sembuh_Baru) AS Sembuh_Awal
  FROM FIRST_TIME_JOURNAL AS a
  LEFT JOIN FIRST_JOURNAL AS b
  ON a.First_Time_Journal = b.Date AND a.Kode_Provinsi = b.Kode_Provinsi
),
NEW_CASES AS(
  SELECT
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  LTRIM(RTRIM(Location)) AS Provinsi,
  SUM(New_Deaths) AS Kematian_Baru,
  SUM(New_Recovered) AS Sembuh_Baru
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 1,2
),
BASE_DATA AS(
  SELECT
  a.Kode_Provinsi AS Kode_Provinsi,
  a.Provinsi AS Provinsi,
  (a.Kematian_Baru + b.Kematian_Awal) AS Jumlah_Kematian,
  (a.Sembuh_Baru + b.Sembuh_Awal) AS Jumlah_Sembuh
  FROM NEW_CASES AS a
  LEFT JOIN OLD_CASES AS b
  ON a.Kode_Provinsi = b.Kode_Provinsi
),
CFR AS(
  SELECT
  Kode_Provinsi,
  Provinsi,
  ROUND(((Jumlah_Kematian/(Jumlah_Kematian + Jumlah_Sembuh))*100),2) AS Case_Fatality_Rate
  FROM BASE_DATA
),
CRR AS(
  SELECT
  Kode_Provinsi,
  Provinsi,
  ROUND(((Jumlah_Sembuh/(Jumlah_Sembuh + Jumlah_Kematian))*100),2) AS Case_Recovery_Rate
  FROM BASE_DATA
)
SELECT
  a.Kode_Provinsi,
  a.Provinsi,
  a.Case_Fatality_Rate AS CFR,
  b.Case_Recovery_Rate AS CRR
FROM CFR AS a
LEFT JOIN CRR AS b
ON a.Kode_Provinsi = b.Kode_Provinsi
ORDER BY CFR ASC, CRR DESC;

-- Time when the number of active cases in Indonesia is more than equal to 30,000 cases.
WITH FIRST_TIME_JOURNAL AS (
  SELECT 
  MIN(Date) AS First_Time_Journal,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  LTRIM(RTRIM(Location)) AS Provinsi
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
  GROUP BY 2,3
),
FIRST_JOURNAL AS(
  SELECT
  Date,
  LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
  New_Cases,
  New_Deaths,
  New_Recovered,
  Total_Cases,
  Total_Deaths,
  Total_Recovered
  FROM `Covid19_Cases.Case`
  WHERE Location_ISO_Code != 'IDN'
),
OLD_CASES AS(
  SELECT
  a.Kode_Provinsi AS Kode_Provinsi,
  a.Provinsi AS Provinsi,
  (b.Total_Cases - b.New_Cases) AS Kasus_Aktif_Awal,
  (b.Total_Deaths - b.New_Deaths) AS Kematian_Awal,
  (b.Total_Recovered - b.New_Recovered) AS Sembuh_Awal,
  FROM FIRST_TIME_JOURNAL AS a
  LEFT JOIN FIRST_JOURNAL AS b
  ON a.First_Time_Journal = b.Date AND a.Kode_Provinsi = b.Kode_Provinsi
),
AGG_FUNC_OLD_CASES AS(
  SELECT
  Kode_Provinsi,
  Provinsi,
  (Kasus_Aktif_Awal + Kematian_Awal + Sembuh_Awal) AS Kasus_Awal,
  Kematian_Awal,
  Sembuh_Awal
  FROM OLD_CASES
),
NEW_CASES AS(
    SELECT
    EXTRACT(MONTH FROM Date) AS Bulan,
    EXTRACT(YEAR FROM Date) AS Tahun,
    LTRIM(RTRIM(Location_ISO_Code)) AS Kode_Provinsi,
    SUM(New_Cases) AS Kasus_Baru,
    SUM(New_Deaths) AS Kematian_Baru,
    SUM(New_Recovered) AS Sembuh_Baru,
    FROM `Covid19_Cases.Case`
    WHERE Location_ISO_Code != 'IDN'
    GROUP BY 1,2,3
),
AGG_FUNC_CASES AS(
  SELECT
  MIN(a.Bulan) AS Bulan,
  MIN(a.Tahun) AS Tahun,
  a.Kode_Provinsi AS Kode_Provinsi,
  (a.Kasus_Baru + b.Kasus_Awal) AS Total_Kasus,
  (a.Kematian_Baru + b.Kematian_Awal) AS Total_Kematian,
  (a.Sembuh_Baru + b.Sembuh_Awal) AS Total_Sembuh
  FROM NEW_CASES AS a
  LEFT JOIN AGG_FUNC_OLD_CASES AS b
  ON a.Kode_Provinsi = b.Kode_Provinsi
);