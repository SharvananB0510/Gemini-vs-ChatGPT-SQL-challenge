# 1)What are the average scores for each capability on both the Gemini Ultra and GPT-4 models?

SELECT 
    ROUND(AVG(B.ScoreGPT4), 2) AS GPT4,
    ROUND(AVG(B.ScoreGemini), 2) AS Gemini_Ultra,
    CapabilityName
FROM benchmarks B
JOIN capabilities C USING (CapabilityID)
GROUP BY CapabilityName;

# 2)Which benchmarks does Gemini Ultra outperform GPT-4 in terms of scores?

WITH cte1 AS (
    SELECT
        BenchmarkID,
        BenchmarkName,
        ROUND(SUM(ScoreGemini), 2) AS gemini
    FROM benchmarks
    GROUP BY BenchmarkID, BenchmarkName
),
cte2 AS (
    SELECT
        BenchmarkID,
        BenchmarkName,
        ROUND(SUM(ScoreGPT4), 2) AS gpt
    FROM benchmarks
    GROUP BY BenchmarkID, BenchmarkName
)

SELECT
    C1.gemini,
    C2.gpt,
    C1.benchmarkname
FROM cte1 C1
JOIN cte2 C2 on C1.benchmarkname = C2.benchmarkname
GROUP BY C1.gemini,C2.gpt, C1.benchmarkname 
HAVING C1.gemini > C2.gpt;

-- without CTE
SELECT
    b1.BenchmarkName
    ,ROUND(SUM(b1.ScoreGemini), 2) AS gemini
    ,ROUND(SUM(b2.ScoreGPT4),2) AS GPT
FROM benchmarks b1
JOIN benchmarks b2 ON b1.BenchmarkName = b2.BenchmarkName
GROUP BY b1.BenchmarkName
HAVING ROUND(SUM(b1.ScoreGemini), 2) > ROUND(SUM(b2.ScoreGPT4), 2);

# 3)What are the highest scores achieved by Gemini Ultra and GPT-4 for each benchmark in the Image capability?

SELECT 
    ROUND(SUM(ScoreGemini), 2) AS Gemini,
    ROUND(SUM(ScoreGPT4), 2) AS GPT,
    BenchmarkName
FROM benchmarks
JOIN capabilities C USING (capabilityID)
WHERE C.CapabilityName = 'Image'
GROUP BY benchmarkname;

# 4) Calculate the percentage improvement of Gemini Ultra over GPT-4 for each benchmark?

SELECT 
    BenchmarkName,
    CONCAT(ROUND(((ScoreGemini - ScoreGPT4) / SUM(ScoreGemini + ScoreGPT4)) * 100,2),'%') 
    AS improvement_percentage
FROM benchmarks
GROUP BY BenchmarkName , ScoreGemini , ScoreGPT4
HAVING improvement_percentage > 0;

# 5)Retrieve the benchmarks where both models scored above the average for their respective models?

SELECT benchmarkname, ScoreGemini, ScoreGPT4
FROM benchmarks
WHERE ScoreGemini > (
	SELECT ROUND(AVG(ScoreGemini), 2)
        FROM benchmarks)
        AND 
        ScoreGPT4 > (
        SELECT ROUND(AVG(ScoreGPT4), 2)
        FROM benchmarks);

# 6) Which benchmarks show that Gemini Ultra is expected to outperform GPT-4 based on the next score?

select Benchmarkname from
(select benchmarkname,
Scoregemini, 
ScoreGPT4,
lead(scoregemini) over (order by scoregemini) as LeadGem
from benchmarks
where ScoreGPT4 is not null
) as NextScore
where LeadGem > ScoreGPT4;

# 7) Classify benchmarks into performance categories based on score ranges?

SELECT 
    benchmarkname,
    Scoregemini,
    ScoreGPT4,
    CASE
        WHEN Scoregemini >= 75 THEN 'Excellent'
        WHEN Scoregemini >= 55 AND Scoregemini < 75 THEN 'Good'
        WHEN Scoregemini >= 45 AND Scoregemini < 55 THEN 'Not Bad'
        WHEN Scoregemini >= 35 AND Scoregemini < 45 THEN 'Poor'
        ELSE 'Very Poor'
    END AS Gemini_Performance_cat_wise,
    CASE
        WHEN ScoreGPT4 >= 75 THEN 'Excellent'
        WHEN ScoreGPT4 >= 55 AND ScoreGPT4 < 75 THEN 'Good'
        WHEN ScoreGPT4 >= 45 AND ScoreGPT4 < 55 THEN 'Not Bad'
        WHEN ScoreGPT4 >= 35 AND ScoreGPT4 < 45 THEN 'Poor'
        ELSE 'Very Poor'
    END AS GPT4_Performance_cat_wise
FROM benchmarks
WHERE ScoreGPT4 IS NOT NULL;

# 8. Retrieve the rankings for each capability based on Gemini Ultra scores?

SELECT
    Scoregemini,
    C.capabilityName,
    DENSE_RANK() OVER (ORDER BY Scoregemini) AS ranking
FROM benchmarks B
JOIN capabilities C USING (capabilityID);

# 9. Convert the Capability and Benchmark names to uppercase?

SELECT UPPER(B.benchmarkname) AS Benchmark
	   , UPPER(C.capabilityname) AS Capability
FROM benchmarks B
JOIN capabilities C USING (CapabilityID);

# 10. Can you provide the benchmarks along with their descriptions in a concatenated format ?

SELECT CONCAT(benchmarkname, '  ->   ', description) AS benchmark_descriptions
FROM benchmarks
