# Frontend guide: build it, run it, explain it

You own the web frontend, which is the single file `app/static/index.html` (393 lines). Line numbers below match that file. Open it next to this guide and read each part before you explain it.

## 1. The big picture (say this first)

The browser page never calculates a fraud score. It only shows what MySQL decided.

```
browser (index.html)  --fetch JSON-->  Flask (app.py)  --SQL-->  MySQL
        ^                                                          |
        +---------------- JSON back <------ trigger scored it -----+
```

- One HTML file, plain JavaScript, no framework, no internet files. That is why it works in a lab with no network.
- It talks to Flask through `fetch("/api/...")`. Flask is Seshi's part. Yours is everything the user sees and clicks.
- Ten screens: Dashboard, Transactions, Alerts, Rules, Users, Accounts, Merchants, Devices, Locations, Audit log.

## 2. Map of the file

| Lines | What it is |
|---|---|
| 6 to 90 | `<style>`: colours as CSS variables (`--accent` teal, `--side` dark green), layout, table, modal, badges |
| 91 to 98 | HTML skeleton: `<aside>` sidebar, `<main id="main">`, the modal `#modal`, the toast `#toast` |
| 102 to 109 | helpers: `$` (querySelector), `esc` (escapes HTML), `inr` (rupee format) |
| 111 | `api(path, method, body)`: the only place that calls `fetch` |
| 120 | `toast(msg, err)`: the small message at the bottom right |
| 125 | `STATUS`: allowed status values for accounts, transactions, alerts |
| 132 | `UI`: one object describing every screen (title, columns, form fields) |
| 201 | `PAGES`: the sidebar menu list |
| 210 | `lookup()`: fetches id and label pairs for drop-downs, with a cache |
| 216 | `cell()`: draws one table cell (money, badge, score, reason chips, status select) |
| 231 | `listPage()`: draws a screen with search box, filter, Add button |
| 253 | `load()`: fetches rows, draws the table and pager, wires Edit, Delete and status changes |
| 284 | `remove()`: confirm, then DELETE |
| 292 | `form()`: builds the Add or Edit modal from `UI[name].fields` |
| 328 | `showScore()`: the "Scored by the database" box |
| 347 | `dashboard()` and `hbars()`: stat cards and bar charts |
| 373 | `audit()`: the audit log screen |
| 384 | `route()`: reads `location.hash` and opens the right screen |

## 3. The one idea to explain: the screens are data, not code

Every list screen is the same code (`listPage` and `load`). What changes is the `UI` object at line 132.

```js
users: {
  title: "Users",
  cols:   [["user_id","ID"], ["full_name","Name"], ["email","Email"], ...],
  fields: [{k:"full_name", l:"Full name", t:"text", req:1}, ...],
  add: "New user"
}
```

- `cols` says which JSON keys become table columns, and optionally how to draw them (`"money"`, `"badge"`, `"score"`, `"reasons"`, `"bool"`, `"alertstatus"`).
- `fields` says what the Add and Edit form asks for. `t` is the input type: `text`, `number`, `email`, `date`, `datetime-local`, `enum` (fixed list) or `lookup` (drop-down filled from the database).
- To add a screen you add one entry to `UI` and one line to `PAGES`. No new function.

If asked "why not eight separate pages?": one generic component means less code, and every screen behaves the same way (search, paging, validation messages).

## 4. How the main actions work

**Opening a screen.** Clicking a sidebar link sets `location.hash`. The `hashchange` listener (line 389) calls `route()`, which picks `dashboard()`, `audit()` or `listPage(name)`.

**Search.** Typing in the box restarts a 250 ms timer (line 243). Only when you stop typing does it call `load()`. This is called debouncing, and it stops one request per keystroke.

**Paging.** The server returns `rows`, `total`, `page` and `size`. The page shows "Page 1 of N" and the Prev and Next buttons change `state.page`.

**Add and Edit.** `form()` builds the modal. On submit it collects the fields with `FormData`, then calls `POST /api/<name>` for new rows or `PUT /api/<name>/<id>` for edits. Drop-downs such as Account and Merchant come from `GET /api/lookup/<name>`.

**Delete.** `confirm()` first, then `DELETE /api/<name>/<id>`. If MySQL refuses (a user who still owns accounts, a merchant used in transactions), Flask sends back a readable message and `toast(..., 1)` shows it in red. This is the foreign-key design from the report, visible on screen.

**Adding a transaction (the best demo moment).** The form posts the new row. The trigger runs inside MySQL before the insert returns. Flask reads the new alert and sends it back as `res.alert`. `showScore()` (line 328) then shows "Flagged, score 3 of 6" with one chip per reason, or "Clean, no rule fired".

**Changing an alert status.** In the Alerts table, each row has a `<select>`. On change, line 276 sends `PUT /api/alerts/<id>` with the new status. The database trigger writes the old and new value to `audit_log`, and the Audit log screen reads it back.

