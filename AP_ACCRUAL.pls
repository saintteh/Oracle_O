
--SELECT TO_DATE ((SUBSTR(:PERIOD_S5,5,2) ||'-01-'||  SUBSTR(:PERIOD_S5,1,4)),'MM-DD-YYYY') AS CURR_DATE,
---P-----------
WITH P AS (
SELECT CURR_DATE,
TO_CHAR (ADD_MONTHS (A.CURR_DATE, -0), 'YYYYMM') AS CURR_PERIOD,
TO_CHAR (ADD_MONTHS (A.CURR_DATE, -1), 'YYYYMM') AS PREV_PERIOD
FROM (
SELECT TO_CHAR(:ACCT_DATE,'YYYY-MM-DD') AS CURR_DATE
FROM DUAL)A
)
---GL_TRANS_ACT (OPEN)-----------
,GLO AS (
SELECT 'GLO' AS T, JEL.AOC_NAME, JEL.AOC_ID,
JEL.ACCT_DATE,JEL.ACCT_PERIOD, JEL.ACCT_YEAR,
JEL.ACCOUNT_ID, JEL.ACCOUNT_NAME, JEL.ACCRUAL_PERIOD,
JEL.LEGAL_ENTITY_ID, JEL.LEDGER_ID, JEL.CHART_OF_ACCOUNTS_ID, JEL.JE_BATCH_NAME, JEL.JE_BATCH_ID, JEL.DEFAULT_PERIOD_NAME,
JEL.JE_HEADER_ID, JEL.JOURNAL_NAME, JEL.JE_SOURCE,JEL.PERIOD_NAME, JEL.DEFAULT_EFFECTIVE_DATE,
JEL.STATUS, JEL.DATE_CREATED, JEL.POSTED_DATE, JEL.DESCRIPTION, JEL.DESCRIPTION_JL,
JEL.TRX_CURR, JEL.ACCT_CURR, JEL.TRX_AMT, JEL.ACCT_AMT,
JEL.ENTERED_DR,JEL.ENTERED_CR,JEL.ACCOUNTED_DR,JEL.ACCOUNTED_CR,JEL.GL_SEGMENT,
JEL.SEGMENT1,JEL.SEGMENT2,JEL.SEGMENT3,JEL.SEGMENT4,JEL.SEGMENT5,JEL.SEGMENT6,JEL.SEGMENT7,
JEL.SEGMENT1_DESC, JEL.SEGMENT2_DESC, JEL.SEGMENT3_DESC, JEL.SEGMENT4_DESC, JEL.SEGMENT5_DESC, JEL.SEGMENT6_DESC, JEL.SEGMENT7_DESC
FROM (
SELECT GLL.NAME AS AOC_NAME,
GLCC.SEGMENT1 AS AOC_ID,
GLJH.LEGAL_ENTITY_ID, GLCC.CHART_OF_ACCOUNTS_ID,
GLJB.NAME AS JE_BATCH_NAME, GLJB.JE_BATCH_ID, GLJB.DEFAULT_PERIOD_NAME,
TO_CHAR(CAST(GLJH.DEFAULT_EFFECTIVE_DATE AS DATE), 'YYYY') AS ACCT_YEAR,
TO_CHAR(CAST(GLJH.DEFAULT_EFFECTIVE_DATE AS DATE), 'YYYYMM') AS ACCT_PERIOD,
GLJH.DEFAULT_EFFECTIVE_DATE AS ACCT_DATE,
GLCC.SEGMENT3 AS ACCOUNT_ID,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,3,GLCC.SEGMENT3),1,40) ACCOUNT_NAME,
GLCC.SEGMENT5 ||'-'|| GLCC.SEGMENT4 AS ACCRUAL_PERIOD,
GLJH.DEFAULT_EFFECTIVE_DATE,
GLJH.JE_HEADER_ID, GLJH.NAME AS JOURNAL_NAME,
GLJH.LEDGER_ID, GLJH.JE_SOURCE,GLJH.PERIOD_NAME,
GLJH.STATUS, GLJH.DATE_CREATED, GLJH.POSTED_DATE, GLJH.DESCRIPTION, GLJL.DESCRIPTION AS DESCRIPTION_JL,
GLJL.CURRENCY_CODE AS TRX_CURR,
GLL.CURRENCY_CODE AS ACCT_CURR,
GLJL.ENTERED_DR, GLJL.ENTERED_CR,
NVL(GLJL.ENTERED_DR,0)+NVL(GLJL.ENTERED_CR,0) AS TRX_AMT,
GLJL.ACCOUNTED_DR,GLJL.ACCOUNTED_CR,
NVL(GLJL.ACCOUNTED_DR,0)+NVL(GLJL.ACCOUNTED_CR,0) AS ACCT_AMT,
GLCC.SEGMENT1 ||'-'|| GLCC.SEGMENT2 ||'-'|| GLCC.SEGMENT3 ||'-'|| GLCC.SEGMENT4 ||'-'|| GLCC.SEGMENT5 ||'-'|| GLCC.SEGMENT6 ||'-'|| GLCC.SEGMENT7 AS GL_SEGMENT,
GLCC.SEGMENT1,GLCC.SEGMENT2,GLCC.SEGMENT3,GLCC.SEGMENT4,GLCC.SEGMENT5,GLCC.SEGMENT6,GLCC.SEGMENT7,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,1,GLCC.SEGMENT1),1,40) SEGMENT1_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,2,GLCC.SEGMENT2),1,40) SEGMENT2_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,3,GLCC.SEGMENT3),1,40) SEGMENT3_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,4,GLCC.SEGMENT4),1,40) SEGMENT4_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,5,GLCC.SEGMENT5),1,40) SEGMENT5_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,6,GLCC.SEGMENT6),1,40) SEGMENT6_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,7,GLCC.SEGMENT7),1,40) SEGMENT7_DESC
FROM GL_LEDGERS GLL INNER JOIN GL_JE_HEADERS GLJH ON GLL.LEDGER_ID=GLJH.LEDGER_ID
--LEFT JOIN XLE_ENTITY_PROFILES E ON GLJH.LEGAL_ENTITY_ID = E.LEGAL_ENTITY_ID
--INNER JOIN GL_PERIOD_STATUSES GLPS ON GLL.LEDGER_ID=GLJH.LEDGER_ID AND GLJH.PERIOD_NAME=GLPS.PERIOD_NAME
INNER JOIN GL_JE_BATCHES GLJB ON GLJH.JE_BATCH_ID=GLJB.JE_BATCH_ID
INNER JOIN GL_JE_LINES GLJL ON GLJH.JE_HEADER_ID=GLJL.JE_HEADER_ID
INNER JOIN GL_CODE_COMBINATIONS GLCC ON GLJL.CODE_COMBINATION_ID=GLCC.CODE_COMBINATION_ID
)JEL
WHERE JEL.AOC_NAME IN (:AOC_NAME)
AND JEL.ACCOUNT_ID IN (:ACCRUAL_ACCT)
--AND JEL.ACCT_PERIOD <=:PERIOD_S5
AND JEL.ACCT_PERIOD <= (SELECT CURR_PERIOD FROM P)
AND JEL.SEGMENT4 IN (:SEGMENT_LOC)
AND (:SEGMENT5 IS NULL OR JEL.SEGMENT5 = :SEGMENT5)
--AND (:ACCT_ID IS NULL OR JEL.ACCOUNT_ID = :ACCT_ID)
AND JEL.STATUS = 'P'
)

