
--GGR by Sport with Margin %
SELECT 
sport,
COUNT(bet_id)                                           as Total_bets,
CAST(SUM(stake) as decimal(10,2))                       as total_stake,
CAST(SUM(GGR) as decimal(10,2))                         as total_revenue,
CAST(ROUND(SUM(GGR)/SUM(stake)*100,2) as decimal(10,2)) as gain_pct
FROM bets
GROUP BY sport
ORDER BY total_revenue DESC

--GGR by Bet Type with GGR per Bet
SELECT 
bet_type,
COUNT(bet_id)                                            as Total_bets,
CAST(SUM(stake) as decimal(10,2))                        as total_stake,
CAST(SUM(GGR) as decimal(10,2))                          as total_GGR,
CAST(ROUND(SUM(GGR)/SUM(stake)*100,2) as decimal (10,2)) as gain_pct,
CAST(ROUND(SUM(GGR)/COUNT(bet_id),2) as decimal (10,2))  as ggr_per_bet
FROM bets
GROUP BY bet_type
ORDER BY total_GGR DESC

--Player Profitability Ranking
SELECT
    user_id,
    COUNT(bet_id)                            AS total_bets,
    CAST(SUM(stake) AS DECIMAL(10,2))        AS total_stake,
    CAST(SUM(GGR) AS DECIMAL(10,2))          AS total_GGR,
    CAST(AVG(odds) AS DECIMAL(10,2))         AS avg_odds,
    CAST(SUM(CASE WHEN is_win = 'True' 
         THEN 1.0 ELSE 0 END) / 
         COUNT(bet_id) * 100 
         AS DECIMAL(10,2))                   AS win_rate_pct,
    RANK() OVER 
         (ORDER BY SUM(GGR) DESC)            AS ggr_rank
FROM bets
GROUP BY user_id
ORDER BY total_GGR 


--One Quick Analysis
SELECT
    CAST(AVG(CASE WHEN is_win = 'True' 
        THEN 1.0 ELSE 0 END) * 100 
        AS DECIMAL(10,2))    AS platform_avg_win_rate,
    CAST(AVG(stake) 
        AS DECIMAL(10,2))    AS platform_avg_stake,
    CAST(AVG(GGR) 
        AS DECIMAL(10,2))    AS platform_avg_GGR_per_bet
FROM bets

--Risk Flagging
WITH player_summary AS (
    SELECT
        user_id,
        COUNT(bet_id)                             AS total_bets,
        CAST(SUM(stake) AS DECIMAL(10,2))         AS total_stake,
        CAST(SUM(GGR) AS DECIMAL(10,2))           AS total_GGR,
        CAST(AVG(stake) AS DECIMAL(10,2))         AS avg_stake,
        CAST(AVG(odds) AS DECIMAL(10,2))          AS avg_odds,
        CAST(SUM(CASE WHEN is_win = 'True'
             THEN 1.0 ELSE 0 END) /
             COUNT(bet_id) * 100
             AS DECIMAL(10,2))                    AS win_rate_pct
    FROM bets
    GROUP BY user_id
)
SELECT
    user_id,
    total_bets,
    total_stake,
    total_GGR,
    avg_stake,
    avg_odds,
    win_rate_pct,
    CASE
        WHEN win_rate_pct >= 55 
         AND total_GGR < 0        THEN 'High Risk'
        WHEN win_rate_pct >= 55 
         OR  total_GGR < 0        THEN 'Medium Risk'
        WHEN avg_stake >= 500      THEN 'Review'
        ELSE                            'Low Risk'
    END                                           AS risk_flag
FROM player_summary
ORDER BY total_GGR ASC


-- check for Query 4
WITH player_summary AS (
    SELECT
        user_id,
        CAST(SUM(GGR) AS DECIMAL(10,2))           AS total_GGR,
        CAST(AVG(stake) AS DECIMAL(10,2))         AS avg_stake,
        CAST(SUM(CASE WHEN is_win = 'True'
             THEN 1.0 ELSE 0 END) /
             COUNT(bet_id) * 100
             AS DECIMAL(10,2))                    AS win_rate_pct
    FROM bets
    GROUP BY user_id
)
SELECT
    CASE
        WHEN win_rate_pct >= 55 
         AND total_GGR < 0        THEN 'High Risk'
        WHEN win_rate_pct >= 55 
         OR  total_GGR < 0        THEN 'Medium Risk'
        WHEN avg_stake >= 500      THEN 'Review'
        ELSE                            'Low Risk'
    END                            AS risk_flag,
    COUNT(*)                       AS player_count
FROM player_summary
GROUP BY
    CASE
        WHEN win_rate_pct >= 55 
         AND total_GGR < 0        THEN 'High Risk'
        WHEN win_rate_pct >= 55 
         OR  total_GGR < 0        THEN 'Medium Risk'
        WHEN avg_stake >= 500      THEN 'Review'
        ELSE                            'Low Risk'
    END
ORDER BY player_count DESC