**Dashboard.** `GET /api/dashboard` returns counts and groups. `hbars()` turns each group into bars by setting `width` as a percentage of the largest value. The daily chart does the same with heights.

## 5. Build it yourself in stages

If you want to understand it by typing it, rebuild the file in this order. Each stage runs on its own.

1. **Skeleton.** `<aside>` with a menu, `<main id="main">`, and a `<script>`. Make `route()` print the page name from `location.hash`.
2. **The `api()` helper.** Call `fetch("/api/users")` and `console.log` the result. Start Flask first (section 7).
3. **A plain table.** Loop over `d.rows` and build `<tr><td>` strings. Escape every value with `esc()`.
4. **Search and paging.** Add the input, the debounce timer, and the Prev and Next buttons.
5. **Add, edit and delete.** Modal, `FormData`, `POST`, `PUT`, `DELETE`, `toast`.
6. **Make it data driven.** Move titles, columns and fields into the `UI` object so one function serves every screen.
7. **The scoring popup and the dashboard.** `showScore()` and `hbars()`.
8. **Styling.** CSS variables first, then the table, badges and modal.

You do not have to retype it for the demo. What matters is that you can say what each part does.

## 6. Demo script (about 90 seconds on screen)

1. Open `http://localhost:5000`. "This is the Sentinel dashboard. The numbers come from the database views: 12,067 transactions, 21 alerts."
2. Point at Alerts by rule. "Each bar is one of the six rules."
3. Go to **Transactions**. Type a name in search. Tick "flagged only".
4. Click **New transaction**. Pick an account, any merchant, a device, a city, and an amount of 900000. Click Add.
5. The popup appears. "The page did not calculate this. The trigger `trg_after_txn_insert` called `score_transaction()` inside MySQL, and the page shows the answer." Read the reason chips.
6. Click **Open alerts**. Change that alert's status to `investigated`.
7. Go to **Audit log**. "A trigger wrote this row, not the app. It has the old status, the new status and the MySQL user."
8. (Optional) **Rules**: lower a threshold, add another transaction, show the score change.
9. (Optional) **Users**: try to delete a user who has accounts. Show the red message. "That is the foreign key protecting the data."

Before the demo, check these: MySQL is running, `bash app/run.sh` printed the port, the page loads, and you have tried step 4 once. Use the same amount each time so you know what to expect.

## 7. Run it

```
cd sentinel-sql-progress
bash app/run.sh          # creates a venv, installs from app/wheels (offline), starts on port 5000
```

Open `http://localhost:5000`. If MySQL is not on the default host or port, set `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS` and `PORT` before running. `LAB_SETUP.md` has the lab steps.

## 8. Questions you may get, with answers

**Where is the fraud logic?** In MySQL: the `AFTER INSERT` trigger and the `score_transaction()` procedure. The frontend only displays the result.

**Why no React?** The lab computer may have no internet. One file with no dependencies runs anywhere, and the screens are simple enough not to need a framework.

**How does the page talk to the database?** It does not. It calls Flask with `fetch`. Flask runs parameterised SQL and returns JSON.

**What stops someone typing HTML into a field?** Every value is passed through `esc()` before it goes into the page, so `<` and `>` are shown as text.

**What happens when the database rejects something?** Flask turns MySQL errors (foreign key, duplicate, CHECK) into a short message with HTTP 400. `api()` throws it and `toast()` shows it.

**Why can rules be edited but not added or deleted?** The rule names are used inside `score_transaction()`. Only the threshold and the enabled flag are safe to change (`noAdd` and `noDel` on that screen).

**Why can an alert be edited only by status?** The alert is output of the engine. An analyst should review it, not rewrite what the rules decided.

**How do the drop-downs get filled?** `lookup()` calls `/api/lookup/<name>` and caches the result. The cache is cleared after any add, edit or delete so new rows appear.

**Is there a login?** No. It uses one database account and is meant for a lab or trusted network. The report lists a login screen as future work.

**What would you add next?** Automatic refresh of the alert screen, and a login that connects through the `txn_app` and `api_reader` roles.

## 9. If something breaks in the lab

| Symptom | Likely cause | Fix |
|---|---|---|
| Page loads but tables say "Nothing here yet" | Flask cannot reach MySQL | Check MySQL is running and the `DB_*` variables match |
| Red toast "Can't connect" | Wrong host, port or password | Set `DB_HOST`, `DB_PORT`, `DB_PASS` and restart `app/run.sh` |
| Port 5000 already in use | Another program has it | `PORT=5055 bash app/run.sh` and open that port |
| `pip` cannot install | No internet | `run.sh` uses `app/wheels/`; make sure that folder was copied |
| New transaction adds but shows "Clean" | The amount or device is ordinary | Use 900000, an unused device, or a far-away city |
