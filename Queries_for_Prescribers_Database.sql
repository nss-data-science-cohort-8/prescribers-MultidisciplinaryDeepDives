--EDA:

SELECT *
FROM drug  
-- WHERE drug_name = 'ARIPIPRAZOLE'
ORDER BY drug_name
;



SELECT *
FROM prescription 
-- WHERE drug_name = 'ARIPIPRAZOLE'
ORDER BY npi
;


SELECT * 
FROM cbsa
;


SELECT * 
FROM fips_county
;


SELECT *
FROM population
;



-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- Ans: NPI: 1912011792; total number of claims: 4538

SELECT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC
LIMIT 1
;



-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
-- Ans:  

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, prescriber.npi, total_claim_count
FROM prescriber
INNER JOIN prescription on prescriber.npi = prescription.npi
ORDER BY total_claim_count DESC 
;


-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
--Ans: Family Medicine / Practice


SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, prescriber.npi, total_claim_count
FROM prescriber
INNER JOIN prescription on prescriber.npi = prescription.npi
ORDER BY total_claim_count DESC 
;



-- 2b. Which specialty had the most total number of claims for opioids?
--Ans: Nurse Practitioner (though listed under specialty, it's a clinical role, not a specialty) and Family Medicine / Practice

 
SELECT prescriber.specialty_description, COUNT(prescription.*) AS Overall_Opioid_Prescription_Count
FROM (SELECT * 
		FROM drug 
		WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') as drug
INNER JOIN prescription ON drug.drug_name = prescription.drug_name 
INNER JOIN prescriber ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY Overall_Opioid_Prescription_Count DESC
; 

 
/*
SELECT pb.specialty_description, COUNT(pn.*) AS Overall_Opioid_Prescription_Count
FROM (SELECT *
		FROM drug 
		WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') AS d
INNER JOIN prescription AS pn ON UPPER(TRIM(d.generic_name)) = UPPER(TRIM(pn.drug_name)) OR UPPER(TRIM(d.brand_name)) = UPPER(TRIM(pn.drug_name))  --This OR logic arrangement within JOIN clause should work well
INNER JOIN prescriber AS pb ON pb.npi = pn.npi
GROUP BY pb.specialty_description
ORDER BY Overall_Opioid_Prescription_Count DESC
;
*/


 





-- 2c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
--Ans: Yes
 
SELECT prescriber.specialty_description, COUNT(prescription.*) AS prescription_count  
FROM drug
FULL JOIN prescription ON drug.drug_name = prescription.drug_name 
FULL JOIN prescriber ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY prescription_count 
;



-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?




SELECT COUNT(name)
FROM(SELECT name,
		COUNT(CASE WHEN gender = 'F' THEN 'f_count' END) AS F_count,
		COUNT(CASE WHEN gender = 'M' THEN 'm_count' END) AS M_count
	FROM names
	GROUP BY name
	ORDER BY F_count DESC) AS counts
WHERE F_count > 0
AND M_count > 0
;






-- 3a. Which drug (generic_name) had the highest total drug cost?
-- Ans: "INSULIN GLARGINE,HUM.REC.ANLOG" has the highest total drug cost ($104264066.35)

SELECT generic_name, SUM(total_drug_cost)
FROM prescription
INNER JOIN drug ON drug.drug_name = prescription.drug_name 
GROUP BY generic_name
ORDER BY SUM(total_drug_cost) DESC
;



-- 3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
-- Ans: C1 ESTERASE INHIBITOR 

SELECT generic_name, ROUND((SUM(total_drug_cost)/SUM(total_day_supply)), 2) AS drug_cost_per_day
FROM prescription as p
LEFT JOIN drug as d ON  d.drug_name = p.drug_name 
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC
;



-- to test out the REPLACE() AND UPPER() functions in the context of a JOIN
SELECT generic_name, REPLACE(UPPER(generic_name), ' ', ''), ROUND((SUM(total_drug_cost)/SUM(total_day_supply)), 2) AS drug_cost_per_day
FROM prescription as p
LEFT JOIN drug as d ON REPLACE(UPPER(d.drug_name), ' ', '') = REPLACE(UPPER(p.drug_name), ' ', '')
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC
;



-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
-- Ans: 

-- Stringent way of writing, covering all the bases:

SELECT drug_name, (CASE 
					WHEN (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') AND antibiotic_drug_flag = 'N' THEN 'Opioid'
					WHEN antibiotic_drug_flag = 'Y' AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') THEN 'Antibiotic'
					ELSE 'Neither' END
						) AS Drug_Type
FROM drug
;



--Simplified way of writing, though less stringent

SELECT drug_name, (CASE 
					WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'Opioid'
					WHEN antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
					ELSE 'Neither' END
						) AS Drug_Type
FROM drug
;




-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
-- Ans: Opioids' total cost exceed that of Antibiotics

SELECT (CASE WHEN opioids_total_drug_costs > Abx_total_drug_costs then 'true' else 'false' end) AS do_Opioids_cost_more_than_Abx_in_total_cost
FROM (SELECT SUM(total_drug_cost) 
		FROM drug AS d
		INNER JOIN prescription AS p ON d.drug_name = p.drug_name
		WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') AS opioids_total_drug_costs,
     (SELECT SUM(total_drug_cost) 
		FROM drug AS d
		INNER JOIN prescription AS p ON d.drug_name = p.drug_name
		WHERE antibiotic_drug_flag = 'Y') AS Abx_total_drug_costs
;




-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
-- Ans: 10

SELECT count(DISTINCT cbsa)
FROM fips_county AS f
INNER JOIN cbsa AS c ON c.fipscounty = f.fipscounty
WHERE state = 'TN'
;



-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
-- Ans: Largest CBSA is 34980; it has a total population of 1830410. Smallest CBSA is 34100; it has a total population of 116352. 


SELECT c.cbsa, SUM(p.population)
FROM population AS p
INNER JOIN cbsa AS c ON c.fipscounty = p.fipscounty
GROUP BY c.cbsa
ORDER BY SUM(p.population) DESC
LIMIT 1
;


SELECT c.cbsa, SUM(p.population)
FROM population AS p
INNER JOIN cbsa AS c ON c.fipscounty = p.fipscounty
GROUP BY c.cbsa
ORDER BY SUM(p.population)  
LIMIT 1
;



-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
-- Ans: Sevier County has the largest population (95523) out of all the counties that are not included in a CBSA, 

SELECT county, p.population
FROM fips_county AS f
INNER JOIN population AS p ON p.fipscounty = f.fipscounty
WHERE p.fipscounty NOT IN 
	(SELECT subQ_c.fipscounty 
		FROM cbsa AS subQ_c)
ORDER BY p.population DESC
;





-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
;


-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT p.drug_name, total_claim_count, (CASE 
										WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'Yes'
										ELSE 'No' END
											) AS Opioid_Drug_Type
FROM prescription AS p
INNER JOIN drug AS d ON d.drug_name = p.drug_name
WHERE total_claim_count >= 3000
;


-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.


SELECT nppes_provider_first_name, nppes_provider_last_org_name, pn.drug_name, total_claim_count, (CASE 
																									WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'Yes'
																									ELSE 'No' END
																										) AS Opioid_Drug_Type
FROM prescription AS pn
INNER JOIN drug AS d ON d.drug_name = pn.drug_name
INNER JOIN prescriber AS pb ON pb.npi = pn.npi
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC
;



-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--My initial solution: 
SELECT pn.npi, pn.drug_name, pn.total_claim_count, SUM(pn.total_claim_count) AS claims_per_drug_per_prescriber
FROM prescription AS pn
INNER JOIN drug AS d ON d.drug_name = pn.drug_name
INNER JOIN prescriber AS pb ON pb.npi = pn.npi 
WHERE nppes_provider_city = 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y')  
GROUP BY pn.npi, pn.drug_name, pn.total_claim_count
ORDER BY claims_per_drug_per_prescriber DESC
;



-- Michael's way or a simulacrum thereof: 

SELECT *
FROM prescriber AS pb
CROSS JOIN drug  
WHERE nppes_provider_city = 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') 
ORDER BY pb.npi
;





-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT *
FROM prescriber AS pb
CROSS JOIN drug  
WHERE nppes_provider_city = 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') 
ORDER BY pb.npi
;






--Alt solution 1:

WITH prescriber_drug_combo AS (
 SELECT *
	FROM prescriber AS pb
	CROSS JOIN drug  
	WHERE nppes_provider_city = 'NASHVILLE' 
		AND specialty_description = 'Pain Management'
		AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') 
	ORDER BY pb.npi
)
SELECT pdc.npi, pdc.drug_name, SUM(pn.total_claim_count) AS claims_per_drug_per_prescriber
FROM prescriber_drug_combo AS pdc
LEFT JOIN prescription AS pn ON pn.npi = pdc.npi AND pn.drug_name = pdc.drug_name
GROUP BY pdc.npi, pdc.drug_name, pn.total_claim_count
;


--Alt solution 2:


SELECT pdc.npi, pdc.drug_name, SUM(pn.total_claim_count) AS claims_per_drug_per_prescriber
FROM 
	(SELECT *
		FROM prescriber AS pb
		CROSS JOIN drug  
		WHERE nppes_provider_city = 'NASHVILLE' 
			AND specialty_description = 'Pain Management'
			AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') 
		ORDER BY pb.npi) AS pdc
LEFT JOIN prescription AS pn ON pn.npi = pdc.npi AND pn.drug_name = pdc.drug_name
GROUP BY pdc.npi, pdc.drug_name, pn.total_claim_count
ORDER BY claims_per_drug_per_prescriber DESC 
;



-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT pdc.npi as npi, pdc.drug_name, COALESCE(pn.total_claim_count, 0), SUM(COALESCE(pn.total_claim_count, 0)) AS claims_per_drug_per_prescriber
FROM 
	(SELECT *
		FROM prescriber AS pb
		CROSS JOIN drug  
		WHERE nppes_provider_city = 'NASHVILLE' 
			AND specialty_description = 'Pain Management'
			AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y') 
		ORDER BY pb.npi) AS pdc
LEFT JOIN prescription AS pn ON pn.npi = pdc.npi AND pn.drug_name = pdc.drug_name
GROUP BY pdc.npi, pdc.drug_name, pn.total_claim_count
ORDER BY claims_per_drug_per_prescriber DESC 
;


