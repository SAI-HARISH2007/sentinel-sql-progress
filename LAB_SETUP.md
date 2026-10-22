# Running Sentinel in the lab

Pick the first option that works on the lab machine.

## Option A: MySQL 8.0.31+ is installed (Workbench or command line)

Check the version: `mysql --version` (or `SELECT VERSION();` in Workbench). It must be MySQL 8.0.31 or newer. MariaDB (for example XAMPP) will not work.

```bash
git clone https://github.com/SAI-HARISH2007/sentinel-sql-progress.git
cd sentinel-sql-progress
DB_HOST=127.0.0.1 DB_ROOT_PASS=<root password> bash scripts/build.sh 10
DB_HOST=127.0.0.1 DB_ROOT_PASS=<root password> bash scripts/check.sh 11
```

This needs a MySQL account with root-level rights (it creates the database, users, roles, triggers and an event). Without bash, open the `sql/` files of `week-01` to `week-10` in Workbench and run them in order.

Then run the demo: `week-10-procedures-triggers/demo/01_fraud_demo.sql`.

## Option B: no usable MySQL on the lab machine

Open `report/sentinel_project_report.pdf` for the code and captured output, and open `demo.html` in a browser (it needs internet for the Tailwind CDN). Run the live database from your own laptop with Docker: `make up && make all`.

Host mode (`DB_HOST`) has not been tested on a lab machine, so try it at home first against a local MySQL install.
