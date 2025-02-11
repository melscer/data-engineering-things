Solution for [this](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2025/03-data-warehouse/homework.md) homework assignment.
# Question 1
 What is count of records for the 2024 Yellow Taxi Data?

```
SELECT
    COUNT(*)
FROM `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_native`
````

# Question 2
Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.

```
SELECT
  DISTINCT PULocationID
FROM `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_native`

````
# Question 3
Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table. Why are the estimated number of Bytes different?
```
SELECT
  DISTINCT PULocationID, DOLocationID 
FROM `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_native`

````

# Question 4:
How many records have a fare_amount of 0?
```
SELECT
  COUNT(1)
FROM `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_native`
WHERE fare_amount = 0
```

# Question 5
What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

```
CREATE OR REPLACE TABLE `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_partitioned`
PARTITION BY tpep_dropoff_date
CLUSTER BY VendorID 
AS (
  SELECT
    DATE(tpep_dropoff_datetime) AS tpep_dropoff_date,
    *
  FROM `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_native`
);
```

# Question 6:
Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive)

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?
```
SELECT
  COUNT(DISTINCT VendorID)
FROM
  `{{MY_PROJECT}}.zoomcamp.yellow_tripdata_partitioned`
WHERE
  tpep_dropoff_date BETWEEN "2024-03-01"
  AND "2024-03-15"

  ```