-- ====================================================================
-- SCRIPT: 01_create_database.sql
-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation
-- DESCRIPTION: Initializes database schema with production standards
-- ENGINE: MySQL 8.0+
-- ====================================================================

DROP DATABASE IF EXISTS new_wheels_db;

CREATE DATABASE new_wheels_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE new_wheels_db;

-- Session configuration for deterministic date handling & strict validation
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+00:00';

SELECT 
    DATABASE() AS current_database,
    VERSION() AS mysql_version,
    CURRENT_TIMESTAMP() AS initialized_at;
