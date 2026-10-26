# Sentinel web app

A small CRUD interface over the Sentinel database. Flask serves one HTML page and a JSON API.
All fraud scoring still happens inside MySQL: inserting a transaction fires the trigger, and the
app only reads back the alert the trigger wrote.

Run: `bash run.sh`, then open http://127.0.0.1:5000

Environment variables (defaults in brackets): DB_HOST [127.0.0.1], DB_PORT [3306], DB_USER [root],
DB_PASS [sentinel_root_2026], DB_NAME [sentinel], PORT [5000].

Pages: dashboard, transactions, alerts, rules, users, accounts, merchants, devices, locations, audit log.
