--  PROBLEMA beecrowd SQL | 2988
--
--  O Campeonato Cearense de Futebol atrai milhares de torcedores todos os anos, 
--  você trabalha em um jornal e está encarregado de calcular a tabela de pontuação dos times. 
--  Mostre uma tabela com as seguintes colunas: o nome do time, número de partidas, vitórias, 
--  derrotas, empates e pontuação. Sabendo que a pontuação é calculada com cada vitória valendo 3 pontos, 
--  empate vale 1 e derrota rende 0. No final mostre sua tabela com a pontuação ordenada do maior para o menor.
--
--
--
--  Criação das tabelas
--
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS teams;

CREATE TABLE teams (
  id INT NOT NULL PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);

INSERT INTO teams VALUES 
(1, 'CEARA'), (2, 'FORTALEZA'), (3, 'GUARANY DE SOBRAL'), (4, 'FLORESTA');

CREATE TABLE matches (
  id INT NOT NULL PRIMARY KEY,
  team_1 INT NOT NULL REFERENCES teams(id),
  team_2 INT NOT NULL REFERENCES teams(id),
  team_1_goals INT NOT NULL,
  team_2_goals INT NOT NULL
);

INSERT INTO matches VALUES 
(1, 4, 1, 0, 4), (2, 3, 2, 0, 1), (3, 1, 3, 3, 0), (4, 3, 4, 0, 1), (5, 1, 2, 0, 0), (6, 2, 4, 2, 1);


--  Posibles soluções
--
--  Solução 1
--
--  Solução na qual consegui fazer pela minha conta com um tempo de execução no beecrowd de 0.015

SELECT
    t.name, 
    COUNT(m.team_1) FILTER(WHERE t.id = m.team_1)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2) "matches",
    COUNT(m.team_1) FILTER(WHERE t.id = m.team_1 AND m.team_1_goals > m.team_2_goals)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2 AND m.team_1_goals < m.team_2_goals) "victories",
    COUNT(m.team_1) FILTER(WHERE t.id = m.team_1 AND m.team_1_goals < m.team_2_goals)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2 AND m.team_1_goals > m.team_2_goals) "defeats",
    COUNT(m.team_1) FILTER(WHERE t.id = m.team_1 AND m.team_1_goals = m.team_2_goals)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2 AND m.team_1_goals = m.team_2_goals) "draws",
    ((COUNT(m.team_1) FILTER(WHERE t.id = m.team_1 AND m.team_1_goals > m.team_2_goals)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2 AND m.team_1_goals < m.team_2_goals))* 3) +
        COUNT(m.team_1) FILTER(WHERE t.id = m.team_1 AND m.team_1_goals = m.team_2_goals)
        + COUNT(m.team_2) FILTER(WHERE t.id = m.team_2 AND m.team_1_goals = m.team_2_goals) "score"
FROM
    teams t
JOIN matches m ON t.id IN (m.team_1, m.team_2)
GROUP BY t.name
ORDER BY "score" DESC




--  Posibles soluções
--
--  Solução 2
--
--  Solução que foi proposta no stackoverflow com um tempo de execução no beecrowd de 0.009


WITH norm_matches AS (
  SELECT id AS match_id, team_1 AS team_id, team_1_goals AS goals, 
         CASE
           WHEN team_1_goals > team_2_goals THEN 'W'
           WHEN team_1_goals = team_2_goals THEN 'D'
           WHEN team_1_goals < team_2_goals THEN 'L'
         END AS outcome
    FROM matches
  UNION ALL
  SELECT id AS match_id, team_2 AS team_id, team_2_goals AS goals, 
         CASE
           WHEN team_1_goals > team_2_goals THEN 'L'
           WHEN team_1_goals = team_2_goals THEN 'D'
           WHEN team_1_goals < team_2_goals THEN 'W'
         END AS outcome
    FROM matches
), points (outcome, value) AS (
  VALUES ('W', 3), ('D', 1), ('L', 0)
)
SELECT t.name, 
       COUNT(1) AS matches,
       COUNT(1) FILTER (where m.outcome = 'W') AS victories,
       COUNT(1) FILTER (where m.outcome = 'L') AS defeats,
       COUNT(1) FILTER (where m.outcome = 'D') AS draws,
       sum(p.value) AS score
  FROM teams t
       JOIN norm_matches m ON m.team_id = t.id
       JOIN points p ON p.outcome = m.outcome
 GROUP BY t.name
 ORDER BY score DESC;


--  Posibles soluções
--
--  Solução 3
--
--  Solução que foi proposta no stackoverflow e não testei ainda no beecrowd

WITH cte_matches AS (
    SELECT id, 
           team_1                                          AS team, 
           team_1_goals                                    AS goals, 
           CASE WHEN team_1_goals > team_2_goals THEN  1
                WHEN team_1_goals < team_2_goals THEN -1
                ELSE 0 END                                 AS has_won
    FROM matches
    UNION ALL
    SELECT id, 
           team_2                                          AS team, 
           team_2_goals                                    AS goals, 
           CASE WHEN team_2_goals > team_1_goals THEN 1
                WHEN team_2_goals < team_1_goals THEN -1
                ELSE 0 END                                 AS has_won
    FROM matches
)
SELECT t.name, 
       COUNT(t.id)      AS matches,
       COALESCE(SUM(CASE WHEN has_won =  1 THEN 1 END), 0) AS victories,
       COALESCE(SUM(CASE WHEN has_won = -1 THEN 1 END), 0) AS defeats,
       COALESCE(SUM(CASE WHEN has_won =  0 THEN 1 END), 0) AS draws,
       COALESCE(SUM(CASE WHEN has_won =  1 THEN 3
                         WHEN has_won =  0 THEN 1 END), 0) AS score
FROM      teams       t
LEFT JOIN cte_matches m
       ON t.id = m.team
GROUP BY t.name
ORDER BY score DESC