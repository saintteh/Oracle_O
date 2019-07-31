--------IH------------
WITH IH AS (
SELECT 'AP_IH' AS T, H.* FROM (
SELECT
			--APIA.INVOICE_ID, APIA.ORG_ID  , PSV.SEGMENT1  , PSV.PARTY_ID  , APIA.LEGAL_ENTITY_ID  , APIA.FUNDS_STATUS  , APIA.INVOICE_RECEIVED_DATE
			APIA.SOURCE
		  , APIA.SOURCE_GRP
		  , APIA.ORG_ID
		  , APIA.INVOICE_NUM
		  , APIA.INVOICE_ID
		  , APIA.SUPPLIER_TAX_INVOICE_NUMBER
		  --, APIL.VAT_F, APIL.WHT_F
		  , APIL.TAX_FLAG
		  , APIL.WHT_FLAG
		  , APIL.FLAG
		  , APIA.REQUESTER_ID
		  , E.LEGAL_ENTITY_IDENTIFIER AS AOC
		  , APIA.DOC_CATEGORY_CODE    AS DOC_CAT
		  , APIA.VENDOR_ID
		  , PSV.VENDOR_NAME
		  , PSV.VENDOR_TYPE_LOOKUP_CODE AS VEND_TYPE
		  , APIA.DESCRIPTION
		  , APIA.INVOICE_CURRENCY_CODE
		  , APIA.PAYMENT_CURRENCY_CODE
		  , APIA.INVOICE_AMOUNT
		  , APIA.TOTAL_TAX_AMOUNT
		  , APIA.INVOICE_DATE
		  , APIA.GL_DATE AS ACCOUNTING_DATE
		  , APIA.CANCELLED_DATE
		  , APIA.CANCELLED_BY
		  , APIA.WFAPPROVAL_STATUS
		  , APIA.APPROVAL_STATUS
		  , APIA.LAST_UPDATE_DATE
		  , APIA.LAST_UPDATED_BY
		  , APIA.CREATED_BY
		  , APIA.CREATION_DATE
		  , TO_CHAR(APIA.CREATION_DATE, 'YYYYMM') AS CREATION_PERIOD
		  , S.INITIATED_DATE
		  , S.INITIATED_BY
		  , S.ASSIGNED_BY
		  , S.ASSIGNED_DATE
		  , S.APPROVED_BY
		  , S.APPROVED_DATE
		  , S.STAGE_DATE
		  , S.STAGE_STATUS AS STAGE_STATUS_ORIG
		  , CASE
				WHEN S.STAGE_STATUS IS NULL
					THEN APIA.APPROVAL_STATUS
					ELSE S.STAGE_STATUS
			END AS STAGE_STATUS
		  , CASE
				WHEN APIA.SOURCE_GRP ='AMOS' AND S.INITIATED_DATE IS NOT NULL THEN S.INITIATED_DATE
				WHEN APIA.SOURCE_GRP ='AMOS' AND S.INITIATED_DATE IS NULL THEN APIA.CREATION_DATE
				WHEN APIA.SOURCE_GRP ='TAX'	THEN APIA.CREATION_DATE
				WHEN APIA.SOURCE_GRP ='GEN' THEN APIA.CREATION_DATE
				--ELSE APIA.CREATION_DATE
			END AS AGE_START_DATE
		  , CASE
				WHEN S.STAGE_DATE IS NOT NULL THEN S.STAGE_DATE
				WHEN S.STAGE_DATE IS NULL THEN APIA.LAST_UPDATE_DATE
			END AS AGE_END_DATE
		FROM
			(
				SELECT
					CASE
						WHEN APIA.SOURCE IN ('AMOS')
							THEN 'AMOS'
						WHEN APIA.SOURCE IN ('Withholding tax'
										   , 'ISP')
							THEN 'TAX'
						WHEN APIA.SOURCE NOT IN ('AMOS'
											   , 'Withholding tax'
											   , 'ISP')
							THEN 'GEN'
							ELSE 'UNKNOWN'
					END AS SOURCE_GRP
				  , APIA.*
				FROM
					AP_INVOICES_ALL APIA
			)
			APIA
			LEFT JOIN
				(SELECT A.INVOICE_ID,
				CASE WHEN A.VAT_F>0 THEN 'YES' ELSE 'NO' END AS TAX_FLAG,
				CASE WHEN A.WHT_F>0 THEN 'YES' ELSE 'NO' END AS WHT_FLAG,
				CASE WHEN A.VAT_F>0 AND A.WHT_F=0 THEN 'VAT'
				WHEN A.VAT_F>0 AND A.WHT_F>0 THEN 'VAT+WHT'
				WHEN A.VAT_F=0 AND A.WHT_F>0 THEN 'WHT' ELSE 'NO_TAX'
				END AS FLAG FROM
								(
								SELECT IL.INVOICE_ID, SUM(CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('TAX') THEN 1 ELSE 0 END) AS VAT_F,
								SUM(CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('AWT') THEN 1 ELSE 0 END) AS WHT_F
								FROM AP_INVOICE_LINES_ALL IL
								GROUP BY IL.INVOICE_ID
								)A

			)APIL ON APIA.INVOICE_ID=APIL.INVOICE_ID
			LEFT JOIN
				XLE_ENTITY_PROFILES E
				ON
					APIA.LEGAL_ENTITY_ID=E.LEGAL_ENTITY_ID
			LEFT JOIN
				POZ_SUPPLIERS_V PSV
				ON
					APIA.VENDOR_ID=PSV.VENDOR_ID
			LEFT JOIN
				(
					SELECT
						X.INVOICE_ID
					  , SYSDATE AS CURR_DATE
					  , MAX(DECODE(X.RN
									 , '1', X.RESPONSE))STAGE_STATUS
					  , MAX(DECODE(X.RN
									 , '1', X.CREATION_DATE))STAGE_DATE
					  , MAX(DECODE(X.RESPONSE
									 , 'INITIATED', X.APPROVER_ID))INITIATED_BY
					  , MAX(DECODE(X.RESPONSE
									 , 'INITIATED', X.CREATION_DATE))INITIATED_DATE
					  , MAX(DECODE(X.RESPONSE
									 , 'ORA_ASSIGNED TO', X.APPROVER_ID))ASSIGNED_BY
					  , MAX(DECODE(X.RESPONSE
									 , 'ORA_ASSIGNED TO', X.CREATION_DATE))ASSIGNED_DATE
					  , MAX(DECODE(X.RESPONSE
									 , 'APPROVED', X.APPROVER_ID))APPROVED_BY
					  , MAX(DECODE(X.RESPONSE
									 , 'APPROVED', X.CREATION_DATE))APPROVED_DATE
					FROM
						(
							SELECT
								'AP_INV_APRVL_HIST_ALL' AS T
							  , ROW_NUMBER() OVER (PARTITION BY A.ORG_ID, A.INVOICE_ID ORDER BY
												   A.CREATION_DATE DESC) AS RN
							  , A.ORG_ID
							  , A.INVOICE_ID
							  , A.RESPONSE
							  , A.APPROVER_ID
							  , A.CREATION_DATE
							  , A.LAST_UPDATE_DATE
							FROM
								AP_INV_APRVL_HIST_ALL A
								--WHERE A.INVOICE_ID='300000006603871'
						)
						X
					GROUP BY
						X.INVOICE_ID
				)
				S
				ON
					APIA.INVOICE_ID=S.INVOICE_ID
				--WHERE E.LEGAL_ENTITY_IDENTIFIER IN (:AOC) AND APIA.INVOICE_NUM=:INVOICE_NUM
					)H
	WHERE H.AOC IN (:AOC) AND H.CREATION_PERIOD IN (:INVOICE_PERIOD)
	AND (H.FLAG IN (:FLAG))
	AND (:INVOICE_NUM IS NULL OR H.INVOICE_NUM = :INVOICE_NUM)

)
--------IL------------
,IL AS (
SELECT 'AP_IL' AS T, DS2.* FROM
(SELECT --'AP_INVOICE_LINES_ALL_01' AS T,
IH.INVOICE_NUM, IL.ORG_ID,
E.LEGAL_ENTITY_IDENTIFIER AS AOC,
TO_CHAR(IH.CREATION_DATE, 'YYYYMM') AS CREATION_PERIOD,
IL.INVOICE_ID, IL.LINE_NUMBER, IL.LINE_TYPE_LOOKUP_CODE,
IL.DESCRIPTION, IL.LINE_SOURCE, IL.OVERLAY_DIST_CODE_CONCAT,
IL.SET_OF_BOOKS_ID, IL.AMOUNT, IL.ASSESSABLE_VALUE, IL.TOTAL_REC_TAX_AMOUNT, IL.TAX_RATE_ID,IL.TAX_RATE_CODE,IL.TAX_RATE,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('ITEM') THEN IL.AMOUNT ELSE 0 END AS BASE_AMT,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('TAX') THEN IL.AMOUNT ELSE 0 END AS TAX_AMT,
CASE WHEN IL.LINE_TYPE_LOOKUP_CODE IN ('AWT') THEN IL.AMOUNT ELSE 0 END AS WHT_AMT
FROM AP_INVOICES_ALL IH INNER JOIN XLE_ENTITY_PROFILES E
ON IH.LEGAL_ENTITY_ID=E.LEGAL_ENTITY_ID
INNER JOIN AP_INVOICE_LINES_ALL IL ON IH.INVOICE_ID=IL.INVOICE_ID
)DS2
WHERE DS2.AOC IN (:AOC) AND DS2.CREATION_PERIOD IN (:INVOICE_PERIOD) AND (:INVOICE_NUM IS NULL  OR DS2.INVOICE_NUM = :INVOICE_NUM)
)
,IT AS (
SELECT DS3.* FROM (
SELECT 'ZX_WITHHOLDING_LINES_02' AS T, IH.INVOICE_NUM, IL.ORG_ID,
E.LEGAL_ENTITY_IDENTIFIER AS AOC,
TO_CHAR(IH.CREATION_DATE, 'YYYYMM') AS CREATION_PERIOD,
IL.INVOICE_ID, IL.LINE_NUMBER, IL.AMOUNT,
IL.TAX_CLASSIFICATION_CODE AS VAT_CODE,
ZRB.PERCENTAGE_RATE AS VAT_RATE,
NVL(IL.AMOUNT,0)*ZRB.PERCENTAGE_RATE/100 AS VAT_AMT,
ZWL.CAL_TAXABLE_AMT, ZWL.LAST_MANUAL_ENTRY, ZWL.LINE_AMT, ZWL.ORIG_TAX_AMT,
ZWL.ORIG_TAX_RATE, ZWL.SUMMARY_TAX_LINE_ID, ZWL.TAX, ZWL.TAXABLE_AMT, ZWL.TAX_AMT, ZWL.TAX_ID, ZWL.TAX_JURISDICTION_CODE,ZWL.TAX_RATE,
ZWL.TAX_RATE_CODE AS WHT_CODE,
ZWL.TAX_AMT AS WHT_AMT,
ZWL.TAX_RATE_ID,
ZWL.TAX_JURISDICTION_ID, ZWL.TAX_STATUS_CODE, ZWL.TAX_STATUS_ID, ZWL.TAX_TYPE_CODE,  ZWL.UNIT_PRICE, ZWL.UNROUNDED_TAX_AMT, ZWL.UNROUNDED_TAXABLE_AMT
FROM AP_INVOICES_ALL IH INNER JOIN XLE_ENTITY_PROFILES E
ON IH.LEGAL_ENTITY_ID=E.LEGAL_ENTITY_ID
INNER JOIN AP_INVOICE_LINES_ALL IL ON IH.INVOICE_ID=IL.INVOICE_ID
LEFT JOIN ZX_WITHHOLDING_LINES ZWL ON IL.INVOICE_ID=ZWL.TRX_ID
AND IL.ORG_ID=ZWL.INTERNAL_ORGANIZATION_ID AND IL.LINE_NUMBER=ZWL.TRX_LINE_ID
LEFT JOIN ZX_RATES_B ZRB ON IL.TAX_CLASSIFICATION_CODE=ZRB.TAX_RATE_CODE	-- 	300000006610574
)DS3
WHERE DS3.AOC IN (:AOC) AND DS3.CREATION_PERIOD IN (:INVOICE_PERIOD) AND (:INVOICE_NUM IS NULL  OR DS3.INVOICE_NUM = :INVOICE_NUM)
)


