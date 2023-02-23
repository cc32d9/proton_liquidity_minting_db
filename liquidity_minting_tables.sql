CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE CURRENT_REWARDS
(
  account           VARCHAR(12) NOT NULL,
  currency          VARCHAR(7) NOT NULL,
  precision         SMALLINT NOT NULL,
  reward_snapshot   JSONB  NOT NULL
);

CREATE UNIQUE INDEX CURRENT_REWARDS_I01 ON CURRENT_REWARDS (account, currency, precision);


CREATE TABLE REWARDS_HISTORY
(
  block_num         BIGINT NOT NULL,
  block_time        TIMESTAMP WITHOUT TIME ZONE NOT NULL,  
  account           VARCHAR(12) NOT NULL,
  currency          VARCHAR(7) NOT NULL,
  precision         SMALLINT NOT NULL,
  reward_snapshot   JSONB  NOT NULL
);

CREATE UNIQUE INDEX REWARDS_HISTORY_I01 ON REWARDS_HISTORY (block_num, account, currency, precision);
CREATE INDEX REWARDS_HISTORY_I02 ON REWARDS_HISTORY (block_time);
CREATE INDEX REWARDS_HISTORY_I03 ON REWARDS_HISTORY (account, block_time);


/* approximately 7 days in blocks*/
SELECT create_hypertable('REWARDS_HISTORY', 'block_num', chunk_time_interval => 1209600);