---AP_IL---------------------------------------
,APIL AS (
SELECT 'APIL' AS T, DS2.*
FROM
(SELECT IL.ORG_ID, E.LEGAL_ENTITY_IDENTIFIER AS AOC, E.NAME AS AOC_NAME,
GCC.SEGMENT1 AS AOC_ID,
IH.INVOICE_NUM, IH.APPROVAL_STATUS,
IH.INVOICE_CURRENCY_CODE, IH.PAYMENT_CURRENCY_CODE,
IH.INVOICE_AMOUNT AS TRX_AMT_IH,
NVL(IH.BASE_AMOUNT,IH.INVOICE_AMOUNT) AS ACCT_AMT_IH,
IH.INVOICE_CURRENCY_CODE AS TRX_CURR,
IL.AMOUNT AS TRX_AMT,
IH.PAYMENT_CURRENCY_CODE AS ACCT_CURR,
NVL(IL.BASE_AMOUNT,IL.AMOUNT) AS ACCT_AMT,
regexp_replace(regexp_replace(E.NAME, '[(][A-Z]+[)]', ''), '[^a-zA-Z ]', '') AS AOC_NAME1,
TO_CHAR(IH.CREATION_DATE, 'YYYY') AS CREATION_YR,
TO_CHAR(IH.CREATION_DATE, 'YYYYMM') AS CREATION_PERIOD,
IH.CREATION_DATE,
TO_CHAR(IH.GL_DATE, 'YYYY') AS GL_YEAR,
TO_CHAR(IH.GL_DATE, 'YYYYMM') AS GL_PERIOD,
IH.GL_DATE AS GL_DATE,
TO_CHAR(IH.GL_DATE, 'YYYY') AS ACCT_YEAR,
TO_CHAR(IH.GL_DATE, 'YYYYMM') AS ACCT_PERIOD,
IH.GL_DATE AS ACCT_DATE,
GCC.SEGMENT3 AS ACCOUNT_ID,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( NVL(GCC.CHART_OF_ACCOUNTS_ID,'2001'),3,GCC.SEGMENT3),1,40) ACCOUNT_NAME,
GCC.SEGMENT5 ||'-'|| GCC.SEGMENT4 AS ACCRUAL_PERIOD,
IL.INVOICE_ID, IL.LINE_NUMBER, IL.LINE_TYPE_LOOKUP_CODE,
IL.DESCRIPTION, IL.LINE_SOURCE, IL.OVERLAY_DIST_CODE_CONCAT, GCC.SEGMENT1,GCC.SEGMENT2,GCC.SEGMENT3,GCC.SEGMENT4,GCC.SEGMENT5,GCC.SEGMENT6,GCC.SEGMENT7,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( NVL(GCC.CHART_OF_ACCOUNTS_ID,'2001'),3,GCC.SEGMENT3),1,40) SEGMENT3_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( NVL(GCC.CHART_OF_ACCOUNTS_ID,'2001'),4,GCC.SEGMENT4),1,40) SEGMENT4_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( NVL(GCC.CHART_OF_ACCOUNTS_ID,'2001'),5,GCC.SEGMENT5),1,40) SEGMENT5_DESC,
GCC.SEGMENT1 ||'-'|| GCC.SEGMENT2 ||'-'|| GCC.SEGMENT3 ||'-'|| GCC.SEGMENT4 ||'-'|| GCC.SEGMENT5 ||'-'|| GCC.SEGMENT6 ||'-'|| GCC.SEGMENT7 AS GL_SEGMENT,
IL.SET_OF_BOOKS_ID, IL.AMOUNT, IL.ASSESSABLE_VALUE, IL.TOTAL_REC_TAX_AMOUNT, IL.TAX_RATE_ID,IL.TAX_RATE_CODE,IL.TAX_RATE,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('ITEM') THEN IL.AMOUNT ELSE 0 END AS ITEM_AMT,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('TAX') THEN IL.AMOUNT ELSE 0 END AS TAX_AMT,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('AWT') THEN IL.AMOUNT ELSE 0 END AS WHT_AMT
FROM AP_INVOICES_ALL IH INNER JOIN XLE_ENTITY_PROFILES E
ON IH.LEGAL_ENTITY_ID=E.LEGAL_ENTITY_ID
INNER JOIN AP_INVOICE_LINES_ALL IL ON IH.INVOICE_ID=IL.INVOICE_ID
LEFT JOIN GL_CODE_COMBINATIONS GCC ON IL.DEFAULT_DIST_CCID=GCC.CODE_COMBINATION_ID
)DS2
WHERE DS2.AOC_NAME1 IN (:AOC_NAME)
AND DS2.ACCOUNT_ID IN (:EXPENSE_ACCT)
--AND DS2.ACCT_PERIOD=(SELECT CURR_PERIOD FROM P)
AND DS2.ACCT_DATE<=(SELECT CURR_DATE FROM P)
AND DS2.SEGMENT4 IN (:SEGMENT_LOC)
AND (:SEGMENT5 IS NULL OR DS2.SEGMENT5 = :SEGMENT5)
--AND (:ACCT_ID IS NULL OR DS2.ACCOUNT_ID = :ACCT_ID)
AND DS2.APPROVAL_STATUS='APPROVED'
)
---GLO1---------------------------------------
,GLO1 AS (
SELECT GLO.AOC_NAME, GLO.AOC_ID, GLO.ACCT_YEAR, GLO.ACCT_PERIOD, GLO.ACCRUAL_PERIOD,GLO.ACCOUNT_ID, GLO.SEGMENT4,GLO.SEGMENT5, GLO.ACCOUNT_NAME,GLO.ACCT_CURR,
ROW_NUMBER() OVER (PARTITION BY GLO.AOC_NAME, GLO.ACCOUNT_ID, GLO.ACCT_PERIOD, GLO.ACCRUAL_PERIOD ORDER BY GLO.ACCT_PERIOD ASC) AS RNA,
ROW_NUMBER() OVER (PARTITION BY GLO.AOC_NAME, GLO.ACCOUNT_ID, GLO.ACCT_PERIOD, GLO.ACCRUAL_PERIOD ORDER BY GLO.ACCT_PERIOD DESC) AS RND,
COUNT(GLO.JOURNAL_NAME) AS J_COUNT,
SUM(GLO.ACCT_AMT) AS ACCT_AMT
FROM GLO GLO
GROUP BY GLO.AOC_NAME, GLO.AOC_ID, GLO.ACCT_YEAR, GLO.ACCT_PERIOD, GLO.ACCRUAL_PERIOD,GLO.ACCOUNT_ID, GLO.SEGMENT4,GLO.SEGMENT5,GLO.ACCOUNT_NAME,GLO.ACCT_CURR)
---APIL1---------------------------------------
,APIL1 AS (
SELECT APIL.AOC_NAME1, APIL.AOC_ID, APIL.ACCT_YEAR,
APIL.ACCT_PERIOD, APIL.ACCRUAL_PERIOD, APIL.ACCOUNT_ID, APIL.ACCOUNT_NAME,APIL.SEGMENT4,APIL.SEGMENT5,
COUNT(APIL.INVOICE_NUM) AS INV_COUNT,
APIL.TRX_CURR,
SUM(APIL.TRX_AMT) AS TRX_AMT,
APIL.ACCT_CURR,
SUM(APIL.ACCT_AMT) AS ACCT_AMT
FROM APIL APIL
GROUP BY APIL.AOC_NAME1, APIL.AOC_ID, APIL.ACCT_YEAR,
APIL.ACCT_PERIOD, APIL.ACCRUAL_PERIOD, APIL.ACCOUNT_ID, APIL.ACCOUNT_NAME, APIL.TRX_CURR,APIL.ACCT_CURR,APIL.SEGMENT4,APIL.SEGMENT5
)


