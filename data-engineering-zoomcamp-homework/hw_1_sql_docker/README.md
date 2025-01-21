# Module 1 Homework: Docker & SQL
Here are my solutions and steps I've taken to solve this week's assignment

## Question 1. Understanding docker first run 

### Problem statement
Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

### Solution

Solution: 24.3.1

```
docker run -it python:3.12.8 bash
pip -V
```


## Question 2. Understanding Docker networking and docker-compose

### Problem statement
Given the following `docker-compose.yaml`, what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432 -> this is the correct answer


##  Prepare Postgres

Run Postgres and load data as shown in the videos
We'll use the green taxi trips from October 2019:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```

You will also need the dataset with zones:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Download this data and put it into Postgres.

You can use the code from the course. It's up to you whether
you want to use Jupyter or a python script.


### Solution: Steps I've taken:
* Create an empty folder ny_taxi_postgres
* Modified the docker compose file to specify the correct volume path (ny_taxi_postgres)
* Created a container to run postgres via docker compose up
* Run  winpty docker compose up -d
* Observed that postgres created some folders in my ny_taxi_postgres folder
* Find out the name of the docker network (will show up after running docker compose up)
* Create Dockerfile (ingestion script)
    * Copy over the python script to download the data and load into the Docker database
    * Note: when you run the ingestion script within the docker network, it does not care about your local db config. you need to specify the ports & config of your container.
* Run the following to ingest the first data link
```
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"

winpty docker run -it \
  --network=hw_1_sql_docker_default \
  taxi_ingest:v001 \
    --user=root \
    --password=root \
    --host=pgdatabase \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --url=${URL}

```
* At this point I had an error in my python file. I changed it and then had to rebuild the image for the changes to take effect.
`docker build -t taxi_ingest:v001 .`

* Now if you login you will see the table there: http://localhost:8080/browser/
Let's ingest the second table:

```
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv"

winpty docker run -it \
  --network=hw_1_sql_docker_default \
  taxi_ingest:v001 \
    --user=root \
    --password=root \
    --host=pgdatabase \
    --port=5432 \
    --db=ny_taxi \
    --table_name=taxi_zones \
    --url=${URL}

```


## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281
- 104,802;  198,924;  109,603;  27,678;  35,189 -> this is the answer
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202


### Answer
```
SELECT
	COUNT(CASE WHEN trip_distance <= 1 THEN 1 END) AS trips_less_1,
    COUNT(CASE WHEN trip_distance > 1 AND trip_distance <= 3 THEN 1 END) AS trips_1_3,
    COUNT(CASE WHEN trip_distance > 3 AND trip_distance <= 7 THEN 1 END) AS trips_3_7,
    COUNT(CASE WHEN trip_distance > 7 AND trip_distance <= 10 THEN 1 END) AS trips_7_10,
    COUNT(CASE WHEN trip_distance > 10 THEN 1 END) AS trips_over_10
FROM yellow_taxi_trips
WHERE lpep_pickup_datetime >= CAST('2019-10-01' AS TIMESTAMP) AND lpep_dropoff_datetime < CAST('2019-11-01' AS TIMESTAMP)
;
```
## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31 -> answer

```
SELECT
    DATE_TRUNC('day', lpep_pickup_datetime) AS date,
    MAX(trip_distance) AS max_daily_distance
FROM yellow_taxi_trips
GROUP BY DATE_TRUNC('day', lpep_pickup_datetime)
ORDER BY max_daily_distance DESC;
```


## Question 5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- East Harlem North, East Harlem South, Morningside Heights -> Answer
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park
```
SELECT
	z."Zone",
    SUM(total_amount) AS total_amount_sum
FROM yellow_taxi_trips AS t
LEFT JOIN taxi_zones AS z
	ON t."PULocationID" = z."LocationID"
WHERE DATE_TRUNC('day', lpep_pickup_datetime) = '2019-10-18'
GROUP BY z."Zone"
HAVING SUM(total_amount) >= 13000
ORDER BY SUM(total_amount) DESC
LIMIT 4;
```

## Question 6. Largest tip

For the passengers picked up in October 2019 in the zone
name "East Harlem North" which was the drop off zone that had
the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

- Yorkville West
- JFK Airport -> Answer
- East Harlem North
- East Harlem South

```
SELECT
	z_do."Zone" AS dropoff_zone,
    MAX(tip_amount) AS max_tip
FROM yellow_taxi_trips AS t
LEFT JOIN taxi_zones AS z_do
	ON t."DOLocationID" = z_do."LocationID"
LEFT JOIN taxi_zones AS z_pu
	ON t."PULocationID" = z_pu."LocationID"
WHERE
	DATE_TRUNC('day', lpep_pickup_datetime) >= '2019-10-01'
	AND DATE_TRUNC('day', lpep_pickup_datetime) <= '2019-10-31'
	AND z_pu."Zone" = 'East Harlem North'
GROUP BY z_do."Zone"
ORDER BY MAX(tip_amount) DESC;
````


## Terraform

In this section homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform. 
Copy the files from the course repo
[here](../../../01-docker-terraform/1_terraform_gcp/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.


## Question 7. Terraform Workflow

Which of the following sequences, **respectively**, describes the workflow for: 
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy -> answer
- terraform import, terraform apply -y, terraform rm


## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw1
