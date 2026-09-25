BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "device" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tokenHash" text NOT NULL,
    "appVersion" text NOT NULL,
    "ipHash" text,
    "createdAt" timestamp without time zone NOT NULL,
    "lastSeenAt" timestamp without time zone NOT NULL,
    "blocked" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "device_token_hash_idx" ON "device" USING btree ("tokenHash");
CREATE INDEX "device_ip_hash_idx" ON "device" USING btree ("ipHash");


--
-- MIGRATION VERSION FOR stopka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('stopka', '20260925000616946', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260925000616946', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