--SELECT 'P_SUM' AS T0, P.* FROM P P
--SELECT 'GLO_SUM' AS T0, GLO1.* FROM GLO1 GLO1
--SELECT 'APIL_SUM' AS T0, APIL1.* FROM APIL1 APIL1




SELECT 'AP_ACCR_RPT' AS T0, R.AOC_NAME, R.ACCRUAL_ACCT_ID, R.ACCRUAL_ACCT_NAME, R.ACCRUAL_PERIOD, R.ACCRUAL_PERIOD_AP, R.SEGMENT4,R.SEGMENT5,R.SEGMENT5_ISNUM,
R.ACCT_PERIOD, R.RNA，R.RND,
R.ACCT_CURR, R.ACCRRUAL_CR_AMT, R.ACTUAL_EXP_AMT,
R.CLOSE_BAL_ACCR_AMT, R.ACCR_ADJ__DR__CR,
CASE WHEN R.RND=1 AND R.RNA > 6 THEN 0
WHEN R.ACCR_ADJ__DR__CR <0 THEN 0 ELSE R.ACCR_ADJ__DR__CR END AS ACCR_ADJ__DR__CR_ADJUSTED,
R.EXPENSE_ACCT_ID, R.EXPENSE_ACCT_NAME FROM (
SELECT G.AOC_NAME,
G.ACCOUNT_ID AS ACCRUAL_ACCT_ID, G.ACCOUNT_NAME AS ACCRUAL_ACCT_NAME, G.ACCT_PERIOD, G.ACCRUAL_PERIOD,
G.SEGMENT4,G.SEGMENT5,
LENGTH(TRIM(TRANSLATE(G.SEGMENT5, ' +-.0123456789',' '))) AS SEGMENT5_ISNUM,
G.RNA，G.RND, G.ACCT_CURR, G.ACCT_AMT AS ACCRRUAL_CR_AMT,
NVL(A.ACCT_AMT,0) AS ACTUAL_EXP_AMT,
G.ACCT_AMT-NVL(A.ACCT_AMT,0) AS CLOSE_BAL_ACCR_AMT, ((G.ACCT_AMT-NVL(A.ACCT_AMT,0))-G.ACCT_AMT) AS ACCR_ADJ__DR__CR,
A.ACCOUNT_ID AS EXPENSE_ACCT_ID, A.ACCOUNT_NAME AS EXPENSE_ACCT_NAME, A.ACCRUAL_PERIOD AS ACCRUAL_PERIOD_AP
FROM GLO1 G LEFT JOIN APIL1 A ON G.ACCT_PERIOD=A.ACCT_PERIOD AND G.ACCRUAL_PERIOD=A.ACCRUAL_PERIOD
)R
WHERE R.SEGMENT5_ISNUM IS NULL
ORDER BY R.AOC_NAME, R.ACCRUAL_ACCT_ID, R.ACCT_PERIOD, R.ACCRUAL_PERIOD, R.RNA