/*
SELECT IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE,
COUNT(IT1.LINE_NUMBER) AS LINE_COUNT, SUM(IT1.BASE_AMT) AS BASE_AMT, SUM(IT1.TAX_AMT) AS TAX_AMT
FROM (
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.VAT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.VAT_AMT AS TAX_AMT FROM IT IT
UNION ALL
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.WHT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.WHT_AMT AS TAX_AMT FROM IT IT
)IT1
GROUP BY IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE
*/
/*
SELECT 'AP_TAX_RPT_00' AS T, A.* FROM (
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.VAT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.VAT_AMT AS TAX_AMT FROM IT IT
UNION ALL
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.WHT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.WHT_AMT AS TAX_AMT FROM IT IT)A
*/
SELECT DS.* FROM (
SELECT T.* FROM (
SELECT 'AP_TAX_RPT' AS T, IH.AOC,IH.INVOICE_NUM,IH.VENDOR_NAME,IH.SUPPLIER_TAX_INVOICE_NUMBER AS TAX_INVOICE_NUMBER,
IH.INVOICE_DATE, IH.ACCOUNTING_DATE, IH.DESCRIPTION, IH.APPROVAL_STATUS, IH.FLAG,
NVL(IT2.TAX_CODE,'NIL') AS TAX_CODE,
IT2.BASE_AMT,
ROUND(NVL(IT2.TAX_AMT,0),0) AS TAX_AMT
FROM IH LEFT JOIN
(
SELECT IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE,
COUNT(IT1.LINE_NUMBER) AS LINE_COUNT, SUM(IT1.BASE_AMT) AS BASE_AMT, SUM(IT1.TAX_AMT) AS TAX_AMT
FROM (
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.VAT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.VAT_AMT AS TAX_AMT FROM IT IT
UNION ALL
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.WHT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.WHT_AMT AS TAX_AMT FROM IT IT
)IT1
GROUP BY IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE
)IT2
ON
IH.ORG_ID=IT2.ORG_ID AND
IH.INVOICE_ID=IT2.INVOICE_ID)T
WHERE T.FLAG <> 'NO_TAX' AND T.TAX_CODE<>'NIL'
--ORDER BY IH.AOC,IH.APPROVAL_STATUS,IH.INVOICE_DATE,IH.INVOICE_NUM

UNION ALL

SELECT 'AP_TAX_RPT' AS T, IH.AOC,IH.INVOICE_NUM,IH.VENDOR_NAME,IH.SUPPLIER_TAX_INVOICE_NUMBER AS TAX_INVOICE_NUMBER,
IH.INVOICE_DATE, IH.ACCOUNTING_DATE, IH.DESCRIPTION, IH.APPROVAL_STATUS, IH.FLAG,
NVL(IT2.TAX_CODE,'NIL') AS TAX_CODE,
IT2.BASE_AMT,
ROUND(NVL(IT2.TAX_AMT,0),0) AS TAX_AMT
FROM IH LEFT JOIN
(
SELECT IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE,
COUNT(IT1.LINE_NUMBER) AS LINE_COUNT, SUM(IT1.BASE_AMT) AS BASE_AMT, SUM(IT1.TAX_AMT) AS TAX_AMT
FROM (
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.VAT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.VAT_AMT AS TAX_AMT FROM IT IT
UNION ALL
SELECT IT.INVOICE_NUM, IT.ORG_ID, IT.AOC, IT.CREATION_PERIOD, IT.INVOICE_ID, IT.LINE_NUMBER, IT.WHT_CODE AS TAX_CODE,  IT.AMOUNT AS BASE_AMT, IT.WHT_AMT AS TAX_AMT FROM IT IT
)IT1
GROUP BY IT1.INVOICE_NUM, IT1.ORG_ID, IT1.AOC, IT1.CREATION_PERIOD, IT1.INVOICE_ID, IT1.TAX_CODE
)IT2
ON
IH.ORG_ID=IT2.ORG_ID AND
IH.INVOICE_ID=IT2.INVOICE_ID
WHERE IH.FLAG = 'NO_TAX'
--ORDER BY IH.AOC,IH.APPROVAL_STATUS,IH.INVOICE_DATE,IH.INVOICE_NUM
)DS

ORDER BY DS.AOC,DS.APPROVAL_STATUS,DS.INVOICE_DATE,DS.INVOICE_NUM
