-- =============================================================================
-- Week 1 — Experiment 0: Introduction to SQL & MySQL and Database Design
-- 01_create_database.sql — create the empty database that every later week builds on
-- =============================================================================
-- Re-running this file wipes the database and starts over. That is intentional:
-- scripts/build.sh N relies on it to rebuild "the project as it was at week N".

DROP DATABASE IF EXISTS sentinel;
CREATE DATABASE sentinel
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sentinel;