--------------------------------------------------------------------------------------------------------------------------
--WHERE G.RNA=1 AND (:ACCRUAL_PERIOD IS NULL  OR G.ACCRUAL_PERIOD IN (:ACCRUAL_PERIOD))
--WHERE G.RNA=1 AND G.ACCRUAL_PERIOD IN (:ACCRUAL_PERIOD)















SELECT APIL.AOC_NAME1,
APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT3_DESC, APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE,
COUNT(APIL.INVOICE_ID) AS INV_COUNT,
SUM(AMOUNT) AS INV_AMT
FROM APIL APIL
GROUP BY APIL.AOC_NAME1, APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT3_DESC, APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE







---RPT DET-------------------------------
SELECT 'GL_VS_AP_DET1' AS GL,
GO.AOC_NAME, GO.ACCT_YEAR, GO.ACCOUNT_ID AS EXPENSE_ACCT，GO.ACCOUNT_NAME AS EXPENSE_ACCT_DESC，I.SEGMENT3 AS AP_ACCT, I.SEGMENT3_DESC AS AP_ACCT_DESC,
GO.SEGMENT4 AS LOC, GO.CURRENCY_CODE AS CURR_CODE,
GO.CURR_AMT AS OPEN_AMT,
GC.CURR_AMT AS CURR_AMT,
I.INV_AMT AS INV_AMT,
GO.CURR_AMT+GC.CURR_AMT+I.INV_AMT AS CLOSING_AMT
FROM
(
SELECT GLO.AOC_NAME, GLO.ACCT_YEAR, GLO.ACCOUNT_ID, GLO.ACCOUNT_NAME, GLO.STATUS, GLO.SEGMENT4, GLO.SEGMENT5, GLO.CURRENCY_CODE,
COUNT(GLO.JOURNAL_NAME) AS J_COUNT,
SUM(GLO.CURR_AMT) AS CURR_AMT,
SUM(GLO.ACCT_AMT) AS ACCT_AMT
FROM GLO GLO
GROUP BY GLO.AOC_NAME, GLO.ACCT_YEAR, GLO.ACCOUNT_ID, GLO.ACCOUNT_NAME, GLO.STATUS, GLO.SEGMENT4, GLO.SEGMENT5, GLO.CURRENCY_CODE
)GO
LEFT JOIN
(
SELECT GLC.AOC_NAME, GLC.ACCT_YEAR,  GLC.ACCOUNT_ID, GLC.ACCOUNT_NAME, GLC.STATUS, GLC.SEGMENT4, GLC.SEGMENT5, GLC.CURRENCY_CODE,
COUNT(GLC.JOURNAL_NAME) AS J_COUNT,
SUM(GLC.CURR_AMT) AS CURR_AMT,
SUM(GLC.ACCT_AMT) AS ACCT_AMT
FROM GLC GLC
GROUP BY GLC.AOC_NAME, GLC.ACCT_YEAR, GLC.ACCOUNT_ID, GLC.ACCOUNT_NAME, GLC.STATUS, GLC.SEGMENT4, GLC.SEGMENT5, GLC.CURRENCY_CODE
)GC
ON GO.AOC_NAME=GC.AOC_NAME
AND GO.ACCT_YEAR=GC.ACCT_YEAR
AND GO.SEGMENT5=GC.SEGMENT5
AND GO.SEGMENT4=GC.SEGMENT4
AND GO.CURRENCY_CODE=GC.CURRENCY_CODE
LEFT JOIN
(
SELECT APIL.AOC_NAME1,
APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT3_DESC, APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE,
COUNT(APIL.INVOICE_ID) AS INV_COUNT,
SUM(AMOUNT) AS INV_AMT
FROM APIL APIL
GROUP BY APIL.AOC_NAME1, APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT3_DESC, APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE
)I
ON GO.AOC_NAME=I.AOC_NAME1
AND GO.ACCT_YEAR=I.ACCT_YEAR_AP
--AND GO.ACCOUNT_ID=I.SEGMENT3
AND GO.SEGMENT5=I.SEGMENT5
AND GO.SEGMENT4=I.SEGMENT4
AND GO.CURRENCY_CODE=I.INVOICE_CURRENCY_CODE

