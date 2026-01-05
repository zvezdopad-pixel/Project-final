SELECT * FROM customer;
SELECT * FROM transactions;
# Используя данные таблиц customer_info.xlsx (информация о клиентах) и transactions_info.xlsx 
# (информация о транзакциях за период с 01.06.2015 по 01.06.2016), нужно вывести:

# 1. Cписок клиентов с непрерывной историей за год, каждый месяц без пропусков за указанный годовой период.
# (даты >= '2015-06-01',  <= '2016-06-01' - фактически получается 13 месяцев)
SELECT ID_client
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <= '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 13;

# средний чек за период с 01.06.2015 по 01.06.2016 (по клиенту). 
SELECT 
    ID_client,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <= '2016-06-01'
GROUP BY ID_client;

# средняя сумма покупок за месяц (по клиенту). 
SELECT
    ID_client,
    AVG(month_sum) AS avg_month_sum
FROM (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS act_month,
        SUM(Sum_payment) AS month_sum
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <= '2016-06-01'
    GROUP BY ID_client, act_month
) t
GROUP BY ID_client
ORDER BY ID_client;

# количество всех операций по клиенту за период (по клиенту). 
SELECT ID_client,
       COUNT(*) AS total_operations
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new <= '2016-06-01'
GROUP BY ID_client;

# 2. информация в разрезе месяцев:
# a) средняя сумма чека в месяц;
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS act_month,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <= '2016-06-01'
GROUP BY act_month
ORDER BY act_month;

# b) среднее количество операций в месяц.
SELECT
    AVG(month_operations) AS avg_operations
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS act_month,
        COUNT(*) AS month_operations
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <= '2016-06-01'
    GROUP BY act_month
) t;

# c) среднее количество клиентов, которые совершали операции;
    
    SELECT
    AVG(month_clients) AS avg_operations_per_clients
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS act_month,
        COUNT(DISTINCT ID_client) AS month_clients
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <= '2016-06-01'
    GROUP BY act_month
) t;
   
# d) долю от общего количества операций за год и долю в месяц от общей суммы операций.
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS act_month,
    COUNT(*) AS operations_month,
    SUM(Sum_payment) AS sum_month,
    SUM(COUNT(*)) OVER () AS total_operations_year,
    SUM(SUM(Sum_payment)) OVER () AS total_sum_year,
    COUNT(*) / SUM(COUNT(*)) OVER () AS operations_share,
    SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER () AS sum_share
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new <= '2016-06-01'
GROUP BY act_month
ORDER BY act_month;

# e) % соотношение M/F/NA в каждом месяце с их долей затрат.
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS act_month,
    c.Gender,
    COUNT(DISTINCT t.ID_client) AS clients_count,      
    SUM(t.Sum_payment) AS total_payment,            
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS payment_share 
FROM transactions t
JOIN customer c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new <= '2016-06-01'
GROUP BY act_month, c.Gender
ORDER BY act_month, c.Gender;

# 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

SELECT
    CASE 
        WHEN c.Age IS NULL THEN 'Данные отсутствуют'
        ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
    END AS age_group,
    COUNT(DISTINCT t.ID_client) AS clients_count,
    COUNT(t.Id_check) AS total_operations,
    SUM(t.Sum_payment) AS total_payment
FROM customer c
INNER JOIN transactions t ON c.Id_client = t.ID_client
GROUP BY age_group
ORDER BY age_group;


SELECT
    CASE 
        WHEN c.Age IS NULL THEN 'Данные отсутствуют'
        ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
    END AS age_group,
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
    COUNT(t.Id_check) AS operations_q,
    SUM(t.Sum_payment) AS payment_q,
     COUNT(t.Id_check) * 100.0 / SUM(COUNT(t.Id_check)) OVER (PARTITION BY CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new))) AS operations_share,
    SUM(t.Sum_payment) * 100.0 / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new))) AS payment_share 
FROM customer c
JOIN transactions t ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01' AND t.date_new <= '2016-06-01'
GROUP BY age_group, quarter
ORDER BY age_group, quarter;
