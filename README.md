# 🎯 Sportsbook Player Analytics

> An end-to-end iGaming analytics project covering player segmentation, GGR analysis, betting behaviour trends, and risk flagging — built on 100,000 real sportsbook transactions.

![Excel](https://img.shields.io/badge/Excel-217346?style=flat&logo=microsoft-excel&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=flat&logo=microsoft-sql-server&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=flat&logo=tableau&logoColor=white)

---

## 📌 Project Overview

This project simulates the analytical workflow of a **Data Analyst at an online sportsbook**. Starting from raw transaction data and progressing through data cleaning, SQL analysis, player segmentation, and an interactive Tableau dashboard — the project answers four business questions a sportsbook analytics team deals with daily:

1. Which sports drive the most revenue?
2. How do Singles and Multiples compare in profitability?
3. Who are our most and least valuable players?
4. Which players show behavioural risk signals?

> **Industry connection:** This project directly mirrors KYC, AML, and fraud detection workflows from Flutter International (FanDuel, PokerStars, Betfair, Paddy Power) — rebuilding manual compliance review logic as an automated SQL risk flagging system.

---

## 📊 Dataset

**Source:** [Sports Betting Profiling Dataset — Kaggle](https://www.kaggle.com/datasets/emiliencoicaud/sports-betting-profiling-dataset)

| Attribute | Detail |
|---|---|
| Rows | 100,000 betting transactions |
| Players | 5,000 unique users |
| Sports | 13 (Football, Tennis, Basketball, Rugby, F1, and more) |
| Bet Types | Single, Multiple (Accumulator) |

### Column Dictionary

| Column | Type | Description |
|---|---|---|
| `bet_id` | VARCHAR | Unique bet identifier — primary key |
| `user_id` | INT | Unique player identifier |
| `bet_type` | VARCHAR | Single or Multiple |
| `sport` | VARCHAR | Sport the bet was placed on |
| `odds` | DECIMAL | Decimal odds at time of bet |
| `is_win` | VARCHAR | True/False — whether the bet won |
| `stake` | DECIMAL | Amount wagered by the player |
| `gain` | DECIMAL | Amount paid out (0 on losses) |
| `GGR` | DECIMAL | Gross Gaming Revenue = Stake − Gain |

---

## 🔑 Key Metrics

| Metric | Value |
|---|---|
| Total GGR | $1,334,586 |
| Total Bets | 100,000 |
| Unique Players | 5,000 |
| Avg Win Rate | 36.45% |
| Avg Stake per Bet | $132.63 |
| Avg GGR per Bet | $13.35 |
| High Risk Players Flagged | 227 |

---

## 🛠️ Tools & Workflow

```
Raw CSV  →  Excel (Clean + Segment)  →  SQL Server (Analyse)  →  Tableau (Visualise)
```

### Excel — Data Preparation
- Imported semicolon-delimited CSV via Get Data wizard
- Formatted as named Excel Table (`BettingData`)
- 6 structured data quality checks across 100,000 rows
- Added helper columns: `is_win_num`, `outcome`, `ggr_flag`
- Built 3 pivot tables: GGR by Sport, GGR by Bet Type, Player Summary
- Classified 5,000 players into High / Mid / Low value tiers using nested IF formula

### SQL Server — Analytical Queries
- Created `iGaming_Analytics` database in SQL Server Express
- Used `DECIMAL(10,2)` for all monetary columns (not FLOAT)
- 4 queries: GGR by sport, GGR by bet type, player ranking, risk flagging
- Advanced techniques: CTEs, CASE WHEN, RANK() window function, inline aggregations

### Tableau Public — Dashboard
- Connected to Excel workbook with two related tables (raw bets + player summary)
- 4 charts: GGR by Sport, Player Risk Distribution, Risk Flagging, Player Behaviour Scatter
- Interactive tooltips and cross-chart filtering

---

## 📁 Repository Structure

```
sportsbook-player-analytics/
│
├── data/
│   └── sports_betting_profiling.csv      # Raw dataset (from Kaggle)
│
├── excel/
│   └── BettingData_Analysis.xlsx         # Cleaned data, pivot tables, player tiers
│
├── sql/
│   └── iGaming_Analytics_Queries.sql     # All 4 analytical queries
│
├── tableau/
│   └── Sportsbook_Dashboard.twbx         # Packaged Tableau workbook
│
└── README.md
```

---

## 🗄️ SQL Queries

### Query 1 — GGR by Sport with Hold Percentage

```sql
SELECT
    sport,
    COUNT(bet_id)                         AS total_bets,
    CAST(SUM(stake) AS DECIMAL(10,2))     AS total_stake,
    CAST(SUM(GGR) AS DECIMAL(10,2))       AS total_GGR,
    CAST(ROUND(SUM(GGR) /
         SUM(stake) * 100, 2)
         AS DECIMAL(10,2))                AS GGR_margin_pct
FROM sports_bets
GROUP BY sport
ORDER BY total_GGR DESC
```

**Key result:** Football = $573K GGR (43% of total). Formula 1 = −$3,587 (only loss-making sport at −4.09% margin).

---

### Query 2 — GGR by Bet Type

```sql
SELECT
    bet_type,
    COUNT(bet_id)                           AS total_bets,
    CAST(SUM(GGR) AS DECIMAL(10,2))         AS total_GGR,
    CAST(SUM(GGR) / COUNT(bet_id)
         AS DECIMAL(10,2))                  AS GGR_per_bet,
    CAST(SUM(GGR) / SUM(stake) * 100
         AS DECIMAL(10,2))                  AS GGR_margin_pct
FROM sports_bets
GROUP BY bet_type
ORDER BY total_GGR DESC
```

**Key result:** Singles $14.00/bet vs Multiples $12.13/bet. Similar margins (~10%) — platform extracts value equally from both types.

---

### Query 3 — Player Profitability Ranking

```sql
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
FROM sports_bets
GROUP BY user_id
ORDER BY total_GGR DESC
```

**Key result:** Top vs bottom player — near-identical bet counts (25 vs 30), but a 19-point win rate gap produced a $38,622 GGR swing.

---

### Query 4 — Risk Flagging (CTE + CASE WHEN)

```sql
WITH player_summary AS (
    SELECT
        user_id,
        COUNT(bet_id)                          AS total_bets,
        CAST(SUM(GGR) AS DECIMAL(10,2))        AS total_GGR,
        CAST(AVG(stake) AS DECIMAL(10,2))      AS avg_stake,
        CAST(SUM(CASE WHEN is_win = 'True'
             THEN 1.0 ELSE 0 END) /
             COUNT(bet_id) * 100
             AS DECIMAL(10,2))                 AS win_rate_pct
    FROM sports_bets
    GROUP BY user_id
)
SELECT
    user_id,
    total_bets,
    total_GGR,
    avg_stake,
    win_rate_pct,
    CASE
        WHEN win_rate_pct >= 55 AND total_GGR < 0  THEN 'High Risk'
        WHEN win_rate_pct >= 55 OR  total_GGR < 0  THEN 'Medium Risk'
        WHEN avg_stake >= 500                       THEN 'Review'
        ELSE                                             'Low Risk'
    END AS risk_flag
FROM player_summary
ORDER BY total_GGR ASC
```

**Thresholds anchored to platform baselines:**
- Win rate flag at **55%** — 1.5x the platform average of 36.45%
- Stake flag at **$500** — nearly 4x the average bet of $132.63

---

## 📈 Key Findings

### 1. Football dominates at 43% — concentration risk
Football generated $573K of $1.33M total GGR. The platform is heavily dependent on a single sport. If Football margins compress or player acquisition slows, it materially impacts revenue.

### 2. Formula 1 is the only loss-making market
At −4.09% hold, players are net profitable against the platform on F1 bets. In a real sportsbook this would trigger an odds model review and potential stake restrictions on that market.

### 3. Win rate drives GGR more than bet volume
Top player (rank 1) and bottom player (rank 5000) had near-identical bet counts (25 vs 30) and similar average stakes. A 19 percentage point win rate gap produced a $38,622 GGR swing — confirming win rate as the primary profitability driver over volume.

### 4. 34% of players generating negative GGR
1,706 of 5,000 players are currently unprofitable for the platform. Combined with 227 High Risk players showing win rates of 47–60%, this represents a material risk concentration in a small user segment.

### 5. Singles and Multiples are equally efficient per dollar staked
Despite Singles generating 2x the total GGR ($910K vs $424K), GGR margin is similar at ~10%. The platform extracts value equally from both bet types — a sign of a well-calibrated odds model.

---

## 🚨 Risk Flag Distribution

| Flag | Count | % of Base | Criteria |
|---|---|---|---|
| 🟢 Low Risk | 3,118 | 62.4% | Normal behaviour |
| 🟡 Medium Risk | 1,532 | 30.6% | Win rate ≥ 55% OR negative GGR |
| 🔴 High Risk | 227 | 4.5% | Win rate ≥ 55% AND negative GGR |
| 🔵 Review | 123 | 2.5% | Avg stake ≥ $500 |

---

## 👤 Player Tier Classification

| Tier | GGR Threshold | Players | % of Base |
|---|---|---|---|
| 🟢 High | Above $1,000 | 983 | 19.7% |
| 🟡 Mid | $0 to $1,000 | 2,312 | 46.2% |
| 🔴 Low | Below $0 | 1,706 | 34.1% |

Thresholds anchored to the data-derived average profitable player GGR of **$1,354.70**.

---

## 📊 Tableau Dashboard

> 🔗 https://public.tableau.com/app/profile/ganesh.reddy.peesari/viz/Book1_17821264761690/Dashboard1

**4 charts:**
- **GGR by Sport** — Horizontal bar, colour-encoded by GGR value. Formula 1 immediately stands out.
- **Player Risk Distribution** — Pie chart with 4 risk tiers colour-coded.
- **Risk Flagging** — Bar chart with interactive tooltips defining each risk category.
- **Player Behaviour Scatter** — 5,000 dots by Win Rate (X) vs Total GGR (Y). Two reference lines at 55% win rate and $0 GGR create four risk quadrants. High Risk players cluster visibly in the bottom-right.

---

## 🏭 Industry Context

> This project was built to demonstrate analytical skills directly applicable to roles in **iGaming, sports betting, and fintech data teams**.

The risk flagging methodology mirrors real-world KYC (Know Your Customer) and AML (Anti-Money Laundering) workflows used by major sportsbook operators. The GGR and hold percentage calculations reflect standard sportsbook P&L metrics used at companies like FanDuel, DraftKings, BetMGM, and PrizePicks.

---

## 👨‍💻 Author

**Ganesh Reddy**
M.S. Data Analytics — Indiana Wesleyan University (2026)
Former Operations Analyst — Flutter International (FanDuel · PokerStars · Paddy Power · Betfair)

[![LinkedIn] https://www.linkedin.com/in/ganesh-reddy-peesari-27293527b/
[![Portfolio] https://literate-motion-b44.notion.site/Data-Portfolio-1e3fc4aaea2f807eb1e8d078ecba9b33
[![Tableau] https://public.tableau.com/app/profile/ganesh.reddy.peesari/viz/Book1_17821264761690/Dashboard1

---

*Built with Excel · SQL Server · Tableau Public*