---RPT SUM-------------------------------
SELECT 'GL_VS_AP_DET1' AS GL,
GO.AOC_NAME, GO.ACCT_YEAR, GO.ACCOUNT_ID AS EXPENSE_ACCT，GO.ACCOUNT_NAME AS EXPENSE_ACCT_DESC，
GO.SEGMENT4 AS LOC, GO.CURRENCY_CODE AS CURR_CODE,
GO.CURR_AMT AS OPEN_AMT,
GC.CURR_AMT AS CURR_AMT,
I.INV_AMT AS INV_AMT,
GO.CURR_AMT+GC.CURR_AMT+I.INV_AMT AS CLOSING_AMT
FROM
(
SELECT GLO.AOC_NAME, GLO.ACCT_YEAR, GLO.ACCOUNT_ID, GLO.ACCOUNT_NAME, GLO.STATUS, GLO.SEGMENT4, GLO.SEGMENT5, GLO.CURRENCY_CODE,
COUNT(GLO.JOURNAL_NAME) AS J_COUNT,
SUM(GLO.CURR_AMT) AS CURR_AMT,
SUM(GLO.ACCT_AMT) AS ACCT_AMT
FROM GLO GLO
GROUP BY GLO.AOC_NAME, GLO.ACCT_YEAR, GLO.ACCOUNT_ID, GLO.ACCOUNT_NAME, GLO.STATUS, GLO.SEGMENT4, GLO.SEGMENT5, GLO.CURRENCY_CODE
)GO
LEFT JOIN
(
SELECT GLC.AOC_NAME, GLC.ACCT_YEAR,  GLC.ACCOUNT_ID, GLC.ACCOUNT_NAME, GLC.STATUS, GLC.SEGMENT4, GLC.SEGMENT5, GLC.CURRENCY_CODE,
COUNT(GLC.JOURNAL_NAME) AS J_COUNT,
SUM(GLC.CURR_AMT) AS CURR_AMT,
SUM(GLC.ACCT_AMT) AS ACCT_AMT
FROM GLC GLC
GROUP BY GLC.AOC_NAME, GLC.ACCT_YEAR, GLC.ACCOUNT_ID, GLC.ACCOUNT_NAME, GLC.STATUS, GLC.SEGMENT4, GLC.SEGMENT5, GLC.CURRENCY_CODE
)GC
ON GO.AOC_NAME=GC.AOC_NAME
AND GO.ACCT_YEAR=GC.ACCT_YEAR
AND GO.SEGMENT5=GC.SEGMENT5
AND GO.SEGMENT4=GC.SEGMENT4
AND GO.CURRENCY_CODE=GC.CURRENCY_CODE
LEFT JOIN
(
SELECT APIL.AOC_NAME1,
APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE,
COUNT(APIL.INVOICE_ID) AS INV_COUNT,
SUM(AMOUNT) AS INV_AMT
FROM APIL APIL
GROUP BY APIL.AOC_NAME1, APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT5_DESC, APIL.ACCT_YEAR_AP, APIL.INVOICE_CURRENCY_CODE
)I
ON GO.AOC_NAME=I.AOC_NAME1
AND GO.ACCT_YEAR=I.ACCT_YEAR_AP
--AND GO.ACCOUNT_ID=I.SEGMENT3
AND GO.SEGMENT5=I.SEGMENT5
AND GO.SEGMENT4=I.SEGMENT4
AND GO.CURRENCY_CODE=I.INVOICE_CURRENCY_CODE

