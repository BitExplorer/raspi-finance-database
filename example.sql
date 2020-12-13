set serveroutput on

select sysdate from dual;

--------------
-- Account --
--------------
drop table t_account;
CREATE TABLE  t_account
(
    account_id         NUMBER GENERATED always AS IDENTITY PRIMARY KEY,
    account_name_owner VARCHAR(30) UNIQUE NOT NULL,
    account_name       VARCHAR(30), -- NULL for now
    account_owner      VARCHAR(30), -- NULL for now
    account_type       VARCHAR(20) DEFAULT 'undefined' NOT NULL,
    active_status      CHAR(1)     DEFAULT '1' NOT NULL,
    moniker            VARCHAR(10) DEFAULT '0000' NOT NULL,
    totals             DECIMAL(8, 2) DEFAULT 0.0,
    totals_balanced    DECIMAL(8, 2) DEFAULT 0.0,
    date_closed        TIMESTAMP,
    date_updated       TIMESTAMP   NOT NULL,
    date_added         TIMESTAMP   NOT NULL,
    CONSTRAINT unique_account_name_owner_account_id UNIQUE (account_id, account_name_owner, account_type),
    CONSTRAINT unique_account_name_owner_account_type UNIQUE (account_name_owner, account_type),
    CONSTRAINT ck_account_type CHECK (account_type IN ('debit', 'credit', 'undefined')),
    CONSTRAINT ck_account_type_lowercase CHECK (account_type = lower(account_type))
);

describe t_account;

--------------
-- Category --
--------------
drop table t_category;
CREATE TABLE  t_category
(
    category_id   NUMBER GENERATED always AS IDENTITY PRIMARY KEY,
    category      VARCHAR(30) UNIQUE NOT NULL,
    active_status CHAR(1)     DEFAULT 1 NOT NULL,
    date_updated  TIMESTAMP   NOT NULL,
    date_added    TIMESTAMP   NOT NULL,
    CONSTRAINT ck_lowercase_category CHECK (category = lower(category))
);

describe t_category;

---------------------------
-- TransactionCategories --
---------------------------
drop table t_transaction_categories;

CREATE TABLE  t_transaction_categories
(
    category_id    NUMBER    NOT NULL,
    transaction_id NUMBER    NOT NULL,
    date_updated   TIMESTAMP NOT NULL,
    date_added     TIMESTAMP NOT NULL,
    PRIMARY KEY (category_id, transaction_id)
);
describe t_transaction_categories;

-------------------
-- ReceiptImage  --
-------------------
drop table t_receipt_image;
CREATE TABLE  t_receipt_image
(
    receipt_image_id NUMBER GENERATED always AS IDENTITY PRIMARY KEY,
    transaction_id   NUMBER    NOT NULL,
    jpg_image        BLOB      NOT NULL,                         -- ADD the not NULL constraint
    active_status    CHAR(1)   DEFAULT 1 NOT NULL,
    date_updated     TIMESTAMP NOT NULL,
    date_added       TIMESTAMP NOT NULL,
    CONSTRAINT ck_jpg_size CHECK (length(jpg_image) <= 1048576) -- 1024 kb file size limit
    --646174613a696d6167652f706e673b626173653634 = data:image/png;base64
    --646174613a696d6167652f6a7065673b626173653634 = data:image/jpeg;base64
    --CONSTRAINT ck_image_type_png CHECK(left(encode(receipt_image,'hex'),42) = '646174613a696d6167652f706e673b626173653634'),
    --CONSTRAINT ck_image_type_jpg CHECK (left(encode(jpg_image, 'hex'), 44) =
     --                                   '646174613a696d6167652f6a7065673b626173653634')
    --CONSTRAINT fk_transaction FOREIGN KEY (transaction_id) REFERENCES t_transaction (transaction_id) ON DELETE CASCADE
);


-----------------
-- Transaction --
-----------------
  drop table t_transaction;
  CREATE TABLE  t_transaction
  (
      transaction_id     NUMBER GENERATED always AS IDENTITY PRIMARY KEY,
      account_id         NUMBER         NOT NULL,
      account_type       VARCHAR(20) DEFAULT 'undefined' NOT NULL,
      account_name_owner VARCHAR(25)           NOT NULL,
      guid               VARCHAR(40)           NOT NULL UNIQUE,
      transaction_date   DATE           NOT NULL,
      description        VARCHAR(50)           NOT NULL,
      category           VARCHAR(30) DEFAULT '' NOT NULL,
      amount             DECIMAL(8, 2) DEFAULT 0.0 NOT NULL,
      transaction_state  VARCHAR(30)           NOT NULL,
      reoccurring        CHAR(1) DEFAULT 1 NOT NULL,
      reoccurring_type   VARCHAR(30) DEFAULT 'undefined' NULL,
      active_status      CHAR(1) DEFAULT 1 NOT NULL,
      notes              VARCHAR(100) DEFAULT '' NOT NULL,
      receipt_image_id   NUMBER         NULL,
      date_updated       TIMESTAMP      NOT NULL,
      date_added         TIMESTAMP      NOT NULL,
          CONSTRAINT transaction_constraint UNIQUE (account_name_owner, transaction_date, description, category, amount,
                                              notes),
    CONSTRAINT t_transaction_description_lowercase_ck CHECK (description = lower(description)),
    CONSTRAINT t_transaction_category_lowercase_ck CHECK (category = lower(category)),
    CONSTRAINT t_transaction_notes_lowercase_ck CHECK (notes = lower(notes)),
    --CONSTRAINT fk_category_id_transaction_id FOREIGN KEY(transaction_id) REFERENCES t_transaction_categories(category_id, transaction_id) ON DELETE CASCADE,
    CONSTRAINT ck_transaction_state CHECK (transaction_state IN ('outstanding', 'future', 'cleared', 'undefined')),
    CONSTRAINT check_account_type CHECK (account_type IN ('debit', 'credit', 'undefined')),
    CONSTRAINT ck_reoccurring_type CHECK (reoccurring_type IN
                                          ('annually', 'bi-annually', 'every_two_weeks', 'monthly', 'undefined')),
    CONSTRAINT fk_account_id_account_name_owner FOREIGN KEY (account_id, account_name_owner, account_type) REFERENCES t_account (account_id, account_name_owner, account_type) ON DELETE CASCADE,
    CONSTRAINT fk_receipt_image FOREIGN KEY (receipt_image_id) REFERENCES t_receipt_image (receipt_image_id) ON DELETE CASCADE,
    CONSTRAINT fk_category FOREIGN KEY (category) REFERENCES t_category (category) ON DELETE CASCADE
    );


--WHENEVER SQLERROR CONTINUE NONE
--DROP TABLE TABLE_NAME;

--BEGIN
--    FOR i IN (SELECT NULL FROM USER_OBJECTS WHERE OBJECT_TYPE = 'TABLE' AND OBJECT_NAME = 'T_ACCOUNT') LOOP
 --           EXECUTE IMMEDIATE 'DROP TABLE T_ACCOUNT';
--    END LOOP;
--END;

quit;
/