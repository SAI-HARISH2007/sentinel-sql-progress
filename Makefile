# Convenience wrappers. Everything real lives in scripts/ (plain bash) so you can also run those directly.
#   make up            start MySQL in Docker
#   make week N=5      rebuild the database as it was at the END of week 5, then check it
#   make all           the finished project (weeks 1-10)
#   make shell         open a mysql prompt inside the database
#   make test          the Python/pytest tests (week 11)
N ?= 10

.PHONY: up down week all check shell test reference

up:
	docker compose up -d
	@echo "waiting for MySQL..." && until docker exec sentinel-db mysqladmin ping -uroot -psentinel_root_2026 --silent 2>/dev/null; do sleep 2; done
	@echo "MySQL is up."

down:
	docker compose down

week:
	scripts/build.sh $(N)
	scripts/check.sh $(N)

all:
	scripts/build.sh 10
	scripts/check.sh 11

check:
	scripts/check.sh $(N)

shell:
	docker exec -it sentinel-db mysql -uroot -psentinel_root_2026 --default-character-set=utf8mb4 sentinel

test:
	python3 -m pip install -q -r week-11-final-polish/tests/requirements.txt
	pytest week-11-final-polish/tests -v

reference:
	scripts/compare_to_reference.sh