/*
SELECT 'GL_VS_AP_SUM' AS GL, G.AOC_NAME, G.GL_SEGMENT, G.ACCOUNT_ID，G.ACCOUNT_NAME，G.SEGMENT5 AS SEGMENT5_GL, G.STATUS, G.J_COUNT, G.CURRENCY_CODE, G.CURR_AMT, G.ACCT_AMT,
'INV' AS INV, I.INV_COUNT, I.INV_AMT, I.INVOICE_CURRENCY_CODE AS INV_CURR_CODE_AP, I.SEGMENT5 AS SEGMENT5_AP, I.GL_SEGMENT AS GL_SEGMENT_AP, I.SEGMENT5_DESC AS SEGMENT5_DESC_AP, I.SEGMENT3 AS ACCOUNT_ID_AP, I.AOC_NAME1 AS AOC_NAME_AP
FROM (
SELECT GLA.AOC_NAME, GLA.ACCT_PERIOD, GLA.ACCOUNT_ID, GLA.ACCOUNT_NAME, GLA.STATUS, GLA.GL_SEGMENT, GLA.SEGMENT5, GLA.CURRENCY_CODE,
COUNT(GLA.JOURNAL_NAME) AS J_COUNT,
SUM(GLA.CURR_AMT) AS CURR_AMT,
SUM(GLA.ACCT_AMT) AS ACCT_AMT
FROM GLA GLA
GROUP BY GLA.AOC_NAME, GLA.ACCT_PERIOD, GLA.ACCOUNT_ID, GLA.ACCOUNT_NAME, GLA.STATUS, GLA.GL_SEGMENT, GLA.SEGMENT5, GLA.CURRENCY_CODE
)G
LEFT JOIN
(
SELECT APIL.AOC_NAME1, APIL.GL_SEGMENT,
APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT5_DESC, APIL.INVOICE_CURRENCY_CODE,
COUNT(APIL.INVOICE_ID) AS INV_COUNT,
SUM(AMOUNT) AS INV_AMT
FROM APIL APIL
GROUP BY APIL.AOC_NAME1, APIL.GL_SEGMENT,
APIL.SEGMENT1,APIL.SEGMENT2,APIL.SEGMENT3,APIL.SEGMENT4,APIL.SEGMENT5,APIL.SEGMENT6,APIL.SEGMENT7,APIL.SEGMENT5_DESC, APIL.INVOICE_CURRENCY_CODE
)I
ON G.AOC_NAME=I.AOC_NAME1
--AND G.ACCOUNT_ID=I.SEGMENT3
AND G.SEGMENT5=I.SEGMENT5
AND G.CURRENCY_CODE=I.INVOICE_CURRENCY_CODE
ORDER BY G.AOC_NAME, G.SEGMENT5, G.ACCT_PERIOD, G.CURRENCY_CODE
*/
---COA---
SELECT DISTINCT A.SEGMENT5 FROM (
SELECT GLCC.SEGMENT1 ||'-'|| GLCC.SEGMENT2 ||'-'|| GLCC.SEGMENT3 ||'-'|| GLCC.SEGMENT4 ||'-'|| GLCC.SEGMENT5 ||'-'|| GLCC.SEGMENT6 ||'-'|| GLCC.SEGMENT7 AS GL_SEGMENT,
GLCC.SEGMENT1,GLCC.SEGMENT2,GLCC.SEGMENT3,GLCC.SEGMENT4,GLCC.SEGMENT5,GLCC.SEGMENT6,GLCC.SEGMENT7,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,1,GLCC.SEGMENT1),1,40) SEGMENT1_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,2,GLCC.SEGMENT2),1,40) SEGMENT2_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,3,GLCC.SEGMENT3),1,40) SEGMENT3_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,4,GLCC.SEGMENT4),1,40) SEGMENT4_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,5,GLCC.SEGMENT5),1,40) SEGMENT5_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,6,GLCC.SEGMENT6),1,40) SEGMENT6_DESC,
SUBSTR(GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL( GLCC.CHART_OF_ACCOUNTS_ID,7,GLCC.SEGMENT7),1,40) SEGMENT7_DESC
FROM GL_CODE_COMBINATIONS GLCC)A


