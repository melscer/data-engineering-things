Solution for [this](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2025/02-workflow-orchestration/homework.md#quiz-questions) homework assignment.
# Question 3

```
SELECT COUNT(*)
FROM
  `{{MY_PROJECT}}.zoomcamp.yellow_tripdata`
WHERE
  filename LIKE "%2020%"
````

# Question 4

```
SELECT COUNT(*)
FROM
  `{{MY_PROJECT}}.zoomcamp.green_tripdata`
WHERE
  filename LIKE "%2020%"
````

# Question 5

```
SELECT COUNT(*)
FROM
  `{{MY_PROJECT}}.zoomcamp.yellow_tripdata`
WHERE
  filename LIKE "%2021-03%"
````

# Question 6

See the docs: https://kestra.io/docs/workflow-components/triggers/schedule-trigger#example-a-schedule-that-runs-every-quarter-of-an-hour 

