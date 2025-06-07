-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: db-mysql-fra1-25072-do-user-19056117-0.g.db.ondigitalocean.com:25060
-- Generation Time: Cze 06, 2025 at 08:43 PM
-- Wersja serwera: 8.0.35
-- Wersja PHP: 8.4.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Baza danych: `ksr_cranes_dk_db`
--

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PushNotifications`
--

CREATE TABLE `PushNotifications` (
  `notification_id` bigint NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `token_id` bigint DEFAULT NULL,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` enum('URGENT','HIGH','NORMAL','LOW') COLLATE utf8mb4_unicode_ci DEFAULT 'NORMAL',
  `category` enum('HOURS','PROJECT','TASK','WORKPLAN','LEAVE','PAYROLL','SYSTEM','EMERGENCY') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action_required` tinyint(1) DEFAULT '0',
  `notification_type` enum('HOURS_SUBMITTED','HOURS_APPROVED','HOURS_CONFIRMED','HOURS_REJECTED','HOURS_CONFIRMED_FOR_PAYROLL','PAYROLL_PROCESSED','HOURS_REMINDER','HOURS_OVERDUE','TASK_ASSIGNED','TASK_COMPLETED','TASK_DEADLINE_APPROACHING','TASK_OVERDUE','WORKPLAN_CREATED','WORKPLAN_UPDATED','LEAVE_REQUEST_SUBMITTED','LEAVE_REQUEST_APPROVED','LEAVE_REQUEST_REJECTED','LEAVE_REQUEST_CANCELLED','LEAVE_BALANCE_UPDATED','LEAVE_REQUEST_REMINDER','LEAVE_STARTING','LEAVE_ENDING','PROJECT_CREATED','EMERGENCY_ALERT','LICENSE_EXPIRING','LICENSE_EXPIRED','SYSTEM_MAINTENANCE','PAYROLL_READY') COLLATE utf8mb4_unicode_ci NOT NULL,
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) DEFAULT '0',
  `read_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `status` enum('PENDING','SENT','FAILED') COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `error_message` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `PushNotifications`
--