---GL_TRANS_BUD (BUDGET)---------------------------------------

SELECT DS.* FROM (
SELECT 'BUDGET TRANS' AS T0, 'XCC_CONTROL_BUDGETS' AS T1, GLL.NAME AS AOC_NAME, XCB.LEDGER_ID, XBA.BUDGET_CHART_OF_ACCOUNTS_ID, XCB.NAME, XCPS.PERIOD_NAME, XCPS.PERIOD_NUM, XCPS.STATUS_CODE, XCPS.FISCAL_YEAR, XCPS.BUDGET_EFFECTIVE_PERIOD_NUM,
XCPS.BUDGET_PERIOD_NUM, lpad(XCPS.BUDGET_PERIOD_NUM, 2, '0') MONTH_PAD,
XCPS.FISCAL_YEAR AS ACCT_YEAR,
XCPS.FISCAL_YEAR ||lpad(XCPS.BUDGET_PERIOD_NUM, 2, '0') AS ACCT_MONTH,
XCPS.QUARTER_NUM,
XBA.BUDGET_CODE_COMBINATION_ID,
xcc_budget_analysis_pkg.get_seg_details_from_label(XBA.BUDGET_CHART_OF_ACCOUNTS_ID,XBA.BUDGET_CODE_COMBINATION_ID,XCB.control_budget_id,1,'LABEL') AS seg1_label,
xcc_budget_analysis_pkg.get_seg_details_from_label(XBA.BUDGET_CHART_OF_ACCOUNTS_ID,XBA.BUDGET_CODE_COMBINATION_ID,XCB.control_budget_id,1,'VALUE') AS seg1_code,
xcc_budget_analysis_pkg.get_seg_details_from_label(XBA.BUDGET_CHART_OF_ACCOUNTS_ID,XBA.BUDGET_CODE_COMBINATION_ID,XCB.control_budget_id,3,'LABEL') seg3_label,
XBA.SEGMENT_VALUE1,XBA.SEGMENT_VALUE2,XBA.SEGMENT_VALUE3,
XBA.SEGMENT_VALUE1 ||'-'|| XBA.SEGMENT_VALUE2||'-'||XBA.SEGMENT_VALUE3 AS SEGMENT_COMB,
XB.budget_amount, ( NVL(XB.commitment_amount,0) + NVL(XB.obligation_amount,0) + NVL(XB.other_amount,0) + NVL(XB.actual_amount,0) ) consumption
FROM GL_LEDGERS GLL INNER JOIN XCC_CONTROL_BUDGETS XCB ON GLL.LEDGER_ID=XCB.LEDGER_ID
LEFT JOIN XCC_BALANCES XB ON XCB.CONTROL_BUDGET_ID=XB.CONTROL_BUDGET_ID
LEFT JOIN XCC_BUDGET_ACCOUNTS XBA ON XB.BUDGET_CCID=XBA.BUDGET_CODE_COMBINATION_ID
LEFT JOIN XCC_CB_PERIOD_STATUSES XCPS ON XB.period_name = XCPS.period_name AND XB.control_budget_id = XCPS.control_budget_id
)DS
--WHERE DS.BUDGET_CODE_COMBINATION_ID='300000004498400' AND
WHERE DS.SEGMENT_COMB='221-000-41112'
