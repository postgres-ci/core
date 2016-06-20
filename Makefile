EXTENSION = postgres_ci
DATA      = postgres_ci--0.2.sql \
	postgres_ci--0.2--0.3.sql \
	postgres_ci--0.3.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)