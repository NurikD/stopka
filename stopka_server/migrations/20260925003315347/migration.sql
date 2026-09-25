BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ai_usage" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "deviceId" uuid NOT NULL,
    "day" text NOT NULL,
    "kind" text NOT NULL,
    "requests" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ai_usage_device_day_kind_idx" ON "ai_usage" USING btree ("deviceId", "day", "kind");
CREATE INDEX "ai_usage_day_idx" ON "ai_usage" USING btree ("day");


--
-- MIGRATION VERSION FOR stopka
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('stopka', '20260925003315347', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260925003315347', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
