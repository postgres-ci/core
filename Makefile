EXTENSION = postgres_ci
DATA      = postgres_ci--0.1.sql \
	postgres_ci--0.1--0.2.sql \
	postgres_ci--0.2.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)