INSERT INTO `PushNotifications` (`notification_id`, `employee_id`, `token_id`, `title`, `message`, `priority`, `category`, `action_required`, `notification_type`, `sent_at`, `is_read`, `read_at`, `expires_at`, `status`, `error_message`) VALUES
(1, 2, NULL, 'Hours approved for Tower crane operation ', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:01:37', 0, NULL, NULL, 'PENDING', NULL),
(2, 2, NULL, 'Hours approved for Task cream', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:36', 0, NULL, NULL, 'PENDING', NULL),
(3, 2, NULL, 'Hours approved for Task cream', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:37', 0, NULL, NULL, 'PENDING', NULL),
(4, 2, NULL, 'Hours approved for Task cream', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:37', 0, NULL, NULL, 'PENDING', NULL),
(5, 2, NULL, 'Hours approved for Task cream', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:37', 0, NULL, NULL, 'PENDING', NULL),
(6, 2, NULL, 'Hours approved for Task cream', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:37', 0, NULL, NULL, 'PENDING', NULL),
(7, 2, NULL, 'Hours approved for KRAN 2', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:45', 0, NULL, NULL, 'PENDING', NULL),
(8, 2, NULL, 'Hours approved for KRAN 2', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:45', 0, NULL, NULL, 'PENDING', NULL),
(9, 2, NULL, 'Hours approved for KRAN 2', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:45', 0, NULL, NULL, 'PENDING', NULL),
(10, 2, NULL, 'Hours approved for KRAN 2', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:03:45', 0, NULL, NULL, 'PENDING', NULL),
(11, 2, NULL, 'Hours approved for Test 1500', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:30:38', 0, NULL, NULL, 'PENDING', NULL),
(12, 2, NULL, 'Hours approved for Test 1500', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:30:39', 0, NULL, NULL, 'PENDING', NULL),
(13, 2, NULL, 'Hours approved for Test 1500', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:30:39', 0, NULL, NULL, 'PENDING', NULL),
(14, 2, NULL, 'Hours approved for Test 1500', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 19:30:39', 0, NULL, NULL, 'PENDING', NULL),
(15, 2, NULL, 'Hours approved for Test Crane', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 20:34:39', 0, NULL, NULL, 'PENDING', NULL),
(16, 2, NULL, 'Hours approved for Test Crane', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 20:34:40', 0, NULL, NULL, 'PENDING', NULL),
(17, 2, NULL, 'Hours approved for Test Crane', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 20:34:40', 0, NULL, NULL, 'PENDING', NULL),
(18, 2, NULL, 'Hours approved for Test Crane', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 20:34:41', 0, NULL, NULL, 'PENDING', NULL),
(19, 2, NULL, 'Hours approved for Test Crane', 'Your work hours have been approved and processed.', 'NORMAL', 'HOURS', 0, 'HOURS_CONFIRMED', '2025-06-06 20:34:41', 0, NULL, NULL, 'PENDING', NULL),
(20, 2, NULL, 'Task unassigned', 'Du er ikke længere tildelt opgaven: Task cream', 'NORMAL', 'TASK', 0, 'SYSTEM_MAINTENANCE', '2025-06-06 20:37:08', 0, NULL, NULL, 'PENDING', NULL),
(21, 2, NULL, 'New task assigned', 'You have been assigned to task: Task cream. Please review the task details.', 'NORMAL', 'TASK', 1, 'TASK_ASSIGNED', '2025-06-06 20:37:16', 0, NULL, NULL, 'PENDING', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PushTokens`
--

CREATE TABLE `PushTokens` (
  `token_id` bigint NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_type` enum('ios','android') COLLATE utf8mb4_unicode_ci NOT NULL,
  `app_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `os_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `PushTokens`
--

INSERT INTO `PushTokens` (`token_id`, `employee_id`, `token`, `device_type`, `app_version`, `os_version`, `created_at`, `updated_at`, `last_used_at`, `is_active`) VALUES
(1, 2, 'eSkhpHUaI0fopRr7fxgPoD:APA91bHx2DJF4eUYNPxWqZR03TCS3W7XkhCCebtCT9TQrY7rb_xOiWOjVkRFZl5Mt0sCvB0IouzkRCnTxXXCZVJjeEbo2sedrS19IfXyW5CkgYyKcFJrPww', 'ios', '1.0', '18.5', '2025-06-06 16:14:15', '2025-06-06 20:30:27', '2025-06-06 20:30:27', 1),
(2, 8, 'dCoUeiuIXkCSmRMl86_hAv:APA91bHLoIj7YPmbLNOkwMVZMV1Lg7yDpgS8YWmwufotsQx3na92j51amxCMsuPleAAgjc9qtz_CVFWFCHluiIK2hQx8nKn2jneHIcInpNCSdJ5__k_6zOI', 'ios', '1.0', '18.5', '2025-06-06 18:26:23', '2025-06-06 20:36:13', '2025-06-06 20:36:13', 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `TaskAssignments`
--

CREATE TABLE `TaskAssignments` (
  `assignment_id` int UNSIGNED NOT NULL,
  `task_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `assigned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `crane_model_id` int UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `TaskAssignments`
--

INSERT INTO `TaskAssignments` (`assignment_id`, `task_id`, `employee_id`, `assigned_at`, `crane_model_id`) VALUES
(11, 12, 2, '2025-05-12 00:00:00', NULL),
(12, 13, 2, '2025-05-15 17:39:51', NULL),
(13, 14, 7, '2025-05-19 00:00:00', NULL),
(14, 14, 2, '2025-05-20 13:08:54', NULL),
(15, 16, 2, '2025-06-01 19:13:33', NULL),
(18, 19, 2, '2025-06-02 16:28:44', NULL),
(20, 20, 2, '2025-06-03 09:39:47', NULL),
(21, 21, 2, '2025-06-06 20:37:16', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `WorkEntries`
--

CREATE TABLE `WorkEntries` (
  `entry_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `task_id` int UNSIGNED NOT NULL,
  `work_date` date NOT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `pause_minutes` int DEFAULT '0',
  `status` enum('pending','submitted','confirmed','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `confirmation_status` enum('pending','submitted','confirmed','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `confirmed_by` int UNSIGNED DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_draft` tinyint(1) NOT NULL DEFAULT '1',
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `rejection_reason` text COLLATE utf8mb4_unicode_ci,
  `timesheetId` int DEFAULT NULL,
  `km` decimal(10,2) DEFAULT '0.00',
  `payroll_batch_id` int DEFAULT NULL COMMENT 'Reference to PayrollBatches when sent',
  `sent_to_payroll` tinyint(1) DEFAULT '0' COMMENT 'Whether entry was sent to payroll',
  `sent_to_payroll_at` datetime DEFAULT NULL COMMENT 'Timestamp when sent to payroll'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `WorkEntries`
--

INSERT INTO `WorkEntries` (`entry_id`, `employee_id`, `task_id`, `work_date`, `start_time`, `end_time`, `pause_minutes`, `status`, `confirmation_status`, `confirmed_by`, `confirmed_at`, `description`, `created_at`, `is_draft`, `isActive`, `rejection_reason`, `timesheetId`, `km`, `payroll_batch_id`, `sent_to_payroll`, `sent_to_payroll_at`) VALUES
(181, 2, 13, '2025-05-15', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 0, NULL),
(182, 2, 13, '2025-05-16', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 0, NULL),
(183, 2, 13, '2025-05-13', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 0, NULL),
(184, 2, 13, '2025-05-17', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 1, '2025-06-04 19:39:15'),
(185, 2, 13, '2025-05-14', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 0, NULL),
(186, 2, 13, '2025-05-12', '2025-05-12 05:00:00', '2025-05-12 19:00:00', 65, 'pending', 'confirmed', NULL, NULL, '', '2025-05-18 14:32:09', 1, 1, NULL, 34, 83.00, NULL, 0, NULL),
(187, 2, 12, '2025-05-14', '2025-05-12 06:00:00', '2025-05-12 18:00:00', 35, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-18 14:36:52', 0, 1, NULL, 32, 45.00, NULL, 0, NULL),
(188, 2, 12, '2025-05-15', '2025-05-12 06:00:00', '2025-05-12 18:00:00', 35, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-18 14:36:52', 0, 1, NULL, 32, 45.00, NULL, 0, NULL),
(189, 2, 12, '2025-05-13', '2025-05-12 06:00:00', '2025-05-12 18:00:00', 35, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-18 14:36:52', 0, 1, NULL, 32, 45.00, NULL, 0, NULL),
(190, 2, 12, '2025-05-16', '2025-05-12 06:00:00', '2025-05-12 18:00:00', 35, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-18 14:36:52', 0, 1, NULL, 32, 45.00, NULL, 0, NULL),
(191, 2, 12, '2025-05-12', '2025-05-12 06:00:00', '2025-05-12 18:00:00', 35, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-18 14:36:52', 0, 1, NULL, 32, 45.00, NULL, 1, '2025-06-04 19:40:46'),
(193, 2, 14, '2025-05-26', '2025-05-26 05:00:00', '2025-05-26 15:00:00', 0, 'rejected', 'confirmed', NULL, NULL, '', '2025-05-26 16:06:55', 0, 1, NULL, 35, 0.00, NULL, 0, NULL),
(194, 2, 13, '2025-05-29', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, 37, 80.00, NULL, 0, NULL),
(195, 2, 13, '2025-05-27', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, 37, 80.00, NULL, 0, NULL),
(196, 2, 13, '2025-05-28', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, 37, 80.00, NULL, 0, NULL),
(197, 2, 13, '2025-05-26', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'confirmed', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, 37, 80.00, NULL, 0, NULL),
(198, 2, 21, '2025-06-04', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 20, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:00:05', 0, 1, NULL, 36, 0.00, NULL, 0, NULL),
(199, 2, 21, '2025-06-05', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 20, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:00:05', 0, 1, NULL, 36, 0.00, NULL, 0, NULL),
(200, 2, 21, '2025-06-06', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 20, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:00:05', 0, 1, NULL, 36, 0.00, NULL, 0, NULL),
(201, 2, 21, '2025-06-03', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 20, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:00:05', 0, 1, NULL, 36, 0.00, NULL, 0, NULL),
(202, 2, 21, '2025-06-02', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 20, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:00:05', 0, 1, NULL, 36, 0.00, NULL, 0, NULL),
(203, 2, 20, '2025-06-02', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 55, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:29:30', 0, 1, NULL, 38, 0.00, NULL, 0, NULL),
(204, 2, 20, '2025-06-04', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 55, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:29:30', 0, 1, NULL, 38, 0.00, NULL, 0, NULL),
(205, 2, 20, '2025-06-05', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 55, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:29:30', 0, 1, NULL, 38, 0.00, NULL, 0, NULL),
(206, 2, 20, '2025-06-03', '2025-06-02 05:00:00', '2025-06-02 17:00:00', 55, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 19:29:30', 0, 1, NULL, 38, 0.00, NULL, 0, NULL),
(207, 2, 19, '2025-06-05', '2025-06-02 06:00:00', '2025-06-02 17:00:00', 65, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 20:30:53', 0, 1, NULL, 39, 0.00, NULL, 0, NULL),
(208, 2, 19, '2025-06-02', '2025-06-02 06:00:00', '2025-06-02 17:00:00', 65, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 20:30:53', 0, 1, NULL, 39, 0.00, NULL, 0, NULL),
(209, 2, 19, '2025-06-04', '2025-06-02 06:00:00', '2025-06-02 17:00:00', 65, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 20:30:53', 0, 1, NULL, 39, 0.00, NULL, 0, NULL),
(210, 2, 19, '2025-06-03', '2025-06-02 06:00:00', '2025-06-02 17:00:00', 65, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 20:30:53', 0, 1, NULL, 39, 0.00, NULL, 0, NULL),
(211, 2, 19, '2025-06-06', '2025-06-02 06:00:00', '2025-06-02 17:00:00', 65, 'submitted', 'confirmed', NULL, NULL, '', '2025-06-06 20:30:53', 0, 1, NULL, 39, 0.00, NULL, 0, NULL);

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `PushNotifications`
--
ALTER TABLE `PushNotifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `employee_id` (`employee_id`),
  ADD KEY `token_id` (`token_id`),
  ADD KEY `idx_pushnotifications_priority` (`priority`,`status`),
  ADD KEY `idx_pushnotifications_category` (`category`,`sent_at`),
  ADD KEY `idx_pushnotifications_expires` (`expires_at`);

--
-- Indeksy dla tabeli `PushTokens`
--
ALTER TABLE `PushTokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `employee_id` (`employee_id`),
  ADD KEY `idx_pushtokens_last_used` (`last_used_at`,`is_active`);

--
-- Indeksy dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `TaskAssignments_employee_id_idx` (`employee_id`),
  ADD KEY `TaskAssignments_task_id_idx` (`task_id`),
  ADD KEY `idx_crane_model_id` (`crane_model_id`);

--
-- Indeksy dla tabeli `WorkEntries`
--
ALTER TABLE `WorkEntries`
  ADD PRIMARY KEY (`entry_id`),
  ADD UNIQUE KEY `employee_id_task_id_work_date` (`employee_id`,`task_id`,`work_date`),
  ADD KEY `WorkEntries_employee_id_idx` (`employee_id`),
  ADD KEY `WorkEntries_task_id_idx` (`task_id`),
  ADD KEY `idx_timesheet_id` (`timesheetId`),
  ADD KEY `idx_payroll_status` (`sent_to_payroll`,`confirmation_status`),
  ADD KEY `idx_payroll_batch_id` (`payroll_batch_id`);

--
-- AUTO_INCREMENT dla zrzuconych tabel
--

--
-- AUTO_INCREMENT dla tabeli `PushNotifications`
--
ALTER TABLE `PushNotifications`
  MODIFY `notification_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT dla tabeli `PushTokens`
--
ALTER TABLE `PushTokens`
  MODIFY `token_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  MODIFY `assignment_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT dla tabeli `WorkEntries`
--
ALTER TABLE `WorkEntries`
  MODIFY `entry_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=212;

--
-- Ograniczenia dla zrzutów tabel
--

--
-- Ograniczenia dla tabeli `PushNotifications`
--
ALTER TABLE `PushNotifications`
  ADD CONSTRAINT `PushNotifications_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `PushNotifications_ibfk_2` FOREIGN KEY (`token_id`) REFERENCES `PushTokens` (`token_id`) ON DELETE SET NULL;

--
-- Ograniczenia dla tabeli `PushTokens`
--
ALTER TABLE `PushTokens`
  ADD CONSTRAINT `PushTokens_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  ADD CONSTRAINT `fk_taskassignments_cranemodel` FOREIGN KEY (`crane_model_id`) REFERENCES `CraneModel` (`id`),
  ADD CONSTRAINT `TaskAssignments_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `TaskAssignments_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`);

--
-- Ograniczenia dla tabeli `WorkEntries`
--
ALTER TABLE `WorkEntries`
  ADD CONSTRAINT `fk_workentries_payroll_batch` FOREIGN KEY (`payroll_batch_id`) REFERENCES `PayrollBatches` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_workentries_timesheet` FOREIGN KEY (`timesheetId`) REFERENCES `Timesheet` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `WorkEntries_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `WorkEntries_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
