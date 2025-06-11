-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: db-mysql-fra1-25072-do-user-19056117-0.g.db.ondigitalocean.com:25060
-- Generation Time: Cze 06, 2025 at 09:35 AM
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

DELIMITER $$
--
-- Procedury
--
CREATE DEFINER="doadmin"@"%" PROCEDURE "UpdateLeaveBalance" (IN `p_employee_id` INT UNSIGNED, IN `p_leave_type` VARCHAR(20), IN `p_days` INT, IN `p_year` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Ensure leave balance record exists
    INSERT IGNORE INTO LeaveBalance (employee_id, year) 
    VALUES (p_employee_id, p_year);
    
    -- Update appropriate balance based on leave type
    IF p_leave_type = 'VACATION' THEN
        UPDATE LeaveBalance 
        SET vacation_days_used = vacation_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
            
    ELSEIF p_leave_type = 'PERSONAL' THEN
        UPDATE LeaveBalance 
        SET personal_days_used = personal_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
            
    ELSEIF p_leave_type = 'SICK' THEN
        UPDATE LeaveBalance 
        SET sick_days_used = sick_days_used + p_days,
            updated_at = CURRENT_TIMESTAMP
        WHERE employee_id = p_employee_id AND year = p_year;
    END IF;
    
    COMMIT;
END$$

--
-- Functions
--
CREATE DEFINER="doadmin"@"%" FUNCTION "CalculateWorkDays" (`p_start_date` DATE, `p_end_date` DATE) RETURNS INT DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_work_days INT DEFAULT 0;
    DECLARE v_current_date DATE DEFAULT p_start_date;
    DECLARE v_day_of_week INT;
    DECLARE v_holiday_count INT;
    
    WHILE v_current_date <= p_end_date DO
        SET v_day_of_week = DAYOFWEEK(v_current_date);
        
        -- Check if it's not weekend (Sunday = 1, Saturday = 7)
        IF v_day_of_week NOT IN (1, 7) THEN
            -- Check if it's not a public holiday
            SELECT COUNT(*) INTO v_holiday_count 
            FROM PublicHolidays 
            WHERE date = v_current_date AND is_national = TRUE;
            
            IF v_holiday_count = 0 THEN
                SET v_work_days = v_work_days + 1;
            END IF;
        END IF;
        
        SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
    END WHILE;
    
    RETURN v_work_days;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `About`
--

CREATE TABLE `About` (
  `id` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` json DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `imageAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `About`
--

INSERT INTO `About` (`id`, `title`, `content`, `createdAt`, `updatedAt`, `imageAlt`, `imageUrl`) VALUES
(1, 'Om os', '{\"type\": \"doc\", \"content\": [{\"type\": \"paragraph\", \"content\": [{\"text\": \"KSR Cranes er grundlagt af erfarne kranførere, der forstår branchens udfordringer indefra. Vi er en lokal virksomhed med en passion for at levere højkvalitets kranbetjening til byggeprojekter i hele regionen.\", \"type\": \"text\", \"marks\": [{\"type\": \"bold\"}]}]}, {\"type\": \"paragraph\", \"content\": [{\"text\": \"Vores styrke ligger i vores praktiske erfaring. Vi ved, at kranen er hjertet i ethvert byggeprojekt, og derfor prioriterer vi sikkerhed, præcision og effektivitet i alt, hvad vi gør.\", \"type\": \"text\"}]}, {\"type\": \"paragraph\", \"content\": [{\"text\": \"Hos KSR Cranes handler det ikke kun om at løfte materialer – det handler om at opbygge tillid. Vi tror på åben kommunikation, pålidelighed og personligt ansvar. Vores succes måles ikke i profit, men i langvarige kunderelationer baseret på kvalitet og sikkerhed.\", \"type\": \"text\"}]}, {\"type\": \"paragraph\", \"content\": [{\"text\": \"Vores operatører er ikke bare ansatte – de er erfarne fagfolk, der bringer værdi til dit projekt med deres dybdegående kendskab til branchen.\", \"type\": \"text\"}]}], \"imageAlt\": \"\", \"imageUrl\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_1200.webp\", \"imageWidth\": 3968, \"imageHeight\": 1852, \"imageVariants\": [{\"url\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_400.webp\", \"width\": 400, \"height\": 187}, {\"url\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_800.webp\", \"width\": 800, \"height\": 373}, {\"url\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_1200.webp\", \"width\": 1200, \"height\": 560}, {\"url\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_1600.webp\", \"width\": 1600, \"height\": 747}, {\"url\": \"https://ksr-media.fra1.digitaloceanspaces.com/about/28eb1c06-27d9-417c-ac53-4fa779a62541_original.jpeg\", \"width\": 3968, \"height\": 1852, \"isOriginal\": true}]}', '2025-03-12 16:21:51.354', '2025-03-24 15:11:28.995', NULL, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `activation_email_logs`
--

CREATE TABLE `activation_email_logs` (
  `id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(50) NOT NULL DEFAULT 'SENT',
  `email_type` varchar(50) NOT NULL DEFAULT 'ACTIVATION'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `AuditLogs`
--

CREATE TABLE `AuditLogs` (
  `log_id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `action` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `details` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `BillingSettings`
--

CREATE TABLE `BillingSettings` (
  `setting_id` int UNSIGNED NOT NULL,
  `project_id` int UNSIGNED DEFAULT NULL,
  `normal_rate` decimal(10,2) NOT NULL,
  `weekend_rate` decimal(10,2) NOT NULL,
  `overtime_rate1` decimal(10,2) NOT NULL,
  `overtime_rate2` decimal(10,2) NOT NULL,
  `weekend_overtime_rate1` decimal(10,2) NOT NULL,
  `weekend_overtime_rate2` decimal(10,2) NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `BillingSettings`
--

INSERT INTO `BillingSettings` (`setting_id`, `project_id`, `normal_rate`, `weekend_rate`, `overtime_rate1`, `overtime_rate2`, `weekend_overtime_rate1`, `weekend_overtime_rate2`, `effective_from`, `effective_to`) VALUES
(1, 5, 250.00, 350.00, 100.00, 200.00, 100.00, 200.00, '2025-06-01', '2025-07-01'),
(2, 6, 250.00, 350.00, 100.00, 200.00, 100.00, 200.00, '2025-06-01', '2025-07-01'),
(3, 7, 420.00, 520.00, 100.00, 200.00, 100.00, 200.00, '2025-06-01', '2025-07-15'),
(4, 8, 420.00, 520.00, 120.00, 220.00, 120.00, 220.00, '2025-06-01', '2025-07-01'),
(6, 9, 420.00, 520.00, 100.00, 200.00, 100.00, 200.00, '2025-06-03', '2026-06-19');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `BlogPost`
--

CREATE TABLE `BlogPost` (
  `id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `publishedAt` datetime(3) DEFAULT NULL,
  `metaTitle` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metaDescription` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `excerpt` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mainImageUrl` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mainImageAlt` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mainVideoUrl` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mainVideoAlt` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `videoDuration` int DEFAULT NULL,
  `videoThumbnail` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contentType` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'image',
  `body` json DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `BlogPost`
--

INSERT INTO `BlogPost` (`id`, `title`, `slug`, `publishedAt`, `metaTitle`, `metaDescription`, `excerpt`, `mainImageUrl`, `mainImageAlt`, `mainVideoUrl`, `mainVideoAlt`, `videoDuration`, `videoThumbnail`, `contentType`, `body`, `createdAt`, `updatedAt`) VALUES
(1, 'Arbejdet med tårnkraner – vigtige sikkerhedsregler om vinteren', 'arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-03-13 23:00:00.000', 'Arbejdet med tårnkraner om vinteren – 4 vigtige sikkerhedsregler', 'Beskyt dit mandskab og udstyr under vinterforhold. Læs vores 4 vigtigste råd om sikker drift af tårnkraner i kulden og mindsk risikoen for ulykker.', 'Vinterforhold på byggepladsen stiller særlige krav, når man arbejder med tårnkraner. I dette indlæg får du vores vigtigste sikkerhedstips til at beskytte både mandskab og udstyr, så du kan minimere risikoen for ulykker i de kolde måneder.', 'https://ksr-media.fra1.digitaloceanspaces.com/blog/993dbe04-6352-4256-b84c-495afbfd346a.jpeg', 'En tårnkran, der rager op over et bylandskab dækket af sne, set i fugleperspektiv.', NULL, NULL, NULL, NULL, 'image', '{\"_type\": \"block\", \"content\": \"<h3>Arbejdet med tårnkraner – vigtige sikkerhedsregler om vinterens</h3><p>Når temperaturen udenfor falder, og der dannes sne og is på byggepladsen, kræver betjening af en tårnkran særlig opmærksomhed. Her er nogle tip, der kan</p><p>hjælpe med at sikre maksimal sikkerhed og effektivitet:</p><p>1. Sænk krogen ca. 1 meter ved parkering<br>I vinterperioden er det en god idé at lade krogen hænge lidt lavere ved dagens afslutning, så det første, man gør næste morgen, er at løfte krogen op. På den måde bryder man eventuel isdannelse.</p><p>2. Drej kranen mod et sikkert område, og brug løbekatten til at rydde sne<br>Sørg for, at kranen er drejet mod en fri zone, så løbekatten kan bevæge sig sikkert og fjerne sne. Tjek jævnligt for sne og is på kranens bane.</p><p>3. Kontrollér platforme og bageste dele af kranen<br>Sne og is kan samle sig i mindre synlige områder såsom gangbroer, tekniske platforme og bagenden af kranen. Fjern is og sne for at forebygge fald og nedfaldende isstykker.</p><p>4. Sikr området under kranen<br>Sne og is kan falde ned fra både kranen og andre høje konstruktioner. Sørg for at afspærre et særligt sikkerhedsområde, så personer ikke opholder sig i risikozonen, mens kranen er i drift.</p><p>Ved at følge disse retningslinjer minimerer du risikoen for ulykker og skaber en mere sikker og effektiv arbejdsdag, selv under barske vinterforhold.</p><p><br><br><br></p>\"}', '2025-03-15 12:31:23.324', '2025-03-15 12:31:23.324');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ClientInteractions`
--

CREATE TABLE `ClientInteractions` (
  `interaction_id` int UNSIGNED NOT NULL,
  `project_id` int UNSIGNED NOT NULL,
  `interaction_type` enum('meeting','feedback','complaint','praise','review') DEFAULT 'meeting',
  `satisfaction_score` int DEFAULT NULL,
  `interaction_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  `follow_up_required` tinyint(1) DEFAULT '0',
  `created_by` int UNSIGNED NOT NULL
) ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Conversation`
--

CREATE TABLE `Conversation` (
  `conversation_id` int UNSIGNED NOT NULL,
  `task_id` int UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Conversation`
--

INSERT INTO `Conversation` (`conversation_id`, `task_id`, `created_at`, `updated_at`, `isActive`) VALUES
(20, NULL, '2025-02-25 11:37:35', '2025-02-27 15:06:38', 1),
(22, NULL, '2025-03-05 19:09:15', '2025-03-05 19:09:15', 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ConversationParticipant`
--

CREATE TABLE `ConversationParticipant` (
  `id` int UNSIGNED NOT NULL,
  `conversation_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `joined_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `ConversationParticipant`
--

INSERT INTO `ConversationParticipant` (`id`, `conversation_id`, `employee_id`, `joined_at`) VALUES
(21, 20, 2, '2025-02-25 11:37:34.994'),
(22, 20, 1, '2025-02-25 11:37:34.994'),
(26, 22, 2, '2025-03-05 19:09:15.499'),
(27, 22, 1, '2025-03-05 19:09:15.499');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CookiePolicy`
--

CREATE TABLE `CookiePolicy` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` json NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CookiePolicy`
--

INSERT INTO `CookiePolicy` (`id`, `title`, `content`, `createdAt`, `updatedAt`) VALUES
('cm8bwo8f80000v3x81vegaua7', 'Cookie Politik', '{\"sections\": [{\"title\": \"1. Hvad er cookies?\", \"content\": \"<p>Cookies er små tekstfiler, der gemmes på din computer, tablet eller smartphone, når du besøger vores hjemmeside. Disse filer gør det muligt for hjemmesiden at huske dine handlinger og præferencer (såsom login, sprog, skriftstørrelse og andre visningsindstillinger) over en periode, så du ikke behøver at indstille dem igen, hver gang du besøger hjemmesiden eller navigerer fra én side til en anden.</p>\"}, {\"title\": \"2. Hvordan bruger vi cookies?\", \"content\": \"<p>KSR CRANES bruger cookies til følgende formål:</p><h3>Nødvendige cookies</h3><p>Disse cookies er afgørende for, at du kan bruge hjemmesiden og dens funktioner. Uden disse cookies kan tjenester, du har bedt om, som f.eks. navigation på hjemmesiden eller adgang til sikre områder, ikke fungere korrekt.</p><h3>Præferencecookies</h3><p>Disse cookies giver hjemmesiden mulighed for at huske information, der ændrer måden, hjemmesiden ser ud eller opfører sig på. For eksempel dit foretrukne sprog eller den region, du befinder dig i.</p><h3>Statistik- og analysecookies</h3><p>Disse cookies hjælper os med at forstå, hvordan besøgende interagerer med hjemmesiden ved at indsamle og rapportere information anonymt. De hjælper os med at forbedre hjemmesidens funktionalitet.</p><h3>Marketing- og sporingscookies</h3><p>Disse cookies bruges til at spore besøgende på tværs af hjemmesider. Formålet er at vise annoncer, der er relevante og engagerende for den enkelte bruger.</p>\"}, {\"title\": \"3. Hvilke cookies bruger vi?\", \"content\": \"<p>Her er en liste over de vigtigste cookies, vi bruger:</p><h3>Nødvendige cookies:</h3><ul><li><p><strong>Session-cookies</strong>: Gemmer grundlæggende information om din session på vores hjemmeside.</p></li><li><p><strong>Sikkerhedscookies</strong>: Beskytter dig og vores hjemmeside mod sikkerhedstrusler.</p></li></ul><h3>Præferencecookies:</h3><ul><li><p><strong>Sprogcookies</strong>: Husker dit sprogvalg.</p></li><li><p><strong>Visningscookies</strong>: Husker dine foretrukne visningsindstillinger.</p></li></ul><h3>Statistik- og analysecookies:</h3><ul><li><p><strong>Google Analytics</strong>: Hjælper os med at forstå, hvordan besøgende bruger vores hjemmeside.</p></li></ul><h3>Marketing- og sporingscookies:</h3><ul><li><p><strong>Sociale medier cookies</strong>: Giver dig mulighed for at dele indhold på sociale medier.</p></li><li><p><strong>Annoncecookies</strong>: Hjælper os med at vise relevante annoncer baseret på dine interesser.</p></li></ul>\"}, {\"title\": \"4. Hvordan kan du styre cookies?\", \"content\": \"<p>Du kan styre og/eller slette cookies efter behov. Du kan slette alle cookies, der allerede er på din computer, og du kan indstille de fleste browsere til at forhindre, at de placeres. Men hvis du gør dette, skal du muligvis justere nogle præferencer manuelt, hver gang du besøger en hjemmeside, og nogle tjenester og funktioner fungerer muligvis ikke.</p><p>Du kan styre cookies ved at justere indstillingerne i din browser:</p><ul><li><p><strong>Google Chrome</strong>: Menu → Indstillinger → Vis avancerede indstillinger → Indhold indstillinger → Cookies</p></li><li><p><strong>Mozilla Firefox</strong>: Menu → Indstillinger → Privatliv → Historik → Brug brugerdefinerede indstillinger → Cookies</p></li><li><p><strong>Safari</strong>: Præferencer → Privatliv → Cookies og webstedsdata</p></li><li><p><strong>Microsoft Edge</strong>: Menu → Indstillinger → Cookies og webstedstilladelser</p></li></ul>\"}, {\"title\": \"5. Ændringer i vores cookiepolitik\", \"content\": \"<p>Vi kan opdatere vores cookiepolitik fra tid til anden for at afspejle ændringer i vores praksis eller af andre operationelle, juridiske eller lovgivningsmæssige årsager. Vi opfordrer dig til regelmæssigt at gennemgå denne politik for at holde dig informeret om, hvordan vi bruger cookies.</p>\"}, {\"title\": \"6. Kontakt os\", \"content\": \"<p>Hvis du har spørgsmål om vores brug af cookies, er du velkommen til at kontakte os på:</p><p><strong>KSR CRANES</strong></p><p>Eskebuen 49</p><p>2620, Albertslund Danmark</p><p>E-mail: info@ksrcranes.dk</p><p>Telefon: +45 23 26 20 64</p>\"}]}', '2025-03-16 17:24:35.109', '2025-03-16 17:24:35.109');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneBrand`
--

CREATE TABLE `CraneBrand` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `logoUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `foundedYear` int DEFAULT NULL,
  `headquarters` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CraneBrand`
--

INSERT INTO `CraneBrand` (`id`, `name`, `code`, `logoUrl`, `website`, `description`, `foundedYear`, `headquarters`, `isActive`, `createdAt`, `updatedAt`) VALUES
(1, 'Liebherr', 'liebherr', 'https://www-assets.liebherr.com/media/global/global-media/liebherr_logos/logo_ci_liebherr.svg', 'www.liebherr.com', '', NULL, '', 1, '2025-03-26 15:10:54.765', '2025-03-26 15:10:54.765'),
(2, 'Krøll Cranes', 'kr-ll-cranes', 'https://www.krollcranes.dk/media/sitelayouts/4/imagegenerator/347x87/logo-krol-cranes.png', 'https://www.krollcranes.dk/', '', NULL, '', 1, '2025-03-26 15:19:38.020', '2025-03-26 15:21:34.002'),
(3, 'Comansa', 'comansa', 'https://www.comansa.com/media/images/comansa.svg', 'https://www.comansa.com/', '', NULL, '', 1, '2025-03-26 15:23:19.106', '2025-03-26 15:23:19.106'),
(4, 'Potain', 'potain', 'https://www.manitowoc.com/sites/default/files/media/menu/icons/2020-07/logo-potain.svg', 'https://www.manitowoc.com/', '', NULL, '', 1, '2025-03-26 15:24:41.835', '2025-03-26 15:24:41.835');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneCategory`
--

CREATE TABLE `CraneCategory` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `iconUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `displayOrder` int NOT NULL DEFAULT '0',
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CraneCategory`
--

INSERT INTO `CraneCategory` (`id`, `name`, `code`, `description`, `iconUrl`, `displayOrder`, `isActive`, `createdAt`, `updatedAt`) VALUES
(1, ' Tårnkran', 't-rnkran', 'En tårnkran er en høj, stationær kran, som ofte bruges på byggepladser til at løfte tunge materialer i stor højde. Den er kendt for sin stabilitet, store løftekapacitet og lange rækkevidde, hvilket gør den særligt velegnet til større byggeprojekter.', 'https://cdn3.iconfinder.com/data/icons/industrial-process-flat-colorful/2048/5808_-_Crane_II-512.png', 1, 1, '2025-03-26 15:04:27.333', '2025-03-26 15:04:27.333'),
(2, 'Mobilkran', 'mobilkran', 'En mobilkran er en kran, der er monteret på en egen køretøjplatform, hvilket giver den en høj grad af mobilitet og fleksibilitet. Den er ideel til byggepladser, hvor man hurtigt skal kunne flytte kranen til nye opgaver og lokationer, da den kan køre på offentlige veje. Mobilkraner kombinerer kraftfulde løfteevner med god manøvredygtighed, hvilket gør dem velegnede til både tunge løfteopgaver og mere komplekse installationer i byområder.', '', 2, 1, '2025-03-26 15:46:29.661', '2025-03-26 15:46:41.553'),
(3, 'Beltekran', 'beltekran', 'En beltekran er en mobil kran monteret på larvefødder (bælter), som gør det muligt at bevæge sig sikkert og effektivt på ujævnt eller blødt terræn. Den bruges primært til tunge løft og monteringsopgaver på byggepladser, havneområder og ved større infrastrukturelle projekter. Beltekranens design sikrer høj stabilitet, mobilitet og fleksibilitet under krævende arbejdsforhold.', 'https://static.thenounproject.com/png/2003358-200.png', 3, 1, '2025-03-26 17:39:31.770', '2025-03-26 17:39:31.770'),
(4, 'Teleskoplæsser', 'teleskopl-sser', 'En **teleskoplæsser** er en alsidig maskine, der primært anvendes på byggepladser, landbrug og industri. Den kombinerer egenskaber fra en gaffeltruck og en kran og er udstyret med en teleskopisk arm, der kan forlænges for at løfte og placere materialer på svært tilgængelige steder. Teleskoplæssere er kendt for deres store rækkevidde, fleksibilitet og evne til at håndtere forskellige arbejdsredskaber som gafler, skovle eller kurve, hvilket gør dem yderst effektive til mange forskellige opgaver.', 'https://cdn.vectorstock.com/i/500p/29/41/telescopic-handler-vector-27962941.jpg', 0, 1, '2025-03-26 17:44:33.804', '2025-03-26 17:44:33.804');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneModel`
--

CREATE TABLE `CraneModel` (
  `id` int UNSIGNED NOT NULL,
  `brandId` int UNSIGNED NOT NULL,
  `typeId` int UNSIGNED NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `maxLoadCapacity` decimal(10,2) DEFAULT NULL,
  `maxHeight` decimal(10,2) DEFAULT NULL,
  `maxRadius` decimal(10,2) DEFAULT NULL,
  `enginePower` int DEFAULT NULL,
  `specifications` json DEFAULT NULL,
  `imageUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `brochureUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `videoUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `releaseYear` int DEFAULT NULL,
  `isDiscontinued` tinyint(1) NOT NULL DEFAULT '0',
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CraneModel`
--

INSERT INTO `CraneModel` (`id`, `brandId`, `typeId`, `name`, `code`, `description`, `maxLoadCapacity`, `maxHeight`, `maxRadius`, `enginePower`, `specifications`, `imageUrl`, `brochureUrl`, `videoUrl`, `releaseYear`, `isDiscontinued`, `isActive`, `createdAt`, `updatedAt`) VALUES
(1, 1, 1, '140 EC-H 6 LITRONIC', '140-ec-h-6-litronic', '', 6.00, 47.00, 60.00, NULL, '{}', 'https://www.lectura-specs.com/models/renamed/detail_max_retina/tower-cranes-trolley-boom-top-slewing-140-ec-h-6-liebherr(3).jpg', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_140_EC-H_6_Litronic.pdf', '', NULL, 0, 1, '2025-03-26 15:15:02.612', '2025-03-26 15:16:44.416'),
(2, 1, 1, '154 EC-H 6 LITRONIC', '154-ec-h-6-litronic', '', 6.00, NULL, NULL, NULL, '{}', 'https://uco.no/Files/Images/Produkt%20Bilder/714111-1_1.jpg', 'https://www.normas.dk/assets/files/brochurer/154EC.pdf', '', NULL, 0, 1, '2025-03-27 13:30:08.178', '2025-03-27 13:30:08.178'),
(3, 1, 1, '180 EC-H-10 LITRONIC', '180-ec-h-10-litronic', '', 10.00, NULL, NULL, NULL, '{}', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT3bwPCkHb50A4_xe9TTVB5uwj6G3khO8OFHg&s', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_180_EC-H10_Litronic_05_01.pdf', '', NULL, 0, 1, '2025-03-27 13:35:14.757', '2025-03-27 13:35:14.757'),
(4, 1, 1, '245 EC-H 12 LITRONIC', 'liebherr-245-ec-h-12-litronic', '', 12.00, NULL, NULL, NULL, '{}', 'https://live.staticflickr.com/7822/46763756084_058bbed197_b.jpg', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_245_EC-H_12.pdf', '', NULL, 0, 1, '2025-03-27 13:40:35.165', '2025-03-27 13:40:35.165'),
(5, 1, 1, '280 EC-H 12 LITRONIC', 'liebherr-280-ec-h-12-litronic', '', 16.00, NULL, NULL, NULL, '{}', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSEA0zOp0stZyt3ZkXv56xQw8HU565yGF5pPw&s', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_280_EC-H_12_Litronic.pdf', '', NULL, 0, 1, '2025-03-27 14:24:21.186', '2025-03-27 14:24:37.676'),
(6, 1, 1, '550 EC-H 20 LITRONIC', '550-ec-h-20-litronic', '', 20.00, NULL, NULL, NULL, '{}', 'https://www.rentmas.net/img/cache/listebg/images/types/obendreher-kran-550-ec-h-20-litronic/tower-cranes-trolley-boom-top-slewing-550-ec-h-20-liebherr.jpg', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_550_EC-H_20_Litronic.pdf', '', NULL, 0, 1, '2025-03-27 14:25:54.695', '2025-03-27 14:29:15.969'),
(7, 1, 1, '420 EC-H 20 LITRONIC', 'liebherr-420-ec-h-20-litronic', '', 20.00, NULL, NULL, NULL, '{}', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR4cPo6CgwasfATNQe2UrS_5qUAa9T5mB5O3A&s', '', '', NULL, 0, 1, '2025-03-27 14:27:10.766', '2025-03-27 14:27:56.909'),
(8, 1, 1, '550 EC-H 40 LITRONIC', 'liebherr-550-ec-h-40-litronic', '', 40.00, NULL, NULL, NULL, '{}', 'https://www.lectura-specs.com/models/renamed/orig/tower-cranes-trolley-boom-top-slewing-420-ec-h-20-liebherr(1).jpg', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr_550_EC-H_40_Litronic.pdf', '', NULL, 0, 1, '2025-03-27 14:27:50.793', '2025-03-27 14:27:50.793'),
(9, 1, 1, '630 EC-H 40 LITRONIC', '630-ec-h-40-litronic', '', 40.00, NULL, NULL, NULL, '{}', 'https://images.bigge.com/equipment/LIEBHERR-630-EC-H-40.jpeg?auto=format&crop=focalpoint&fit=crop&fp-x=0.5&fp-y=0.5&h=743&q=90&w=991', 'https://www.normas.dk/assets/files/brochurer/630EC.pdf', '', NULL, 0, 1, '2025-03-27 14:29:08.602', '2025-03-27 14:30:13.294'),
(10, 1, 1, '1000 EC-H 40 LITRONIC', 'liebherr-1000-ec-h-40-litronic', '', 40.00, NULL, NULL, NULL, '{}', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTW5ZLitzrAlR1qDa6abnNDcoYsZmP5MxrSNg&s', 'https://www.normas.dk/assets/files/brochurer/top-slewing/liebherr-1000ec-h-40-litronic-datasheet.pdf', '', NULL, 0, 1, '2025-03-27 14:30:03.014', '2025-03-29 07:35:51.481'),
(11, 2, 2, 'K130F', 'k130f', '', 6.00, NULL, 60.00, NULL, '{}', '', 'https://www.krollcranes.dk/ref.aspx?s=-300000&id=215&pageid=3', '', NULL, 0, 1, '2025-03-29 07:14:33.823', '2025-03-29 07:14:33.823'),
(12, 2, 2, 'K230F', 'k230f', '', 10.00, NULL, 60.00, NULL, '{}', '', 'https://www.krollcranes.dk/ref.aspx?s=-300000&id=217&pageid=3', '', NULL, 0, 1, '2025-03-29 07:16:11.672', '2025-03-29 07:16:11.672'),
(13, 2, 2, 'K330F', 'k330f', '', 18.00, NULL, 75.00, NULL, '{}', '', 'https://www.krollcranes.dk/ref.aspx?s=-300000&id=219&pageid=3', '', NULL, 0, 1, '2025-03-29 07:17:14.185', '2025-03-29 07:17:27.716'),
(14, 2, 2, 'K430F', 'k430f', '', 24.00, NULL, 75.00, NULL, '{}', '', 'https://www.krollcranes.dk/ref.aspx?s=-300000&id=221&pageid=3', '', NULL, 0, 1, '2025-03-29 07:19:14.304', '2025-03-29 07:19:14.304'),
(15, 2, 2, 'K630F', 'k630f', '', 24.00, NULL, 75.00, NULL, '{}', '', 'https://www.krollcranes.dk/ref.aspx?s=-300000&id=224&pageid=3', '', NULL, 0, 1, '2025-03-29 07:20:57.506', '2025-03-29 07:20:57.506'),
(16, 2, 2, 'K830F', 'k830f24', '', 24.00, NULL, 81.50, NULL, '{}', '', '', '', NULL, 0, 1, '2025-03-29 07:35:29.872', '2025-03-29 07:35:29.872'),
(17, 2, 2, 'K830F', 'k830f32', '', 32.00, NULL, 81.50, NULL, '{}', '', '', '', NULL, 0, 1, '2025-03-29 07:36:35.183', '2025-03-29 07:36:58.128'),
(18, 3, 2, '10LC110', '10lc110', '', 8.00, NULL, 60.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/2-billeder/110_68.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/5-pdf/13_10lc110.pdf', '', NULL, 0, 1, '2025-03-29 07:40:25.118', '2025-03-29 07:41:43.216'),
(19, 3, 2, '10LC140', '10lc140', '', 8.00, NULL, 60.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/phoca_thumb_l_dscf43181_260.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/39_comansa20140.pdf', '', NULL, 0, 1, '2025-03-29 07:43:14.010', '2025-03-29 07:43:14.010'),
(20, 3, 2, '11LC132', '11lc132', '', 6.00, NULL, 60.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/132_200.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/31_11lc132-6t-ds-1307-12.pdf', '', NULL, 0, 1, '2025-03-29 07:44:31.625', '2025-03-29 07:45:50.656'),
(21, 3, 2, '11LC160', '11lc160', '', 8.00, NULL, NULL, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/160_206.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/32_11lc160.pdf', '', NULL, 0, 1, '2025-03-29 07:45:28.066', '2025-03-29 07:45:28.066'),
(22, 3, 2, '16LC260', '16lc260', '', 18.00, NULL, 74.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/jesper-telefon-billeder-2014-2278_248.jpeg', 'https://kran-elektro.dk/udlejning-taarnkran.aspx', '', NULL, 0, 1, '2025-03-29 07:47:24.538', '2025-03-29 07:47:24.538'),
(23, 3, 2, '21LC335', '21lc335', '', 20.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/billede-27-10-2017-08_230.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/95_21lc400-18t-ds-1148-04-powerlift.pdf', '', NULL, 0, 1, '2025-03-29 07:48:49.027', '2025-03-29 07:48:49.027'),
(24, 3, 2, '21LC450', '21lc450', '', 20.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/450_218.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/36_21lc450-20t-3220-10256.pdf', '', NULL, 0, 1, '2025-03-29 07:50:25.166', '2025-03-29 07:53:33.284'),
(25, 3, 2, '21LC550', '21lc550', '', 18.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/img_0771_242.jpeg', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/img_0771_242.jpeg', '', NULL, 0, 1, '2025-03-29 07:51:59.462', '2025-03-29 07:51:59.462'),
(26, 3, 2, '21LC550', '21lc55020', '', 20.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/img_0771_242.jpeg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/37_21lc550-20t-ds-1548-11.pdf', '', NULL, 0, 1, '2025-03-29 07:53:22.593', '2025-03-29 07:53:22.593'),
(27, 3, 2, '21LC550', '21lc55025', '', 25.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/21lc550_458.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/6-taarnkraner/98_21lc550-25t.pdf', '', NULL, 0, 1, '2025-03-29 07:55:01.939', '2025-03-29 07:55:01.939'),
(28, 3, 2, '21LC660', '21lc660', '', 24.00, NULL, 84.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/billede-20-10-2018-10_224.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/38_21lc660-24t-ds-1229-02.pdf', '', NULL, 0, 1, '2025-03-29 07:56:10.158', '2025-03-29 07:56:10.158'),
(29, 3, 2, '21LC1050', '21lc1050', '', 50.00, NULL, 80.00, NULL, '{}', 'https://kran-elektro.dk/CustomerData/Files/Images/Archive/6-taarnkraner/21lc1050_375.jpg', 'https://kran-elektro.dk/CustomerData/Files/Folders/7-taarnkraner-pdf/78_21lc1050.pdf', '', NULL, 0, 1, '2025-03-29 07:57:15.023', '2025-03-29 07:57:15.023'),
(30, 1, 2, '71 EC-B5 ', 'liebherr', '', 5.00, NULL, NULL, NULL, '{}', '', '', '', NULL, 0, 1, '2025-05-03 07:45:40.162', '2025-05-03 07:48:27.642'),
(31, 1, 2, '110 EC-B6 ', 'liebherr-110-ec-b6', '', 6.00, NULL, 55.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/110EC.pdf', '', NULL, 0, 1, '2025-05-03 07:47:27.505', '2025-05-03 07:48:01.243'),
(32, 1, 2, '130 EC-B 6', '130-ec-b-6', '', 6.00, NULL, 60.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr_130_EC-B_6_Fr.tronic.pdf', '', NULL, 0, 1, '2025-05-03 07:50:05.834', '2025-05-03 07:50:05.834'),
(33, 1, 2, '160 EC-B 8', '160-ec-b-8', '', 8.00, NULL, 60.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr_160_EC-B_8_Litronic.pdf', '', NULL, 0, 1, '2025-05-03 07:51:44.516', '2025-05-03 07:51:44.516'),
(34, 3, 1, '160 EC-B 6', '160-ec-b-6', '', 6.00, NULL, 60.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr_160_EC-B_6_Litronic_01.pdf', '', NULL, 0, 1, '2025-05-03 07:52:40.287', '2025-05-03 07:52:40.287'),
(35, 1, 2, '172 EC-B 8', '172-ec-b-8', '', 8.00, NULL, 60.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr-172-EC-B-8-Litronic.pdf', '', NULL, 0, 1, '2025-05-03 07:54:59.297', '2025-05-03 07:54:59.297'),
(36, 1, 2, '202 EC-B ', '202-ec-b', '', 10.00, NULL, 65.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr-202-EC-B-10-Litronic.pdf', '', NULL, 0, 1, '2025-05-03 07:55:48.902', '2025-05-03 07:55:48.902'),
(37, 1, 2, '250 EC-B 12', '250-ec-b-12', '', 12.00, NULL, 70.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr_250_EC-B_12_Litronic.pdf', '', NULL, 0, 1, '2025-05-03 07:57:18.469', '2025-05-03 07:57:18.469'),
(38, 1, 2, '340 EC-B 16', '340-ec-b-16', '', 16.00, NULL, 78.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr-340-EC-B-16.pdf', '', NULL, 0, 1, '2025-05-03 07:58:09.857', '2025-05-03 07:58:09.857'),
(39, 3, 1, '380 EC-B 16', '380-ec-b-16', '', 16.00, NULL, 75.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/top-slewing/Liebherr-380-EC-B-16-Litronic.pdf', '', NULL, 0, 1, '2025-05-03 07:58:56.523', '2025-05-03 07:58:56.523'),
(40, 3, 1, '470 EC-B 20', '470-ec-b-20', '', 20.00, NULL, 80.00, NULL, '{}', '', 'https://www.normas.dk/assets/files/brochurer/Liebherr-470-EC-B-20.pdf', '', NULL, 0, 1, '2025-05-03 08:00:16.255', '2025-05-03 08:00:16.255');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneOperator`
--

CREATE TABLE `CraneOperator` (
  `id` int NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `post` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `cropHeight` double DEFAULT NULL,
  `cropLeft` double DEFAULT NULL,
  `cropTop` double DEFAULT NULL,
  `cropWidth` double DEFAULT NULL,
  `hotspotWidth` double DEFAULT NULL,
  `hotspotX` double DEFAULT NULL,
  `hotspotY` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CraneOperator`
--

INSERT INTO `CraneOperator` (`id`, `name`, `post`, `description`, `imageUrl`, `imageAlt`, `createdAt`, `updatedAt`, `cropHeight`, `cropLeft`, `cropTop`, `cropWidth`, `hotspotWidth`, `hotspotX`, `hotspotY`) VALUES
(1, 'Lukas K.S.Rytter ', 'Tower Crane Operator - Indehaver - Kranfører - Drone pilot - Fotograf', '8y Exp', 'https://ksr-media.fra1.digitaloceanspaces.com/crane-operators/2ced9ef2-1902-4898-ba2f-d5ee3c7a4fde.webp', '', '2025-03-15 14:23:42.922', '2025-03-25 08:47:29.301', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneType`
--

CREATE TABLE `CraneType` (
  `id` int UNSIGNED NOT NULL,
  `categoryId` int UNSIGNED NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `technicalSpecs` json DEFAULT NULL,
  `iconUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageUrl` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `displayOrder` int NOT NULL DEFAULT '0',
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `CraneType`
--

INSERT INTO `CraneType` (`id`, `categoryId`, `name`, `code`, `description`, `technicalSpecs`, `iconUrl`, `imageUrl`, `displayOrder`, `isActive`, `createdAt`, `updatedAt`) VALUES
(1, 1, 'Top-slewing', 'top-slewing', '', '{}', '', '', 1, 1, '2025-03-26 15:08:48.528', '2025-03-26 15:08:48.528'),
(2, 1, 'Flat-Top', 'flat-top', '', '{}', 'https://www.krollcranes.dk/media/imagegenerator/735x300/canvascolor(0xffffffff)/Flattop3.jpg', 'https://www.krollcranes.dk/media/imagegenerator/735x300/canvascolor(0xffffffff)/Flattop3.jpg', 2, 1, '2025-03-27 14:32:04.599', '2025-03-27 14:32:04.599');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `CraneTypes`
--

CREATE TABLE `CraneTypes` (
  `crane_type_id` int UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `CurrentLeaveRequests`
-- (See below for the actual view)
--
CREATE TABLE `CurrentLeaveRequests` (
`id` int unsigned
,`employee_id` int unsigned
,`employee_name` varchar(255)
,`employee_email` varchar(255)
,`type` enum('VACATION','SICK','PERSONAL','PARENTAL','COMPENSATORY','EMERGENCY')
,`start_date` date
,`end_date` date
,`total_days` int
,`status` enum('PENDING','APPROVED','REJECTED','CANCELLED','EXPIRED')
,`reason` text
,`created_at` timestamp
,`approved_by` int unsigned
,`approver_name` varchar(255)
,`approved_at` datetime
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Customers`
--

CREATE TABLE `Customers` (
  `customer_id` int UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cvr_nr` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `logo_url` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL to customer company logo stored in S3',
  `logo_key` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'S3 key for logo file (used for deletion)',
  `logo_uploaded_at` timestamp NULL DEFAULT NULL COMMENT 'Timestamp when logo was uploaded'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Customers`
--

INSERT INTO `Customers` (`customer_id`, `name`, `contact_email`, `phone`, `address`, `cvr_nr`, `created_at`, `logo_url`, `logo_key`, `logo_uploaded_at`) VALUES
(1, 'Nordbyg Aps', 'office@Norbyg.aps', '12345678', 'Sueper Street 69', '132546', '2025-02-24 16:17:35', NULL, NULL, NULL),
(2, 'KSR CONSULTING', 'ksrcranes@outlook.com', '23262064', NULL, NULL, '2025-03-20 12:14:49', 'https://ksr-customers.fra1.cdn.digitaloceanspaces.com/customer-logos/customer-2/logo-1748677679395.jpg', 'customer-logos/customer-2/logo-1748677679395.jpg', '2025-05-31 07:48:00'),
(4, 'Heidelberg Materials', NULL, NULL, NULL, NULL, '2025-05-31 13:31:23', 'https://ksr-customers.fra1.cdn.digitaloceanspaces.com/customer-logos/customer-4/logo-1748789477422.jpg', 'customer-logos/customer-4/logo-1748789477422.jpg', '2025-06-01 14:51:18');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `EmployeeCraneTypes`
--

CREATE TABLE `EmployeeCraneTypes` (
  `employee_id` int UNSIGNED NOT NULL,
  `crane_type_id` int UNSIGNED NOT NULL,
  `certification_date` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `EmployeeLanguage`
--

CREATE TABLE `EmployeeLanguage` (
  `id` int UNSIGNED NOT NULL,
  `employeeId` int UNSIGNED NOT NULL,
  `language` enum('DANISH','ENGLISH','POLISH','GERMAN') NOT NULL,
  `proficiency` enum('BASIC','INTERMEDIATE','FLUENT','NATIVE') NOT NULL DEFAULT 'BASIC'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `EmployeeLeaveBalances`
-- (See below for the actual view)
--
CREATE TABLE `EmployeeLeaveBalances` (
`employee_id` int unsigned
,`employee_name` varchar(255)
,`employee_email` varchar(255)
,`year` int
,`vacation_days_total` int
,`vacation_days_used` int
,`vacation_days_remaining` bigint
,`personal_days_total` int
,`personal_days_used` int
,`personal_days_remaining` bigint
,`carry_over_days` int
,`carry_over_expires` date
);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `EmployeeOvertimeSettings`
--

CREATE TABLE `EmployeeOvertimeSettings` (
  `id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `overtime_rate1` decimal(10,2) NOT NULL,
  `overtime_rate2` decimal(10,2) NOT NULL,
  `weekend_overtime_rate1` decimal(10,2) NOT NULL,
  `weekend_overtime_rate2` decimal(10,2) NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Employees`
--

CREATE TABLE `Employees` (
  `employee_id` int UNSIGNED NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('arbejder','byggeleder','chef','system') COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `operator_normal_rate` decimal(10,2) DEFAULT '0.00',
  `operator_overtime_rate1` decimal(10,2) DEFAULT '0.00',
  `operator_overtime_rate2` decimal(10,2) DEFAULT '0.00',
  `operator_weekend_rate` decimal(10,2) DEFAULT '0.00',
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_contact` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cpr_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `has_driving_license` tinyint(1) DEFAULT '0',
  `driving_license_category` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driving_license_expiration` date DEFAULT NULL,
  `profilePictureUrl` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zenegy_employee_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Employee number in Zenegy system',
  `is_activated` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Employees`
--

INSERT INTO `Employees` (`employee_id`, `email`, `name`, `role`, `password_hash`, `created_at`, `operator_normal_rate`, `operator_overtime_rate1`, `operator_overtime_rate2`, `operator_weekend_rate`, `address`, `phone_number`, `emergency_contact`, `cpr_number`, `birth_date`, `has_driving_license`, `driving_license_category`, `driving_license_expiration`, `profilePictureUrl`, `zenegy_employee_number`, `is_activated`) VALUES
(0, 'system@ksrcranes.dk', 'system', 'system', 'defaultPassword', '2025-02-27 09:07:44', 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1),
(1, 'KSRCranes@outlook.com', 'Lukas KS Rytter', 'chef', '$2a$12$n2TVHXFlUNZN1IrL5s.NDe3Lg.NkP/itL1nDgQyaLs.8XULJXJrd.', '2025-02-24 15:37:59', 0.00, 0.00, 0.00, 0.00, '', '', '', '', NULL, 0, '', NULL, '', NULL, 1),
(2, 'kranforerplatform@gmail.com', 'Maksymilian Marcinowski', 'arbejder', '$2b$10$309nzfFY.VZRMYzRgh9sUuLkoLDDVHLhZLZEPP9un6lZtAVr5gu1q', '2025-02-24 15:43:24', 270.00, 0.00, 0.00, 0.00, '', '', '', '', NULL, 0, '', NULL, 'https://ksr-employees.fra1.digitaloceanspaces.com/profiles/2/profile_1748626307159_da96f538-4b53-4b09-b1dd-22c42a2b3bcc.jpg', NULL, 1),
(3, 'majkemanizer@gmail.com', 'John Kowalski', 'byggeleder', '$2b$10$hCL05qHNhE6RGLlcypMtfeAh7.xtGHOu7HxRHJlOeeT8uqbX6aIfO', '2025-02-24 16:20:18', 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, 'https://ksr-employees.fra1.digitaloceanspaces.com/profiles/3/profile_1748611326337_927f69d2-1c42-4bcf-b024-1bf276903020.jpg', NULL, 1),
(7, 'agnieszka.rejniak79@gmail.com', 'Agnieszka Rejniak', 'arbejder', '$2a$12$qYwA/JvPpEpto3/kaIfOS.29AEfRJA.VWXtlm5UMVyuDVr7DZLr3G', '2025-05-08 10:56:39', 250.00, 0.00, 0.00, 0.00, 'Nivahoj 76\n2.1\n2990 Niva', '22360757', '26440486', '0107794018', '1979-07-01', 0, '', NULL, '', NULL, 1),
(8, 'admin@ksrcranes.dk', 'Admin', 'chef', '$2a$12$46EZVQewkU/O1wavdXNVmeiD9OP3DHgyTLoIxhJiSOjZLx.SYCP.u', '2025-05-08 14:55:49', 0.00, 0.00, 0.00, 0.00, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1),
(9, 'tester@ksrcranes.dk', 'Testowy Tester', 'arbejder', 'temp_hash', '2025-06-05 10:45:53', 240.00, 0.00, 0.00, 0.00, 'Super 8, 2990 Nivå', '26440486', 'Jens hf skakfbrb', NULL, '2025-06-05', 0, NULL, NULL, NULL, NULL, 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ErfaringImage`
--

CREATE TABLE `ErfaringImage` (
  `id` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `metaTitle` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metaDescription` text COLLATE utf8mb4_unicode_ci,
  `description` text COLLATE utf8mb4_unicode_ci,
  `imageUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `ErfaringImage`
--

INSERT INTO `ErfaringImage` (`id`, `title`, `slug`, `metaTitle`, `metaDescription`, `description`, `imageUrl`, `imageAlt`, `createdAt`, `updatedAt`) VALUES
(1, 'Rejsegilde', 'rejsegilde', 'Kranfører Udleje | Professionelle kranførere til alle byggeprojekter', 'Leder du efter en pålidelig kranfører til dit næste projekt? Vi tilbyder kranførerudleje med erfarne fagfolk, der sikrer sikker og effektiv håndtering af enhver opgave. Kontakt os i dag for et skræddersyet tilbud!', 'Det danske flag, løftet af en kran, kan synes som en let last, men det bærer en enorm symbolsk vægt. Det hejses altid med stolthed og minder om den mangeårige tradition for rejsegilde, samtidig med at det fremhæver fællesskabet og glæden ved at nå en ny milepæl i ethvert byggeprojekt.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/4d95c7f9-3af4-488b-8ad6-f23c777b5944.png', '', '2025-03-14 09:31:15.027', '2025-03-14 09:31:15.027'),
(2, 'Redmolen, Nordhavn ', 'redmolen-nordhavn-', '', '', '', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/cc55a7f1-5b8e-4d71-88bb-983779871ca5.jpeg', '', '2025-03-16 05:27:01.999', '2025-03-16 05:27:01.999'),
(3, 'Else Alfelts Vej, Ørestad, Copenhagen.', 'else-alfelts-vej-oerestad-copenhagen', 'Krøll kran montage med erfarne kranførere i Ørestad', 'Erfarne kranførere og sikker montage i Københavna – Else Alfelts Vej', 'Lejlighedskompleks, montering og støbning af beton, CLT- og stålelementer med Krøll-kraner.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/2abec36e-f834-43f5-bcb1-f64563ce34df.jpeg', '', '2025-03-16 05:29:11.016', '2025-03-16 05:29:11.016'),
(5, 'Ny Carlsberg Vej, Copenhagen.', 'ny-carlsberg-vej-copenhagen', 'Lejligheder og erhvervskompleks | Fundament, stål & in-situ-former', 'Opførsel af lejligheder og erhvervskompleks med fundament, løftning af stål, montering og støbning af in-situ-former, brostenshåndtering og ventilation.', 'Lejligheder og erhvervskompleks. Fundament, løftning af stål, montering og støbning af in-situ-former, løftning af brosten og ventilation. Montering og støbning af beton- og stålelementer.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/a56e145c-c28d-42d3-a2e9-ed87fd565658.jpeg', '', '2025-03-16 05:33:02.246', '2025-03-16 05:33:02.246'),
(7, 'Ny Carlsberg Vej, Copenhagen', 'ny-carlsberg-vej', 'Lejligheder og Erhvervskompleks | Fundament, Stål & In-Situ', 'Opførelse af lejligheder og erhvervskompleks med fundament, løftning af stål, montering og støbning af in-situ-former, løft af brosten og ventilation samt montering og støbning af beton- og stålelementer.', 'Bebyggelsen omfatter lejligheder og et erhvervskompleks, hvor fundamentet udføres, stål løftes, in-situ-former monteres og støbes, brosten håndteres, og ventilation etableres. Projektet inkluderer også montering og støbning af beton- og stålelementer for at sikre en robust og fleksibel bygningsstruktur.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/dda71775-40c5-4a7a-8709-451ce658d4eb.jpeg', '', '2025-03-16 05:36:07.338', '2025-03-16 05:36:07.338'),
(8, 'Lykkebækvej, Køge.', 'lykkebaekvej-koege', 'Sjællands Universitetshospital | Montering og Støbning af Stål- og Betonelementer', 'Opførelse af Sjællands Universitetshospital med avanceret montering og støbning af stål- og betonelementer, designet til at opfylde moderne hospitalsstandarder.', 'Projektet for Sjællands Universitetshospital fokuserer på effektiv montering og præcis støbning af stål- og betonelementer. Denne metode sikrer en robust og funktionel bygningsstruktur, der understøtter hospitalets krav til både sikkerhed og drift. Ved at anvende moderne teknikker og materialer opfyldes de strenge standarder for et moderne sundhedsmiljø.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/92c84baf-a2f7-46b0-b7ae-aa2f9b3ddf3d.jpeg', '', '2025-03-16 05:38:24.569', '2025-03-16 05:38:24.569'),
(9, 'Krøll kran', 'kroell-kran', 'Copenhagen', '', '', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/5efa4fb6-6493-4806-bad3-f9f5af7909e7.jpeg', '', '2025-03-16 05:40:27.133', '2025-03-16 05:40:27.133'),
(10, 'World Trade Center, Ballerup', 'world-trade-center-ballerup', 'Erhvervskompleks | Montering af Beton, Stål & Altanelementer', 'Opførelse af et moderne erhvervskompleks med montering af beton, stål og altanelementer for at sikre en robust og funktionel struktur.', 'Projektet omfatter konstruktionen af et erhvervskompleks, hvor beton-, stål- og altanelementer monteres med stor præcision. Ved at benytte moderne teknikker og materialer opnås en solid og æstetisk tiltalende bygningsstruktur, der opfylder de høje krav til funktionalitet og design i moderne erhvervsbyggeri.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/a63e19b4-a516-43b0-8ba3-01b0853b1427.jpeg', '', '2025-03-16 05:42:06.798', '2025-03-16 05:42:06.798'),
(11, 'World Trade Center, Ballerup ', 'world-trade-center-ballerup-', 'Erhvervskompleks: Montering af beton, stål & altaner', 'Opbygning af et moderne erhvervskompleks med avanceret montering af beton, stål og altanelementer, som sikrer en robust og æstetisk bygningsstruktur, der lever op til nutidens krav.', 'Erhvervskompleks: Montering af beton, stål og altanelementer', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/2341f010-f9f5-40f5-840e-fc9e72382a2b.jpeg', '', '2025-03-16 05:48:24.403', '2025-03-16 05:48:24.403'),
(12, 'Postbyen, Copenhagen.', 'postbyen-copenhagen', 'Erhvervsdistrikt: Montering af fundament, betonelementer & glasfacader med Liebherr tårnkraner', 'Opbygning af et moderne erhvervsdistrikt med montering og støbning af fundament, betonelementer og installation af glasfacader ved hjælp af avancerede Liebherr tårnkraner.', 'Dette projekt omfatter opførelsen af et erhvervsdistrikt, hvor fundamentet monteres og støbes, betonelementer integreres, og glasfacader installeres. Ved at anvende Liebherr tårnkraner sikres en effektiv håndtering og præcis placering af materialer, hvilket resulterer i en robust og æstetisk moderne bygningsstruktur, der opfylder de højeste standarder for kvalitet og design.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/912dc0c9-f36f-41fb-9acd-ea0486201c97.jpeg', '', '2025-03-16 06:02:00.454', '2025-03-16 06:02:00.454'),
(14, 'Postbyen,  Copenhagen.', 'postbyen--copenhagen', 'Erhvervsdistrikt: Montering af fundament, betonelementer & glasfacader med Liebherr tårnkraner', 'Opbygning af et moderne erhvervsdistrikt med montering og støbning af fundament, betonelementer samt installation af glasfacader ved hjælp af avancerede Liebherr tårnkraner.', 'Dette projekt omfatter opførelsen af et erhvervsdistrikt, hvor fundamentet monteres og støbes, betonelementer integreres, og glasfacader installeres. Ved at anvende Liebherr tårnkraner sikres en effektiv og præcis håndtering af materialer, hvilket resulterer i en robust og æstetisk moderne bygningsstruktur, der opfylder de højeste standarder for kvalitet og design.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/3339f81d-4824-4a2d-b148-fd8566b4cd60.jpeg', '', '2025-03-16 06:03:36.337', '2025-03-16 06:03:36.337'),
(15, 'Grandskoven, Glostrup.', 'grandskoven-glostrup', 'Lejlighedskompleks: Montering og støbning af beton- og stålelementer med Liebherr EC-H', 'Opførelse af et moderne lejlighedskompleks med avanceret montering og støbning af beton- og stålelementer ved hjælp af Liebherr EC-H, som sikrer effektiv materialehåndtering og en robust konstruktion.', 'Dette projekt omfatter opførelsen af et lejlighedskompleks, hvor beton- og stålelementer monteres og støbes med høj præcision. Ved at anvende Liebherr EC-H sikres en effektiv og sikker håndtering af materialerne, hvilket resulterer i en robust, moderne bygningsstruktur, der lever op til nutidens krav til kvalitet og design.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/df8e876d-d349-4785-a5a4-a31c18130c63.jpeg', '', '2025-03-16 06:04:57.859', '2025-03-16 06:04:57.859'),
(17, 'Else Alfelts Vej, Ørestad, Copenhagen.', 'else-alfelts-vej--oerestad-copenhagen', 'Lejlighedskompleks i Ørestad, København – Beton, CLT & Stålelementer med Krøll-kraner', 'Moderne lejlighedskompleks på Else Alfelts Vej, Ørestad, København. Projektet omfatter montering og støbning af beton, CLT- og stålelementer med avancerede Krøll-kraner.', 'Dette projekt beliggende på Else Alfelts Vej i Ørestad, København, fokuserer på opførelsen af et moderne lejlighedskompleks. Der udføres præcis montering og støbning af beton, CLT- og stålelementer ved hjælp af Krøll-kraner, hvilket sikrer en effektiv og sikker materialehåndtering. Resultatet er en robust og æstetisk tiltalende bygningsstruktur, der opfylder de nyeste krav inden for moderne byggeri.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/00328fd8-126b-409b-8bd9-cf27b156f0b5.jpeg', '', '2025-03-16 06:07:56.659', '2025-03-16 06:07:56.659'),
(18, 'Ny Carlsberg Vej, Copenhagen.', 'ny--carlsberg-vej-copenhagen', 'Lejlighedsejendom & Erhvervskompleks på Ny Carlsberg Vej, København – Beton & Stålelementer med 120m Liebherr EC-H', 'Opførelse af en moderne lejlighedsejendom og erhvervskompleks på Ny Carlsberg Vej, København. Projektet omfatter montering og støbning af beton- og stålelementer med en 120 meter frittstående Liebherr EC-H for effektiv materialehåndtering og en robust bygningsstruktur.', 'Projektet på Ny Carlsberg Vej, København, omfatter opførelsen af en lejlighedsejendom og et erhvervskompleks, hvor beton- og stålelementer monteres og støbes med præcision. Ved at anvende en 120 meter frittstående Liebherr EC-H sikres en sikker og effektiv håndtering af materialer, hvilket resulterer i en robust, moderne bygningsstruktur, der opfylder de højeste krav til både funktionalitet og æstetik.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/dae24395-a911-4785-b613-02e33e45b968.jpeg', '', '2025-03-16 06:09:25.753', '2025-03-16 06:09:25.753'),
(19, 'Carlsberg District, Copenhagen.', 'carlsberg-district-copenhagen', 'Udsigt fra førerkabinen på Liebherr tårnkran – Carlsberg District, København', 'Panoramaudsigt fra førerkabinen på en Liebherr tårnkran i Carlsberg District, København. Moderne teknologi og effektiv byggepladsstyring møder spektakulær udsigt.', 'Billedet viser den imponerende udsigt fra førerkabinen på en Liebherr tårnkran, der arbejder i Carlsberg District i København. Kranføreren har adgang til avancerede kontrolsystemer og kameraer, som sikrer præcis og sikker betjening. Kombinationen af moderne teknologi og udsigt over byens skyline understreger kompleksiteten og præcisionen i nutidens byggepladser.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/347114bf-601c-4dfe-8142-a407707a3b55.jpeg', '', '2025-03-16 06:12:03.714', '2025-03-16 06:12:03.714'),
(20, 'Marta Christensens Vej, Ørestad, Copenhagen.', 'marta-christensens-vej-oerestad-copenhagen', 'Lejlighedskompleks – Montering & støbning af beton- og stålelementer med Krøll-kran', 'Opførelse af lejlighedskompleks med præcis montering og støbning af beton- og stålelementer ved hjælp af Krøll-kran, der sikrer effektivitet, sikkerhed og høj kvalitet.', 'Projektet omfatter opførelse af et moderne lejlighedskompleks med præcis håndtering og montering af beton- og stålelementer ved hjælp af Krøll-kran. Den avancerede kranteknologi giver mulighed for effektiv og præcis placering af byggematerialerne, hvilket sikrer en robust struktur, der opfylder nutidens krav til æstetik og holdbarhed.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/7cd35659-5ed9-4c5b-815e-c2ae5a78ce63.jpeg', '', '2025-03-16 06:13:05.627', '2025-03-16 06:13:05.627'),
(21, 'Fehmarn Belt Tunnel, Rødby.', 'fehmarn-belt-tunnel-roedby', 'Fehmarn Bælt-tunnelen, Rødby – Løft af stål, montering og støbning af in-situ testelement med Liebherr 1000 EC-H', 'Fehmarn Bælt-tunnelprojektet i Rødby omfatter løftning af stål samt montering og støbning af in-situ forme til testelementer ved hjælp af dobbelt kat, 4-cut Liebherr 1000 EC-H tårnkran', 'Projektet ved Fehmarn Bælt-tunnelen i Rødby involverer præcis håndtering af stål, montering og støbning af in-situ forme til produktion af testelementer. Arbejdet udføres med en specialiseret dobbelt kat Liebherr 1000 EC-H tårnkran med 4-cut-konfiguration, der muliggør høj løftekapacitet, præcision og effektivitet, hvilket sikrer optimale resultater og høj sikkerhed under konstruktionen af testelementerne til dette ambitiøse infrastrukturprojekt.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/30acbb86-1f72-4ee1-9284-d4c1e2fff1fc.jpeg', '', '2025-03-16 06:14:43.780', '2025-03-16 06:14:43.780'),
(22, 'Else Alfelts Vej, Ørestad, Copenhagen.', 'else-alfelts--vej-oerestad-copenhagen', 'Lejlighedskompleks – Montering af beton-, CLT- og stålelementer med Krøll-kraner', 'Opførelse af lejlighedskompleks med avanceret montering og støbning af beton-, CLT- og stålelementer ved brug af Krøll-kraner, der sikrer høj kvalitet og effektiv udførelse.', 'Projektet består i konstruktionen af et moderne lejlighedskompleks, hvor beton-, CLT- og stålelementer monteres og støbes med høj præcision ved hjælp af specialiserede Krøll-kraner. Anvendelsen af avanceret kranteknologi sikrer hurtig og præcis placering af materialerne, hvilket bidrager til en robust struktur med et moderne og bæredygtigt design.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/056d635d-5143-4a10-9911-e495ebb33925.jpeg', '', '2025-03-16 06:15:56.553', '2025-03-16 06:15:56.553'),
(23, 'Else Alfelts Vej, Ørestad, Copenhagen.', 'else-a-lfelts-vej-oerestad-copenhagen', 'Lejlighedskompleks på Else Alfelts Vej, Ørestad – Beton, CLT & Stål med Krøll-kraner', 'Opførelse af lejlighedskompleks på Else Alfelts Vej i Ørestad, København, med præcis montering og støbning af beton-, CLT- og stålelementer ved hjælp af Krøll-kraner.', 'Dette byggeprojekt beliggende på Else Alfelts Vej i Københavns moderne bydel, Ørestad, omfatter opførelsen af et lejlighedskompleks, hvor beton-, CLT- og stålelementer monteres og støbes ved brug af Krøll-kraner. Den specialiserede kranteknologi sikrer effektivitet, nøjagtighed og sikkerhed gennem hele byggeprocessen, hvilket resulterer i en robust, moderne og bæredygtig boligstruktur.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/dae83e81-bde8-458a-b778-6c187730ab59.jpeg', '', '2025-03-16 06:17:18.017', '2025-03-16 06:17:18.017'),
(24, 'Postbyen, Copenhagen. ', 'postbyen---copenhagen-', 'Erhvervsdistrikt Postbyen, København – Fundament, betonelementer og glasfacader med Liebherr tårnkraner', 'Opførelse af erhvervsdistriktet Postbyen i København, med montering og støbning af fundament, betonelementer og installation af glasfacader udført med Liebherr tårnkraner.', 'Projektet omfatter konstruktionen af det nye erhvervsområde Postbyen i København, hvor fundamentet monteres og støbes, betonelementer opsættes, og glasfacader installeres med høj præcision ved brug af Liebherr tårnkraner. Kranernes avancerede teknologi sikrer en effektiv og sikker byggeproces samt en robust og æstetisk moderne struktur, der matcher områdets vision om et dynamisk og moderne erhvervsmiljø.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/daa02965-5b85-4766-a953-c1540f84f740.jpeg', '', '2025-03-16 06:18:58.988', '2025-03-16 06:18:58.988'),
(25, 'Krøll Crane.', 'kroell-crane', 'Præcis betjening af kran i tåget vejr – sikkerhed og synlighed', 'Professionel kranbetjening under krævende forhold. Vores operatører sikrer optimal sikkerhed og effektivitet, også i tæt tåge og dårligt lys.', 'Effektiv drift af kranens udligger med kraftige projektører, der giver operatøren optimal synlighed, selv under vanskelige forhold som tåge eller nattearbejde. Vores operatørers ekspertise sikrer sikkerheden og præcisionen på byggepladsen uanset vejret.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/5e8fb924-086d-4e03-a395-d055de175b44.jpeg', '', '2025-03-16 06:23:31.854', '2025-03-16 06:23:31.854'),
(26, 'Andrea Brochmanns Gade, Copenhagen.', 'andrea-brochmanns-gade-copenhagen', 'Lejlighedskompleks på Andrea Brochmanns Gade – montering af betonelementer med Liebherr EC-H', 'Opførelse af lejlighedskompleks på Andrea Brochmanns Gade, København. Effektiv og sikker montering af betonelementer med Liebherr EC-H tårnkraner.', 'Opførelse af et nyt lejlighedskompleks på Andrea Brochmanns Gade i København. Vores kranførere sikrer effektiv montering og støbning af betonelementer med Liebherr EC-H kraner. Fokus ligger på præcision, sikkerhed og professionel styring af byggepladsen fra stor højde – uanset tid på døgnet.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/a93daa10-8575-45bf-97f0-46d4f077d492.jpeg', '', '2025-03-16 06:24:37.259', '2025-03-16 06:24:37.259'),
(27, 'Andrea Brochmanns Gade, Copenhagen ', 'andrea-brochmanns--gade-copenhagen-', 'Lejlighedskompleks, Andrea Brochmanns Gade – Betonelementer med Liebherr EC-H kraner', 'Professionel montering og støbning af betonelementer til lejlighedskompleks på Andrea Brochmanns Gade i København. Effektiv byggeproces med Liebherr EC-H tårnkraner.', 'Byggepladsen på Andrea Brochmanns Gade i København med montering af beton- og stålelementer til et nyt lejlighedskompleks. Arbejdet udføres med Liebherr EC-H tårnkraner, som sikrer præcis materialehåndtering, høj sikkerhed og effektiv drift – også i aftentimerne, hvor kranernes projektører sikrer optimale arbejdsforhold. Projektet kombinerer præcision, kvalitet og effektivitet.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/df5ce5bb-1b34-48cb-9989-9550cbe09d96.jpeg', '', '2025-03-16 06:26:14.537', '2025-03-16 06:26:14.537'),
(28, 'Kactus Towers, Copenhagen', 'kactus-towers-copenhagen', 'Kactus Towers, København – Montering af betonelementer og facader med Liebherr EC-H', 'Kranarbejde ved Kactus Towers i København. Professionel montering af beton-, facade- og altanelementer udført med høj præcision af vores erfarne operatører.', 'Tidlig morgen ved Kactus Towers i København, hvor vores operatører effektivt monterer beton-, facade- og altanelementer med Liebherr EC-H tårnkraner. Sikkerhed, præcision og erfaring kendetegner arbejdet, der udføres i højden, midt i et tæt bymiljø.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/6c76ecb6-7826-463d-8151-565eeee9e929.jpeg', '', '2025-03-16 06:28:35.419', '2025-03-16 06:28:35.419'),
(29, 'Papirøen, Copenhagen.', 'papiroeen-copenhagen', 'Hotel og Casino – montering af betonelementer med Liebherr 1000 EC-H, dual cat, 4-cut', 'Professionel kranbetjening ved opførelse af Hotel og Casino med montering af betonelementer, udført med dual cat, 4-cut Liebherr 1000 EC-H i komplekst havneområde.', 'Kranarbejde ved konstruktion af Hotel og Casino, hvor vores kranførere har monteret betonelementer med en dual cat, 4-cut Liebherr 1000 EC-H. Projektet udføres i et krævende miljø ved havnefronten, hvor præcision, sikkerhed og erfaring er afgørende for en effektiv byggeproces.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/85457c98-9429-4e84-baa7-f94feecd2959.jpeg', '', '2025-03-16 06:29:40.431', '2025-03-16 06:29:40.431'),
(30, 'Postbyen, København – Komplekst kranarbejde med Liebherr tårnkraner', 'postbyen-koebenhavn-komplekst-kranarbejde-med-liebherr-taarnkraner', 'Professionel montage af fundament, betonelementer og glasfacader i Postbyen, København, udført med flere Liebherr tårnkraner.', 'Professionel montage af fundament, betonelementer og glasfacader i Postbyen, København, udført med flere Liebherr tårnkraner.', 'Postbyen i København er et omfattende erhvervsprojekt med kompleks krandrift, hvor flere Liebherr tårnkraner arbejder samtidigt. Vores operatører sikrer effektiv og sikker montering af fundament, betonelementer og glasfacader, hvilket kræver præcis koordination og ekspertise på en travl byggeplads.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/1fdfd2bc-af53-40f8-9812-10468eb05bd0.jpeg', '', '2025-03-16 06:31:14.920', '2025-03-16 06:31:14.920'),
(31, 'Carlsberg Byen, København', 'carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', 'Carlsberg Byen, København – In-situ støbning, montage og pladslogistik med Liebherr EC-B kran', 'Effektiv og præcis insitu-støbning med betonspand, løft af gasbeton og byggepladslogistik udført med 100 meter fritstående Liebherr EC-B i Carlsberg Byen.', 'Opførelse af lejlighedsbyggeri i Carlsberg Byen, København. Vores kranførere varetager effektiv støbning med betonspand, håndtering af gasbeton og oprydning på pladsen med en 100 meter fritstående Liebherr EC-B tårnkran. Erfaring og præcision sikrer sikkerhed og en optimal byggeproces på en kompleks og travl byggeplads.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/b3dc3233-9184-43c3-b1d6-1add0377bd7b.jpeg', '', '2025-03-16 06:32:29.371', '2025-03-16 06:32:29.371'),
(32, 'Kongelysvej, Hedehusene ', 'kongelysvej-hedehusene-', 'Lejlighedskompleks, Kongelysvej, Hedehusene – Montering af betonelementer med Krøll-kran', 'Professionel montage af betonelementer til nyt lejlighedskompleks på Kongelysvej i Hedehusene, udført med præcision og sikkerhed ved hjælp af Krøll-kran.', 'Montage af betonelementer til lejlighedskompleks på Kongelysvej i Hedehusene. Vores erfarne operatører anvender Krøll-kraner, der sikrer hurtig og effektiv placering af materialer på byggepladsen, hvor sikkerhed og kvalitet prioriteres højt. Projektet leveres med præcision og godt overblik fra højden.', 'https://ksr-media.fra1.digitaloceanspaces.com/erfaring/71b73429-6230-4029-a5aa-19fa666f352f.jpeg', '', '2025-03-16 06:34:08.473', '2025-03-16 06:34:08.473');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FAQ`
--

CREATE TABLE `FAQ` (
  `id` int NOT NULL,
  `question` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `answer` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `order` int DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `FAQ`
--

INSERT INTO `FAQ` (`id`, `question`, `answer`, `order`, `createdAt`, `updatedAt`) VALUES
(2, 'Hvilke projekter kan I hjælpe med?', 'Vi tilbyder erfarne tårnkranførere til et bredt udvalg af bygge- og anlægsprojekter i hele Danmark. Uanset om det drejer sig om opførelse af højhuse, infrastrukturprojekter eller mindre byggerier, sørger vores kranførere for sikker og effektiv drift af tårnkraner.', 1, '2025-03-14 15:24:33.916', '2025-03-14 15:25:03.480'),
(3, 'Dækker I alle regioner i Danmark?', 'Ja, vi servicerer alle regioner – fra Sjælland og Fyn til Jylland og mindre øer. Vi har et landsdækkende netværk af kranførere, der kan rykke ud til den ønskede lokation efter behov.', 2, '2025-03-14 15:24:57.612', '2025-03-14 15:25:03.460'),
(4, 'Hvordan booker jeg en tårnkranfører?', 'Kontakt os via vores kontaktformular eller telefon. Giv os så mange oplysninger som muligt om projektet – varighed, adresse, arbejdstider, krantype m.m. – så vi kan matche den rette kranfører og planlægge tidsplanen.', 3, '2025-03-14 15:25:18.596', '2025-03-14 15:25:18.596'),
(5, 'Udlejer I også selve tårnkranerne?', 'Nej, vi specialiserer os i udlejning af dygtige kranførere (tårnkranførere) og har ikke selv kraner til rådighed. Hvis du både mangler kran og operatør, kan vi eventuelt henvise til partnere, som leverer selve kranudstyret.', 4, '2025-03-14 15:25:34.774', '2025-03-14 15:25:34.774'),
(6, 'Hvordan booker jeg en tårnkranfører?', 'Kontakt os via vores kontaktformular eller telefon. Giv os så mange oplysninger som muligt om projektet – varighed, adresse, arbejdstider, krantype m.m. – så vi kan matche den rette kranfører og planlægge tidsplanen.', 5, '2025-03-14 15:25:47.332', '2025-03-14 15:25:47.332'),
(7, 'Hvilke kvalifikationer har jeres kranførere?', 'Vores kranførere:\n	•	Har gyldige certifikater til tårnkraner i Danmark,\n	•	Har mange års praktisk erfaring på forskellige projekter,\n	•	Har styr på sikkerhed, kommunikation og arbejdsmiljø,\n	•	Kan nemt indgå i et samarbejde med byggeledelse og øvrigt personale på pladsen.', 6, '2025-03-14 15:25:59.674', '2025-03-14 15:25:59.674'),
(8, 'Er I interesseret i at ansætte nye kranførere?', 'Vi er altid åbne for ansøgninger fra kompetente tårnkranførere, der ønsker at arbejde rundt i Danmark. Har du de nødvendige certifikater og erfaring, så send os en ansøgning via vores jobside eller ring til os direkte.', 7, '2025-03-14 15:26:12.743', '2025-03-14 15:26:12.743'),
(9, 'Hvad hvis projektet bliver forsinket?', 'Hvis dit projekt bliver forsinket, kan vi som regel forlænge lejeaftalen, forudsat at den pågældende kranfører er til rådighed i den forlængede periode. Giv os besked hurtigst muligt, så sørger vi for kontinuerlig drift.', 8, '2025-03-14 15:26:23.803', '2025-03-14 15:26:23.803'),
(10, 'Tilbyder I kranførere uden for almindelig arbejdstid, f.eks. om natten eller i weekender?', 'Ja, vi stræber efter at være fleksible. Ved særlige behov for natarbejde eller weekendarbejde kan vi ofte stille tårnkranførere til rådighed, afhængigt af tilgængelighed og planlægning.', 9, '2025-03-14 15:26:37.078', '2025-03-14 15:26:37.078'),
(11, 'Hjælper I med løftelogistik eller planlægning?', 'Vores hovedfokus er at levere erfarne kranførere. Men i dialog med byggeledelsen kan vi også bidrage med rådgivning om løfteplaner, signaler og sikkerhedsprocedurer, så projektet forløber effektivt og forsvarligt.', 10, '2025-03-14 15:26:49.162', '2025-03-14 15:26:49.162'),
(12, 'Hvordan foregår kommunikationen mellem kranfører og folkene på jorden?', 'Vi benytter typisk radio- og visuelle signaler. Tydelig kommunikation er afgørende for både sikkerhed og hastighed i arbejdet. Vores kranførere tilpasser sig gerne lokale procedurer og samarbejdsformer.', 11, '2025-03-14 15:27:00.089', '2025-03-14 15:27:00.089'),
(13, 'Hvorfor er det en fordel at leje kranførere frem for at ansætte dem?', '•	Fleksibilitet: Let at tilpasse antallet af kranførere til projektets forløb.•	Ekspertise: I får specialister med indsigt i præcis jeres type projekt.\n•	Minimal administration: I slipper for at håndtere ansættelser, løn, forsikringer m.m.', 12, '2025-03-14 15:27:16.492', '2025-03-14 15:27:16.492'),
(14, 'Hvordan kommer jeg i kontakt med jer?', 'I kan sende en besked via kontaktformularen eller ringe til det oplyste telefonnummer. Vi besvarer normalt henvendelser inden for 24 timer, men ved akutte behov er telefon den hurtigste mulighed for at opnå kontakt.\n', 13, '2025-03-14 15:27:28.819', '2025-03-14 15:27:28.819');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FooterSettings`
--

CREATE TABLE `FooterSettings` (
  `id` int NOT NULL,
  `logoUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `videoUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `companyName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `addressLine1` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `addressLine2` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cvrNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `facebookUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `linkedinUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `instagramUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `copyrightYear` int NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `FooterSettings`
--

INSERT INTO `FooterSettings` (`id`, `logoUrl`, `videoUrl`, `companyName`, `addressLine1`, `addressLine2`, `country`, `email`, `phone`, `cvrNumber`, `facebookUrl`, `linkedinUrl`, `instagramUrl`, `copyrightYear`, `createdAt`, `updatedAt`) VALUES
(1, 'https://ksr-media.fra1.digitaloceanspaces.com/footer/6b8ed666-1ba2-422d-8d07-a3f2ebb72681.png', '', 'KSR  CRANES', 'Eskebuen 49', '2620, Albertslund', 'Danmark', 'KSRCranes@outlook.com', '+4523262064', '39095939', 'https://www.instagram.com/ksr_cranes/', 'https://www.linkedin.com/company/ksrcranes/', 'https://www.instagram.com/ksr_cranes/', 2025, '2025-03-15 11:02:40.189', '2025-05-04 18:32:53.099');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FormFieldInteraction`
--

CREATE TABLE `FormFieldInteraction` (
  `id` int NOT NULL,
  `formSessionId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fieldName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `firstTouchedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastTouchedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `interactionCount` int NOT NULL DEFAULT '1',
  `wasCompleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `FormFieldInteraction`
--

INSERT INTO `FormFieldInteraction` (`id`, `formSessionId`, `fieldName`, `firstTouchedAt`, `lastTouchedAt`, `interactionCount`, `wasCompleted`) VALUES
(1, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'serviceType', '2025-05-06 09:10:29', '2025-05-06 09:10:29', 1, 1),
(2, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'selectedOperator', '2025-05-06 09:10:29', '2025-05-06 09:10:29', 1, 1),
(3, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'operatorQuantity', '2025-05-06 09:10:29', '2025-05-06 09:10:29', 1, 1),
(4, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'experienceLevel', '2025-05-06 09:10:33', '2025-05-06 09:10:33', 1, 1),
(5, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'requiredCertifications', '2025-05-06 09:10:36', '2025-05-06 09:10:36', 1, 1),
(6, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'selectedCraneType', '2025-05-06 09:10:39', '2025-05-06 09:10:44', 2, 1),
(7, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'selectedCraneBrand', '2025-05-06 09:10:41', '2025-05-06 09:10:47', 2, 1),
(8, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'selectedCraneModels', '2025-05-06 09:10:49', '2025-05-06 09:10:49', 1, 1),
(9, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'startDate', '2025-05-06 09:10:56', '2025-05-06 09:10:56', 1, 1),
(10, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'duration', '2025-05-06 09:10:57', '2025-05-06 09:10:57', 1, 1),
(11, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'projectName', '2025-05-06 09:11:03', '2025-05-06 09:11:03', 1, 1),
(12, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'projectLocation', '2025-05-06 09:11:05', '2025-05-06 09:11:05', 1, 1),
(13, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'accommodationType', '2025-05-06 09:11:09', '2025-05-06 09:11:09', 1, 1),
(14, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'fullName', '2025-05-06 09:11:13', '2025-05-06 09:11:13', 1, 1),
(15, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'phone', '2025-05-06 09:11:13', '2025-05-06 09:11:13', 1, 1),
(16, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'companyName', '2025-05-06 09:11:15', '2025-05-06 09:11:15', 1, 1),
(17, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'cvrNumber', '2025-05-06 09:11:16', '2025-05-06 09:11:16', 1, 1),
(18, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'email', '2025-05-06 09:11:18', '2025-05-06 09:11:18', 1, 1),
(19, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'acceptTerms', '2025-05-06 09:11:19', '2025-05-06 09:11:19', 1, 1),
(20, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'projectDescription', '2025-05-06 09:12:13', '2025-05-06 09:12:13', 1, 1),
(22, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'operatorDuties', '2025-05-06 09:12:14', '2025-05-06 09:12:14', 1, 1),
(24, '4da2f447-f20b-4067-b344-84e3b5d0e835', 'specialRequirements', '2025-05-06 09:12:15', '2025-05-06 09:12:15', 1, 1),
(26, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'serviceType', '2025-05-06 09:21:54', '2025-05-06 09:21:54', 1, 1),
(28, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'selectedOperator', '2025-05-06 09:21:54', '2025-05-06 09:21:54', 1, 1),
(30, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'includeHooker', '2025-05-06 09:21:56', '2025-05-06 09:21:56', 1, 1),
(31, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'craneModelText', '2025-05-06 09:21:57', '2025-05-06 09:21:57', 1, 1),
(32, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'selectedCraneType', '2025-05-06 09:21:57', '2025-05-06 09:22:28', 2, 1),
(33, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'selectedCraneBrand', '2025-05-06 09:22:21', '2025-05-06 09:22:22', 2, 1),
(34, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'selectedCraneModels', '2025-05-06 09:22:24', '2025-05-06 09:22:32', 2, 1),
(35, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'experienceLevel', '2025-05-06 09:22:39', '2025-05-06 09:22:39', 1, 1),
(36, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'startDate', '2025-05-06 09:23:03', '2025-05-06 09:23:03', 1, 1),
(37, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 'duration', '2025-05-06 09:23:04', '2025-05-06 09:23:04', 1, 1),
(38, '88b9e81c-7c1e-47c4-b585-f0586ec56b50', 'serviceType', '2025-05-07 12:45:53', '2025-05-07 12:46:56', 2, 1),
(39, '88b9e81c-7c1e-47c4-b585-f0586ec56b50', 'selectedOperator', '2025-05-07 12:47:00', '2025-05-07 12:47:00', 1, 1),
(40, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'serviceType', '2025-05-08 07:02:25', '2025-05-08 07:02:25', 1, 1),
(41, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'selectedOperator', '2025-05-08 07:02:32', '2025-05-08 07:02:32', 1, 1),
(42, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'experienceLevel', '2025-05-08 07:02:37', '2025-05-08 07:02:37', 1, 1),
(43, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'requiredCertifications', '2025-05-08 07:02:42', '2025-05-08 07:02:42', 1, 1),
(44, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'includeHooker', '2025-05-08 07:02:44', '2025-05-08 07:02:52', 5, 1),
(45, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'selectedCraneType', '2025-05-08 07:02:57', '2025-05-08 07:03:04', 2, 1),
(46, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'selectedCraneBrand', '2025-05-08 07:02:59', '2025-05-08 07:02:59', 1, 1),
(47, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 'selectedCraneModels', '2025-05-08 07:03:11', '2025-05-08 07:03:11', 1, 1),
(48, '14216011-9be0-4e6c-b1e6-34c061964abd', 'serviceType', '2025-05-23 13:00:40', '2025-05-23 13:00:44', 5, 1),
(49, '14216011-9be0-4e6c-b1e6-34c061964abd', 'selectedOperator', '2025-05-23 13:00:49', '2025-05-23 13:00:50', 2, 1),
(50, '14216011-9be0-4e6c-b1e6-34c061964abd', 'experienceLevel', '2025-05-23 13:00:54', '2025-05-23 13:00:54', 1, 1),
(51, '14216011-9be0-4e6c-b1e6-34c061964abd', 'requiredCertifications', '2025-05-23 13:00:56', '2025-05-23 13:00:56', 1, 1),
(52, '14216011-9be0-4e6c-b1e6-34c061964abd', 'includeHooker', '2025-05-23 13:00:58', '2025-05-23 13:00:58', 1, 1),
(53, '14216011-9be0-4e6c-b1e6-34c061964abd', 'hookerQuantity', '2025-05-23 13:00:59', '2025-05-23 13:00:59', 1, 1),
(54, '14216011-9be0-4e6c-b1e6-34c061964abd', 'selectedCraneType', '2025-05-23 13:01:03', '2025-05-23 13:01:13', 2, 1),
(55, '14216011-9be0-4e6c-b1e6-34c061964abd', 'selectedCraneBrand', '2025-05-23 13:01:05', '2025-05-23 13:01:05', 1, 1),
(56, '14216011-9be0-4e6c-b1e6-34c061964abd', 'selectedCraneModels', '2025-05-23 13:01:18', '2025-05-23 13:01:18', 1, 1),
(57, '14216011-9be0-4e6c-b1e6-34c061964abd', 'startDate', '2025-05-23 13:01:27', '2025-05-23 13:01:29', 2, 1),
(58, '14216011-9be0-4e6c-b1e6-34c061964abd', 'duration', '2025-05-23 13:01:31', '2025-05-23 13:01:31', 1, 1),
(59, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'serviceType', '2025-05-27 10:14:49', '2025-05-27 10:14:49', 1, 1),
(60, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'selectedOperator', '2025-05-27 10:14:55', '2025-05-27 10:14:55', 1, 1),
(61, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'operatorLanguages', '2025-05-27 10:15:15', '2025-05-27 10:15:16', 2, 1),
(62, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'requiredCertifications', '2025-05-27 10:15:18', '2025-05-27 10:15:18', 1, 1),
(63, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'craneHeight', '2025-05-27 10:15:22', '2025-05-27 10:15:23', 5, 1),
(64, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'experienceLevel', '2025-05-27 10:15:36', '2025-05-27 10:15:36', 1, 1),
(65, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'craneModelText', '2025-05-27 10:15:45', '2025-05-27 10:15:45', 2, 1),
(66, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 'includeHooker', '2025-05-27 10:16:00', '2025-05-27 10:16:00', 1, 1),
(67, 'cf656aaf-e8c1-4140-92ce-f4df6c962a4f', 'serviceType', '2025-05-28 09:07:49', '2025-05-28 09:07:49', 1, 1),
(68, 'cf656aaf-e8c1-4140-92ce-f4df6c962a4f', 'selectedOperator', '2025-05-28 09:07:55', '2025-05-28 09:07:55', 1, 1),
(69, 'cf656aaf-e8c1-4140-92ce-f4df6c962a4f', 'experienceLevel', '2025-05-28 09:07:57', '2025-05-28 09:07:57', 1, 1),
(70, 'cf656aaf-e8c1-4140-92ce-f4df6c962a4f', 'requiredCertifications', '2025-05-28 09:07:59', '2025-05-28 09:08:00', 3, 1),
(71, '51865912-9870-4d3b-bbcd-7afeddabe886', 'serviceType', '2025-05-29 09:30:28', '2025-05-29 09:30:28', 1, 1),
(72, '51865912-9870-4d3b-bbcd-7afeddabe886', 'selectedOperator', '2025-05-29 09:30:30', '2025-05-29 09:30:48', 3, 1),
(73, '14216011-9be0-4e6c-b1e6-34c061964abd', 'accommodationType', '2025-05-31 20:20:11', '2025-05-31 20:20:31', 3, 1),
(74, '14216011-9be0-4e6c-b1e6-34c061964abd', 'projectName', '2025-05-31 20:20:22', '2025-05-31 20:20:23', 3, 1),
(75, '14216011-9be0-4e6c-b1e6-34c061964abd', 'projectLocation', '2025-05-31 20:20:23', '2025-05-31 20:20:24', 3, 1),
(76, '14216011-9be0-4e6c-b1e6-34c061964abd', 'projectDescription', '2025-05-31 20:20:24', '2025-05-31 20:20:25', 3, 1),
(77, '14216011-9be0-4e6c-b1e6-34c061964abd', 'operatorDuties', '2025-05-31 20:20:25', '2025-05-31 20:20:26', 3, 1),
(78, '14216011-9be0-4e6c-b1e6-34c061964abd', 'specialRequirements', '2025-05-31 20:20:26', '2025-05-31 20:20:26', 3, 1),
(79, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'serviceType', '2025-06-04 09:32:55', '2025-06-04 09:32:55', 1, 1),
(80, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'selectedOperator', '2025-06-04 09:33:19', '2025-06-04 09:33:19', 1, 1),
(81, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'experienceLevel', '2025-06-04 09:33:25', '2025-06-04 09:33:25', 1, 1),
(82, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'requiredCertifications', '2025-06-04 09:33:32', '2025-06-04 09:33:32', 1, 1),
(83, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'operatorLanguages', '2025-06-04 09:33:37', '2025-06-04 09:33:37', 1, 1),
(84, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 'craneModelText', '2025-06-04 09:33:59', '2025-06-04 09:34:01', 8, 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FormSession`
--

CREATE TABLE `FormSession` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `startedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completedAt` datetime DEFAULT NULL,
  `ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userAgent` text COLLATE utf8mb4_unicode_ci,
  `country` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deviceType` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `os` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `browser` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `referrer` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lastStep` int NOT NULL DEFAULT '1',
  `isSubmitted` tinyint(1) NOT NULL DEFAULT '0',
  `formType` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sessionData` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `FormSession`
--

INSERT INTO `FormSession` (`id`, `startedAt`, `completedAt`, `ip`, `userAgent`, `country`, `city`, `deviceType`, `os`, `browser`, `referrer`, `lastStep`, `isSubmitted`, `formType`, `sessionData`) VALUES
('14216011-9be0-4e6c-b1e6-34c061964abd', '2025-05-23 13:00:38', NULL, '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', NULL, NULL, 'mobile', 'iOS', 'Mobile Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 5, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"1-week\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"2025-05-24\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"45\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"Red\", \"serviceType\": \"weekly\", \"includeHooker\": true, \"craneModelText\": \"\", \"hookerQuantity\": 2, \"operatorDuties\": \"Hhg\", \"projectContext\": \"\", \"experienceLevel\": \"experienced\", \"projectLocation\": \"Hhf\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"tower-crane\", \"accommodationType\": \"none\", \"operatorLanguages\": [\"danish\"], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"Hhg\", \"selectedCraneBrand\": \"3\", \"selectedCraneModels\": [], \"specialRequirements\": \"Bhf\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"1\", \"requiredCertifications\": [\"standard\"]}'),
('196d4180-6f82-4ed3-8aca-fec5143b66ee', '2025-05-28 09:04:19', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('32563328-7eb4-4420-901f-0c7d27718442', '2025-05-23 20:44:06', NULL, '66.249.66.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', NULL, NULL, 'mobile', 'Android', 'Mobile Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('33464914-20dd-4901-81ef-d227e73014a8', '2025-05-28 09:53:42', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('387284c3-e972-4b13-bdd5-3197a658d3a5', '2025-05-07 17:16:56', NULL, '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1', NULL, NULL, 'mobile', 'iOS', 'Mobile Safari', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('3c91a62f-e9f8-4f2e-800f-f243c60f51a4', '2025-05-06 09:19:00', NULL, '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Linux', 'Chrome', 'http://localhost:3000/', 4, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"2-weeks\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"2025-05-06\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"45\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"daily\", \"includeHooker\": true, \"craneModelText\": \"liebherr beltcrane\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"experienced\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"tower-crane\", \"accommodationType\": \"\", \"operatorLanguages\": [\"danish\"], \"selectedCraneType\": \"2\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"3\", \"selectedCraneModels\": [23], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"1\", \"requiredCertifications\": []}'),
('4da2f447-f20b-4067-b344-84e3b5d0e835', '2025-05-06 07:15:10', '2025-05-06 09:12:21', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Linux', 'Chrome', 'http://localhost:3000/', 5, 1, 'operator-hiring', '{\"email\": \"majkemanizer@gmail.com\", \"phone\": \"52796019\", \"duration\": \"1-week\", \"fullName\": \"Maksymilian Marcinowski\", \"cvrNumber\": \"39095939\", \"startDate\": \"2025-05-06\", \"acceptTerms\": true, \"companyName\": \"Dansk Konstruktion & Byg ApS\", \"craneHeight\": \"45\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"Nordre Havn Boligtårn\", \"serviceType\": \"weekly\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"ok\", \"projectContext\": \"\", \"experienceLevel\": \"experienced\", \"projectLocation\": \"Havnevej 24, 8000 Aarhus C\", \"additionalSkills\": \"\", \"operatorQuantity\": 2, \"selectedOperator\": \"tower-crane\", \"accommodationType\": \"none\", \"operatorLanguages\": [\"danish\"], \"selectedCraneType\": \"2\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"ok\", \"selectedCraneBrand\": \"1\", \"selectedCraneModels\": [38], \"specialRequirements\": \"ok\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"1\", \"requiredCertifications\": [\"standard\"]}'),
('51865912-9870-4d3b-bbcd-7afeddabe886', '2025-05-29 09:30:25', NULL, '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.1579.3', NULL, NULL, 'mobile', 'iOS', 'LinkedIn', 'https://ksrcranes.dk/lej-en-kranforer', 2, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"weekly\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"\", \"accommodationType\": \"\", \"operatorLanguages\": [], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"\", \"selectedCraneModels\": [], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"\", \"requiredCertifications\": []}'),
('6b1193d3-32d5-4a7b-81a0-e2e7c165a083', '2025-05-06 09:19:00', NULL, '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Linux', 'Chrome', 'http://localhost:3000/', 1, 0, 'operator-hiring', NULL),
('6bd4a929-29e4-4dce-9fad-dd62452f17a2', '2025-06-04 09:32:44', NULL, '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Windows', 'Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 2, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"daily\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"\", \"accommodationType\": \"\", \"operatorLanguages\": [], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"\", \"selectedCraneModels\": [], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"\", \"requiredCertifications\": []}'),
('833b682b-aaaa-4628-b12f-8d121380a1e8', '2025-06-02 03:08:40', NULL, '66.249.66.160', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', NULL, NULL, 'mobile', 'Android', 'Mobile Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('87f8f6e1-fb8d-4463-be8f-c8825f942e5d', '2025-05-26 12:06:05', NULL, '66.249.65.172', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', NULL, NULL, 'mobile', 'Android', 'Mobile Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('88b9e81c-7c1e-47c4-b585-f0586ec56b50', '2025-05-07 12:45:45', NULL, '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Windows', 'Chrome', 'https://www.ksrcranes.dk/lej-en-kranforer', 2, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"weekly\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"\", \"accommodationType\": \"\", \"operatorLanguages\": [], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"\", \"selectedCraneModels\": [], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"\", \"requiredCertifications\": []}'),
('8e4b4c4d-23fc-42f8-9d05-43e0a78a5177', '2025-06-03 08:54:24', NULL, '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Windows', 'Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('a4baca9f-238a-4ab2-9695-10a882d6d64b', '2025-05-28 09:53:33', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('a78923bd-8f62-4a68-b002-ac3c92d5d95e', '2025-05-11 05:26:22', NULL, '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', NULL, NULL, 'mobile', 'iOS', 'Mobile Firefox', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('aebd6e2a-09a5-46b7-bee5-c7cd04f920ad', '2025-05-28 09:53:33', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('b814aa76-ea45-404d-8817-eec7337c9bce', '2025-05-27 10:04:53', NULL, '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', NULL, NULL, 'desktop', 'Windows', 'Edge', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('c6ae102f-0fe2-4d5e-afc4-dbfd57568fc6', '2025-05-06 07:15:10', NULL, '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'Linux', 'Chrome', 'http://localhost:3000/', 1, 0, 'operator-hiring', NULL),
('cf656aaf-e8c1-4140-92ce-f4df6c962a4f', '2025-05-28 09:04:19', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 2, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"daily\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"\", \"accommodationType\": \"\", \"operatorLanguages\": [], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"\", \"selectedCraneModels\": [], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"\", \"requiredCertifications\": []}'),
('d516dab0-8847-41a1-b823-9e5ad06f163f', '2025-05-24 02:09:31', NULL, '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', NULL, NULL, 'mobile', 'Android', 'Mobile Chrome', 'https://www.ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', '2025-05-06 13:16:22', NULL, '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', NULL, NULL, 'mobile', 'iOS', 'Mobile Chrome', 'https://ksrcranes.dk/', 3, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"45\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"weekly\", \"includeHooker\": true, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"experienced\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"tower-crane\", \"accommodationType\": \"\", \"operatorLanguages\": [\"danish\"], \"selectedCraneType\": \"2\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"2\", \"selectedCraneModels\": [14], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"1\", \"requiredCertifications\": [\"standard\"]}'),
('e9d5339f-e923-40ec-ab93-27ab8997dedb', '2025-05-27 10:14:37', NULL, '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', NULL, NULL, 'desktop', 'Windows', 'Firefox', 'https://ksrcranes.dk/lej-en-kranforer', 2, 0, 'operator-hiring', '{\"email\": \"\", \"phone\": \"\", \"duration\": \"\", \"fullName\": \"\", \"cvrNumber\": \"\", \"startDate\": \"\", \"acceptTerms\": false, \"companyName\": \"\", \"craneHeight\": \"\", \"daysPerWeek\": 5, \"hoursPerDay\": 8, \"projectName\": \"\", \"serviceType\": \"monthly\", \"includeHooker\": false, \"craneModelText\": \"\", \"hookerQuantity\": 1, \"operatorDuties\": \"\", \"projectContext\": \"\", \"experienceLevel\": \"\", \"projectLocation\": \"\", \"additionalSkills\": \"\", \"operatorQuantity\": 1, \"selectedOperator\": \"\", \"accommodationType\": \"\", \"operatorLanguages\": [], \"selectedCraneType\": \"\", \"additionalTimeInfo\": \"\", \"projectDescription\": \"\", \"selectedCraneBrand\": \"\", \"selectedCraneModels\": [], \"specialRequirements\": \"\", \"accommodationDetails\": \"\", \"selectedCraneCategory\": \"\", \"requiredCertifications\": []}'),
('ec549165-a68a-4251-9e3f-b8fdc71dabed', '2025-05-11 09:00:55', NULL, '66.249.79.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', NULL, NULL, 'mobile', 'Android', 'Mobile Chrome', 'https://ksrcranes.dk/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('fee2c49e-d989-40c8-92f5-071bb134b4ca', '2025-05-28 09:53:42', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL),
('ff7c09f1-5248-450e-94a3-4c6baee453c8', '2025-05-28 09:04:11', NULL, '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', NULL, NULL, 'desktop', 'macOS', 'Chrome', 'http://localhost:3000/lej-en-kranforer', 1, 0, 'operator-hiring', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FormSnapshot`
--

CREATE TABLE `FormSnapshot` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `formSessionId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stepNumber` int NOT NULL,
  `formData` json NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `FormStepData`
--

CREATE TABLE `FormStepData` (
  `id` int NOT NULL,
  `formSessionId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `stepNumber` int NOT NULL,
  `enteredAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `exitedAt` datetime DEFAULT NULL,
  `timeSpentMs` int DEFAULT NULL,
  `wasCompleted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `FormStepData`
--

INSERT INTO `FormStepData` (`id`, `formSessionId`, `stepNumber`, `enteredAt`, `exitedAt`, `timeSpentMs`, `wasCompleted`) VALUES
(1, 'c6ae102f-0fe2-4d5e-afc4-dbfd57568fc6', 1, '2025-05-06 07:15:16', NULL, NULL, 0),
(2, '4da2f447-f20b-4067-b344-84e3b5d0e835', 1, '2025-05-06 07:15:16', '2025-05-06 09:10:29', 6912971, 1),
(3, '4da2f447-f20b-4067-b344-84e3b5d0e835', 2, '2025-05-06 09:10:52', NULL, NULL, 1),
(4, '4da2f447-f20b-4067-b344-84e3b5d0e835', 3, '2025-05-06 09:11:00', NULL, NULL, 1),
(5, '4da2f447-f20b-4067-b344-84e3b5d0e835', 4, '2025-05-06 09:11:11', '2025-05-06 09:12:17', 66443, 1),
(6, '4da2f447-f20b-4067-b344-84e3b5d0e835', 5, '2025-05-06 09:11:31', '2025-05-06 09:12:22', 51029, 1),
(7, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 1, '2025-05-06 09:19:03', '2025-05-06 09:21:54', 171209, 1),
(8, '6b1193d3-32d5-4a7b-81a0-e2e7c165a083', 1, '2025-05-06 09:19:03', NULL, NULL, 0),
(9, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 2, '2025-05-06 09:22:43', NULL, NULL, 1),
(10, '3c91a62f-e9f8-4f2e-800f-f243c60f51a4', 3, '2025-05-06 09:23:06', NULL, NULL, 1),
(11, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 1, '2025-05-06 13:16:22', '2025-05-08 07:02:27', 150364693, 1),
(12, '88b9e81c-7c1e-47c4-b585-f0586ec56b50', 1, '2025-05-07 12:45:45', '2025-05-07 12:46:58', 72676, 1),
(13, '387284c3-e972-4b13-bdd5-3197a658d3a5', 1, '2025-05-07 17:16:56', NULL, NULL, 0),
(14, 'e3a7f5b5-5014-4bdc-99c9-2ef9c38e33c1', 2, '2025-05-08 07:03:14', NULL, NULL, 1),
(15, 'a78923bd-8f62-4a68-b002-ac3c92d5d95e', 1, '2025-05-11 05:26:22', NULL, NULL, 0),
(16, 'ec549165-a68a-4251-9e3f-b8fdc71dabed', 1, '2025-05-11 09:00:55', NULL, NULL, 0),
(17, '14216011-9be0-4e6c-b1e6-34c061964abd', 1, '2025-05-23 13:00:38', '2025-05-23 13:00:45', 7221, 1),
(18, '14216011-9be0-4e6c-b1e6-34c061964abd', 2, '2025-05-23 13:01:25', NULL, NULL, 1),
(19, '14216011-9be0-4e6c-b1e6-34c061964abd', 3, '2025-05-23 13:01:34', NULL, NULL, 1),
(20, '32563328-7eb4-4420-901f-0c7d27718442', 1, '2025-05-23 20:44:06', NULL, NULL, 0),
(21, 'd516dab0-8847-41a1-b823-9e5ad06f163f', 1, '2025-05-24 02:09:31', NULL, NULL, 0),
(22, '87f8f6e1-fb8d-4463-be8f-c8825f942e5d', 1, '2025-05-26 12:06:05', NULL, NULL, 0),
(23, 'b814aa76-ea45-404d-8817-eec7337c9bce', 1, '2025-05-27 10:04:53', NULL, NULL, 0),
(24, 'e9d5339f-e923-40ec-ab93-27ab8997dedb', 1, '2025-05-27 10:14:37', '2025-05-27 10:14:51', 14126, 1),
(25, 'ff7c09f1-5248-450e-94a3-4c6baee453c8', 1, '2025-05-28 09:04:12', NULL, NULL, 0),
(26, '196d4180-6f82-4ed3-8aca-fec5143b66ee', 1, '2025-05-28 09:04:19', NULL, NULL, 0),
(27, 'cf656aaf-e8c1-4140-92ce-f4df6c962a4f', 1, '2025-05-28 09:04:19', '2025-05-28 09:07:50', 211022, 1),
(28, 'a4baca9f-238a-4ab2-9695-10a882d6d64b', 1, '2025-05-28 09:53:33', NULL, NULL, 0),
(29, 'aebd6e2a-09a5-46b7-bee5-c7cd04f920ad', 1, '2025-05-28 09:53:34', NULL, NULL, 0),
(30, '33464914-20dd-4901-81ef-d227e73014a8', 1, '2025-05-28 09:53:42', NULL, NULL, 0),
(31, 'fee2c49e-d989-40c8-92f5-071bb134b4ca', 1, '2025-05-28 09:53:43', NULL, NULL, 0),
(32, '51865912-9870-4d3b-bbcd-7afeddabe886', 1, '2025-05-29 09:30:25', '2025-05-29 09:30:29', 3777, 1),
(33, '14216011-9be0-4e6c-b1e6-34c061964abd', 4, '2025-05-31 20:20:32', NULL, NULL, 1),
(34, '833b682b-aaaa-4628-b12f-8d121380a1e8', 1, '2025-06-02 03:08:40', NULL, NULL, 0),
(35, '8e4b4c4d-23fc-42f8-9d05-43e0a78a5177', 1, '2025-06-03 08:54:24', NULL, NULL, 0),
(36, '6bd4a929-29e4-4dce-9fad-dd62452f17a2', 1, '2025-06-04 09:32:44', '2025-06-04 09:32:56', 11945, 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Hero`
--

CREATE TABLE `Hero` (
  `id` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ctaText` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ctaLink` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `videoUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Hero`
--

INSERT INTO `Hero` (`id`, `title`, `subtitle`, `ctaText`, `ctaLink`, `videoUrl`, `createdAt`, `updatedAt`) VALUES
(1, 'Drevet af kranførere, for kranførere', 'Hos KSR CRANES forstår vi at kranen er kernen i ethvert byggeprojekt. \nVi prioriterer kommunikation og sikkerhed – lad os løfte dine byggerier til nye højder.', 'Kontakt os i dag', '#contact', '', '2025-03-12 13:26:08.223', '2025-03-21 06:01:25.148');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `HiringRequestAttachment`
--

CREATE TABLE `HiringRequestAttachment` (
  `id` int UNSIGNED NOT NULL,
  `requestId` int UNSIGNED NOT NULL,
  `fileName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fileUrl` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fileType` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fileSize` int UNSIGNED NOT NULL,
  `uploadedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `HiringRequestStatusHistory`
--

CREATE TABLE `HiringRequestStatusHistory` (
  `id` int UNSIGNED NOT NULL,
  `requestId` int UNSIGNED NOT NULL,
  `previousStatus` enum('PENDING','REVIEWING','APPROVED','SCHEDULED','REJECTED','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `newStatus` enum('PENDING','REVIEWING','APPROVED','SCHEDULED','REJECTED','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `changedById` int UNSIGNED NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `HiringRequestStatusHistory`
--

INSERT INTO `HiringRequestStatusHistory` (`id`, `requestId`, `previousStatus`, `newStatus`, `changedById`, `notes`, `createdAt`) VALUES
(4, 17, 'PENDING', 'APPROVED', 1, 'Quote generated: KSR-250328-7855', '2025-03-28 11:24:01'),
(5, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250328-7759', '2025-03-28 15:57:14'),
(6, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250328-3918 (PDF only)', '2025-03-28 22:17:48'),
(7, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KO-001207 (PDF only)', '2025-03-29 10:26:42'),
(8, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250329-5200 (PDF only)', '2025-03-29 11:59:39'),
(9, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250329-9852 (PDF only)', '2025-03-29 12:01:07'),
(10, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250329-7260 (PDF only)', '2025-03-29 12:02:57'),
(11, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250329-6865', '2025-03-29 12:08:51'),
(12, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-250329-2336', '2025-03-29 14:14:02'),
(13, 17, 'APPROVED', 'APPROVED', 1, 'Oferta KSR-2025-1861 wygenerowana.', '2025-03-29 20:26:00'),
(14, 17, 'APPROVED', 'APPROVED', 1, 'Oferta KSR-2025-1861 wygenerowana.', '2025-03-29 20:28:48'),
(15, 17, 'APPROVED', 'APPROVED', 1, 'Oferta KSR-2025-3030 wygenerowana.', '2025-03-30 08:05:06'),
(16, 17, 'APPROVED', 'APPROVED', 1, 'Oferta KSR-2025-3030 wygenerowana.', '2025-03-30 08:05:06'),
(17, 17, 'APPROVED', 'APPROVED', 1, 'Oferta KSR-2025-1867 wygenerowana.', '2025-03-30 08:08:35'),
(18, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-1867', '2025-03-30 08:17:27'),
(19, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-1867', '2025-03-30 09:12:01'),
(20, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-1867', '2025-03-30 09:12:20'),
(21, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-1867', '2025-03-30 09:13:00'),
(22, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-1867', '2025-03-30 09:14:36'),
(23, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-0757', '2025-03-30 10:05:07'),
(24, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-5014', '2025-03-31 20:29:52'),
(25, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-0526', '2025-03-31 20:30:42'),
(26, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-7277', '2025-03-31 20:34:52'),
(27, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-5984', '2025-03-31 20:51:30'),
(28, 17, 'APPROVED', 'APPROVED', 1, 'Quote generated: KSR-2025-7958', '2025-04-05 13:05:27'),
(29, 17, 'APPROVED', 'CANCELLED', 1, NULL, '2025-05-03 06:02:21');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `LeaveAuditLog`
--

CREATE TABLE `LeaveAuditLog` (
  `id` int UNSIGNED NOT NULL,
  `leave_request_id` int UNSIGNED DEFAULT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `action` enum('CREATED','APPROVED','REJECTED','CANCELLED','MODIFIED','DELETED') NOT NULL,
  `old_values` json DEFAULT NULL COMMENT 'previous values in JSON format',
  `new_values` json DEFAULT NULL COMMENT 'new values in JSON format',
  `performed_by` int UNSIGNED NOT NULL,
  `performed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `notes` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Audit trail for all leave-related actions';

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `LeaveBalance`
--

CREATE TABLE `LeaveBalance` (
  `id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `year` int NOT NULL,
  `vacation_days_total` int DEFAULT '25' COMMENT 'total annual vacation days (Danish standard)',
  `vacation_days_used` int DEFAULT '0' COMMENT 'used vacation days',
  `sick_days_used` int DEFAULT '0' COMMENT 'used sick days (tracking only)',
  `personal_days_total` int DEFAULT '5' COMMENT 'personal days allowance',
  `personal_days_used` int DEFAULT '0' COMMENT 'used personal days',
  `carry_over_days` int DEFAULT '0' COMMENT 'carried over from previous year',
  `carry_over_expires` date DEFAULT NULL COMMENT 'expiration date for carried over days',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

--
-- Zrzut danych tabeli `LeaveBalance`
--

INSERT INTO `LeaveBalance` (`id`, `employee_id`, `year`, `vacation_days_total`, `vacation_days_used`, `sick_days_used`, `personal_days_total`, `personal_days_used`, `carry_over_days`, `carry_over_expires`, `created_at`, `updated_at`) VALUES
(1, 1, 2025, 25, 0, 0, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(2, 2, 2025, 25, 0, 2, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 17:17:42'),
(3, 3, 2025, 25, 0, 0, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(4, 7, 2025, 25, 0, 0, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(5, 8, 2025, 25, 0, 0, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(6, 9, 2025, 25, 0, 0, 5, 0, 0, NULL, '2025-06-05 11:32:43', '2025-06-05 11:32:43');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `LeaveRequests`
--

CREATE TABLE `LeaveRequests` (
  `id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `type` enum('VACATION','SICK','PERSONAL','PARENTAL','COMPENSATORY','EMERGENCY') NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `total_days` int NOT NULL,
  `half_day` tinyint(1) DEFAULT '0' COMMENT 'true if morning/afternoon only',
  `status` enum('PENDING','APPROVED','REJECTED','CANCELLED','EXPIRED') DEFAULT 'PENDING',
  `reason` text,
  `sick_note_url` varchar(1024) DEFAULT NULL COMMENT 'S3 URL for sick leave documentation',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `approved_by` int UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `rejection_reason` text,
  `emergency_leave` tinyint(1) DEFAULT '0' COMMENT 'for urgent sick leave'
) ;

--
-- Zrzut danych tabeli `LeaveRequests`
--

INSERT INTO `LeaveRequests` (`id`, `employee_id`, `type`, `start_date`, `end_date`, `total_days`, `half_day`, `status`, `reason`, `sick_note_url`, `created_at`, `updated_at`, `approved_by`, `approved_at`, `rejection_reason`, `emergency_leave`) VALUES
(1, 2, 'VACATION', '2025-07-16', '2025-07-31', 12, 0, 'REJECTED', NULL, NULL, '2025-06-05 15:46:52', '2025-06-05 23:22:24', NULL, NULL, 'A', 1),
(2, 2, 'SICK', '2025-06-05', '2025-06-05', 1, 0, 'APPROVED', NULL, NULL, '2025-06-05 16:26:55', '2025-06-05 16:26:55', 2, '2025-06-05 16:26:55', NULL, 1),
(3, 2, 'SICK', '2025-06-04', '2025-06-04', 1, 0, 'APPROVED', 'Very sick ', NULL, '2025-06-05 17:07:59', '2025-06-05 17:07:59', 2, '2025-06-05 17:07:59', NULL, 1),
(4, 2, 'VACATION', '2025-06-26', '2025-07-04', 7, 0, 'PENDING', NULL, NULL, '2025-06-05 20:06:16', '2025-06-05 20:06:16', NULL, NULL, NULL, 0);

--
-- Wyzwalacze `LeaveRequests`
--
DELIMITER $$
CREATE TRIGGER `tr_leave_request_approved` AFTER UPDATE ON `LeaveRequests` FOR EACH ROW BEGIN
    -- Only process if status changed to APPROVED
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' THEN
        CALL UpdateLeaveBalance(
            NEW.employee_id, 
            NEW.type, 
            NEW.total_days, 
            YEAR(NEW.start_date)
        );
    END IF;
    
    -- If status changed from APPROVED to something else, reverse the balance
    IF OLD.status = 'APPROVED' AND NEW.status != 'APPROVED' THEN
        CALL UpdateLeaveBalance(
            NEW.employee_id, 
            NEW.type, 
            -NEW.total_days, 
            YEAR(NEW.start_date)
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_leave_request_calculate_days` BEFORE INSERT ON `LeaveRequests` FOR EACH ROW BEGIN
    SET NEW.total_days = CalculateWorkDays(NEW.start_date, NEW.end_date);
    
    -- If half day, reduce by 0.5
    IF NEW.half_day = TRUE THEN
        SET NEW.total_days = GREATEST(1, NEW.total_days / 2);
    END IF;
    
    -- Validate approval logic (since we can't use check constraint)
    IF NEW.status = 'APPROVED' AND (NEW.approved_by IS NULL OR NEW.approved_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approved leave requests must have approved_by and approved_at values';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_leave_request_validate_update` BEFORE UPDATE ON `LeaveRequests` FOR EACH ROW BEGIN
    -- Validate approval logic
    IF NEW.status = 'APPROVED' AND (NEW.approved_by IS NULL OR NEW.approved_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approved leave requests must have approved_by and approved_at values';
    END IF;
    
    -- Auto-set approved_at when status changes to APPROVED
    IF OLD.status != 'APPROVED' AND NEW.status = 'APPROVED' AND NEW.approved_at IS NULL THEN
        SET NEW.approved_at = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `linkedin_embeds`
--

CREATE TABLE `linkedin_embeds` (
  `id` int NOT NULL,
  `postUrl` varchar(255) NOT NULL,
  `embedCode` text NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `imageUrl` varchar(255) DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT '1',
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `linkedin_posts`
--

CREATE TABLE `linkedin_posts` (
  `id` int NOT NULL,
  `blogPostId` int NOT NULL,
  `linkedInPostId` varchar(255) NOT NULL,
  `publishedAt` datetime NOT NULL,
  `status` varchar(50) DEFAULT 'published',
  `engagementData` text,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `linkedin_publish_errors`
--

CREATE TABLE `linkedin_publish_errors` (
  `id` int NOT NULL,
  `blogPostId` int NOT NULL,
  `errorMessage` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `retryCount` int NOT NULL DEFAULT '0',
  `lastRetryAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `linkedin_settings`
--

CREATE TABLE `linkedin_settings` (
  `id` int NOT NULL,
  `accessToken` text NOT NULL,
  `refreshToken` text,
  `expiresAt` datetime NOT NULL,
  `personUrn` varchar(255) NOT NULL,
  `profileData` text,
  `autoPublish` tinyint(1) DEFAULT '0',
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `linkedin_settings`
--

INSERT INTO `linkedin_settings` (`id`, `accessToken`, `refreshToken`, `expiresAt`, `personUrn`, `profileData`, `autoPublish`, `createdAt`, `updatedAt`) VALUES
(1, 'AQUZQDjyVUXyS9WCTZ0tUzXd4_9oqDdEU4RCvT6kmtWlOu_nVPoiLYvwG5r4uKGf5Xf_0pKnOZHW_ZacZfg2bBnqhZnc3rqW7m0-j4qy0vjK0ht0agYjI2vu4QvfHggzCh8lZ5MvOZqtt6y2tCXELvm1x_zND3AFGvqft_QkSV-X5k6McLDT6opN8Gllc-HsCBlFVbunO-jylBFuDWbs7UXBGHMM_bdSJy-3eU8y6fJG89a5dV4MOxUC6DUfNImvFdCNWe-Kg5xh8ne79IAZgVD3yrsqn0dnDxfOFY51uJDUrghy0lauaBMQB6513BTZwdtTh5MQ3MIEo3K6X8EPH6uzAQL3wA', NULL, '2025-07-24 11:34:52', 'gQKsuIOvzT', '{\"sub\":\"gQKsuIOvzT\",\"email_verified\":true,\"name\":\"Max Marcinowski\",\"locale\":{\"country\":\"PL\",\"language\":\"pl\"},\"given_name\":\"Max\",\"family_name\":\"Marcinowski\",\"email\":\"marcimax@wp.pl\",\"picture\":\"https://media.licdn.com/dms/image/v2/D4D03AQFLHM5ZDhZkTQ/profile-displayphoto-shrink_100_100/profile-displayphoto-shrink_100_100/0/1671458809018?e=1753920000&v=beta&t=3Q6m0NkRRjuFO_bho9QBIZQf3t3BZ0kYraAZJYq4R8w\"}', 0, '2025-05-25 11:34:52', '2025-05-25 11:34:52');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Message`
--

CREATE TABLE `Message` (
  `message_id` int UNSIGNED NOT NULL,
  `conversation_id` int UNSIGNED NOT NULL,
  `sender_id` int UNSIGNED NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `embed` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Message`
--

INSERT INTO `Message` (`message_id`, `conversation_id`, `sender_id`, `content`, `created_at`, `embed`) VALUES
(199, 22, 1, 'wewew', '2025-03-19 20:39:01', NULL),
(200, 22, 1, 'wecwecw', '2025-03-19 20:54:34', NULL),
(201, 22, 1, 'attachment:https://direct-bucket.fra1.digitaloceanspaces.com/direct/22/1742417693944_347114bf-601c-4dfe-8142-a407707a3b55.jpeg', '2025-03-19 20:54:54', NULL),
(202, 22, 1, 'qqwcqw', '2025-03-19 20:56:09', NULL),
(203, 22, 1, 'vreveravrav', '2025-03-19 20:56:11', NULL),
(204, 22, 1, 'arvaervaeva', '2025-03-19 20:56:13', NULL),
(205, 22, 1, 'vraevaevaevr', '2025-03-19 20:56:17', NULL),
(206, 22, 1, 'vraevaevae', '2025-03-19 20:56:19', NULL),
(207, 22, 1, 'cewcw', '2025-03-19 20:58:45', NULL),
(208, 22, 1, 'wewecw', '2025-03-19 21:03:19', NULL),
(209, 20, 1, 'whooop', '2025-03-19 21:46:06', NULL),
(212, 22, 1, 'Pk', '2025-03-19 22:10:50', NULL),
(216, 20, 1, 'Hi', '2025-03-20 07:48:47', NULL),
(217, 22, 1, 'Hdbe', '2025-03-20 07:49:02', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `MessageStatus`
--

CREATE TABLE `MessageStatus` (
  `id` int UNSIGNED NOT NULL,
  `message_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `status` enum('SENT','DELIVERED','READ') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SENT',
  `delivered_at` datetime(3) DEFAULT NULL,
  `read_at` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `MessageStatus`
--

INSERT INTO `MessageStatus` (`id`, `message_id`, `employee_id`, `status`, `delivered_at`, `read_at`) VALUES
(357, 199, 1, 'READ', '2025-03-19 20:39:01.560', '2025-03-19 20:39:01.560'),
(358, 199, 2, 'SENT', NULL, NULL),
(359, 200, 1, 'READ', '2025-03-19 20:54:34.245', '2025-03-19 20:54:34.245'),
(360, 200, 2, 'SENT', NULL, NULL),
(361, 201, 2, 'SENT', NULL, NULL),
(362, 201, 1, 'READ', '2025-03-19 20:54:54.593', '2025-03-19 20:54:54.593'),
(363, 202, 2, 'SENT', NULL, NULL),
(364, 202, 1, 'READ', '2025-03-19 20:56:09.223', '2025-03-19 20:56:09.223'),
(365, 203, 2, 'SENT', NULL, NULL),
(366, 203, 1, 'READ', '2025-03-19 20:56:11.102', '2025-03-19 20:56:11.102'),
(367, 204, 2, 'SENT', NULL, NULL),
(368, 204, 1, 'READ', '2025-03-19 20:56:13.200', '2025-03-19 20:56:13.200'),
(369, 205, 2, 'SENT', NULL, NULL),
(370, 205, 1, 'READ', '2025-03-19 20:56:17.131', '2025-03-19 20:56:17.131'),
(371, 206, 2, 'SENT', NULL, NULL),
(372, 206, 1, 'READ', '2025-03-19 20:56:18.946', '2025-03-19 20:56:18.946'),
(373, 207, 1, 'READ', '2025-03-19 20:58:45.547', '2025-03-19 20:58:45.547'),
(374, 207, 2, 'SENT', NULL, NULL),
(375, 208, 2, 'SENT', NULL, NULL),
(376, 208, 1, 'READ', '2025-03-19 21:03:19.537', '2025-03-19 21:03:19.537'),
(377, 209, 1, 'READ', '2025-03-19 21:46:05.845', '2025-03-19 21:46:05.845'),
(378, 209, 2, 'SENT', NULL, NULL),
(385, 212, 2, 'SENT', NULL, NULL),
(386, 212, 1, 'READ', '2025-03-19 22:10:49.961', '2025-03-19 22:10:49.961'),
(396, 216, 2, 'SENT', NULL, NULL),
(397, 216, 1, 'READ', '2025-03-20 07:48:46.883', '2025-03-20 07:48:46.883'),
(398, 217, 1, 'READ', '2025-03-20 07:49:02.073', '2025-03-20 07:49:02.073'),
(399, 217, 2, 'SENT', NULL, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Navbar`
--

CREATE TABLE `Navbar` (
  `id` int NOT NULL,
  `accentColor` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logoUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logoAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Navbar`
--

INSERT INTO `Navbar` (`id`, `accentColor`, `logoUrl`, `logoAlt`, `createdAt`, `updatedAt`) VALUES
(1, '#ffb500', '', 'KSR Cranes Logo', '2025-03-14 11:48:58.563', '2025-05-30 11:42:19.527');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `NotificationPushSettings`
--

CREATE TABLE `NotificationPushSettings` (
  `id` int UNSIGNED NOT NULL,
  `notification_type` varchar(50) NOT NULL,
  `target_role` enum('arbejder','byggeleder','chef','all') NOT NULL,
  `send_push` tinyint(1) DEFAULT '1',
  `push_priority` enum('URGENT','HIGH','NORMAL','LOW') DEFAULT 'NORMAL',
  `immediate_send` tinyint(1) DEFAULT '1',
  `quiet_hours_respected` tinyint(1) DEFAULT '1',
  `batch_allowed` tinyint(1) DEFAULT '0',
  `push_title_template` varchar(255) DEFAULT NULL,
  `push_message_template` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `NotificationPushSettings`
--

INSERT INTO `NotificationPushSettings` (`id`, `notification_type`, `target_role`, `send_push`, `push_priority`, `immediate_send`, `quiet_hours_respected`, `batch_allowed`, `push_title_template`, `push_message_template`, `created_at`, `updated_at`) VALUES
(1, 'HOURS_REJECTED', 'arbejder', 1, 'HIGH', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(2, 'EMERGENCY_ALERT', 'all', 1, 'URGENT', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(3, 'LICENSE_EXPIRED', 'arbejder', 1, 'HIGH', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(4, 'TASK_OVERDUE', 'arbejder', 1, 'HIGH', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(5, 'HOURS_APPROVED', 'arbejder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(6, 'HOURS_CONFIRMED', 'arbejder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(7, 'TASK_ASSIGNED', 'arbejder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(8, 'WORKPLAN_CREATED', 'arbejder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(9, 'PAYROLL_PROCESSED', 'arbejder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(10, 'HOURS_SUBMITTED', 'byggeleder', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(11, 'HOURS_CONFIRMED_FOR_PAYROLL', 'chef', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(12, 'TASK_COMPLETED', 'chef', 1, 'NORMAL', 1, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(13, 'LICENSE_EXPIRING', 'arbejder', 1, 'LOW', 0, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(14, 'HOURS_REMINDER', 'arbejder', 1, 'LOW', 0, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47'),
(15, 'GENERAL_ANNOUNCEMENT', 'all', 1, 'LOW', 0, 1, 0, NULL, NULL, '2025-05-26 10:52:47', '2025-05-26 10:52:47');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Notifications`
--

CREATE TABLE `Notifications` (
  `notification_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED DEFAULT NULL,
  `project_id` int UNSIGNED DEFAULT NULL,
  `task_id` int UNSIGNED DEFAULT NULL,
  `work_entry_id` int UNSIGNED DEFAULT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Notification title/subject',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `target_role` enum('arbejder','byggeleder','chef','system','all') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Who should receive this',
  `sender_id` int UNSIGNED DEFAULT NULL COMMENT 'Who created this notification',
  `target_employee_id` int UNSIGNED DEFAULT NULL COMMENT 'Specific employee target (optional)',
  `priority` enum('URGENT','HIGH','NORMAL','LOW') COLLATE utf8mb4_unicode_ci DEFAULT 'NORMAL',
  `category` enum('HOURS','PROJECT','TASK','WORKPLAN','LEAVE','PAYROLL','SYSTEM','EMERGENCY') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action_required` tinyint(1) DEFAULT '0' COMMENT 'Does user need to take action',
  `action_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Deep link to relevant screen',
  `expires_at` timestamp NULL DEFAULT NULL COMMENT 'When notification becomes irrelevant',
  `metadata` json DEFAULT NULL COMMENT 'Additional context data',
  `read_at` timestamp NULL DEFAULT NULL COMMENT 'When was it marked as read',
  `notification_type` enum('HOURS_SUBMITTED','HOURS_APPROVED','HOURS_CONFIRMED','HOURS_REJECTED','HOURS_CONFIRMED_FOR_PAYROLL','TIMESHEET_GENERATED','PAYROLL_PROCESSED','HOURS_REMINDER','HOURS_OVERDUE','PROJECT_CREATED','PROJECT_ASSIGNED','PROJECT_ACTIVATED','PROJECT_COMPLETED','PROJECT_CANCELLED','PROJECT_STATUS_CHANGED','PROJECT_DEADLINE_APPROACHING','TASK_CREATED','TASK_ASSIGNED','TASK_REASSIGNED','TASK_UNASSIGNED','TASK_COMPLETED','TASK_STATUS_CHANGED','TASK_DEADLINE_APPROACHING','TASK_OVERDUE','WORKPLAN_CREATED','WORKPLAN_UPDATED','WORKPLAN_ASSIGNED','WORKPLAN_CANCELLED','LEAVE_REQUEST_SUBMITTED','LEAVE_REQUEST_APPROVED','LEAVE_REQUEST_REJECTED','LEAVE_REQUEST_CANCELLED','LEAVE_BALANCE_UPDATED','LEAVE_REQUEST_REMINDER','LEAVE_STARTING','LEAVE_ENDING','EMPLOYEE_ACTIVATED','EMPLOYEE_DEACTIVATED','EMPLOYEE_ROLE_CHANGED','LICENSE_EXPIRING','LICENSE_EXPIRED','CERTIFICATION_REQUIRED','PAYROLL_READY','INVOICE_GENERATED','PAYMENT_RECEIVED','SYSTEM_MAINTENANCE','EMERGENCY_ALERT','GENERAL_ANNOUNCEMENT','GENERAL_INFO') COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Notifications`
--

INSERT INTO `Notifications` (`notification_id`, `employee_id`, `project_id`, `task_id`, `work_entry_id`, `message`, `is_read`, `created_at`, `title`, `updated_at`, `target_role`, `sender_id`, `target_employee_id`, `priority`, `category`, `action_required`, `action_url`, `expires_at`, `metadata`, `read_at`, `notification_type`) VALUES
(97, 1, 4, 14, NULL, 'Timer til godkendelse – \"Ny domicilbygning til Energinet\" / \"Tower crane operation \"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 0, '2025-05-26 15:25:14', NULL, '2025-05-26 15:25:14', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(98, 8, 4, 14, NULL, 'Timer til godkendelse – \"Ny domicilbygning til Energinet\" / \"Tower crane operation \"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 1, '2025-05-26 15:25:14', NULL, '2025-06-04 19:58:51', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(99, 2, NULL, 14, 192, 'Your work hours have been rejected. Reason: You finish at 6pm', 1, '2025-05-26 15:27:45', 'Hours rejected for Tower crane operation ', '2025-05-26 15:28:02', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(100, 2, NULL, 14, 192, 'Your work hours have been approved and processed.', 1, '2025-05-26 15:31:34', 'Hours approved for Tower crane operation ', '2025-05-26 15:31:44', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(101, 1, 4, 14, NULL, 'Timer til godkendelse – \"Ny domicilbygning til Energinet\" / \"Tower crane operation \"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 0, '2025-05-26 16:06:56', NULL, '2025-05-26 16:06:56', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(102, 8, 4, 14, NULL, 'Timer til godkendelse – \"Ny domicilbygning til Energinet\" / \"Tower crane operation \"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 1, '2025-05-26 16:06:56', NULL, '2025-06-04 19:58:56', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(103, 2, NULL, 12, 191, 'Your work hours have been rejected. Reason: I dont know ', 1, '2025-05-26 19:45:40', 'Hours rejected for KRAN 1', '2025-05-26 19:47:00', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(104, 2, NULL, 14, 193, 'Your work hours have been rejected. Reason: Wrong ', 1, '2025-05-26 19:45:54', 'Hours rejected for Tower crane operation ', '2025-05-26 19:47:00', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(105, 2, NULL, 12, 190, 'Your work hours have been approved and processed.', 1, '2025-05-27 10:40:56', 'Hours approved for KRAN 1', '2025-05-27 11:34:12', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(106, 2, NULL, 12, 188, 'Your work hours have been approved and processed.', 0, '2025-05-27 10:40:56', 'Hours approved for KRAN 1', '2025-05-27 10:40:56', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(107, 2, NULL, 12, 187, 'Your work hours have been approved and processed.', 0, '2025-05-27 10:40:56', 'Hours approved for KRAN 1', '2025-05-27 10:40:56', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(108, 2, NULL, 12, 189, 'Your work hours have been approved and processed.', 0, '2025-05-27 10:40:56', 'Hours approved for KRAN 1', '2025-05-27 10:40:56', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(109, 2, NULL, 12, 191, 'Your work hours have been approved and processed.', 0, '2025-05-27 10:40:56', 'Hours approved for KRAN 1', '2025-05-27 10:40:56', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(110, 2, NULL, 13, 184, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:33:11', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(111, 2, NULL, 13, 182, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:34:05', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(112, 2, NULL, 13, 181, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:34:08', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(113, 2, NULL, 13, 185, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:34:09', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(114, 2, NULL, 13, 183, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:34:10', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(115, 2, NULL, 13, 186, 'Your work hours have been rejected. Reason: Too many hours\n\n\nProblematic days marked: Monday, May 12', 1, '2025-05-27 11:29:20', 'Hours rejected for KRAN 2', '2025-05-27 11:34:11', NULL, NULL, NULL, 'HIGH', 'HOURS', 1, NULL, NULL, 'null', NULL, 'HOURS_REJECTED'),
(116, 2, NULL, 14, 193, 'Your work hours have been approved and processed.', 0, '2025-05-28 05:55:43', 'Hours approved for Tower crane operation ', '2025-05-28 05:55:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(117, 2, NULL, 13, 184, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(118, 2, NULL, 13, 182, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(119, 2, NULL, 13, 181, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(120, 2, NULL, 13, 185, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(121, 2, NULL, 13, 183, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(122, 2, NULL, 13, 186, 'Your work hours have been approved and processed.', 0, '2025-05-29 15:13:43', 'Hours approved for KRAN 2', '2025-05-29 15:13:43', NULL, NULL, NULL, 'NORMAL', 'HOURS', 0, NULL, NULL, 'null', NULL, 'HOURS_CONFIRMED'),
(123, 1, 3, 13, NULL, 'Timer til godkendelse – \"Højhuset \" / \"KRAN 2\"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 0, '2025-05-30 17:40:55', NULL, '2025-05-30 17:40:55', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(124, 8, 3, 13, NULL, 'Timer til godkendelse – \"Højhuset \" / \"KRAN 2\"\n        Uge 22, start: 2025-05-26\n        Maksymilian Marcinowski har indsendt timer.\n        \n        Disse timer udgør grundlaget for fakturering, så kontrollér dem venligst omhyggeligt.', 1, '2025-05-30 17:40:55', NULL, '2025-06-04 19:58:55', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'HOURS_SUBMITTED'),
(125, 2, 9, 16, NULL, 'Du er blevet tildelt en ny opgave: Test 9000', 0, '2025-06-01 19:13:33', NULL, '2025-06-01 19:13:33', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(126, 7, 9, 16, NULL, 'Du er blevet tildelt en ny opgave: Test 9000', 0, '2025-06-02 05:45:58', NULL, '2025-06-02 05:45:58', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(127, 7, NULL, 16, NULL, 'Du er ikke længere tildelt opgaven: Test 9000', 0, '2025-06-02 06:20:17', NULL, '2025-06-02 06:20:17', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_UNASSIGNED'),
(128, 2, 9, 17, NULL, 'Du er blevet tildelt en ny opgave: Crane Test', 0, '2025-06-02 11:38:24', NULL, '2025-06-02 11:38:24', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(129, 2, NULL, 17, NULL, 'Opgave \"Crane Test\" er blevet afsluttet', 0, '2025-06-02 11:39:57', NULL, '2025-06-02 11:39:57', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_COMPLETED'),
(130, 2, 9, 19, NULL, 'Du er blevet tildelt en ny opgave: Test Crane', 0, '2025-06-02 16:28:44', NULL, '2025-06-02 16:28:44', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(131, 2, 9, 21, NULL, 'Du er blevet tildelt en ny opgave: Task cream', 0, '2025-06-03 09:39:30', NULL, '2025-06-03 09:39:30', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(132, 2, 9, 20, NULL, 'Du er blevet tildelt en ny opgave: Test 1500', 0, '2025-06-03 09:39:47', NULL, '2025-06-03 09:39:47', NULL, NULL, NULL, 'NORMAL', 'SYSTEM', 0, NULL, NULL, NULL, NULL, 'TASK_ASSIGNED'),
(133, 2, NULL, NULL, NULL, 'Your vacation leave request has been rejected. Reason: A', 0, '2025-06-05 23:22:25', 'Leave request rejected', '2025-06-05 23:22:25', NULL, 8, 2, 'HIGH', 'SYSTEM', 1, NULL, NULL, '\"{\\\"leave_type\\\":\\\"VACATION\\\",\\\"start_date\\\":\\\"2025-07-16T00:00:00.000Z\\\",\\\"end_date\\\":\\\"2025-07-31T00:00:00.000Z\\\",\\\"action\\\":\\\"reject\\\",\\\"approver_name\\\":\\\"Admin\\\",\\\"rejection_reason\\\":\\\"A\\\"}\"', NULL, 'LEAVE_REQUEST_REJECTED');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `OperatorHiringRequest`
--

CREATE TABLE `OperatorHiringRequest` (
  `id` int UNSIGNED NOT NULL,
  `fullName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `companyName` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cvrNumber` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CVR number of the requesting company',
  `customer_id` int UNSIGNED DEFAULT NULL,
  `projectName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `projectLocation` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `projectDescription` text COLLATE utf8mb4_unicode_ci,
  `specialRequirements` text COLLATE utf8mb4_unicode_ci,
  `serviceType` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `craneType` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `startDate` date NOT NULL,
  `estimatedEndDate` date DEFAULT NULL,
  `duration` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `additionalTimeInfo` text COLLATE utf8mb4_unicode_ci,
  `status` enum('PENDING','REVIEWING','APPROVED','SCHEDULED','REJECTED','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `statusNotes` text COLLATE utf8mb4_unicode_ci,
  `assignedOperatorId` int UNSIGNED DEFAULT NULL,
  `assignedProjectId` int UNSIGNED DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` timestamp NOT NULL,
  `assignedTaskId` int UNSIGNED DEFAULT NULL,
  `craneHeight` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `accommodationType` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Typ zakwaterowania (provided, none, discuss)',
  `accommodationDetails` text COLLATE utf8mb4_unicode_ci COMMENT 'Szczegóły zakwaterowania, gdy provided',
  `additionalSkills` text COLLATE utf8mb4_unicode_ci COMMENT 'Additional skills or requirements for the operator, added based on form data',
  `includeHooker` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Whether a hooker/rigger is included in the request',
  `hookerQuantity` int UNSIGNED DEFAULT NULL COMMENT 'Quantity of hookers requested, if includeHooker is true',
  `experienceLevel` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Poziom doświadczenia operatora (trainee, junior, experienced, senior, expert)',
  `hoursPerDay` int UNSIGNED DEFAULT '8',
  `daysPerWeek` int UNSIGNED DEFAULT '5',
  `selectedCraneCategoryName` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the selected crane category',
  `selectedCraneTypeName` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the selected crane type',
  `selectedCraneBrandName` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of the selected crane brand',
  `selectedCraneModelNames` text COLLATE utf8mb4_unicode_ci COMMENT 'Name(s) of the selected crane model(s)',
  `craneCategoryId` int UNSIGNED DEFAULT NULL COMMENT 'Potential FK to CraneCategory ID',
  `craneTypeId` int UNSIGNED DEFAULT NULL COMMENT 'Potential FK to CraneType ID',
  `craneBrandId` int UNSIGNED DEFAULT NULL COMMENT 'Potential FK to CraneBrand ID',
  `operatorDuties` text COLLATE utf8mb4_unicode_ci,
  `projectContext` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `OperatorHiringRequest`
--

INSERT INTO `OperatorHiringRequest` (`id`, `fullName`, `companyName`, `email`, `phone`, `cvrNumber`, `customer_id`, `projectName`, `projectLocation`, `projectDescription`, `specialRequirements`, `serviceType`, `craneType`, `startDate`, `estimatedEndDate`, `duration`, `additionalTimeInfo`, `status`, `statusNotes`, `assignedOperatorId`, `assignedProjectId`, `createdAt`, `updatedAt`, `assignedTaskId`, `craneHeight`, `accommodationType`, `accommodationDetails`, `additionalSkills`, `includeHooker`, `hookerQuantity`, `experienceLevel`, `hoursPerDay`, `daysPerWeek`, `selectedCraneCategoryName`, `selectedCraneTypeName`, `selectedCraneBrandName`, `selectedCraneModelNames`, `craneCategoryId`, `craneTypeId`, `craneBrandId`, `operatorDuties`, `projectContext`) VALUES
(17, 'Anders Møller Jensen', 'Dansk Konstruktion & Byg ApS', 'anders.jensen@dkbyg.dk', '45 87 23 16', NULL, NULL, 'Nordre Havn Boligtårn', 'Havnevej 24, 8000 Aarhus C', 'Opførelse af 15-etagers boligtårn med 120 lejligheder ved havnefronten. Projektet omfatter etablering af fundament, opførelse af betonkonstruktion, facademontage og tagkonstruktion. Kranen skal primært anvendes til løft af betonelementer, armeringsjern, byggeelementer samt leverancer af materialer til de øvre etager.', 'Kranføreren skal have erfaring med vindudfordringer ved havnefront. Certificering til tunge løft er påkrævet, og kendskab til Liebherr 245 EC-H Litronic er en fordel. På grund af projektets profil skal kranføreren være villig til at deltage i PR-arrangementer ved milepæle i byggeriet. Arbejde i højder op til 75m skal accepteres.\n\nCrane Specifications:\nRequired Experience Level: Senior (7+ års erfaring)\nTower Crane Height: 45 meters\nOperator Language Requirements: Engelsk, Dansk\nAccommodation: Vi sørger for indkvartering\nAccommodation Details: Indkvartering tilbydes i møbleret 2-værelses lejlighed i central Aarhus, ca. 3 km fra byggepladsen. Lejligheden deles med en anden kranfører (separate soveværelser). Transport mellem indkvartering og byggeplads arrangeres via firmabil. Internetadgang, vask og rengøring er inkluderet.\nCategory:  Tårnkran\nType: Top-slewing\nBrand: Liebherr\nSpecific Models:\n- Liebherr 550 EC-H 40 LITRONIC (Max Load: 40t)\n', 'weekly', 'tower-crane', '2025-03-28', NULL, '1-month', 'Vi har brug for operatøren primært i hverdage fra 7:00 til 15:30, men der kan forekomme enkelte weekendvagter med varsel på minimum 48 timer. Fleksibilitet omkring start- og sluttidspunkt vil være en fordel.', 'CANCELLED', '', NULL, NULL, '2025-03-28 08:52:01', '2025-05-03 06:02:21', NULL, '45', 'provided', 'Indkvartering tilbydes i møbleret 2-værelses lejlighed i central Aarhus, ca. 3 km fra byggepladsen. Lejligheden deles med en anden kranfører (separate soveværelser). Transport mellem indkvartering og byggeplads arrangeres via firmabil. Internetadgang, vask og rengøring er inkluderet.', NULL, 0, NULL, 'senior', 8, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(52, 'Maksymilian Marcinowski', 'Dansk Konstruktion & Byg ApS', 'majkemanizer@gmail.com', '52796019', '39095939', NULL, 'Nordre Havn Boligtårn', 'Havnevej 24, 8000 Aarhus C', 'ok', 'ok', 'weekly', 'tower-crane', '2025-05-06', NULL, '1-week', NULL, 'PENDING', NULL, NULL, NULL, '2025-05-06 09:12:45', '2025-05-06 09:12:45', NULL, '45', 'none', NULL, NULL, 0, NULL, 'experienced', 8, 5, NULL, NULL, NULL, '', NULL, NULL, NULL, 'ok', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `OperatorHiringRequestModel`
--

CREATE TABLE `OperatorHiringRequestModel` (
  `id` int UNSIGNED NOT NULL,
  `requestId` int UNSIGNED NOT NULL,
  `modelId` int UNSIGNED NOT NULL,
  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `OperatorLanguageRequirement`
--

CREATE TABLE `OperatorLanguageRequirement` (
  `id` int UNSIGNED NOT NULL,
  `requestId` int UNSIGNED NOT NULL,
  `language` enum('DANISH','ENGLISH','POLISH','GERMAN') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `OperatorLanguageRequirement`
--

INSERT INTO `OperatorLanguageRequirement` (`id`, `requestId`, `language`) VALUES
(2, 17, 'ENGLISH'),
(3, 17, 'DANISH'),
(78, 52, 'DANISH');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `OperatorPerformanceReviews`
--

CREATE TABLE `OperatorPerformanceReviews` (
  `review_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `project_id` int UNSIGNED NOT NULL,
  `review_date` date NOT NULL,
  `efficiency_score` int DEFAULT NULL,
  `safety_compliance` tinyint(1) DEFAULT '1',
  `client_feedback` text,
  `areas_for_improvement` text,
  `commendations` text,
  `reviewed_by` int UNSIGNED NOT NULL
) ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `OperatorQuote`
--

CREATE TABLE `OperatorQuote` (
  `id` int UNSIGNED NOT NULL,
  `quoteNumber` varchar(50) NOT NULL,
  `hiringRequestId` int UNSIGNED NOT NULL,
  `pdfUrl` varchar(1024) DEFAULT NULL,
  `issueDate` date NOT NULL,
  `validUntil` date NOT NULL,
  `hourlyRate` decimal(10,2) NOT NULL DEFAULT '0.00',
  `dailyRate` decimal(10,2) NOT NULL,
  `totalAmount` decimal(10,2) NOT NULL,
  `status` enum('PENDING','SENT','ACCEPTED','REJECTED','EXPIRED') NOT NULL DEFAULT 'PENDING',
  `additionalNotes` text,
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `emailSentAt` timestamp NULL DEFAULT NULL,
  `acceptedAt` timestamp NULL DEFAULT NULL,
  `rejectedAt` timestamp NULL DEFAULT NULL,
  `paymentTermsDays` int NOT NULL DEFAULT '30',
  `lineItems` json DEFAULT NULL,
  `transportCost` decimal(10,2) DEFAULT NULL,
  `advancePaymentDiscount` decimal(5,2) DEFAULT NULL,
  `offerInstallments` tinyint(1) DEFAULT '0',
  `installmentCount` int DEFAULT NULL,
  `initialPaymentPercentage` decimal(5,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `OperatorQuote`
--

INSERT INTO `OperatorQuote` (`id`, `quoteNumber`, `hiringRequestId`, `pdfUrl`, `issueDate`, `validUntil`, `hourlyRate`, `dailyRate`, `totalAmount`, `status`, `additionalNotes`, `createdAt`, `updatedAt`, `emailSentAt`, `acceptedAt`, `rejectedAt`, `paymentTermsDays`, `lineItems`, `transportCost`, `advancePaymentDiscount`, `offerInstallments`, `installmentCount`, `initialPaymentPercentage`) VALUES
(4, 'KSR-250329-2336', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-250329-2336.html', '2025-03-29', '2025-04-28', 560.00, 4480.00, 165350.00, 'PENDING', NULL, '2025-03-29 14:14:02', '2025-03-29 14:14:02', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(5, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 19:41:46', '2025-03-29 19:41:46', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(6, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 19:46:52', '2025-03-29 19:46:52', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(7, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 19:49:12', '2025-03-29 19:49:12', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(8, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 19:52:15', '2025-03-29 19:52:15', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(9, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 20:26:00', '2025-03-29 20:26:00', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(10, 'KSR-2025-1861', 17, '/api/quotes/KSR-2025-1861', '2025-03-29', '2025-04-28', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-29 20:28:48', '2025-03-29 20:28:48', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(11, 'KSR-2025-3030', 17, '/api/quotes/KSR-2025-3030', '2025-03-30', '2025-04-29', 450.00, 3600.00, 135726.25, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 08:05:06', '2025-03-30 08:05:06', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(12, 'KSR-2025-3030', 17, '/api/quotes/KSR-2025-3030', '2025-03-30', '2025-04-29', 450.00, 3600.00, 135726.25, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 08:05:06', '2025-03-30 08:05:06', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(13, 'KSR-2025-1867', 17, '/api/quotes/KSR-2025-1867', '2025-03-30', '2025-04-29', 450.00, 3600.00, 136190.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 08:08:35', '2025-03-30 08:08:35', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(14, 'KSR-2025-1867', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-1867.html', '2025-03-30', '2025-04-29', 450.00, 3600.00, 136190.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 08:17:26', '2025-03-30 08:17:26', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(15, 'KSR-2025-1867', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-1867.html', '2025-03-30', '2025-04-29', 420.00, 3360.00, 1085.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 09:12:01', '2025-03-30 09:12:01', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(16, 'KSR-2025-1867', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-1867.html', '2025-03-30', '2025-04-29', 420.00, 3360.00, 0.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 09:12:20', '2025-03-30 09:12:20', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(17, 'KSR-2025-1867', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-1867.html', '2025-03-30', '2025-04-29', 420.00, 3360.00, 126000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 09:13:00', '2025-03-30 09:13:00', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(18, 'KSR-2025-1867', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-1867.html', '2025-03-30', '2025-04-29', 420.00, 3360.00, 126000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 09:14:36', '2025-03-30 09:14:36', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(19, 'KSR-2025-0757', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-0757.html', '2025-03-30', '2025-04-29', 450.00, 3600.00, 135000.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 675 kr. per time.\nWeekend- og helligdagstillæg: 675 kr. per time.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.', '2025-03-30 10:05:07', '2025-03-30 10:05:07', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(20, 'KSR-2025-5014', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-5014.html', '2025-03-31', '2025-04-30', 450.00, 3600.00, 94500.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 600 kr. per time.\nTillæg for arbejde før kl. 07:00 og efter kl. 18:00: 575 kr. per time.\nWeekend- og helligdagstimesats: 675 kr. per time.\n\nI henhold til aftalen pkt. 4.3 - Ved sammenfald af overtidstillæg og tillæg for arbejde før kl. 07:00 eller efter kl. 18:00 sammenlægges disse tillæg og tillægges den relevante grundtimesats.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.\n\nI henhold til aftalen pkt. 4.1 - Ved parternes aftale om udførelse af arbejdsopgaver faktureres virksomheden for minimum 6 timer pr. arbejdsdag på trods af, at arbejdet kan udføres på kortere tid.', '2025-03-31 20:29:51', '2025-03-31 20:29:51', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(21, 'KSR-2025-0526', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-0526.html', '2025-03-31', '2025-04-30', 450.00, 3600.00, 94500.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 600 kr. per time.\nTillæg for arbejde før kl. 07:00 og efter kl. 18:00: 575 kr. per time.\nWeekend- og helligdagstimesats: 675 kr. per time.\n\nI henhold til aftalen pkt. 4.3 - Ved sammenfald af overtidstillæg og tillæg for arbejde før kl. 07:00 eller efter kl. 18:00 sammenlægges disse tillæg og tillægges den relevante grundtimesats.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.\n\nI henhold til aftalen pkt. 4.1 - Ved parternes aftale om udførelse af arbejdsopgaver faktureres virksomheden for minimum 6 timer pr. arbejdsdag på trods af, at arbejdet kan udføres på kortere tid.', '2025-03-31 20:30:42', '2025-03-31 20:30:42', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(22, 'KSR-2025-7277', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-7277.html', '2025-03-31', '2025-04-30', 450.00, 3600.00, 94500.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 600 kr. per time.\nTillæg for arbejde før kl. 07:00 og efter kl. 18:00: 575 kr. per time.\nWeekend- og helligdagstimesats: 675 kr. per time.\n\nI henhold til aftalen pkt. 4.3 - Ved sammenfald af overtidstillæg og tillæg for arbejde før kl. 07:00 eller efter kl. 18:00 sammenlægges disse tillæg og tillægges den relevante grundtimesats.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.\n\nI henhold til aftalen pkt. 4.1 - Ved parternes aftale om udførelse af arbejdsopgaver faktureres virksomheden for minimum 6 timer pr. arbejdsdag på trods af, at arbejdet kan udføres på kortere tid.', '2025-03-31 20:34:52', '2025-03-31 20:34:52', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(23, 'KSR-2025-5984', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-5984.html', '2025-03-31', '2025-04-30', 450.00, 3600.00, 94500.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 600 kr. per time.\nTillæg for arbejde før kl. 07:00 og efter kl. 18:00: 575 kr. per time.\nWeekend- og helligdagstimesats: 675 kr. per time.\n\nI henhold til aftalen pkt. 4.3 - Ved sammenfald af overtidstillæg og tillæg for arbejde før kl. 07:00 eller efter kl. 18:00 sammenlægges disse tillæg og tillægges den relevante grundtimesats.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.\n\nI henhold til aftalen pkt. 4.1 - Ved parternes aftale om udførelse af arbejdsopgaver faktureres virksomheden for minimum 6 timer pr. arbejdsdag på trods af, at arbejdet kan udføres på kortere tid.', '2025-03-31 20:51:30', '2025-03-31 20:51:30', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL),
(24, 'KSR-2025-7958', 17, 'https://ksr-media.fra1.digitaloceanspaces.com/quotes/KSR-2025-7958.html', '2025-04-05', '2025-05-05', 450.00, 3600.00, 94500.00, 'PENDING', 'Tilbuddet inkluderer operatør med senior erfaring. Operatøren taler engelsk og dansk. \n\nStandardpris: 450 kr. per time.\nOvertidbetaling efter 8 timer: 600 kr. per time.\nTillæg for arbejde før kl. 07:00 og efter kl. 18:00: 575 kr. per time.\nWeekend- og helligdagstimesats: 675 kr. per time.\n\nI henhold til aftalen pkt. 4.3 - Ved sammenfald af overtidstillæg og tillæg for arbejde før kl. 07:00 eller efter kl. 18:00 sammenlægges disse tillæg og tillægges den relevante grundtimesats.\n\nBetalingsbetingelser: Netto 30 dage.\n\nProjektsted: Havnevej 24, 8000 Aarhus C\nTilbuddet er baseret på den specificerede tower-crane som beskrevet i forespørgslen.\n\nI henhold til aftalen pkt. 4.1 - Ved parternes aftale om udførelse af arbejdsopgaver faktureres virksomheden for minimum 6 timer pr. arbejdsdag på trods af, at arbejdet kan udføres på kortere tid.', '2025-04-05 13:05:27', '2025-04-05 13:05:27', NULL, NULL, NULL, 30, NULL, NULL, NULL, 0, NULL, NULL);

--
-- Wyzwalacze `OperatorQuote`
--
DELIMITER $$
CREATE TRIGGER `update_operator_quote_timestamp` BEFORE UPDATE ON `OperatorQuote` FOR EACH ROW BEGIN
  SET NEW.updatedAt = NOW();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Page`
--

CREATE TABLE `Page` (
  `id` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PageVisit`
--

CREATE TABLE `PageVisit` (
  `id` int NOT NULL,
  `path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'The page URL path that was visited',
  `ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Visitor IP address (nullable, supports IPv6)',
  `userAgent` text COLLATE utf8mb4_unicode_ci COMMENT 'Browser user agent string',
  `referer` text COLLATE utf8mb4_unicode_ci COMMENT 'The referring URL where the visitor came from',
  `timestamp` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'When the visit occurred',
  `country` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Kraj odwiedzającego (z GeoIP)',
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Miasto odwiedzającego (z GeoIP)',
  `region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Region/Województwo odwiedzającego (z GeoIP)',
  `deviceType` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Typ urządzenia (np. mobile, desktop, tablet)',
  `os` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'System operacyjny (np. Windows 10, iOS 17.4)',
  `browser` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Przeglądarka (np. Chrome 124, Safari 17.4)',
  `refererDomain` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Domena źródłowa (np. google.com)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks website page visits for analytics';

--
-- Zrzut danych tabeli `PageVisit`
--

INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1, '/', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/lej-en-kranforer', '2025-05-02 18:16:34', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(2, '/', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-02 18:30:17', 'Unknown', 'Unknown', 'Unknown', 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(3, '/', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-02 18:33:36', 'Unknown', 'Unknown', 'Unknown', 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(4, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-02 18:36:26', 'Unknown', 'Unknown', 'Unknown', 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(5, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-02 18:58:53', NULL, NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(6, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-02 18:59:57', NULL, NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(7, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:20:11', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(8, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:20:17', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(9, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:27:56', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(10, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:27:57', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(11, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:28:19', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(12, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-02 19:28:22', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(13, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:33:02', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(14, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:34:34', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(15, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 19:34:41', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(16, '/vilkar-og-betingelser', '49.13.142.129', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-02 20:08:59', NULL, NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 124.0.0.0', 'ksrcranes.dk'),
(17, '/privacy-policy', '162.55.174.161', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/privacy-policy', '2025-05-02 20:12:36', NULL, NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(18, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-02 20:31:05', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(19, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.597', 'https://www.linkedin.com/', '2025-05-02 20:31:30', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(20, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.597', 'https://www.linkedin.com/', '2025-05-02 20:31:54', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(21, '/auth/signin', '157.90.253.188', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-02 22:12:15', NULL, NULL, NULL, 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(22, '/', '66.249.75.172', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-03 03:31:01', NULL, NULL, NULL, 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(23, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:41:52', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(24, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:41:57', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(25, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:42:40', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(26, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:46:45', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(27, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.597', 'https://www.linkedin.com/', '2025-05-03 04:51:01', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(28, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.597', 'https://ksrcranes.dk/', '2025-05-03 04:51:05', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'LinkedIn', 'ksrcranes.dk'),
(29, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.597', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 04:51:41', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'LinkedIn', 'ksrcranes.dk'),
(30, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:52:15', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(31, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 04:54:24', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(32, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:01:26', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(33, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:01:31', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(34, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:03:14', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(35, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:05:18', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(36, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:07:29', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(37, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:09:27', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(38, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:10:51', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(39, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:11:07', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(40, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:12:07', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(41, '/auth/signin', '66.249.75.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin', '2025-05-03 05:25:19', NULL, NULL, NULL, 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(42, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:27:34', NULL, NULL, NULL, 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(43, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:48:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(44, '/lej-en-kranforer', '37.96.119.177', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:49:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(45, '/auth/signin', '37.96.119.177', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 05:49:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(46, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 05:55:34', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(47, '/', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/erfaring/carlsberg-district-copenhagen', '2025-05-03 06:08:16', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(48, '/lej-en-kranforer', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 06:08:20', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(49, '/', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 06:08:30', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(50, '/auth/signin', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 06:08:35', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(51, '/', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 06:09:13', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(52, '/', '194.233.101.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 06:24:33', 'PL', 'Warsaw', 'Mazovia', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(53, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 07:41:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(54, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 07:41:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(55, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 07:42:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(56, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 07:43:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(57, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/135.0.7049.83 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 07:43:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 135.0.7049.83', 'ksrcranes.dk'),
(58, '/', '66.249.77.140', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-03 08:25:07', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(59, '/vilkar-og-betingelser', '66.249.77.136', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-03 08:43:09', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(60, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 08:44:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(61, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 08:46:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(62, '/da', '66.249.77.140', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-03 09:25:06', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(63, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 09:28:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(64, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 09:37:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(65, '/lej-en-kranforer', '66.249.77.140', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 10:25:04', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(66, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:32:20', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(67, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:32:27', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(68, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:34:21', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(69, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:36:59', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(70, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:40:04', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(71, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:41:12', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(72, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:41:58', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(73, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:44:41', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(74, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 10:45:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(75, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 10:45:18', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(76, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:46:17', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(77, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:51:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(78, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 10:51:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(79, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 13:52:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(80, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 13:52:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(81, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:04:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(82, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:04:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(83, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:07:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(84, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:07:06', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(85, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:16:57', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(86, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:16:58', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(87, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:17:05', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(88, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:17:33', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(89, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:17:34', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(90, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/erfaring', '2025-05-03 14:18:15', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(91, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/erfaring', '2025-05-03 14:18:15', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(92, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'http://localhost:3000/', '2025-05-03 14:19:32', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'localhost'),
(93, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'http://localhost:3000/', '2025-05-03 14:19:33', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'localhost'),
(94, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:22:38', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(95, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:22:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(96, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-03 14:23:57', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(97, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-03 14:23:58', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(98, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:25:41', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(99, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 14:25:42', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(100, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:12:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(101, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:13:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(102, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:22:11', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(103, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:22:12', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(104, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'http://localhost:3000/', '2025-05-03 15:23:16', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'localhost'),
(105, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'http://localhost:3000/', '2025-05-03 15:23:20', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'localhost'),
(106, '/lej-en-kranforer', '80.62.117.5', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 15:24:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(107, '/', '80.62.117.5', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 15:24:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(108, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:28:02', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(109, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:28:04', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(110, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-03 15:28:43', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(111, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-03 15:31:06', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(112, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-03 15:31:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(113, '/', '80.62.117.5', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 15:32:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(114, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:34:10', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(115, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:34:13', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(116, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:36:13', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(117, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:36:14', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(118, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:37:10', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(119, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:37:11', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(120, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:37:27', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(121, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:37:29', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(122, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:38:28', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(123, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:38:30', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(124, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:43:23', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(125, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:43:24', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(126, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:43:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(127, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:43:56', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(128, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:44:15', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(129, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 15:44:16', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(130, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:56:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(131, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:56:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(132, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(133, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(134, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(135, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(136, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(137, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 15:57:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(138, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:58:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(139, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 15:58:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(140, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.hemigroup.dk/', '2025-05-03 15:59:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'hemigroup.dk'),
(141, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.hemigroup.dk/', '2025-05-03 15:59:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'hemigroup.dk'),
(142, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:00:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(143, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:00:02', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(144, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 16:00:38', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(145, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 16:00:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(146, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(147, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(148, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://tv2.dk/', '2025-05-03 16:04:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'tv2.dk'),
(149, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://tv2.dk/', '2025-05-03 16:04:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'tv2.dk'),
(150, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(151, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(152, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(153, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:04:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(154, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 16:09:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(155, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-03 16:09:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(156, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:21:30', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 132.0.0.0', 'ksrcranes.dk'),
(157, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:21:31', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 132.0.0.0', 'ksrcranes.dk'),
(158, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:00', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 132.0.0.0', 'ksrcranes.dk'),
(159, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:03', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(160, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:04', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(161, '/lej-en-kranforer', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 16:22:46', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(162, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:46', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(163, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:46', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(164, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:49', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(165, '/lej-en-kranforer', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 16:22:49', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(166, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:22:49', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(167, '/lej-en-kranforer', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 16:23:25', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(168, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:23:25', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(169, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:23:26', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(170, '/lej-en-kranforer', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-03 16:23:26', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(171, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:23:26', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(172, '/', '135.232.20.17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 16:23:28', 'US', 'Boydton', 'Virginia', 'desktop', 'Windows 10', 'Chrome 133.0.0.0', 'ksrcranes.dk'),
(173, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 16:24:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(174, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 16:24:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(175, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:25:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(176, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:25:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(177, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:25:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(178, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:25:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(179, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 16:26:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(180, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 16:26:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(181, '/auth/signin', '66.249.77.141', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin', '2025-05-03 16:31:30', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(182, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:44:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(183, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:44:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(184, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:44:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(185, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:44:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(186, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:45:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(187, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 16:45:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(188, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-03 16:56:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(189, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-03 16:56:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(190, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-03 16:56:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(191, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-03 16:56:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(192, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 17:00:56', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(193, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-03 17:00:56', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(194, '/', '66.249.81.167', 'Mozilla/5.0 (Linux; Android 7.0; Moto G (4)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4590.2 Mobile Safari/537.36 Chrome-Lighthouse', 'https://ksrcranes.dk/', '2025-05-03 17:02:21', 'NL', 'Delfzijl', 'Groningen', 'mobile', 'Android 7.0', 'Mobile Chrome 94.0.4590.2', 'ksrcranes.dk'),
(195, '/', '66.249.81.162', 'Mozilla/5.0 (Linux; Android 7.0; Moto G (4)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4590.2 Mobile Safari/537.36 Chrome-Lighthouse', 'https://ksrcranes.dk/', '2025-05-03 17:02:21', 'NL', 'Delfzijl', 'Groningen', 'mobile', 'Android 7.0', 'Mobile Chrome 94.0.4590.2', 'ksrcranes.dk'),
(196, '/', '66.249.93.11', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4590.2 Safari/537.36 Chrome-Lighthouse', 'https://ksrcranes.dk/', '2025-05-03 17:02:22', 'BE', 'Antwerpen', 'Flanders', 'desktop', 'macOS 10.15.7', 'Chrome 94.0.4590.2', 'ksrcranes.dk'),
(197, '/', '66.249.93.10', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4590.2 Safari/537.36 Chrome-Lighthouse', 'https://ksrcranes.dk/', '2025-05-03 17:02:22', 'BE', 'Antwerpen', 'Flanders', 'desktop', 'macOS 10.15.7', 'Chrome 94.0.4590.2', 'ksrcranes.dk'),
(198, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 17:19:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(199, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-03 17:19:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(200, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:52:15', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(201, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:52:17', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(202, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:56:26', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(203, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:56:32', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(204, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:56:33', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(205, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:56:51', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(206, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:58:14', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(207, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:58:15', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(208, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:58:48', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(209, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:58:49', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(210, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:59:14', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(211, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:59:15', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(212, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:59:56', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(213, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:59:57', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(214, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 17:59:59', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(215, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:00:26', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(216, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:01:42', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(217, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:01:43', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(218, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:06:40', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(219, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:06:41', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(220, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:06:57', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(221, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:06:58', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(222, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:06:59', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(223, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:07:42', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(224, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:07:43', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(225, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/', '2025-05-03 18:08:11', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(226, '/', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-03 18:09:08', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(227, '/', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/', '2025-05-03 18:09:09', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(228, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:36:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(229, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:36:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(230, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:37:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(231, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:37:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(232, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(233, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(234, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(235, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(236, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(237, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:38:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(238, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:41:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(239, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 19:41:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(240, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-03 19:41:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(241, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-03 19:41:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(242, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/worker/dashboard', '2025-05-03 19:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(243, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/worker/dashboard', '2025-05-03 19:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(244, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-03 19:46:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(245, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-03 19:46:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(246, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:26:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(247, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:26:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(248, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:26:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(249, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:26:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(250, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:49:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(251, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:49:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(252, '/cookie-politik', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:49:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(253, '/cookie-politik', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:49:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(254, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:50:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(255, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:50:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(256, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:50:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(257, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-03 20:50:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(258, '/', '66.249.75.165', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-03 21:20:01', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(259, '/', '66.249.75.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-03 21:20:06', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(260, '/cookie-politik', '66.249.75.172', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/cookie-politik', '2025-05-03 22:25:09', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(261, '/', '87.49.146.130', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 05:05:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(262, '/', '87.49.146.130', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 05:05:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(263, '/', '87.49.146.130', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 05:06:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(264, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 05:56:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(265, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 05:56:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(266, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:10:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(267, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:10:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(268, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:10:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(269, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:10:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(270, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 06:48:13', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(271, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.802', 'https://www.linkedin.com/', '2025-05-04 06:48:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'LinkedIn', 'linkedin.com'),
(272, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:58:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(273, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:58:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(274, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-04 06:58:49', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(275, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-04 06:58:49', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(276, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:59:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(277, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 06:59:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(278, '/', '2a05:f6c6:9424:0:4d77:ee55:61f:381d', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/504.0.0.44.109;FBBV/724525727;FBDV/iPhone13,3;FBMD/iPhone;FBSN/iOS;FBSV/18.1.1;FBSS/3;FBCR/;FBID/phone;FBLC/da_DK;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:00:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.1.1', 'Facebook 504.0.0.44.109', 'ksrcranes.dk'),
(279, '/', '2a05:f6c6:9424:0:4d77:ee55:61f:381d', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/504.0.0.44.109;FBBV/724525727;FBDV/iPhone13,3;FBMD/iPhone;FBSN/iOS;FBSV/18.1.1;FBSS/3;FBCR/;FBID/phone;FBLC/da_DK;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:00:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.1.1', 'Facebook 504.0.0.44.109', 'ksrcranes.dk'),
(280, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:04:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(281, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:04:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(282, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:07:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(283, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:07:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(284, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:07:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(285, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:07:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(286, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:17:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(287, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:17:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(288, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:17:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(289, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 07:19:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(290, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 07:19:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(291, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 07:22:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(292, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 07:22:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(293, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 07:22:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(294, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:52:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(295, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 07:52:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(296, '/', '87.49.42.43', 'Mozilla/5.0 (Linux; Android 14; SM-S911B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/505.0.0.62.82;]', 'http://m.facebook.com/', '2025-05-04 10:11:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 505.0.0.62.82', 'm.facebook.com'),
(297, '/', '87.49.42.43', 'Mozilla/5.0 (Linux; Android 14; SM-S911B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/505.0.0.62.82;]', 'http://m.facebook.com/', '2025-05-04 10:11:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 505.0.0.62.82', 'm.facebook.com'),
(298, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 10:18:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(299, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 10:18:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(300, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 10:18:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(301, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 10:18:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(302, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-04 10:33:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(303, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-04 10:33:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(304, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fkranf%25C3%25B8rere', '2025-05-04 10:33:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(305, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fkranf%25C3%25B8rere', '2025-05-04 10:33:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(306, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fkranf%25C3%25B8rere', '2025-05-04 10:34:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(307, '/auth/signin', '80.62.116.52', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fkranf%25C3%25B8rere', '2025-05-04 10:34:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(308, '/', '87.52.107.131', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.3.2;FBSS/3;FBCR/;FBID/phone;FBLC/da_DK;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 10:50:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.3.2', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(309, '/', '87.52.107.131', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.3.2;FBSS/3;FBCR/;FBID/phone;FBLC/da_DK;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-04 10:50:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.3.2', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(310, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-04 13:48:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(311, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-04 13:48:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(312, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:03:24', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(313, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:03:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(314, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:07:59', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(315, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:07:59', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(316, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:08:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(317, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:08:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(318, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:09:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(319, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:09:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(320, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:15:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(321, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:15:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(322, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:33:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(323, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:33:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(324, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:34:17', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(325, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:34:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(326, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:34:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(327, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:35:49', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(328, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:35:50', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(329, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:35:50', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(330, '/erfaring/gentofte-hospital', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:36:15', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(331, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:37:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(332, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:37:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(333, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:37:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(334, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:37:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(335, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:40:31', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(336, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:40:31', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(337, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:43:02', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(338, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:43:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(339, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:44:35', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(340, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:44:37', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(341, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:44:37', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(342, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:47:53', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(343, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:47:59', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(344, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:48:00', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(345, '/vilkar-og-betingelser', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-04 14:50:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(346, '/vilkar-og-betingelser', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-04 14:50:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(347, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:52:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(348, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 14:52:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(349, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:59:47', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(350, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 14:59:48', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(351, '/kranfoerer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:03', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(352, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:40', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(353, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:44', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(354, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:44', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(355, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:48', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(356, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(357, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:02:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(358, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:05:41', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(359, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:05:41', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(360, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:11:04', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(361, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:11:05', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(362, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:12:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(363, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:13:52', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(364, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:13:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(365, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:13:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(366, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:16:20', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(367, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:16:21', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(368, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 15:18:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(369, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 15:18:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(370, '/kranfoerer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:20:51', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(371, '/kranfoerer', '::ffff:127.0.0.1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:20:51', NULL, NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(372, '/erfaring/gentofte-hospital', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:22:33', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(373, '/kranfoerer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:22:40', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(374, '/kranfoerer', '::1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1', 'http://localhost:3000/kranfoerer', '2025-05-04 15:22:40', 'Local', NULL, NULL, 'mobile', 'iOS 16.6', 'Mobile Safari 16.6', 'localhost'),
(375, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:30:25', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(376, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:30:49', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(377, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:30:50', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(378, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:31:20', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(379, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:31:24', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(380, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:31:25', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(381, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:33:49', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(382, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 15:34:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(383, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 15:34:48', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(384, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 15:34:52', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(385, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 15:34:52', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(386, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:35:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(387, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:35:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(388, '/auth/signin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 15:35:32', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(389, '/auth/signin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-04 15:35:59', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(390, '/auth/signin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-04 15:36:00', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(391, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:36:10', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(392, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:36:21', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(393, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:36:22', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(394, '/kranfoerer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 15:36:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(395, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(396, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(397, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:37:18', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(398, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:37:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(399, '/erfaring', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:38:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(400, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:38:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(401, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:38:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(402, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:47:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(403, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 15:47:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(404, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 16:00:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(405, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:00:29', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(406, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-05-04 16:01:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'l.facebook.com'),
(407, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(408, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(409, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(410, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(411, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:29', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(412, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(413, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:31', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(414, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:33', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(415, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(416, '/erfaring/kactus-towers-copenhagen', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(417, '/erfaring/kactus-towers-copenhagen', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:01:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(418, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:03:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(419, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:03:09', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(420, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:03:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(421, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:03:11', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(422, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:03:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(423, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '2025-05-04 16:03:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(424, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '2025-05-04 16:03:43', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(425, '/erfaring/kactus-towers-copenhagen', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(426, '/erfaring/kactus-towers-copenhagen', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(427, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:15', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(428, '/erfaring/lykkebaekvej-koege', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(429, '/erfaring/lykkebaekvej-koege', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(430, '/erfaring/redmolen-nordhavn-', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(431, '/erfaring/redmolen-nordhavn-', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 16:04:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(432, '/auth/signin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-04 16:05:31', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(433, '/auth/signin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-04 16:05:31', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(434, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:15:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(435, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:15:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(436, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:17:37', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(437, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:17:38', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(438, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:20:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(439, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:20:54', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(440, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer?fbclid=IwY2xjawKEa1ZleHRuA2FlbQIxMABicmlkETF0SmI1MVdNdVF2ekM5T3RXAR5kAPIviPcVr_k-whnfPy3wy3F1EEZAgq-S0GXg_Kb-nK6bBwG0zUK5xL8Krw_aem_Gyeo7nCH1ueyvOOMGEKEEw', '2025-05-04 16:22:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(441, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer?fbclid=IwY2xjawKEa1ZleHRuA2FlbQIxMABicmlkETF0SmI1MVdNdVF2ekM5T3RXAR5kAPIviPcVr_k-whnfPy3wy3F1EEZAgq-S0GXg_Kb-nK6bBwG0zUK5xL8Krw_aem_Gyeo7nCH1ueyvOOMGEKEEw', '2025-05-04 16:22:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(442, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:22:36', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(443, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:22:38', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(444, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:24:30', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(445, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:24:31', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(446, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:24:39', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(447, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:24:40', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(448, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:28:29', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(449, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:28:30', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(450, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:29:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(451, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:29:06', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(452, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:30:40', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(453, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:30:41', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(454, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 16:33:09', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(455, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 16:33:09', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(456, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:35:07', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(457, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:35:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(458, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:41:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(459, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:41:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(460, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:43:33', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(461, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:43:33', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(462, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:44:53', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(463, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:44:55', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(464, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/erfaring', '2025-05-04 16:53:06', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(465, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/erfaring', '2025-05-04 16:53:06', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(466, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 16:53:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(467, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 16:53:10', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(468, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 16:53:10', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(469, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 16:53:11', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(470, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:58:02', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(471, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 16:58:03', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(472, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 17:01:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(473, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 17:01:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(474, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 17:02:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(475, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 17:02:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(476, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 17:02:26', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(477, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 17:02:40', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(478, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring', '2025-05-04 17:02:46', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(479, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring', '2025-05-04 17:02:47', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(480, '/erfaring/kroell-kran', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:03:04', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(481, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:04:14', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(482, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:04:14', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(483, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:14:25', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(484, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 17:14:25', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(485, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 OPR/118.0.0.0', 'http://localhost:3000/', '2025-05-04 17:14:25', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Opera 118.0.0.0', 'localhost'),
(486, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:18:44', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(487, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:18:44', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(488, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 17:20:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(489, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer', '2025-05-04 17:21:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(490, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 17:21:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(491, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 17:21:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(492, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:21:36', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(493, '/', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/erfaring/kroell-kran', '2025-05-04 17:21:36', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(494, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:21:59', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(495, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:22:58', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(496, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:23:08', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(497, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:30:32', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(498, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:30:38', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(499, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:31:15', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(500, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:35:35', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(501, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:36:34', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(502, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:37:02', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(503, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:37:42', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(504, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:37:53', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(505, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:38:52', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(506, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:40:23', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(507, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:40:35', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(508, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:44:22', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(509, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:47:22', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(510, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:47:36', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(511, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:48:14', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(512, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:51:39', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(513, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:53:18', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(514, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:53:19', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(515, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:53:29', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(516, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:53:30', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(517, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:58:46', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(518, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 17:58:47', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(519, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:00:53', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(520, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:00:54', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(521, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:02:33', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(522, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:02:34', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(523, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:27', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(524, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:27', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(525, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:51', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(526, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:52', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(527, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:56', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(528, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:07:57', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(529, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:08:04', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(530, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:08:05', 'Local', NULL, NULL, 'mobile', 'Android 13', 'Mobile Chrome 135.0.0.0', 'localhost'),
(531, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:10:46', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(532, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:10:46', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(533, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:11:37', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(534, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:11:38', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(535, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:16:32', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(536, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:16:32', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(537, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:18:50', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(538, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:18:51', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(539, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:19:42', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(540, '/kranfoerer', '::1', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36', 'http://localhost:3000/kranfoerer', '2025-05-04 18:19:43', 'Local', NULL, NULL, 'mobile', 'Android 6.0', 'Mobile Chrome 135.0.0.0', 'localhost'),
(541, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:22:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(542, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:22:52', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(543, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-04 18:23:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(544, '/da', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-04 18:23:35', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(545, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-04 18:24:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(546, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.pl/', '2025-05-04 18:24:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.pl'),
(547, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:24:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(548, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:24:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(549, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:30:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(550, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:30:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(551, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:32:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(552, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:32:33', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(553, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:32:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(554, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:32:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(555, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 18:35:43', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(556, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-04 18:35:43', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(557, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:35:56', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(558, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:35:56', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(559, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-04 18:36:18', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(560, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:36:30', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(561, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:36:30', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(562, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring', '2025-05-04 18:36:56', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(563, '/erfaring', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/erfaring', '2025-05-04 18:37:42', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(564, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:38:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(565, '/kranfoerer-koebenhavn', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-koebenhavn', '2025-05-04 18:38:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(566, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:38:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(567, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-04 18:38:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(568, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 18:40:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(569, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 18:40:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(570, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 18:40:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(571, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 18:40:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(572, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:44:23', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(573, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:44:24', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(574, '/erfaring/world-trade-center-ballerup', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:44:45', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(575, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:44:47', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(576, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:44:47', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(577, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:47:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(578, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-04 18:47:18', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(579, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-04 18:47:19', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(580, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:48:50', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(581, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-04 18:48:51', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'localhost'),
(582, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 19:55:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(583, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 19:55:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(584, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(585, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(586, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(587, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(588, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(589, '/kranfoerer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-04 20:22:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(590, '/', '52.34.76.65', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0', 'https://ksrcranes.dk/', '2025-05-05 02:02:49', 'US', 'Boardman', 'Oregon', 'desktop', 'Windows 10', 'Firefox 136.0', 'ksrcranes.dk'),
(591, '/', '66.249.66.162', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/134.0.6998.165 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 02:02:50', 'US', 'Charlotte', 'North Carolina', 'desktop', NULL, 'Chrome 134.0.6998.165', 'ksrcranes.dk'),
(592, '/', '52.34.76.65', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0', 'https://ksrcranes.dk/', '2025-05-05 02:02:51', 'US', 'Boardman', 'Oregon', 'desktop', 'Windows 10', 'Firefox 136.0', 'ksrcranes.dk'),
(593, '/', '34.174.235.94', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 02:02:57', 'US', 'Dallas', 'Texas', 'desktop', 'macOS 10.15.7', 'Chrome 120.0.0.0', 'ksrcranes.dk'),
(594, '/', '34.174.235.94', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 02:03:00', 'US', 'Dallas', 'Texas', 'desktop', 'macOS 10.15.7', 'Chrome 120.0.0.0', 'ksrcranes.dk'),
(595, '/', '205.169.39.5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.132 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 03:05:08', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 117.0.5938.132', 'ksrcranes.dk'),
(596, '/', '205.169.39.5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.132 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 03:05:09', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 117.0.5938.132', 'ksrcranes.dk'),
(597, '/', '104.197.69.115', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 03:12:06', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(598, '/', '104.197.69.115', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 03:12:06', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(599, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:17:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(600, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:17:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(601, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:17:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(602, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:17:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(603, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:49:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(604, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 06:49:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(605, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 07:11:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(606, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 07:11:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(607, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 08:53:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(608, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 08:53:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(609, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:18:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(610, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:18:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(611, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:18:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(612, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:18:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(613, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:19:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(614, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:19:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(615, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-05-05 11:19:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(616, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:20:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(617, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:20:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(618, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:20:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(619, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:20:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(620, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(621, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(622, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(623, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(624, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/dashboard', '2025-05-05 11:28:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(625, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/dashboard', '2025-05-05 11:28:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(626, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(627, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:28:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(628, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:50:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(629, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:50:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(630, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:50:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(631, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 11:50:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(632, '/', '87.49.147.0', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 12:21:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(633, '/', '87.49.147.0', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-05 12:21:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(634, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-05 12:27:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(635, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/505.0.0.46.108;FBBV/727987173;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-05 12:27:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 505.0.0.46.108', 'ksrcranes.dk'),
(636, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 12:57:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(637, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 12:57:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(638, '/', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-05 13:04:32', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(639, '/', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-05 18:59:08', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(640, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 20:42:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(641, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 20:42:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(642, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 20:42:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(643, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-05 20:42:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(644, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-05 20:46:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(645, '/da', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-05 20:46:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(646, '/da', '87.49.42.21', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'https://www.google.com/', '2025-05-05 20:52:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'google.com'),
(647, '/da', '87.49.42.21', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.111 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'https://www.google.com/', '2025-05-05 20:52:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'google.com'),
(648, '/vilkar-og-betingelser', '66.249.66.199', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-05 21:11:53', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(649, '/kranfoerer', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/kranfoerer', '2025-05-05 21:11:58', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(650, '/erfaring', '66.249.66.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring', '2025-05-05 22:57:05', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(651, '/kranfoerer', '66.249.66.199', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/kranfoerer', '2025-05-05 23:27:08', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(652, '/erfaring/kongelysvej-hedehusene-', '66.249.66.75', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/kongelysvej-hedehusene-', '2025-05-05 23:44:34', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(653, '/auth/signin', '66.249.66.165', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fvilkaar-og-betingelser', '2025-05-06 00:10:48', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(654, '/erfaring/world-trade-center-ballerup', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/world-trade-center-ballerup', '2025-05-06 00:23:48', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(655, '/erfaring/world-trade-center-ballerup-', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/world-trade-center-ballerup-', '2025-05-06 00:34:04', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(656, '/erfaring/world-trade-center-ballerup-', '66.249.66.37', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/world-trade-center-ballerup-', '2025-05-06 00:36:11', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(657, '/auth/signin', '66.249.66.6', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-06 01:07:54', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(658, '/faq', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/faq', '2025-05-06 01:15:16', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(659, '/erfaring', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring', '2025-05-06 01:26:29', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(660, '/erfaring/redmolen-nordhavn-', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/redmolen-nordhavn-', '2025-05-06 01:40:45', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(661, '/erfaring/fehmarn-belt-tunnel-roedby', '66.249.66.162', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/fehmarn-belt-tunnel-roedby', '2025-05-06 01:41:39', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(662, '/erfaring/grandskoven-glostrup', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/grandskoven-glostrup', '2025-05-06 01:44:49', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(663, '/erfaring/else-alfelts-vej--oerestad-copenhagen', '66.249.66.5', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-alfelts-vej--oerestad-copenhagen', '2025-05-06 02:14:33', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(664, '/erfaring/grandskoven-glostrup', '66.249.66.6', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/grandskoven-glostrup', '2025-05-06 02:25:51', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(665, '/faq', '66.249.66.15', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/faq', '2025-05-06 02:47:16', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(666, '/erfaring/fehmarn-belt-tunnel-roedby', '66.249.66.6', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/fehmarn-belt-tunnel-roedby', '2025-05-06 02:48:17', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(667, '/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '2025-05-06 03:05:41', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(668, '/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '66.249.66.12', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '2025-05-06 03:10:41', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(669, '/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '66.249.66.68', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '2025-05-06 03:20:59', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(670, '/faq', '66.249.66.165', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/faq', '2025-05-06 03:34:02', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(671, '/erfaring/redmolen-nordhavn-', '66.249.66.37', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/redmolen-nordhavn-', '2025-05-06 03:35:44', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(672, '/erfaring/else-alfelts-vej--oerestad-copenhagen', '66.249.66.75', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-alfelts-vej--oerestad-copenhagen', '2025-05-06 03:37:26', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(673, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 03:53:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(674, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 03:53:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(675, '/kranfoerer', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 03:53:40', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(676, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 03:55:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(677, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 03:55:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(678, '/erfaring/kongelysvej-hedehusene-', '66.249.66.74', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kongelysvej-hedehusene-', '2025-05-06 04:05:43', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(679, '/erfaring/kongelysvej-hedehusene-', '66.249.66.9', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kongelysvej-hedehusene-', '2025-05-06 04:05:45', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(680, '/faq', '66.249.66.72', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/faq', '2025-05-06 04:10:45', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(681, '/erfaring', '66.249.66.78', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring', '2025-05-06 04:27:03', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(682, '/erfaring/kroell-crane', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/kroell-crane', '2025-05-06 04:30:58', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(683, '/erfaring/rejsegilde', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/rejsegilde', '2025-05-06 04:31:01', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(684, '/erfaring/rejsegilde', '66.249.66.72', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/rejsegilde', '2025-05-06 04:34:01', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(685, '/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '66.249.66.34', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '2025-05-06 04:36:39', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(686, '/da', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-06 04:43:41', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(687, '/erfaring/kroell-crane', '66.249.66.14', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/kroell-crane', '2025-05-06 04:56:05', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(688, '/erfaring/kongelysvej-hedehusene-', '66.249.66.76', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/kongelysvej-hedehusene-', '2025-05-06 05:00:23', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(689, '/erfaring/carlsberg-district-copenhagen', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/carlsberg-district-copenhagen', '2025-05-06 05:01:16', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(690, '/erfaring/postbyen-copenhagen', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.165 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen-copenhagen', '2025-05-06 05:05:45', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 134.0.6998.165', 'ksrcranes.dk'),
(691, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-05-06 05:16:18', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(692, '/auth/signin', '66.249.66.75', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-06 05:22:52', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(693, '/kranfoerer', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:28:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(694, '/kranfoerer', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:28:01', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(695, '/faq', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:30:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(696, '/faq', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:30:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(697, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:30:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(698, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-06 05:30:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(699, '/auth/signin', '66.249.66.10', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fvilkaar-og-betingelser', '2025-05-06 05:32:48', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(700, '/erfaring/world-trade-center-ballerup-', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/world-trade-center-ballerup-', '2025-05-06 06:01:45', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(701, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 06:03:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(702, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 06:03:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(703, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 06:03:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(704, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 06:03:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(705, '/erfaring/kroell-kran', '66.249.66.40', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kroell-kran', '2025-05-06 06:04:55', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(706, '/erfaring/world-trade-center-ballerup', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/world-trade-center-ballerup', '2025-05-06 06:16:03', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(707, '/erfaring/kroell-kran', '66.249.66.33', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kroell-kran', '2025-05-06 06:46:03', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(708, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.66.15', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-05-06 06:54:27', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(709, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-05-06 06:54:37', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(710, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.66.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-05-06 06:55:28', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(711, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 06:58:50', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(712, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 06:58:55', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(713, '/erfaring/world-trade-center-ballerup', '66.249.66.199', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/world-trade-center-ballerup', '2025-05-06 07:03:33', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(714, '/erfaring/postbyen-copenhagen', '66.249.66.11', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen-copenhagen', '2025-05-06 07:12:04', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(715, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:12:26', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(716, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:13:14', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(717, '/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '2025-05-06 07:20:09', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(718, '/erfaring/rejsegilde', '66.249.66.163', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/rejsegilde', '2025-05-06 07:31:07', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(719, '/erfaring/world-trade-center-ballerup-', '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/world-trade-center-ballerup-', '2025-05-06 07:39:33', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(720, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-06 07:41:50', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(721, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-06 07:43:00', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(722, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:54:45', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(723, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:54:49', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(724, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:57:48', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(725, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 07:57:55', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(726, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/api/auth/error', '2025-05-06 08:01:08', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(727, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/api/auth/error', '2025-05-06 08:01:17', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(728, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 08:01:23', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(729, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 08:01:26', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(730, '/erfaring/kongelysvej-hedehusene-', '66.249.66.34', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kongelysvej-hedehusene-', '2025-05-06 08:08:07', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(731, '/auth/signin', '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fvilkaar-og-betingelser', '2025-05-06 08:15:36', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(732, '/auth/signin', '66.249.66.6', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fvilkaar-og-betingelser', '2025-05-06 08:16:52', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(733, '/erfaring/world-trade-center-ballerup', '66.249.66.40', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/world-trade-center-ballerup', '2025-05-06 08:23:08', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(734, '/kranfoerer', '66.249.66.5', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/kranfoerer', '2025-05-06 08:46:16', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(735, '/erfaring', '66.249.66.76', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring', '2025-05-06 08:51:32', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(736, '/', '66.249.66.14', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-06 09:01:19', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(737, '/erfaring/carlsberg-district-copenhagen', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/carlsberg-district-copenhagen', '2025-05-06 09:04:04', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(738, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 09:17:28', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(739, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-06 09:17:31', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(740, '/', '66.249.66.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-06 09:41:23', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(741, '/erfaring/marta-christensens-vej-oerestad-copenhagen', '66.249.66.76', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/marta-christensens-vej-oerestad-copenhagen', '2025-05-06 10:10:23', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(742, '/lej-en-kranforer', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-06 10:32:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(743, '/lej-en-kranforer', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-06 10:32:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(744, '/lej-en-kranforer', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-06 10:32:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(745, '/lej-en-kranforer', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-06 10:32:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'google.com'),
(746, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:32:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(747, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:32:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(748, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:32:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(749, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:32:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(750, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:32:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(751, '/erfaring/world-trade-center-ballerup-', '66.249.66.73', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/world-trade-center-ballerup-', '2025-05-06 10:34:02', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(752, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:57:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(753, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 10:57:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(754, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 10:58:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(755, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 10:58:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(756, '/', '66.249.66.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-06 11:04:03', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(757, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 11:31:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(758, '/', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 11:31:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(759, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 11:31:42', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(760, '/auth/signin', '37.96.115.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 11:31:42', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(761, '/lej-en-kranforer', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-06 12:04:30', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(762, '/auth/signin', '66.249.77.137', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-06 12:36:37', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(763, '/auth/signin', '66.249.77.137', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-06 12:36:39', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(764, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 12:48:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(765, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 12:48:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(766, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 12:48:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(767, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 12:48:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(768, '/cookie-politik', '66.249.75.171', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/cookie-politik', '2025-05-06 13:04:08', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(769, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 13:16:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(770, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 13:16:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(771, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 13:56:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(772, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 13:56:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(773, '/auth/signin', '66.249.77.138', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fkontakt', '2025-05-06 15:03:07', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(774, '/auth/signin', '66.249.77.140', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-06 15:09:11', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(775, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:29:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(776, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:29:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(777, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:29:49', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(778, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:29:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(779, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:36:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(780, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 15:36:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(781, '/erfaring/redmolen-nordhavn-', '66.249.75.165', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/redmolen-nordhavn-', '2025-05-06 16:04:09', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(782, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-06 17:35:45', 'US', 'Ashburn', 'Virginia', 'desktop', NULL, NULL, 'ksrcranes.dk'),
(783, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-06 17:35:45', 'US', 'Ashburn', 'Virginia', 'desktop', NULL, NULL, 'ksrcranes.dk'),
(784, '/auth/signin', '66.249.77.137', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fvilkaar-og-betingelser', '2025-05-06 19:56:30', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(785, '/erfaring/rejsegilde', '66.249.75.171', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/rejsegilde', '2025-05-06 19:58:31', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(786, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 21:40:55', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(787, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 21:40:55', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(788, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 21:41:01', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(789, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-06 21:41:00', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(790, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 05:27:07', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(791, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 05:27:08', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(792, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 05:27:11', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(793, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 05:27:11', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(794, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 07:25:16', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(795, '/', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 07:25:17', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(796, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 07:25:21', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(797, '/auth/signin', '149.102.237.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 07:25:21', 'IT', 'Milan', 'Lombardy', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(798, '/auth/signin', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-05-07 12:45:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.com'),
(799, '/auth/signin', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-05-07 12:45:38', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'google.com'),
(800, '/lej-en-kranforer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-07 12:45:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(801, '/lej-en-kranforer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-07 12:45:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(802, '/', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-05-07 12:45:57', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(803, '/', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-05-07 12:45:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(804, '/', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-05-07 12:46:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(805, '/kranfoerer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-07 12:46:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(806, '/kranfoerer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-07 12:46:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(807, '/', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-05-07 12:46:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(808, '/', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-05-07 12:46:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(809, '/lej-en-kranforer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-07 12:46:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(810, '/lej-en-kranforer', '93.178.191.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-07 12:46:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(811, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:11:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(812, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:11:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(813, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:11:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(814, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:11:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(815, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:28:02', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(816, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:28:02', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(817, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:53:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(818, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:53:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(819, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:53:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(820, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 13:53:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(821, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 GoogleWv/1.0 (WKWebView) GeminiiOS/1.2025.1662203', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fkontakt', '2025-05-07 14:16:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'WebKit 605.1.15', 'ksrcranes.dk'),
(822, '/auth/signin', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 GoogleWv/1.0 (WKWebView) GeminiiOS/1.2025.1662203', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fkontakt', '2025-05-07 14:16:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'WebKit 605.1.15', 'ksrcranes.dk'),
(823, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 GoogleWv/1.0 (WKWebView) GeminiiOS/1.2025.1662203', 'https://ksrcranes.dk/', '2025-05-07 14:16:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'WebKit 605.1.15', 'ksrcranes.dk'),
(824, '/', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 GoogleWv/1.0 (WKWebView) GeminiiOS/1.2025.1662203', 'https://ksrcranes.dk/', '2025-05-07 14:16:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'WebKit 605.1.15', 'ksrcranes.dk'),
(825, '/lej-en-kranforer', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-07 14:17:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(826, '/lej-en-kranforer', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-07 14:17:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(827, '/', '66.249.75.165', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-07 16:41:01', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(828, '/', '66.249.75.165', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/135.0.7049.114 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-07 16:41:06', 'US', 'Council Bluffs', 'Iowa', 'desktop', NULL, 'Chrome 135.0.7049.114', 'ksrcranes.dk'),
(829, '/lej-en-kranforer', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 17:16:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.0', 'Mobile Safari 18.0', 'ksrcranes.dk'),
(830, '/lej-en-kranforer', '37.96.120.236', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 17:16:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.0', 'Mobile Safari 18.0', 'ksrcranes.dk'),
(831, '/', '2001:2012:1881:6900:809b:af2a:7904:ddd9', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_8_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6.7 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-07 18:12:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 15.8.4', 'Mobile Safari 15.6.7', 'ksrcranes.dk'),
(832, '/erfaring/postbyen-copenhagen', '66.249.77.138', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/135.0.7049.114 Safari/537.36', 'https://ksrcranes.dk/erfaring/postbyen-copenhagen', '2025-05-08 03:08:18', 'US', 'Council Bluffs', 'Iowa', 'desktop', NULL, 'Chrome 135.0.7049.114', 'ksrcranes.dk'),
(833, '/erfaring/postbyen-copenhagen', '66.249.77.136', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen-copenhagen', '2025-05-08 03:08:19', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(834, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 03:36:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(835, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 03:36:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(836, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 03:36:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(837, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 03:36:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(838, '/', '66.249.77.136', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-08 06:04:44', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(839, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 06:58:49', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(840, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 06:58:49', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(841, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 06:58:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(842, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 06:58:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(843, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:01:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(844, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:01:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(845, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:43:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(846, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:43:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(847, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:43:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(848, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 07:43:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(849, '/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '66.249.75.172', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '2025-05-08 09:04:43', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(850, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 10:16:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(851, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 10:16:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(852, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 10:16:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(853, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 10:16:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(854, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:23:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(855, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:23:43', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(856, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:23:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(857, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:23:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(858, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 10:40:08', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(859, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 10:40:08', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(860, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 10:40:17', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(861, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 10:40:19', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(862, '/', '205.169.39.94', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:55:44', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 79.0.3945.79', 'ksrcranes.dk'),
(863, '/', '205.169.39.94', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 10:55:45', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 79.0.3945.79', 'ksrcranes.dk'),
(864, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 13:19:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(865, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 13:19:24', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(866, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzA1NTIzLCJleHAiOjE3NDY3OTE5MjN9.jgU1gl2IJrRWGOrNUuPOKPeLhC4gbcplSxb_qr9UlrQ', '2025-05-08 13:22:29', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(867, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzA1NTIzLCJleHAiOjE3NDY3OTE5MjN9.jgU1gl2IJrRWGOrNUuPOKPeLhC4gbcplSxb_qr9UlrQ', '2025-05-08 13:22:31', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(868, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/chef/dashboard', '2025-05-08 13:24:46', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(869, '/', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/chef/dashboard', '2025-05-08 13:24:49', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(870, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 13:25:02', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(871, '/auth/signin', '::1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-08 13:25:04', 'Local', NULL, NULL, 'desktop', 'Linux', 'Chrome 135.0.0.0', 'localhost'),
(872, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:30:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(873, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:30:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(874, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:30:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(875, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:30:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(876, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/settings', '2025-05-08 14:33:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(877, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/settings', '2025-05-08 14:33:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(878, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:33:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(879, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 14:33:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(880, '/auth/signin', '95.209.202.229', 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-08 14:34:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Mobile Chrome 131.0.0.0', 'google.com'),
(881, '/auth/signin', '95.209.202.229', 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-08 14:34:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Mobile Chrome 131.0.0.0', 'google.com'),
(882, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 14:45:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(883, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 14:45:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(884, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 14:45:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(885, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 14:45:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(886, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 15:02:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(887, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-08 15:02:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(888, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:03:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(889, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:03:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(890, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:06:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Ubuntu', 'Firefox 138.0', 'ksrcranes.dk'),
(891, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:06:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Ubuntu', 'Firefox 138.0', 'ksrcranes.dk'),
(892, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 15:25:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(893, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 15:25:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(894, '/auth/signin', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0', 'http://localhost:3000/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:29:27', NULL, NULL, NULL, 'desktop', 'Ubuntu', 'Firefox 138.0', 'localhost'),
(895, '/auth/signin', '::ffff:127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0', 'http://localhost:3000/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:29:31', NULL, NULL, NULL, 'desktop', 'Ubuntu', 'Firefox 138.0', 'localhost'),
(896, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:31:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(897, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ2NzE2NTcwLCJleHAiOjE3NDY4MDI5NzB9.M9QVNwarVfAA-aZxX-7M9Qm7hAEjj2EZ22UUqFcu6J0', '2025-05-08 15:31:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(898, '/', '66.249.79.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-08 16:27:56', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(899, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(900, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(901, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(902, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(903, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/worker/dashboard', '2025-05-08 17:12:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(904, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/worker/dashboard', '2025-05-08 17:12:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(905, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(906, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 17:12:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(907, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 18:04:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(908, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 18:04:16', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(909, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 18:04:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(910, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 18:04:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(911, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:33:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(912, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:33:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(913, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:33:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(914, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:33:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(915, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:35:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(916, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 19:35:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(917, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(918, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(919, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(920, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(921, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/dashboard', '2025-05-08 20:01:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(922, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/chef/dashboard', '2025-05-08 20:01:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(923, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(924, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-08 20:01:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(925, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.ksrcranes.dk/', '2025-05-08 20:03:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(926, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.ksrcranes.dk/', '2025-05-08 20:03:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(927, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.ksrcranes.dk/', '2025-05-08 20:03:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(928, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.ksrcranes.dk/', '2025-05-08 20:03:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(929, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:45:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(930, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:45:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(931, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:46:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(932, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:46:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(933, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/worker/dashboard', '2025-05-09 03:46:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(934, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/worker/dashboard', '2025-05-09 03:46:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(935, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:46:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(936, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 03:46:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(937, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/customer/dashboard', '2025-05-09 06:09:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(938, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/customer/dashboard', '2025-05-09 06:09:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(939, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 06:09:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(940, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 06:09:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(941, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-09 08:11:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(942, '/', '37.96.122.159', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-09 08:11:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Linux', 'Chrome 135.0.0.0', 'ksrcranes.dk'),
(943, '/', '37.96.103.65', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 14:44:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(944, '/', '37.96.103.65', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 14:44:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(945, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 19:22:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(946, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 19:22:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(947, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 19:22:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(948, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-09 19:22:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(949, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/auth/signin', '2025-05-10 05:28:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(950, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/auth/signin', '2025-05-10 05:29:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'coral-app-ieeur.ondigitalocean.app'),
(951, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 05:29:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(952, '/', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 05:29:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(953, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 05:29:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(954, '/auth/signin', '37.96.122.159', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 05:29:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.56', 'ksrcranes.dk'),
(955, '/kranfoerer', '37.96.96.93', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-10 13:40:00', 'DK', 'Roskilde', 'Zealand', 'mobile', 'iOS 17.3.1', 'Mobile Safari 17.3.1', 'google.com'),
(956, '/kranfoerer', '37.96.96.93', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-10 13:40:01', 'DK', 'Roskilde', 'Zealand', 'mobile', 'iOS 17.3.1', 'Mobile Safari 17.3.1', 'google.com'),
(957, '/auth/signin', '37.96.96.93', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer', '2025-05-10 13:41:02', 'DK', 'Roskilde', 'Zealand', 'mobile', 'iOS 17.3.1', 'Mobile Safari 17.3.1', 'ksrcranes.dk'),
(958, '/auth/signin', '37.96.96.93', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer', '2025-05-10 13:41:02', 'DK', 'Roskilde', 'Zealand', 'mobile', 'iOS 17.3.1', 'Mobile Safari 17.3.1', 'ksrcranes.dk'),
(959, '/lej-en-kranforer', '37.96.126.130', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 14:32:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.0', 'Mobile Safari 18.0', 'ksrcranes.dk'),
(960, '/lej-en-kranforer', '37.96.126.130', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 14:32:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.0', 'Mobile Safari 18.0', 'ksrcranes.dk'),
(961, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-10 16:49:49', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'localhost'),
(962, '/', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-10 16:49:50', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'localhost'),
(963, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-10 16:50:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'localhost'),
(964, '/kranfoerer-aarhus', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/kranfoerer-aarhus', '2025-05-10 16:50:08', 'Local', NULL, NULL, 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'localhost'),
(965, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-10 16:54:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(966, '/', '80.71.142.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-10 16:54:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(967, '/', '37.47.130.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 17:58:15', 'PL', 'Poznań', 'Greater Poland', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(968, '/', '37.47.130.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 17:58:15', 'PL', 'Poznań', 'Greater Poland', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(969, '/', '37.47.130.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 17:58:45', 'PL', 'Poznań', 'Greater Poland', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(970, '/', '37.47.130.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 17:58:45', 'PL', 'Poznań', 'Greater Poland', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(971, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 19:54:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(972, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-10 19:54:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(973, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 19:54:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(974, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 19:54:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(975, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-10 19:56:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(976, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-10 19:56:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(977, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 19:56:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(978, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 19:56:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(979, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 19:57:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(980, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 19:57:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(981, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 19:57:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(982, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 19:57:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(983, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 20:07:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(984, '/kranfoerer-koebenhavn', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/506.0.0.49.108;FBBV/730976256;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.4.1;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/kranfoerer-koebenhavn', '2025-05-10 20:07:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Facebook 506.0.0.49.108', 'ksrcranes.dk'),
(985, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 20:07:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(986, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 20:07:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(987, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 20:07:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(988, '/kranfoerer-aarhus', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer-aarhus', '2025-05-10 20:07:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(989, '/kranfoerer-aarhus', '87.49.147.77', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-10 21:00:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(990, '/kranfoerer-aarhus', '87.49.147.77', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-10 21:00:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(991, '/kranfoerer-koebenhavn', '87.49.147.77', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-10 21:00:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(992, '/kranfoerer-koebenhavn', '87.49.147.77', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-10 21:00:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(993, '/', '66.249.68.136', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-11 00:52:37', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(994, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.google.com/', '2025-05-11 05:26:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'google.com'),
(995, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://www.google.com/', '2025-05-11 05:26:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'google.com'),
(996, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-11 05:26:34', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(997, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/138.0  Mobile/15E148 Safari/605.1.15', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-11 05:26:34', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Firefox 138.0', 'ksrcranes.dk'),
(998, '/faq', '66.249.79.206', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/faq', '2025-05-11 07:00:46', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(999, '/da', '66.249.79.205', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-11 07:04:46', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1000, '/da', '66.249.79.205', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-11 07:04:48', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1001, '/da', '66.249.79.201', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-11 08:00:46', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1002, '/', '66.249.79.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-11 08:04:46', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1003, '/lej-en-kranforer', '66.249.79.201', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-11 09:00:51', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1004, '/', '66.249.79.204', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-11 09:04:43', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1005, '/', '2a00:f41:9085:9283:f4ae:8491:80f8:f182', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 10:38:22', 'PL', 'Wola', 'Mazovia', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(1006, '/', '2a00:f41:9085:9283:f4ae:8491:80f8:f182', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/114.0.5735.124 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 10:38:22', 'PL', 'Wola', 'Mazovia', 'mobile', 'iOS 18.2', 'Mobile Chrome 114.0.5735.124', 'ksrcranes.dk'),
(1007, '/', '37.96.113.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 16:20:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1008, '/', '37.96.113.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 16:20:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1009, '/auth/signin', '37.96.113.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 16:20:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1010, '/auth/signin', '37.96.113.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-11 16:20:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1011, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-11 17:15:32', 'US', 'Ashburn', 'Virginia', 'desktop', NULL, NULL, 'ksrcranes.dk'),
(1012, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-11 17:15:33', 'US', 'Ashburn', 'Virginia', 'desktop', NULL, NULL, 'ksrcranes.dk'),
(1013, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15', 'http://localhost:3000/', '2025-05-11 17:28:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Safari 18.4', 'localhost'),
(1014, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15', 'http://localhost:3000/', '2025-05-11 17:28:48', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Safari 18.4', 'localhost'),
(1015, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-11 17:32:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1016, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-11 17:32:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1017, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-11 17:36:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1018, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:29:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1019, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:29:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1020, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:30:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1021, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:30:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1022, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:30:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1023, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-11 19:30:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1024, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:05:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1025, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:05:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1026, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:06:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1027, '/', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:06:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1028, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:39:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1029, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:39:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1030, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:43:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1031, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BP22.250325.006; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/133.0.6943.137 Mobile Safari/537.36', 'https://ksrcranes.dk/auth/signin', '2025-05-11 20:43:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 16', 'Chrome WebView 133.0.6943.137', 'ksrcranes.dk'),
(1032, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:35:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'WebKit 605.1.15', 'ksrcranes.dk'),
(1033, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:35:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'WebKit 605.1.15', 'ksrcranes.dk'),
(1034, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fchef%2Fdashboard', '2025-05-12 05:36:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1035, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fchef%2Fdashboard', '2025-05-12 05:36:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1036, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:47:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'WebKit 605.1.15', 'ksrcranes.dk'),
(1037, '/auth/signin', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:47:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4', 'WebKit 605.1.15', 'ksrcranes.dk'),
(1038, '/', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-12 05:48:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1039, '/', '37.96.115.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-12 05:48:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1040, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-12 05:49:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1041, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-12 05:49:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1042, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-12 05:50:11', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1043, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-12 05:50:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1044, '/', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-12 05:50:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1045, '/', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2F%24', '2025-05-12 05:50:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1046, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-12 05:51:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1047, '/auth/signin', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-12 05:51:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1048, '/', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:51:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1049, '/', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:51:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1050, '/', '185.107.12.131', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/auth/signin', '2025-05-12 05:52:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1051, '/', '66.249.77.137', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/135.0.7049.114 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-12 07:57:10', 'US', 'Council Bluffs', 'Iowa', 'desktop', NULL, 'Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1052, '/', '37.96.115.81', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-12 10:40:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1053, '/', '37.96.115.81', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-12 10:40:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1054, '/', '66.249.65.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-13 00:10:57', 'US', 'Tulsa', 'Oklahoma', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1055, '/', '37.96.96.178', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 07:15:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1056, '/', '37.96.96.178', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 07:15:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1057, '/auth/signin', '37.96.96.178', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 07:15:38', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1058, '/auth/signin', '37.96.96.178', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 07:15:38', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1059, '/', '37.96.96.178', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 07:34:01', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1060, '/', '37.96.96.178', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 07:34:01', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1061, '/', '66.249.65.168', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/135.0.7049.114 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 08:16:57', 'US', 'Tulsa', 'Oklahoma', 'desktop', NULL, 'Chrome 135.0.7049.114', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1062, '/auth/signin', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fv1%2Fauth%2Flogin', '2025-05-13 12:33:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1063, '/auth/signin', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/auth/signin?callbackUrl=%2Fv1%2Fauth%2Flogin', '2025-05-13 12:33:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1064, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 14:34:18', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1065, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 14:34:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1066, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 14:34:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1067, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 14:34:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1068, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:15:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1069, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:15:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1070, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:15:18', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1071, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:15:18', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1072, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:24:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1073, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:24:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1074, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:29:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1075, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:29:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1076, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:30:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1077, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:30:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1078, '/', '37.96.120.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 15:30:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1079, '/', '37.96.120.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 15:30:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1080, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:31:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1081, '/', '37.96.120.71', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-13 15:31:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1082, '/', '37.96.120.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 15:32:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1083, '/', '37.96.120.71', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 15:32:33', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1084, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 17:37:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1085, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 17:37:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1086, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 19:51:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1087, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 19:51:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1088, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 19:51:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1089, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-13 19:51:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1090, '/', '66.249.79.204', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.7049.114 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-14 03:35:49', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 135.0.7049.114', 'ksrcranes.dk'),
(1091, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/auth/signin', '2025-05-14 05:36:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'coral-app-ieeur.ondigitalocean.app'),
(1092, '/', '37.96.110.208', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 07:04:38', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1093, '/', '37.96.110.208', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 07:04:38', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1094, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 08:28:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1095, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 08:28:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1096, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/auth/signin', '2025-05-14 08:31:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'coral-app-ieeur.ondigitalocean.app'),
(1097, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/auth/signin', '2025-05-14 08:31:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'coral-app-ieeur.ondigitalocean.app'),
(1098, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ3MjExNDE1LCJleHAiOjE3NDcyOTc4MTV9.N36uIYR4uCdeyvfUntpmXn9V8EJgBs0s9OIxS6yb2z4', '2025-05-14 08:32:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1099, '/auth/signin', '37.96.110.208', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjoyLCJlbWFpbCI6ImtyYW5mb3JlcnBsYXRmb3JtQGdtYWlsLmNvbSIsInR5cGUiOiJhY3RpdmF0aW9uIiwiaWF0IjoxNzQ3MjExNDE1LCJleHAiOjE3NDcyOTc4MTV9.N36uIYR4uCdeyvfUntpmXn9V8EJgBs0s9OIxS6yb2z4', '2025-05-14 08:32:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1100, '/', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 13:44:46', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1101, '/', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 13:44:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1102, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 13:44:50', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1103, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 13:44:50', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1104, '/', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 14:45:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1105, '/', '37.96.123.150', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 14:45:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1106, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 18:35:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1107, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 18:35:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1108, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 18:36:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1109, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-14 18:36:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1110, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 14:46:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1111, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 14:46:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1112, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 14:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1113, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 14:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1114, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 17:38:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1115, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 17:38:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1116, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 17:38:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1117, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-15 17:38:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1118, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 09:40:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1119, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 09:40:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1120, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 09:40:37', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1121, '/auth/signin', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 09:40:37', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1122, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 16:38:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1123, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 16:38:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1124, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 16:38:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1125, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 16:38:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1126, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjozLCJlbWFpbCI6Im1hamtlbWFuaXplckBnbWFpbC5jb20iLCJ0eXBlIjoiYWN0aXZhdGlvbiIsImlhdCI6MTc0NzQxMzU3NiwiZXhwIjoxNzQ3NDk5OTc2fQ.klclhYXFH7nZ_2mFjzXfRaVQNSB7pHjOOqc2K5E8wHE', '2025-05-16 16:40:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1127, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/activate/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBsb3llZUlkIjozLCJlbWFpbCI6Im1hamtlbWFuaXplckBnbWFpbC5jb20iLCJ0eXBlIjoiYWN0aXZhdGlvbiIsImlhdCI6MTc0NzQxMzU3NiwiZXhwIjoxNzQ3NDk5OTc2fQ.klclhYXFH7nZ_2mFjzXfRaVQNSB7pHjOOqc2K5E8wHE', '2025-05-16 16:40:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1128, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 20:49:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1129, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 20:49:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1130, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 20:49:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1131, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-16 20:49:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1132, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 06:50:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1133, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 06:50:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1134, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 06:50:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1135, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 06:50:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1136, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:49:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1137, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:49:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1138, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:49:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1139, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:49:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1140, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:51:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1141, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 08:51:14', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1142, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 10:58:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1143, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 10:58:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1144, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 11:23:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1145, '/', '37.96.123.150', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 11:23:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1146, '/', '37.96.117.1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 18:11:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1147, '/', '37.96.117.1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 18:11:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1148, '/auth/signin', '37.96.117.1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 18:11:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1149, '/auth/signin', '37.96.117.1', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-17 18:11:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1150, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:22:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1151, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:22:24', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1152, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:22:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1153, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:22:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1154, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:23:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1155, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-18 05:23:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1156, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:30:24', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1157, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:30:24', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1158, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:41:03', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1159, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:41:02', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1160, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:49:52', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1161, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-19 12:50:00', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1162, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-19 12:50:04', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1163, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-19 12:51:00', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1164, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:51:03', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1165, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 12:51:04', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1166, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-19 12:54:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1167, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-19 12:54:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1168, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 13:02:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1169, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-19 13:02:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1170, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:23:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1171, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:23:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1172, '/auth/signin', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:23:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1173, '/auth/signin', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:23:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1174, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:24:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1175, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:24:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1176, '/auth/signin', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:26:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1177, '/auth/signin', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:26:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1178, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:26:39', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1179, '/', '37.96.110.251', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-19 18:26:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1180, '/', '37.96.124.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-20 11:02:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1181, '/', '37.96.124.184', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-20 11:02:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1182, '/', '37.96.124.184', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-20 13:05:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1183, '/', '37.96.124.184', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-20 13:05:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1184, '/auth/signin', '37.96.124.184', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-20 13:05:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1185, '/auth/signin', '37.96.124.184', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-20 13:05:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1186, '/', '37.96.124.59', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 16:51:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1187, '/', '37.96.124.59', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 16:51:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1188, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 19:04:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1189, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 19:04:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1190, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 19:04:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1191, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-21 19:04:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1192, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-23 08:54:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1193, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-23 08:54:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1194, '/', '37.96.98.222', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-23 09:11:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1195, '/', '37.96.98.222', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-23 09:11:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1196, '/auth/signin', '37.96.98.222', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-23 09:12:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1197, '/auth/signin', '37.96.98.222', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-23 09:12:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1198, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/22E252 Instagram 381.1.2.26.83 (iPhone15,2; iOS 18_4_1; pl_PL; pl; scale=3.00; 1179x2556; IABMV/1; 737297623) Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 09:35:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Instagram 381.1.2.26.83', 'ksrcranes.dk'),
(1199, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/22E252 Instagram 381.1.2.26.83 (iPhone15,2; iOS 18_4_1; pl_PL; pl; scale=3.00; 1179x2556; IABMV/1; 737297623) Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 09:35:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Instagram 381.1.2.26.83', 'ksrcranes.dk'),
(1200, '/kranfoerer', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/22E252 Instagram 381.1.2.26.83 (iPhone15,2; iOS 18_4_1; pl_PL; pl; scale=3.00; 1179x2556; IABMV/1; 737297623) Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 09:35:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Instagram 381.1.2.26.83', 'ksrcranes.dk'),
(1201, '/kranfoerer', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/22E252 Instagram 381.1.2.26.83 (iPhone15,2; iOS 18_4_1; pl_PL; pl; scale=3.00; 1179x2556; IABMV/1; 737297623) Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 09:35:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Instagram 381.1.2.26.83', 'ksrcranes.dk'),
(1202, '/erfaring/andrea-brochmanns--gade-copenhagen-', '66.249.66.197', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/andrea-brochmanns--gade-copenhagen-', '2025-05-23 11:01:56', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1203, '/erfaring/postbyen---copenhagen-', '66.249.66.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen---copenhagen-', '2025-05-23 11:24:26', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1204, '/erfaring/else-alfelts-vej--oerestad-copenhagen', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/else-alfelts-vej--oerestad-copenhagen', '2025-05-23 11:38:22', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1205, '/erfaring/papiroeen-copenhagen', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/papiroeen-copenhagen', '2025-05-23 11:46:59', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1206, '/erfaring/postbyen-copenhagen', '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen-copenhagen', '2025-05-23 12:09:26', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1207, '/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '66.249.66.161', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/carlsberg-byen-koebenhavn-in-situ-stoebning-montage-og-pladslogistik-med-liebherr-ec-b-kran', '2025-05-23 12:32:09', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1208, '/', '66.249.66.198', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/136.0.7103.92 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-23 12:54:35', 'US', 'Charlotte', 'North Carolina', 'desktop', NULL, 'Chrome 136.0.7103.92', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1209, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 12:57:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1210, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 12:57:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1211, '/auth/signin', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 12:57:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1212, '/auth/signin', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 12:57:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1213, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 13:00:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1214, '/', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 13:00:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1215, '/lej-en-kranforer', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 13:00:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1216, '/lej-en-kranforer', '37.96.98.222', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 13:00:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1217, '/', '37.96.124.97', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/21G93 Instagram 352.2.0.36.89 (iPhone12,3; iOS 17_6_1; pl_DK; pl; scale=3.00; 1125x2436; 650375967; IABMV/1)', 'https://ksrcranes.dk/', '2025-05-23 13:50:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 17.6.1', 'Instagram 352.2.0.36.89', 'ksrcranes.dk'),
(1218, '/', '37.96.124.97', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/21G93 Instagram 352.2.0.36.89 (iPhone12,3; iOS 17_6_1; pl_DK; pl; scale=3.00; 1125x2436; 650375967; IABMV/1)', 'https://ksrcranes.dk/', '2025-05-23 13:50:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 17.6.1', 'Instagram 352.2.0.36.89', 'ksrcranes.dk'),
(1219, '/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '66.249.66.166', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-a-lfelts-vej-oerestad-copenhagen', '2025-05-23 15:31:56', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1220, '/auth/signin', '66.249.66.161', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Fkontakt', '2025-05-23 18:44:06', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1221, '/auth/signin', '66.249.66.162', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/auth/signin?callbackUrl=%2Ffaq', '2025-05-23 19:14:07', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1222, '/kranfoerer', '66.249.66.10', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/kranfoerer', '2025-05-23 20:15:01', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1223, '/lej-en-kranforer', '66.249.66.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-23 20:44:05', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1224, '/da', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/da', '2025-05-23 20:48:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1225, '/da', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/da', '2025-05-23 20:48:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1226, '/', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/da', '2025-05-23 20:48:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1227, '/', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/da', '2025-05-23 20:48:50', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1228, '/', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/da', '2025-05-23 20:49:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1229, '/kranfoerer', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 20:49:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1230, '/kranfoerer', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-23 20:49:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1231, '/', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer', '2025-05-23 20:49:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1232, '/', '77.241.128.142', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/kranfoerer', '2025-05-23 20:49:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.4.1', 'Mobile Safari 18.4', 'ksrcranes.dk'),
(1233, '/erfaring/fehmarn-belt-tunnel-roedby', '66.249.66.164', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/fehmarn-belt-tunnel-roedby', '2025-05-23 21:31:55', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1234, '/', '66.249.66.197', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-24 00:31:56', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1235, '/lej-en-kranforer', '66.249.66.5', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-05-24 02:09:30', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1236, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 06:43:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1237, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 06:43:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1238, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 06:47:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1239, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 06:47:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1240, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:02:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1241, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:03:20', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1242, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:03:20', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1243, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:00', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1244, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:00', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1245, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:57', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1246, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:57', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1247, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:59', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1248, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:09:59', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1249, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:13:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1250, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:13:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1251, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15', 'http://localhost:3000/auth/signin', '2025-05-24 08:14:02', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Safari 18.4', 'localhost'),
(1252, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15', 'http://localhost:3000/auth/signin', '2025-05-24 08:14:03', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Safari 18.4', 'localhost'),
(1253, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:15:06', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1254, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:15:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1255, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:16:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1256, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:16:22', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1257, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:16:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1258, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:16:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1259, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:16:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1260, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:17:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1261, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:18:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1262, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:18:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1263, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:21:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1264, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:21:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1265, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:32:36', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1266, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:32:36', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1267, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:39:01', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1268, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/auth/signin', '2025-05-24 08:39:01', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1269, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 08:42:46', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1270, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 08:42:46', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1271, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:43:06', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1272, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:47:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1273, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:47:50', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1274, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:47:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1275, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:55:15', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1276, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:55:22', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1277, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:55:22', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1278, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:57:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1279, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:57:34', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1280, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:57:34', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1281, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:59:18', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1282, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:59:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1283, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 08:59:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1284, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:03:13', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1285, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:04:04', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1286, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:04:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1287, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:04:22', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1288, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:04:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1289, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1290, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:06', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1291, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:08', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1292, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:09', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1293, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:20', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1294, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1295, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:24', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1296, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:07:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1297, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:08:12', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1298, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 09:08:12', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1299, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:29:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1300, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:29:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1301, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:30:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1302, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:30:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1303, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:30:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1304, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-24 10:30:12', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1305, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/privacy-policy', '2025-05-24 10:30:24', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1306, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/privacy-policy', '2025-05-24 10:30:24', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1307, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:17:52', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1308, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:17:52', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1309, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:19:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1310, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:19:29', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1311, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:22:35', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1312, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:22:35', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1313, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:24:29', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1314, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:24:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1315, '/kranfoerer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:24:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1316, '/kranfoerer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:24:48', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1317, '/kranfoerer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:25:41', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1318, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:29:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1319, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:33:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1320, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:33:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1321, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:35:40', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1322, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:43:04', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1323, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 11:48:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1324, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 11:48:21', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1325, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 11:53:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1326, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 11:53:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1327, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-05-24 11:53:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1328, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 11:56:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1329, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 11:56:32', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1330, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:57:36', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1331, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:57:36', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1332, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:58:48', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1333, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 11:58:48', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1334, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:02:33', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1335, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:02:33', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1336, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:04:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1337, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:04:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1338, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:08:45', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1339, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:08:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1340, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:12:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1341, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:12:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1342, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:12:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1343, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 12:12:38', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1344, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 12:13:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1345, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 12:13:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1346, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 12:13:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1347, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-24 13:40:31', NULL, NULL, NULL, 'desktop', NULL, NULL, 'ksrcranes.dk'),
(1348, '/', '202.8.40.99', 'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)', 'https://ksrcranes.dk/', '2025-05-24 13:40:32', NULL, NULL, NULL, 'desktop', NULL, NULL, 'ksrcranes.dk'),
(1349, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15', 'http://localhost:3000/auth/signin', '2025-05-24 14:14:13', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Safari 18.4', 'localhost'),
(1350, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:15:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1351, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:15:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1352, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:15:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1353, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:15:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1354, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:22:11', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1355, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:22:11', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1356, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:23:57', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1357, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:24:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1358, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:24:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1359, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:26', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1360, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:38', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1361, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:40', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1362, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1363, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:49', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1364, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:42:49', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1365, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:43:00', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1366, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:43:01', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1367, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:43:01', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1368, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:45:53', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1369, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1370, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1371, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:09', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1372, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1373, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1374, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1375, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:20', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1376, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1377, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:26', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1378, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1379, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1380, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1381, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1382, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:46:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1383, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:47:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1384, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:47:34', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1385, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:47:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1386, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:15', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1387, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:18', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1388, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1389, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1390, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1391, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1392, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:40', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1393, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:40', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1394, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:50', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1395, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1396, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:55', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1397, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:48:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1398, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:12', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1399, '/blog', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:12', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1400, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1401, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1402, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:43', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1403, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:45', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1404, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 14:49:45', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1405, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog', '2025-05-24 15:09:33', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1406, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:16:18', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1407, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:30:14', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1408, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:32:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1409, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:44:02', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1410, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:44:35', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1411, '/blog/test', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/blog/test', '2025-05-24 15:44:41', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1412, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 15:47:21', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1413, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 15:47:21', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1414, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 16:00:57', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1415, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-24 16:00:59', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1416, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 16:59:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1417, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 16:59:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1418, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 17:23:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1419, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 17:23:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1420, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 17:23:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1421, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 17:23:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1422, '/', '80.208.65.209', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/482.2.0.68.110;FBBV/658316928;FBDV/iPhone14,7;FBMD/iPhone;FBSN/iOS;FBSV/18.2;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-24 17:29:19', 'DK', 'Ballerup', 'Capital Region', 'mobile', 'iOS 18.2', 'Facebook 482.2.0.68.110', 'ksrcranes.dk'),
(1423, '/', '80.208.65.209', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/482.2.0.68.110;FBBV/658316928;FBDV/iPhone14,7;FBMD/iPhone;FBSN/iOS;FBSV/18.2;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-24 17:29:20', 'DK', 'Ballerup', 'Capital Region', 'mobile', 'iOS 18.2', 'Facebook 482.2.0.68.110', 'ksrcranes.dk'),
(1424, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 21:26:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1425, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 21:26:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1426, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 21:26:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1427, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-24 21:26:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1428, '/privacy-policy', '66.249.79.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/privacy-policy', '2025-05-24 23:10:39', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1429, '/erfaring/carlsberg-district-copenhagen', '66.249.79.202', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/carlsberg-district-copenhagen', '2025-05-25 00:40:39', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1430, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 08:20:36', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1431, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 08:20:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1432, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:27:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1433, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:27:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1434, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:28:22', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1435, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:28:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1436, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:29:20', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1437, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:33:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1438, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:33:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1439, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:33:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1440, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 08:33:39', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1441, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 09:31:18', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1442, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 09:31:18', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1443, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 09:35:04', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1444, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 09:36:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1445, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 09:36:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1446, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 10:00:38', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1447, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 10:00:38', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1448, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1449, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1450, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1451, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1452, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1453, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:35:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1454, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:59:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1455, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:59:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1456, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:59:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1457, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 10:59:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1458, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:20:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1459, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:20:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1460, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:20:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1461, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:20:17', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1462, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:25:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1463, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:25:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1464, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:25:59', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1465, '/auth/signin', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-25 11:26:03', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1466, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 11:45:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1467, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 11:45:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1468, '/', '66.249.79.204', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-25 12:07:59', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1469, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:31:53', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1470, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:31:53', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1471, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:31:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1472, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:31:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1473, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:38:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1474, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 12:38:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1475, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 17:00:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1476, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 17:00:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1477, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 17:00:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1478, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 17:00:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1479, '/da', '66.249.79.205', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-25 18:06:04', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1480, '/da', '66.249.79.206', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-25 18:51:03', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1481, '/', '66.249.79.205', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-25 19:36:06', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1482, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 20:04:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1483, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 20:04:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1484, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 20:04:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1485, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-25 20:04:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1486, '/blog/endpoint-test', '66.249.79.201', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/blog/endpoint-test', '2025-05-25 20:06:03', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1487, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 20:16:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1488, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-25 20:16:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1489, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '66.249.79.206', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-05-25 21:06:02', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1490, '/erfaring', '66.249.68.134', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring', '2025-05-25 21:36:05', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1491, '/erfaring', '66.249.68.133', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring', '2025-05-25 21:36:07', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1492, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.68.131', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-05-25 23:36:05', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1493, '/', '66.249.68.131', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-26 02:28:12', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1494, '/blog/endpoint-test', '66.249.68.133', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/blog/endpoint-test', '2025-05-26 03:58:14', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1495, '/kranfoerer', '66.249.79.202', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/kranfoerer', '2025-05-26 05:36:05', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1496, '/erfaring/kroell-kran', '66.249.79.205', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kroell-kran', '2025-05-26 07:36:03', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1497, '/erfaring/ny--carlsberg-vej-copenhagen', '66.249.68.132', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/ny--carlsberg-vej-copenhagen', '2025-05-26 09:06:03', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1498, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:34:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1499, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:34:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1500, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:34:37', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1501, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:34:37', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1502, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:35:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1503, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 09:35:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1504, '/lej-en-kranforer', '66.249.65.172', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-26 12:06:04', 'US', 'Tulsa', 'Oklahoma', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1505, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 13:19:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1506, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 13:19:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1507, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 13:19:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1508, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 13:19:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1509, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 17:48:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1510, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 17:48:19', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1511, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:48:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1512, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:48:56', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1513, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone17,1;FBMD/iPhone;FBSN/iOS;FBSV/18.4;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:49:51', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1514, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone17,1;FBMD/iPhone;FBSN/iOS;FBSV/18.4;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:49:51', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1515, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone17,1;FBMD/iPhone;FBSN/iOS;FBSV/18.4;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:51:06', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1516, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone17,1;FBMD/iPhone;FBSN/iOS;FBSV/18.4;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:51:06', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1517, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:51:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1518, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:51:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1519, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 17:51:50', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1520, '/', '217.74.152.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 17:51:50', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.4.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1521, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:55:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1522, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-26 17:55:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1523, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 18:04:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1524, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 18:04:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1525, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:04:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1526, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:04:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1527, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:04:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1528, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:04:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1529, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:35:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1530, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-26 19:35:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1531, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 06:24:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1532, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 06:24:48', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1533, '/', '203.189.178.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-27 09:05:16', 'IN', 'Pimpri', 'Maharashtra', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1534, '/', '203.189.178.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-27 09:05:17', 'IN', 'Pimpri', 'Maharashtra', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1535, '/', '40.77.189.124', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm) Chrome/112.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-27 09:17:39', 'US', 'Chicago', 'Illinois', 'desktop', NULL, 'Chrome 112.0.0.0', 'ksrcranes.dk'),
(1536, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:02:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1537, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:02:58', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1538, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:04:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1539, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:04:43', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1540, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:04:44', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1541, '/kranfoerer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:04:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1542, '/kranfoerer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:04:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1543, '/lej-en-kranforer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:04:53', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1544, '/lej-en-kranforer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:04:53', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1545, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:05:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1546, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:05:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1547, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:09:44', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1548, '/da', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://www.google.com/', '2025-05-27 10:12:39', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'google.com'),
(1549, '/da', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://www.google.com/', '2025-05-27 10:12:39', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'google.com'),
(1550, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/da', '2025-05-27 10:13:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1551, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/da', '2025-05-27 10:13:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1552, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/da', '2025-05-27 10:14:35', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1553, '/lej-en-kranforer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:14:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1554, '/lej-en-kranforer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:14:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1555, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:16:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1556, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:16:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1557, '/kranfoerer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:16:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1558, '/kranfoerer', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:16:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1559, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:17:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1560, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:17:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1561, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:18:49', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1562, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:18:51', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1563, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:19:21', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1564, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:19:22', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1565, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/kranfoerer', '2025-05-27 10:22:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1566, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:31:54', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1567, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:31:55', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1568, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:32:02', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1569, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:32:13', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1570, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:32:17', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1571, '/da', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-27 10:32:37', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1572, '/da', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-05-27 10:32:37', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1573, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:33:52', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1574, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 10:34:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1575, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:35:46', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1576, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:37:46', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1577, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:37:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1578, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:37:50', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1579, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:40:46', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1580, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:40:46', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1581, '/', '212.130.0.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-27 10:41:10', 'DK', 'Stenløse', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1582, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:48:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1583, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:48:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1584, '/', '212.237.135.48', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-27 10:50:22', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1585, '/erfaring/marta-christensens-vej-oerestad-copenhagen', '66.249.73.237', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/marta-christensens-vej-oerestad-copenhagen', '2025-05-27 15:56:45', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1586, '/erfaring/andrea-brochmanns--gade-copenhagen-', '66.249.73.237', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/andrea-brochmanns--gade-copenhagen-', '2025-05-27 16:14:38', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1587, '/erfaring/lykkebaekvej-koege', '66.249.73.229', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/lykkebaekvej-koege', '2025-05-27 18:09:20', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1588, '/erfaring/postbyen-koebenhavn-komplekst-kranarbejde-med-liebherr-taarnkraner', '66.249.73.235', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/postbyen-koebenhavn-komplekst-kranarbejde-med-liebherr-taarnkraner', '2025-05-27 19:25:08', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1589, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 21:29:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1590, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 21:29:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1591, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 21:29:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1592, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-27 21:29:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1593, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-27 21:31:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'google.com'),
(1594, '/lej-en-kranforer', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://www.google.com/', '2025-05-27 21:31:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'google.com'),
(1595, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:31:34', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1596, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:31:34', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1597, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:31:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1598, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:31:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1599, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:43:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1600, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/lej-en-kranforer', '2025-05-27 21:43:17', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1601, '/cookie-politik', '66.249.73.236', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/cookie-politik', '2025-05-27 21:59:13', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1602, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:12:14', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1603, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:12:15', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1604, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:13:15', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1605, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:13:15', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1606, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:13:19', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1607, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 06:13:19', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1608, '/', '185.104.138.77', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-28 06:30:15', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1609, '/', '185.104.138.77', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-28 06:30:16', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1610, '/', '185.104.138.77', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-28 06:30:19', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1611, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 08:06:14', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1612, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 08:06:14', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1613, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 08:06:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1614, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 08:06:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1615, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:04:15', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1616, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:04:16', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1617, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:53:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1618, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:53:19', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1619, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 09:53:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1620, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 09:53:37', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1621, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:53:41', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1622, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-05-28 09:53:41', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1623, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 10:05:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1624, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 10:05:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1625, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:11:15', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1626, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:11:15', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1627, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:11:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1628, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:11:17', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1629, '/auth/signin', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:12:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1630, '/auth/signin', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) Gecko/20100101 Firefox/138.0', 'https://ksrcranes.dk/', '2025-05-28 10:12:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 138.0', 'ksrcranes.dk'),
(1631, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 10:44:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1632, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-28 10:44:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1633, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.bing.com/', '2025-05-28 13:17:57', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'bing.com'),
(1634, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.bing.com/', '2025-05-28 13:17:57', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'bing.com'),
(1635, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-28 13:21:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1636, '/', '212.237.135.55', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-05-28 13:21:00', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1637, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-28 13:26:16', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1638, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-28 13:26:16', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1639, '/', '62.198.134.63', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-28 13:31:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Samsung Internet 27.0', 'ksrcranes.dk'),
(1640, '/', '62.198.134.63', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-28 13:31:54', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Samsung Internet 27.0', 'ksrcranes.dk'),
(1641, '/', '62.198.134.63', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-28 13:31:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Samsung Internet 27.0', 'ksrcranes.dk'),
(1642, '/', '62.198.134.63', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-05-28 13:31:59', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Samsung Internet 27.0', 'ksrcranes.dk'),
(1643, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 14:35:54', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1644, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 14:35:54', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1645, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 14:35:58', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1646, '/', '66.249.73.229', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-28 14:36:20', 'US', 'Dallas', 'Texas', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1647, '/', '66.249.73.230', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/136.0.7103.92 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-05-28 14:36:20', 'US', 'Dallas', 'Texas', 'desktop', NULL, 'Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1648, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 14:38:16', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1649, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:24:23', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1650, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:24:23', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1651, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:24:28', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1652, '/', '80.62.117.153', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.61 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-28 15:24:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(1653, '/', '80.62.117.153', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.61 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-05-28 15:24:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(1654, '/', '2a03:2880:11ff:73::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0', 'https://www.facebook.com/', '2025-05-28 15:27:10', 'US', 'Fort Worth', 'Texas', 'desktop', 'Windows 10', 'Edge 134.0.0.0', 'facebook.com'),
(1655, '/', '2a03:2880:11ff:71::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0', 'https://www.facebook.com/', '2025-05-28 15:27:16', 'US', 'Fort Worth', 'Texas', 'desktop', 'Windows 10', 'Edge 134.0.0.0', 'facebook.com'),
(1656, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:43:43', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1657, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:43:43', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1658, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:52:53', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1659, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 15:52:53', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1660, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 16:46:53', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1661, '/', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 16:46:53', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1662, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 16:46:57', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1663, '/auth/signin', '37.96.124.109', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-28 16:46:57', 'DK', 'Haslev', 'Zealand', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1664, '/da', '2a02:aa7:4118:5711:f563:6577:d78a:292a', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-28 18:08:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'google.com'),
(1665, '/da', '2a02:aa7:4118:5711:f563:6577:d78a:292a', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-28 18:08:36', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'google.com'),
(1666, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 05:31:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1667, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 05:31:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1668, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 05:48:50', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1669, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 05:48:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1670, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 06:14:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1671, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 06:14:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1672, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 06:28:26', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1673, '/lej-en-kranforer', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'http://localhost:3000/lej-en-kranforer', '2025-05-29 06:28:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'localhost'),
(1674, '/', '83.137.6.174', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'android-app://com.linkedin.android/', '2025-05-29 07:32:57', 'DK', 'Silkeborg', 'Central Jutland', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'com.linkedin.android'),
(1675, '/', '83.137.6.174', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'android-app://com.linkedin.android/', '2025-05-29 07:32:57', 'DK', 'Silkeborg', 'Central Jutland', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'com.linkedin.android'),
(1676, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 08:44:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1677, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 08:44:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1678, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.1579.3', 'https://www.linkedin.com/', '2025-05-29 09:30:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'LinkedIn', 'linkedin.com'),
(1679, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.1579.3', 'https://www.linkedin.com/', '2025-05-29 09:30:12', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'LinkedIn', 'linkedin.com'),
(1680, '/lej-en-kranforer', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.1579.3', 'https://ksrcranes.dk/', '2025-05-29 09:30:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'LinkedIn', 'ksrcranes.dk'),
(1681, '/lej-en-kranforer', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [LinkedInApp]/9.31.1579.3', 'https://ksrcranes.dk/', '2025-05-29 09:30:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'LinkedIn', 'ksrcranes.dk'),
(1682, '/', '66.249.65.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-05-29 12:51:26', 'US', 'Oklahoma City', 'Oklahoma', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1683, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-29 15:08:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1684, '/privacy-policy', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-29 15:08:46', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1685, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-29 15:11:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1686, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-29 15:11:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1687, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 15:11:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1688, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 15:11:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1689, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 17:02:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1690, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 17:02:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1691, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 17:03:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1692, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 17:03:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1693, '/da', '66.249.65.174', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-05-29 17:29:25', 'US', 'Tulsa', 'Oklahoma', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1694, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 18:41:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1695, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-29 18:41:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 136.0.7103.91', 'ksrcranes.dk'),
(1696, '/auth/signin', '66.249.65.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/auth/signin', '2025-05-29 18:59:26', 'US', 'Oklahoma City', 'Oklahoma', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1697, '/', '80.62.117.108', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-29 19:00:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'google.com'),
(1698, '/', '80.62.117.108', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36', 'https://www.google.com/', '2025-05-29 19:00:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 136.0.0.0', 'google.com'),
(1699, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-29 21:35:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1700, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-29 21:35:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1701, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-29 21:35:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1702, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-29 21:35:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1703, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:11:42', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1704, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:11:42', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1705, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone14,3;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:12:12', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(1706, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone14,3;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:12:12', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(1707, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:12:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1708, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/508.0.0.40.106;FBBV/736813312;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/', '2025-05-30 08:12:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 508.0.0.40.106', 'ksrcranes.dk'),
(1709, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 08:12:15', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1710, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 08:12:15', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1711, '/', '212.237.135.30', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.bing.com/', '2025-05-30 10:40:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'bing.com'),
(1712, '/', '212.237.135.30', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.bing.com/', '2025-05-30 10:40:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'bing.com'),
(1713, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:41:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1714, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:41:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1715, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:41:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1716, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:41:37', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1717, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:42:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1718, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:42:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1719, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:42:31', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1720, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 11:42:31', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1721, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 11:53:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1722, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 11:53:29', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1723, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:12:43', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1724, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:12:44', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1725, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:12:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1726, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:12:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1727, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:13:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1728, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 12:13:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1729, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 12:31:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1730, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 12:31:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1731, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 15:00:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1732, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 15:00:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1733, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 15:20:29', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1734, '/', '217.74.152.140', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 15:20:29', 'DK', 'Odense', 'South Denmark', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1735, '/kranfoerer', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-05-30 15:36:44', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1736, '/kranfoerer', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-05-30 15:36:45', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1737, '/', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-30 15:37:28', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1738, '/', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-30 15:37:28', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1739, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-30 15:38:03', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1740, '/', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-30 15:38:18', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1741, '/', '85.191.213.69', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-05-30 15:38:18', 'DK', 'Aalborg', 'North Denmark', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1742, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 18:45:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1743, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-30 18:45:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1744, '/', '2a05:f6c2:37e4:0:f152:1cc4:1518:91', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 20:04:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1745, '/', '2a05:f6c2:37e4:0:f152:1cc4:1518:91', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-30 20:04:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1746, '/', '207.46.13.127', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm) Chrome/116.0.1938.76 Safari/537.36', NULL, '2025-05-30 21:21:04', 'US', 'Moses Lake', 'Washington', 'desktop', NULL, 'Chrome 116.0.1938.76', NULL),
(1747, '/', '2a05:f6c2:37e4:0:c984:3273:5b14:cc3e', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 03:19:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1748, '/', '2a05:f6c2:37e4:0:c984:3273:5b14:cc3e', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 03:19:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1749, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-31 06:05:05', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1750, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-05-31 06:05:06', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1751, '/vilkar-og-betingelser', '66.249.77.137', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-31 11:43:29', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1752, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 19:57:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1753, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 19:57:11', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1754, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:06:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1755, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:06:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1756, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:18:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1757, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:18:10', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1758, '/auth/signin', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:18:13', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1759, '/auth/signin', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:18:13', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1760, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:19:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1761, '/', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:19:01', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1762, '/privacy-policy', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:19:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1763, '/privacy-policy', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-05-31 20:19:08', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1764, '/lej-en-kranforer', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-31 20:20:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1765, '/lej-en-kranforer', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/privacy-policy', '2025-05-31 20:20:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1766, '/vilkar-og-betingelser', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-31 20:20:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1767, '/vilkar-og-betingelser', '37.96.104.199', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-05-31 20:20:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1768, '/', '66.249.75.171', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-05-31 21:44:34', 'US', 'Council Bluffs', 'Iowa', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1769, '/', '149.40.52.214', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/109.0.5414.46 Safari/537.36', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-31 22:25:51', 'AT', 'Vienna', 'Vienna', 'desktop', 'Linux', 'Chrome Headless 109.0.5414.46', 'coral-app-ieeur.ondigitalocean.app'),
(1770, '/', '149.40.52.214', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/109.0.5414.46 Safari/537.36', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-05-31 22:25:54', 'AT', 'Vienna', 'Vienna', 'desktop', 'Linux', 'Chrome Headless 109.0.5414.46', 'coral-app-ieeur.ondigitalocean.app'),
(1771, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-01 07:07:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1772, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-01 07:07:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1773, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-01 07:07:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1774, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-01 07:07:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1775, '/', '66.249.66.198', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/136.0.7103.92 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 13:22:39', 'US', 'Charlotte', 'North Carolina', 'desktop', NULL, 'Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1776, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 13:38:59', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1777, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 13:38:59', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1778, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 14:58:39', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1779, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 14:58:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1780, '/', '34.72.176.129', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:27', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(1781, '/', '34.72.176.129', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:28', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(1782, '/', '205.169.39.13', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.132 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:29', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 117.0.5938.132', 'ksrcranes.dk'),
(1783, '/', '205.169.39.13', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.132 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:30', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 117.0.5938.132', 'ksrcranes.dk'),
(1784, '/', '205.169.39.150', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:40', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 79.0.3945.79', 'ksrcranes.dk'),
(1785, '/', '205.169.39.150', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 20:39:40', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 79.0.3945.79', 'ksrcranes.dk'),
(1786, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 21:32:22', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(1787, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-01 21:32:23', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(1788, '/', '34.123.170.104', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-01 21:33:31', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(1789, '/', '34.123.170.104', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-01 21:33:32', 'US', 'Council Bluffs', 'Iowa', 'desktop', 'Linux', 'Chrome Headless 125.0.6422.60', 'ksrcranes.dk'),
(1790, '/', '205.169.39.4', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.132 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-01 21:33:36', 'US', 'Dallas', 'Texas', 'desktop', 'Windows 10', 'Chrome 117.0.5938.132', 'ksrcranes.dk'),
(1791, '/', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-02 01:53:07', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1792, '/', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-02 01:53:07', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1793, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-06-02 01:53:09', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1794, '/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/blog/arbejdet-med-taarnkraner-vigtige-sikkerhedsregler-om-vinteren', '2025-06-02 01:53:09', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1795, '/kranfoerer', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:09', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1796, '/kranfoerer', '57.129.4.123', '\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36\"', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:10', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1797, '/auth/signin', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/auth/signin', '2025-06-02 01:53:11', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1798, '/auth/signin', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/auth/signin', '2025-06-02 01:53:11', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1799, '/lej-en-kranforer', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-06-02 01:53:12', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1800, '/lej-en-kranforer', '51.75.162.18', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/lej-en-kranforer', '2025-06-02 01:53:12', 'GB', 'Bexley', 'England', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1801, '/', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-02 01:53:13', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1802, '/erfaring', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/erfaring', '2025-06-02 01:53:13', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1803, '/', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/', '2025-06-02 01:53:14', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1804, '/erfaring', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/erfaring', '2025-06-02 01:53:14', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1805, '/vilkar-og-betingelser', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 01:53:15', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1806, '/auth/signin', '54.37.10.247', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:16', 'FR', 'Strasbourg', 'Grand Est', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1807, '/vilkar-og-betingelser', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 01:53:16', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1808, '/auth/signin', '54.37.10.247', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:16', 'FR', 'Strasbourg', 'Grand Est', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1809, '/privacy-policy', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/privacy-policy', '2025-06-02 01:53:17', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1810, '/privacy-policy', '57.129.4.123', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/privacy-policy', '2025-06-02 01:53:17', 'DE', 'Frankfurt am Main', 'Hesse', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1811, '/faq', '54.37.10.247', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/faq', '2025-06-02 01:53:19', 'FR', 'Strasbourg', 'Grand Est', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1812, '/auth/signin', '167.114.3.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:19', 'CA', 'Montréal', 'Quebec', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1813, '/faq', '54.37.10.247', '\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36\"', 'https://www.ksrcranes.dk/faq', '2025-06-02 01:53:20', 'FR', 'Strasbourg', 'Grand Est', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1814, '/auth/signin', '167.114.3.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 'https://www.ksrcranes.dk/kranfoerer', '2025-06-02 01:53:20', 'CA', 'Montréal', 'Quebec', 'desktop', 'Windows 10', 'Chrome 102.0.0.0', 'ksrcranes.dk'),
(1815, '/lej-en-kranforer', '66.249.66.196', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-02 03:08:39', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1816, '/', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-06-02 03:18:43', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1817, '/', '66.249.66.13', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-06-02 06:08:52', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1818, '/', '62.198.143.224', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-06-02 06:18:19', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1819, '/', '62.198.143.224', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/', '2025-06-02 06:18:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1820, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 07:17:22', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1821, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 07:17:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1822, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 07:17:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1823, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 07:17:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1824, '/da', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-02 08:56:59', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1825, '/da', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-02 08:57:00', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1826, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-02 08:57:08', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1827, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-02 08:57:08', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1828, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:04:05', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1829, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:04:05', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1830, '/kranfoerer', '66.249.66.77', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/kranfoerer', '2025-06-02 09:08:39', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1831, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 09:17:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1832, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 09:17:04', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1833, '/', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:24:17', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1834, '/', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:24:18', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1835, '/', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:25:28', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1836, '/', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 09:25:28', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1837, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:19:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1838, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:19:45', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1839, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:20:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1840, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:20:58', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1841, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:33:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1842, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:33:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1843, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:39:05', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1844, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:39:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1845, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:39:08', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1846, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:40:57', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1847, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:41:02', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1848, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:41:02', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1849, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:44:41', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1850, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 10:44:42', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1851, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:47:50', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1852, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:47:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1853, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:48:15', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1854, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:48:16', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1855, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:48:25', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1856, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:48:27', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1857, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 10:48:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1858, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 12:06:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1859, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 12:06:32', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1860, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 12:06:33', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1861, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 12:06:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1862, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 12:07:35', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1863, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 12:07:35', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1864, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-06-02 12:08:48', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'l.facebook.com'),
(1865, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-06-02 12:08:48', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'l.facebook.com'),
(1866, '/vilkar-og-betingelser', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.125 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-06-02 12:08:51', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(1867, '/vilkar-og-betingelser', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.125 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'http://m.facebook.com/', '2025-06-02 12:08:51', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'm.facebook.com'),
(1868, '/vilkar-og-betingelser', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 12:09:01', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1869, '/vilkar-og-betingelser', '87.49.42.29', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 12:09:01', 'DK', 'Hillerød', 'Capital Region', 'mobile', 'Android 10', 'Mobile Chrome 134.0.0.0', 'ksrcranes.dk'),
(1870, '/vilkar-og-betingelser', '2a03:2880:30ff:43::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0', 'https://www.facebook.com/', '2025-06-02 12:09:12', 'SE', 'Luleå', 'Norrbotten', 'desktop', 'Windows 10', 'Edge 134.0.0.0', 'facebook.com'),
(1871, '/vilkar-og-betingelser', '2a03:2880:30ff:9::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0', 'https://www.facebook.com/', '2025-06-02 12:09:14', 'SE', 'Luleå', 'Norrbotten', 'desktop', 'Windows 10', 'Edge 134.0.0.0', 'facebook.com'),
(1872, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-06-02 12:09:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'l.facebook.com'),
(1873, '/vilkar-og-betingelser', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://l.facebook.com/', '2025-06-02 12:09:34', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'l.facebook.com'),
(1874, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 14:01:30', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1875, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 14:01:31', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1876, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-02 14:46:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1877, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-02 14:46:25', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1878, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-02 14:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1879, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://coral-app-ieeur.ondigitalocean.app/', '2025-06-02 14:46:30', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'coral-app-ieeur.ondigitalocean.app'),
(1880, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 14:47:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1881, '/', '37.96.125.60', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 14:47:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1882, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 15:36:34', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1883, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 15:36:35', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1884, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 16:48:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1885, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 16:48:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1886, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:51:46', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1887, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:51:47', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1888, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:52:52', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1889, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:52:53', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1890, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:54:07', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1891, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:54:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1892, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:54:10', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1893, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:54:34', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1894, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:57:23', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1895, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:57:24', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1896, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:57:56', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1897, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:58:28', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1898, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:58:50', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1899, '/', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/', '2025-06-02 16:58:51', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(1900, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 20:57:56', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(1901, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-02 20:58:00', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(1902, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 21:59:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1903, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 21:59:15', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1904, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 21:59:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1905, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-02 21:59:18', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1906, '/vilkar-og-betingelser', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 22:00:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1907, '/vilkar-og-betingelser', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-02 22:00:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1908, '/privacy-policy', '66.249.66.168', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/privacy-policy', '2025-06-02 22:11:49', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1909, '/erfaring/papiroeen-copenhagen', '66.249.66.197', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/papiroeen-copenhagen', '2025-06-02 23:41:49', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1910, '/erfaring/postbyen---copenhagen-', '66.249.66.196', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/postbyen---copenhagen-', '2025-06-03 01:11:52', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1911, '/da', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-03 08:43:55', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(1912, '/da', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-03 08:43:55', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(1913, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 08:44:29', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1914, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 08:44:29', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1915, '/kranfoerer', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 08:45:54', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1916, '/kranfoerer', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 08:45:54', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1917, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-06-03 08:53:26', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1918, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/kranfoerer', '2025-06-03 08:53:26', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1919, '/lej-en-kranforer', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 08:54:23', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1920, '/lej-en-kranforer', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 08:54:24', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1921, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 08:54:26', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1922, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 08:54:26', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1923, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 08:54:30', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1924, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 09:04:05', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1925, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 09:04:07', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1926, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 09:14:19', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1927, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-03 09:18:46', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1928, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 09:18:52', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1929, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 09:18:52', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1930, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 09:18:59', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1931, '/erfaring/kroell-kran', '66.249.66.40', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/erfaring/kroell-kran', '2025-06-03 09:23:38', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1932, '/', '66.249.66.32', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-06-03 09:46:40', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1933, '/erfaring/world-trade-center-ballerup-', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:14', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1934, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:17', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1935, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:21', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1936, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:23', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1937, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:25', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1938, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:25', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1939, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:03:32', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1940, '/da', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-03 10:16:43', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1941, '/da', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-03 10:16:43', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(1942, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/da', '2025-06-03 10:16:49', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1943, '/', '195.215.233.178', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/da', '2025-06-03 10:16:49', 'DK', 'Tranbjerg', 'Central Jutland', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(1944, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:45:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1945, '/', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:45:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1946, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:45:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1947, '/auth/signin', '37.96.125.60', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 10:45:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1948, '/da', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-03 10:56:12', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1949, '/da', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-03 10:56:12', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'google.com'),
(1950, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 11:00:28', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1951, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 11:00:28', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1952, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 11:06:37', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1953, '/', '78.143.101.90', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-03 11:26:04', 'DK', 'Århus', 'Central Jutland', 'desktop', 'Windows 10', 'Chrome 136.0.0.0', 'ksrcranes.dk'),
(1954, '/', '66.249.66.15', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/136.0.7103.92 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 12:24:46', 'US', 'Charlotte', 'North Carolina', 'desktop', NULL, 'Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1955, '/privacy-policy', '66.249.66.161', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/privacy-policy', '2025-06-03 12:46:55', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1956, '/', '80.208.68.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1957, '/', '80.208.68.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1958, '/', '80.208.68.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1959, '/', '80.208.68.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:04', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1960, '/', '80.208.68.129', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:08', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1961, '/', '52.174.29.70', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:18', 'NL', 'Amsterdam', 'North Holland', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(1962, '/', '52.174.29.70', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:37:20', 'NL', 'Amsterdam', 'North Holland', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(1963, '/', '52.174.29.70', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-03 18:38:05', 'NL', 'Amsterdam', 'North Holland', 'desktop', 'Windows 10', 'Chrome 131.0.0.0', 'ksrcranes.dk'),
(1964, '/da', '66.249.66.199', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-06-03 19:15:27', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1965, '/erfaring/lykkebaekvej-koege', '66.249.66.34', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/lykkebaekvej-koege', '2025-06-03 19:21:21', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1966, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:56:20', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1967, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:56:21', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1968, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:56:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1969, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:56:26', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1970, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:57:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1971, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-03 19:57:09', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(1972, '/erfaring/else-alfelts--vej-oerestad-copenhagen', '66.249.66.200', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/else-alfelts--vej-oerestad-copenhagen', '2025-06-03 20:06:21', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1973, '/da', '66.249.66.14', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/da', '2025-06-03 20:45:27', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1974, '/erfaring/postbyen-koebenhavn-komplekst-kranarbejde-med-liebherr-taarnkraner', '66.249.66.162', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/erfaring/postbyen-koebenhavn-komplekst-kranarbejde-med-liebherr-taarnkraner', '2025-06-03 20:51:48', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(1975, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-04 08:15:29', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(1976, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-04 08:15:30', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(1977, '/da', '2a13:8a02:6758:1800:2ce5:caa7:5e01:d884', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 08:39:59', 'DK', 'Aalborg', 'North Denmark', 'tablet', 'Android 10', 'Chrome 136.0.0.0', 'google.com'),
(1978, '/da', '2a13:8a02:6758:1800:2ce5:caa7:5e01:d884', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 08:40:01', 'DK', 'Aalborg', 'North Denmark', 'tablet', 'Android 10', 'Chrome 136.0.0.0', 'google.com'),
(1979, '/', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:50:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1980, '/', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:50:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1981, '/kranfoerer', '80.199.161.148', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 08:52:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(1982, '/kranfoerer', '80.199.161.148', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 08:52:27', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(1983, '/auth/signin', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:56:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1984, '/auth/signin', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:56:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1985, '/', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:57:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1986, '/', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:57:45', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1987, '/kranfoerer', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:57:49', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1988, '/kranfoerer', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:57:49', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1989, '/erfaring', '37.96.101.46', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 08:57:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(1990, '/erfaring', '80.62.117.5', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.125 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'https://l.facebook.com/', '2025-06-04 08:58:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'l.facebook.com'),
(1991, '/erfaring', '80.62.117.5', 'Mozilla/5.0 (Linux; Android 14; SM-S928B Build/UP1A.231005.007; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/136.0.7103.125 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/499.0.0.56.109;]', 'https://l.facebook.com/', '2025-06-04 08:58:35', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'Android 14', 'Facebook 499.0.0.56.109', 'l.facebook.com'),
(1992, '/erfaring', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/erfaring?fbclid=IwZXh0bgNhZW0CMTEAAR5vUxY6-8pu9n43_taBdnzZ0hQR0QT0hhelg_88PZvXj2zri9tfa2TvJdiZ9A_aem_st02neOukkACJWuhPYb5lw', '2025-06-04 09:00:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(1993, '/erfaring', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/erfaring?fbclid=IwZXh0bgNhZW0CMTEAAR5vUxY6-8pu9n43_taBdnzZ0hQR0QT0hhelg_88PZvXj2zri9tfa2TvJdiZ9A_aem_st02neOukkACJWuhPYb5lw', '2025-06-04 09:00:40', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(1994, '/erfaring/papiroeen-copenhagen', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone15,2;FBMD/iPhone;FBSN/iOS;FBSV/18.5;FBSS/3;FBCR/;FBID/phone;FBLC/pl_PL;FBOP/80]', 'https://ksrcranes.dk/erfaring/papiroeen-copenhagen', '2025-06-04 09:01:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(1995, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-04 09:01:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(1996, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-04 09:01:41', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com');
INSERT INTO `PageVisit` (`id`, `path`, `ip`, `userAgent`, `referer`, `timestamp`, `country`, `city`, `region`, `deviceType`, `os`, `browser`, `refererDomain`) VALUES
(1997, '/erfaring', '2a03:2880:ff:5::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36', 'https://www.facebook.com/', '2025-06-04 09:01:49', 'US', 'Prineville', 'Oregon', 'desktop', 'Windows 10', 'Chrome 125.0.0.0', 'facebook.com'),
(1998, '/erfaring', '2a03:2880:ff:5::', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36', 'https://www.facebook.com/', '2025-06-04 09:01:54', 'US', 'Prineville', 'Oregon', 'desktop', 'Windows 10', 'Chrome 125.0.0.0', 'facebook.com'),
(1999, '/da', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://www.google.com/', '2025-06-04 09:07:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'google.com'),
(2000, '/da', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://www.google.com/', '2025-06-04 09:07:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'google.com'),
(2001, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:14:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2002, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:14:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2003, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:21:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2004, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:21:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2005, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:21:29', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2006, '/auth/signin', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:23:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2007, '/auth/signin', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:23:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2008, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:23:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2009, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:23:16', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2010, '/vilkar-og-betingelser', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-04 09:25:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2011, '/vilkar-og-betingelser', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-04 09:25:27', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2012, '/auth/signin', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-04 09:25:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2013, '/auth/signin', '37.96.101.46', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/vilkar-og-betingelser', '2025-06-04 09:25:31', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2014, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:28:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2015, '/', '212.237.135.51', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0', 'https://ksrcranes.dk/', '2025-06-04 09:28:25', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Firefox 139.0', 'ksrcranes.dk'),
(2016, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:32:38', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2017, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:32:39', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2018, '/lej-en-kranforer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-04 09:32:44', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2019, '/lej-en-kranforer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-04 09:32:44', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2020, '/kranfoerer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-04 09:35:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2021, '/kranfoerer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/lej-en-kranforer', '2025-06-04 09:35:28', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2022, '/lej-en-kranforer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-04 09:35:48', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2023, '/lej-en-kranforer', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/da', '2025-06-04 09:35:48', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2024, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:35:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2025, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:35:55', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2026, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:37:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2027, '/da', '165.1.235.212', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://www.google.com/', '2025-06-04 09:37:23', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Chrome 137.0.0.0', 'google.com'),
(2028, '/erfaring', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 10:12:11', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2029, '/erfaring', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 10:12:11', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2030, '/da', '5.186.40.93', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 11:24:02', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2031, '/da', '5.186.40.93', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 11:24:03', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2032, '/', '5.186.40.93', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/da', '2025-06-04 11:24:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(2033, '/', '5.186.40.93', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/da', '2025-06-04 11:24:10', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(2034, '/', '5.186.40.93', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://ksrcranes.dk/da', '2025-06-04 11:24:20', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'ksrcranes.dk'),
(2035, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:35:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2036, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:35:23', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2037, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:35:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2038, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:35:28', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2039, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:39:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2040, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:39:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2041, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:51:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2042, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 12:51:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2043, '/', '66.249.66.197', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://ksrcranes.dk/', '2025-06-04 12:59:42', 'US', 'Charlotte', 'North Carolina', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(2044, '/', '31.3.72.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 13:44:20', NULL, NULL, NULL, 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2045, '/', '31.3.72.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 13:44:26', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2046, '/', '31.3.72.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 13:44:53', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2047, '/', '31.3.72.106', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0', 'https://www.google.com/', '2025-06-04 13:54:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 136.0.0.0', 'google.com'),
(2048, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:25:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2049, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:25:06', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2050, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:26:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2051, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:26:07', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2052, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:26:55', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2053, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:27:02', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2054, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:27:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2055, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 14:27:03', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2056, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 15:32:52', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2057, '/', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 15:32:53', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2058, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 15:32:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2059, '/auth/signin', '37.96.104.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 15:32:57', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2060, '/test/zenegy', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/test/zenegy', '2025-06-04 16:07:32', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(2061, '/test/zenegy', '::1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'http://localhost:3000/test/zenegy', '2025-06-04 16:07:33', 'Local', NULL, NULL, 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'localhost'),
(2062, '/test/zenegy', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 16:19:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2063, '/test/zenegy', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 16:19:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2064, '/test/zenegy', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 16:23:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2065, '/test/zenegy', '37.96.104.155', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 16:23:07', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2066, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 18:58:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2067, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-04 18:58:51', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2068, '/test/zenegy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 19:07:43', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2069, '/test/zenegy', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/test/zenegy', '2025-06-04 19:07:42', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2070, '/erfaring', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 19:08:38', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2071, '/erfaring', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 19:08:39', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2072, '/', '207.46.13.102', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm) Chrome/116.0.1938.76 Safari/537.36', NULL, '2025-06-04 19:34:46', 'US', 'Moses Lake', 'Washington', 'desktop', NULL, 'Chrome 116.0.1938.76', NULL),
(2073, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 21:07:38', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(2074, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 21:07:40', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(2075, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 21:20:08', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(2076, '/', '54.174.140.70', 'Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/131.0.6778.33 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-04 21:20:09', 'US', 'Ashburn', 'Virginia', 'desktop', 'Linux aarch64', 'Chrome Headless 131.0.6778.33', 'ksrcranes.dk'),
(2077, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-05 07:29:50', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2078, '/', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-05 07:29:50', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2079, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-05 07:29:54', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2080, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36', 'https://ksrcranes.dk/', '2025-06-05 07:29:54', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'macOS 10.15.7', 'Chrome 137.0.0.0', 'ksrcranes.dk'),
(2081, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 14:52:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2082, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 14:52:32', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2083, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 14:52:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2084, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 14:52:47', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2085, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 22:54:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2086, '/', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 22:54:00', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2087, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 22:58:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2088, '/auth/signin', '80.71.142.123', 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/137.0.7151.51 Mobile/15E148 Safari/604.1', 'https://ksrcranes.dk/', '2025-06-05 22:58:05', 'DK', 'Copenhagen', 'Capital Region', 'mobile', 'iOS 18.5.0', 'Mobile Chrome 137.0.7151.51', 'ksrcranes.dk'),
(2089, '/', '66.249.68.133', 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.7103.92 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', 'https://www.ksrcranes.dk/', '2025-06-06 00:45:23', 'US', 'The Dalles', 'Oregon', 'mobile', 'Android 6.0.1', 'Mobile Chrome 136.0.7103.92', 'ksrcranes.dk'),
(2090, '/', '80.197.149.2', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone14,4;FBMD/iPhone;FBSN/iOS;FBSV/16.3.1;FBSS/3;FBCR/;FBID/phone;FBLC/en_GB;FBOP/80]', 'https://ksrcranes.dk/', '2025-06-06 08:40:58', 'DK', 'Albertslund', 'Capital Region', 'mobile', 'iOS 16.3.1', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(2091, '/', '80.197.149.2', 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/509.0.0.52.108;FBBV/740376955;FBDV/iPhone14,4;FBMD/iPhone;FBSN/iOS;FBSV/16.3.1;FBSS/3;FBCR/;FBID/phone;FBLC/en_GB;FBOP/80]', 'https://ksrcranes.dk/', '2025-06-06 08:40:58', 'DK', 'Albertslund', 'Capital Region', 'mobile', 'iOS 16.3.1', 'Facebook 509.0.0.52.108', 'ksrcranes.dk'),
(2092, '/', '212.237.135.58', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-06 09:15:13', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(2093, '/', '212.237.135.58', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-06 09:15:14', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(2094, '/erfaring/world-trade-center-ballerup-', '212.237.135.58', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-06 09:17:40', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(2095, '/', '212.237.135.58', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-06 09:19:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com'),
(2096, '/', '212.237.135.58', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36 Edg/137.0.0.0', 'https://www.bing.com/', '2025-06-06 09:19:47', 'DK', 'Copenhagen', 'Capital Region', 'desktop', 'Windows 10', 'Edge 137.0.0.0', 'bing.com');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PayrollAuditLog`
--

CREATE TABLE `PayrollAuditLog` (
  `id` int NOT NULL,
  `batch_id` int DEFAULT NULL,
  `action` enum('batch_created','batch_approved','batch_rejected','batch_cancelled','sync_started','sync_completed','sync_failed','entry_sent','entry_failed','config_changed','mapping_changed') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` enum('batch','entry','config','mapping') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` int DEFAULT NULL,
  `performed_by` int UNSIGNED NOT NULL,
  `performed_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `error_details` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PayrollBatchEntries`
--

CREATE TABLE `PayrollBatchEntries` (
  `id` int NOT NULL,
  `batch_id` int NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `zenegy_employee_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_days_worked` int DEFAULT '0',
  `total_hours` decimal(8,2) DEFAULT '0.00',
  `total_km` decimal(10,2) DEFAULT '0.00',
  `sync_status` enum('pending','syncing','sent','failed','skipped') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `sync_attempts` int DEFAULT '0',
  `last_sync_attempt` datetime DEFAULT NULL,
  `sync_error` text COLLATE utf8mb4_unicode_ci,
  `zenegy_response` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PayrollBatches`
--

CREATE TABLE `PayrollBatches` (
  `id` int NOT NULL,
  `batch_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `year` int NOT NULL,
  `period_number` int NOT NULL,
  `total_employees` int DEFAULT '0',
  `total_hours` decimal(10,2) DEFAULT '0.00',
  `total_km` decimal(10,2) DEFAULT '0.00',
  `status` enum('draft','ready_for_approval','approved','sent_to_zenegy','completed','failed','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `created_by` int UNSIGNED NOT NULL,
  `approved_by` int UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `sent_to_zenegy_at` datetime DEFAULT NULL,
  `zenegy_batch_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zenegy_response` json DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PayrollDailyEntries`
--

CREATE TABLE `PayrollDailyEntries` (
  `id` int NOT NULL,
  `batch_entry_id` int NOT NULL,
  `work_date` date NOT NULL,
  `hours_worked` decimal(5,2) NOT NULL,
  `kilometers` decimal(8,2) DEFAULT '0.00',
  `work_entry_ids` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PrivacyPolicy`
--

CREATE TABLE `PrivacyPolicy` (
  `id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` json NOT NULL,
  `lastUpdated` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `PrivacyPolicy`
--

INSERT INTO `PrivacyPolicy` (`id`, `title`, `content`, `lastUpdated`, `createdAt`, `updatedAt`) VALUES
(1, 'Privatlivspolitik', '{\"sections\": [{\"title\": \"1. Introduktion\", \"content\": \"<p>KSR CRANES (\\\"vi\\\", \\\"os\\\", \\\"vores\\\") respekterer dit privatliv og er forpligtet til at beskytte dine personoplysninger. Denne privatlivspolitik informerer dig om, hvordan vi behandler dine personoplysninger, når du besøger vores hjemmeside (ksrcranes.dk), og fortæller dig om dine rettigheder i henhold til databeskyttelseslovgivningen (GDPR).</p><p>Vores hjemmeside er ikke beregnet til børn, og vi indsamler ikke bevidst data vedrørende børn.</p>\"}, {\"title\": \"2. Dataansvarlig\", \"content\": \"<p>KSR CRANES er dataansvarlig for dine personoplysninger. Hvis du har spørgsmål til denne privatlivspolitik eller ønsker at udøve dine rettigheder, kan du kontakte os på:</p><p><strong>KSR CRANES</strong><br>Eskebuen 49<br>2620, Albertslund<br>Danmark</p><p><strong>E-mail:</strong> info@ksrcranes.dk<br><strong>Telefon:</strong> +45 23 26 20 64</p>\"}, {\"title\": \"3. Personoplysninger vi indsamler\", \"content\": \"<p>Vi kan indsamle og behandle følgende kategorier af personoplysninger:</p><ul><li><p><strong>Identitetsoplysninger:</strong> Navn, firmanavn.</p></li><li><p><strong>Kontaktoplysninger:</strong> E-mailadresse, telefonnummer, adresse.</p></li><li><p><strong>Tekniske oplysninger:</strong> IP-adresse, browsertype og -version, tidszoneindstilling, browser-plugin-typer og -versioner, operativsystem og platform, enhedstype. Bemærk: Din IP-adresse kan blive brugt til at udlede din omtrentlige geografiske placering (f.eks. land eller region) til analytiske formål.</p></li><li><p><strong>Brugsdata:</strong> Information om hvordan du bruger vores hjemmeside og tjenester (f.eks. besøgte sider, klik).</p></li><li><p><strong>Projektoplysninger:</strong> Når du anmoder om kranførere, indsamler vi oplysninger om dine projekter, herunder lokation, datoer og beskrivelser.</p></li></ul>\"}, {\"title\": \"4. Hvordan vi indsamler dine personoplysninger\", \"content\": \"<p>Vi anvender forskellige metoder til at indsamle personoplysninger, herunder:</p><ul><li><p><strong>Direkte interaktioner:</strong> Du kan give os dine identitets-, kontakt- og projektoplysninger ved at udfylde formularer eller korrespondere med os via post, telefon, e-mail eller på anden måde.</p></li><li><p><strong>Automatiserede teknologier:</strong> Når du interagerer med vores hjemmeside, kan vi automatisk indsamle tekniske oplysninger og brugsdata om dit udstyr og browsing-handlinger gennem cookies og lignende teknologier (se afsnit 6 om Cookies). Vi kan også modtage tekniske data om dig, hvis du besøger andre websteder, der anvender vores cookies.</p></li></ul>\"}, {\"title\": \"5. Hvordan vi bruger dine personoplysninger\", \"content\": \"<p>Vi bruger kun dine personoplysninger, når loven tillader det. Oftest vil vi bruge dine personoplysninger i følgende tilfælde:</p><ul><li><p>Hvor vi skal udføre en kontrakt, vi er ved at indgå eller har indgået med dig.</p></li><li><p>Hvor det er nødvendigt for vores legitime interesser (eller tredjeparters interesser), og dine interesser og grundlæggende rettigheder ikke tilsidesætter disse interesser.</p></li><li><p>Hvor vi skal overholde en juridisk forpligtelse.</p></li><li><p>Hvor vi har dit samtykke (f.eks. til visse typer cookies eller markedsføring).</p></li></ul><p>Vi bruger primært dine personoplysninger til:</p><ul><li><p>At levere kranførerydelser til dig og administrere kontrakten.</p></li><li><p>At besvare dine forespørgsler og kommunikere med dig.</p></li><li><p>At administrere vores forhold til dig.</p></li><li><p>At forbedre vores hjemmeside, tjenester og brugeroplevelse. Dette inkluderer analyse af tekniske oplysninger og brugsdata, herunder den omtrentlige geografiske placering udledt fra IP-adresser, for at forstå, hvordan vores hjemmeside bruges, og hvor vores besøgende kommer fra. Retsgrundlaget for denne behandling er vores legitime interesse i at vedligeholde og forbedre vores online tilstedeværelse (GDPR art. 6, stk. 1, lit. f). Til dette formål kan vi dele din IP-adresse med tredjepartsudbydere af GeoIP-tjenester for at fastslå din omtrentlige placering; vi sikrer os, at sådanne udbydere overholder gældende databeskyttelseslovgivning.</p></li><li><p>At sikre vores hjemmesides sikkerhed og forebygge svindel (legitim interesse).</p></li><li><p>At sende marketing og reklameindhold via e-mail eller andre kanaler, hvis du har givet specifikt samtykke hertil (GDPR art. 6, stk. 1, lit. a).</p></li></ul>\"}, {\"title\": \"6. Cookies\", \"content\": \"<p>Vores hjemmeside bruger cookies til at adskille dig fra andre brugere. Dette hjælper os med at give dig en god oplevelse, når du browser på vores hjemmeside, og giver os også mulighed for at forbedre vores hjemmeside. En cookie er en lille fil af bogstaver og tal, som vi gemmer på din browser eller harddisken på din computer, hvis du accepterer det.</p><p>Vi bruger følgende typer cookies:</p><ul><li><p><strong>Nødvendige cookies:</strong> Disse er påkrævet for, at hjemmesiden kan fungere korrekt (f.eks. navigation, adgang til sikre områder). Hjemmesiden kan ikke fungere ordentligt uden disse cookies. Retsgrundlaget er vores legitime interesse i at levere en fungerende hjemmeside (GDPR art. 6, stk. 1, lit. f).</p></li><li><p><strong>Analytiske/præstationscookies:</strong> Disse giver os mulighed for at genkende og tælle antallet af besøgende og se, hvordan besøgende bevæger sig rundt på vores hjemmeside, når de bruger den. Dette hjælper os med at forbedre den måde, vores hjemmeside fungerer på, f.eks. ved at sikre, at brugerne nemt finder det, de leder efter. Vi bruger kun disse cookies, hvis du giver dit samtykke (GDPR art. 6, stk. 1, lit. a).</p></li><li><p><strong>Marketingcookies:</strong> Disse bruges til at følge besøgende på tværs af hjemmesider med henblik på at vise relevante annoncer baseret på dine interesser. Vi bruger kun disse cookies, hvis du giver dit samtykke (GDPR art. 6, stk. 1, lit. a).</p></li></ul><p>Du kan administrere dine cookie-samtykker via det cookie-banner, der vises ved dit første besøg, og typisk via et link eller ikon på hjemmesiden derefter. Du kan også indstille din browser til at afvise alle eller nogle browsercookies eller advare dig, når hjemmesider sætter eller tilgår cookies. Hvis du deaktiverer eller afviser cookies, skal du være opmærksom på, at nogle dele af denne hjemmeside kan blive utilgængelige eller ikke fungere korrekt.</p>\"}, {\"title\": \"7. Opbevaring af data\", \"content\": \"<p>Vi vil kun opbevare dine personoplysninger, så længe det er rimeligt nødvendigt for at opfylde de formål, vi indsamlede dem til, herunder med henblik på at opfylde juridiske, regnskabsmæssige eller rapporteringsmæssige krav. For at bestemme den passende opbevaringsperiode for personoplysninger tager vi hensyn til mængden, arten og følsomheden af personoplysningerne, den potentielle risiko for skade ved uautoriseret brug eller videregivelse af dine personoplysninger, de formål, hvortil vi behandler dine personoplysninger, og om vi kan opnå disse formål på andre måder samt de gældende lovkrav.</p><p>Vi opbevarer generelt:</p><ul><li><p>Kontraktoplysninger i op til 5 år efter afslutningen af kontrakten (i henhold til bogføringsloven).</p></li><li><p>Marketingdata så længe samtykket er gyldigt og relevant, eller indtil du trækker dit samtykke tilbage (dog typisk ikke længere end 2 år efter din sidste interaktion).</p></li><li><p>Jobansøgninger og rekrutteringsdata i op til 6 måneder efter en afsluttet rekrutteringsproces, medmindre du giver samtykke til længere opbevaring.</p></li><li><p>Tekniske data og brugsdata fra hjemmesidebesøg opbevares typisk i en begrænset periode (f.eks. 6-24 måneder) til analyseformål.</p></li></ul>\"}, {\"title\": \"8. Dine rettigheder\", \"content\": \"<p>Under visse omstændigheder har du følgende rettigheder i henhold til databeskyttelsesloven i forhold til dine personoplysninger:</p><ul><li><p>Anmode om adgang til dine personoplysninger (indsigtsret).</p></li><li><p>Anmode om rettelse af de personoplysninger, vi har om dig.</p></li><li><p>Anmode om sletning af dine personoplysninger (\\\"retten til at blive glemt\\\").</p></li><li><p>Gøre indsigelse mod behandling af dine personoplysninger, hvor vi baserer behandlingen på vores legitime interesse.</p></li><li><p>Anmode om begrænsning af behandlingen af dine personoplysninger.</p></li><li><p>Anmode om overførsel af dine personoplysninger til dig eller en tredjepart (dataportabilitet).</p></li><li><p>Trække dit samtykke tilbage til enhver tid, hvor vi baserer behandlingen på samtykke.</p></li></ul><p>Hvis du ønsker at udøve nogen af rettighederne angivet ovenfor, bedes du kontakte os via kontaktoplysningerne i afsnit 2.</p><p>Du vil normalt ikke skulle betale et gebyr for at få adgang til dine personoplysninger (eller for at udøve nogen af de andre rettigheder). Vi kan dog opkræve et rimeligt gebyr, hvis din anmodning er åbenlyst grundløs, gentagen eller overdreven. Alternativt kan vi nægte at efterkomme din anmodning under disse omstændigheder. Vi kan have brug for at anmode om specifikke oplysninger fra dig for at hjælpe os med at bekræfte din identitet og sikre din ret til at få adgang til dine personoplysninger (eller til at udøve nogen af dine andre rettigheder).</p>\"}, {\"title\": \"9. Klageadgang\", \"content\": \"<p>Hvis du er utilfreds med vores behandling af dine personoplysninger, har du ret til at indgive en klage til Datatilsynet, Borgergade 28, 5., 1300 København K, telefon 33 19 32 00, e-mail: dt@datatilsynet.dk, hjemmeside: www.datatilsynet.dk.</p><p>Vi ville dog sætte pris på at have mulighed for at adressere dine bekymringer, før du kontakter Datatilsynet, så vi opfordrer dig til at kontakte os først.</p>\"}, {\"title\": \"10. Ændringer til privatlivspolitikken\", \"content\": \"<p>Vi kan opdatere denne privatlivspolitik fra tid til anden for at afspejle ændringer i vores praksis eller af juridiske årsager. Ændringer vil blive lagt på denne side med en opdateret dato øverst. I tilfælde af væsentlige ændringer vil vi bestræbe os på at informere dig via e-mail eller en tydelig meddelelse på vores hjemmeside.</p>\"}]}', '2025-03-16 16:49:09.480', '2025-03-16 16:49:09.480', '2025-05-02 18:58:26.821');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Projects`
--

CREATE TABLE `Projects` (
  `project_id` int UNSIGNED NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` enum('aktiv','afsluttet','afventer') COLLATE utf8mb4_unicode_ci DEFAULT 'afventer',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `customer_id` int UNSIGNED DEFAULT NULL,
  `street` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zip` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Projects`
--

INSERT INTO `Projects` (`project_id`, `title`, `description`, `start_date`, `end_date`, `status`, `created_at`, `customer_id`, `street`, `city`, `zip`, `isActive`) VALUES
(2, 'Good Project', 'Something really good ', '2025-02-17', '2025-11-24', 'aktiv', '2025-02-24 16:18:46', 1, 'Super Street 2', 'Gentofte', '3050', 1),
(3, 'Højhuset ', 'Elementmontage ', '2025-05-15', NULL, 'aktiv', '2025-03-20 12:14:51', 2, 'Super Street 2', 'Gentofte', '3050', 1),
(4, 'Ny domicilbygning til Energinet', 'Den nye domicilbygning bygges i tilknytning til Energinets eksisterende domicilbygning og skal opleves som en naturlig sammenhængende enhed, både funktionelt og æstetisk. Der etableres primært kontorarbejdspladser, mødelokaler og kantine.', '2025-05-19', '2025-05-21', 'aktiv', '2025-05-19 16:29:19', NULL, 'Nowhere 52', 'København', '2000', 1),
(5, 'Test 02', 'Hdvwvz', '2025-06-01', '2025-07-01', 'afventer', '2025-06-01 14:48:37', 2, 'Kobenhavnsej 6', 'København', '2000', 0),
(6, 'Test 02', 'Hdvwvz', '2025-06-01', '2025-07-01', 'afventer', '2025-06-01 14:48:41', 2, 'Kobenhavnsej 6', 'København', '2000', 0),
(7, 'Stejlepladsen', 'Two Cranes', '2025-06-01', '2025-07-15', 'aktiv', '2025-06-01 14:53:08', 4, 'Sejlklubvej 6, 2450 København', 'København', '2450', 0),
(8, 'Stejlepladsen', 'Two Cranes', '2025-06-01', '2025-07-01', 'afventer', '2025-06-01 15:13:49', 4, 'Københavnsvej 68', 'København', '2000', 0),
(9, 'Stejlepladsen', 'Jebbd', '2025-06-01', '2025-07-01', 'aktiv', '2025-06-01 15:49:15', 4, 'No', 'Ok', '2000', 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `PublicHolidays`
--

CREATE TABLE `PublicHolidays` (
  `id` int UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `year` int NOT NULL,
  `is_national` tinyint(1) DEFAULT '1' COMMENT 'true for national holidays, false for company-specific',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

--
-- Zrzut danych tabeli `PublicHolidays`
--

INSERT INTO `PublicHolidays` (`id`, `date`, `name`, `description`, `year`, `is_national`, `created_at`, `updated_at`) VALUES
(1, '2025-01-01', 'Nytårsdag', 'New Year\'s Day', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(2, '2025-04-17', 'Skærtorsdag', 'Maundy Thursday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(3, '2025-04-18', 'Langfredag', 'Good Friday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(4, '2025-04-20', 'Påskedag', 'Easter Sunday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(5, '2025-04-21', 'Anden påskedag', 'Easter Monday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(6, '2025-05-16', 'Store bededag', 'Great Prayer Day', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(7, '2025-05-29', 'Kristi himmelfartsdag', 'Ascension Day', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(8, '2025-06-08', 'Pinsedag', 'Whit Sunday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(9, '2025-06-09', 'Anden pinsedag', 'Whit Monday', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(10, '2025-12-24', 'Juleaftensdag', 'Christmas Eve (half day)', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(11, '2025-12-25', 'Juledag', 'Christmas Day', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(12, '2025-12-26', 'Anden juledag', 'Boxing Day', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43'),
(13, '2025-12-31', 'Nytårsaftensdag', 'New Year\'s Eve (half day)', 2025, 1, '2025-06-05 11:32:43', '2025-06-05 11:32:43');

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

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `RevenueTracking`
--

CREATE TABLE `RevenueTracking` (
  `revenue_id` int UNSIGNED NOT NULL,
  `project_id` int UNSIGNED NOT NULL,
  `billing_period_start` date NOT NULL,
  `billing_period_end` date NOT NULL,
  `total_hours` decimal(8,2) NOT NULL,
  `total_revenue` decimal(10,2) NOT NULL,
  `estimated_costs` decimal(10,2) DEFAULT NULL,
  `profit_margin` decimal(5,2) DEFAULT NULL,
  `payment_received` tinyint(1) DEFAULT '0',
  `payment_date` date DEFAULT NULL,
  `payment_method` enum('bank_transfer','check','cash','other') DEFAULT 'bank_transfer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `SectionSettings`
--

CREATE TABLE `SectionSettings` (
  `id` int NOT NULL,
  `sections` json NOT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `SectionSettings`
--

INSERT INTO `SectionSettings` (`id`, `sections`, `createdAt`, `updatedAt`) VALUES
(1, '{\"faq\": true, \"blog\": true, \"hero\": true, \"about\": true, \"contact\": true, \"erfaring\": true, \"services\": true, \"linkedInFeed\": true, \"testimonials\": false, \"hiringSection\": true, \"craneOperators\": false, \"hireOperatorCTA\": false}', '2025-04-03 07:57:45', '2025-05-25 08:08:52');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Service`
--

CREATE TABLE `Service` (
  `id` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `imageUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `imageHeight` int DEFAULT NULL,
  `imageWidth` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Service`
--

INSERT INTO `Service` (`id`, `title`, `slug`, `description`, `imageUrl`, `imageAlt`, `createdAt`, `updatedAt`, `imageHeight`, `imageWidth`) VALUES
(1, 'Kranførere', 'kranforere', 'Vores erfarne kranførere tilbyder professionel og omfattende betjening af alle typer kraner, herunder tårnkraner, mobilkraner og specialkraner. Med erfaring fra 5 til over 20 år sikrer vi sikkerhed, præcision og rettidig udførelse af opgaver, skræddersyet til selv de mest krævende byggeprojekter.', 'https://ksr-media.fra1.digitaloceanspaces.com/services/1a1f1135-eeb0-42b7-bab9-fffce7e2b2df.webp', '', '2025-03-13 11:34:02.739', '2025-05-04 16:24:36.076', 0, 0),
(2, 'Præcisionsmontering og koordinering', 'drone--inspektion', 'Vi specialiserer os i betjening af komplekse og præcisionskrævende montageopgaver. Vores operatører samarbejder effektivt med øvrige teams på byggepladsen, hvilket sikrer optimal koordinering, smidig udførelse og minimal risiko for montagefejl.', 'https://ksr-media.fra1.digitaloceanspaces.com/services/872b159c-5eb9-40ab-9477-5e29a23f2965.webp', '', '2025-03-14 06:53:00.071', '2025-03-30 07:38:19.301', 478, 850),
(3, 'Sikkerhed og certificering', 'rdgivning--kommunikation', 'Sikkerheden er vores højeste prioritet. Vi investerer regelmæssigt i specialiserede uddannelser og certificeringer af vores operatører for at sikre overholdelse af de nyeste sikkerhedsregler og branchestandarder. Når du vælger os, sikrer du dig, at opgaverne udføres af eksperter, der har fokus på sikkerhed og kvalitet.', 'https://ksr-media.fra1.digitaloceanspaces.com/services/87970b13-0bbe-4cd4-b462-9473457223be.webp', '', '2025-03-14 06:57:13.972', '2025-05-02 15:58:01.131', 475, 845);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Subcategory`
--

CREATE TABLE `Subcategory` (
  `id` int NOT NULL,
  `serviceId` int NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `imageUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageAlt` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imageHeight` int DEFAULT NULL,
  `imageWidth` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `SupervisorSignatures`
--

CREATE TABLE `SupervisorSignatures` (
  `id` bigint UNSIGNED NOT NULL,
  `signature_id` varchar(36) NOT NULL COMMENT 'UUID dla podpisu',
  `supervisor_id` int UNSIGNED NOT NULL COMMENT 'Odniesienie do employee_id z tabeli Employees',
  `signature_url` varchar(255) NOT NULL COMMENT 'URL podpisu w S3',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data utworzenia',
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'Data aktualizacji',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Czy podpis jest aktywny'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Przechowuje podpisy supervisorów';

--
-- Zrzut danych tabeli `SupervisorSignatures`
--

INSERT INTO `SupervisorSignatures` (`id`, `signature_id`, `supervisor_id`, `signature_url`, `created_at`, `updated_at`, `is_active`) VALUES
(1, '048d335b-a70b-4a36-8be1-eab3253b99c0', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/048d335b-a70b-4a36-8be1-eab3253b99c0.png', '2025-05-17 20:17:46', '2025-05-17 20:22:10', 0),
(2, '3be830d9-17f7-4458-8684-75e456b1e578', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/3be830d9-17f7-4458-8684-75e456b1e578.png', '2025-05-17 20:22:10', '2025-05-17 20:34:09', 0),
(3, 'dfcf516a-20c4-46e5-b783-b15d513e20f7', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/dfcf516a-20c4-46e5-b783-b15d513e20f7.png', '2025-05-17 20:34:09', '2025-05-17 21:16:45', 0),
(4, 'c2bac7cd-8014-4b30-be7e-4a80354003e8', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/c2bac7cd-8014-4b30-be7e-4a80354003e8.png', '2025-05-17 21:16:45', '2025-05-17 21:49:02', 0),
(5, 'ea04fac2-cd75-4a7b-866b-d57345d93209', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/ea04fac2-cd75-4a7b-866b-d57345d93209.png', '2025-05-17 21:49:03', '2025-05-17 21:53:59', 0),
(6, 'b5387237-0746-4715-985c-8cb4906804cb', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/b5387237-0746-4715-985c-8cb4906804cb.png', '2025-05-17 21:54:00', '2025-05-18 05:43:18', 0),
(7, '99e24c57-9262-4b6f-9dcc-a6330933550f', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/99e24c57-9262-4b6f-9dcc-a6330933550f.png', '2025-05-18 05:43:18', '2025-05-18 08:26:39', 0),
(8, 'b6f3e817-e247-4607-b18e-a8fb8aae310c', 3, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/supervisor_3/signatures/b6f3e817-e247-4607-b18e-a8fb8aae310c.png', '2025-05-18 08:26:39', NULL, 1);

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
(19, 21, 2, '2025-06-03 09:39:30', NULL),
(20, 20, 2, '2025-06-03 09:39:47', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Tasks`
--

CREATE TABLE `Tasks` (
  `task_id` int UNSIGNED NOT NULL,
  `project_id` int UNSIGNED NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `deadline` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `supervisor_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supervisor_phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supervisor_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supervisor_id` int UNSIGNED DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `required_crane_types` json DEFAULT NULL,
  `preferred_crane_model_id` int UNSIGNED DEFAULT NULL,
  `equipment_category_id` int UNSIGNED DEFAULT NULL,
  `equipment_brand_id` int UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Tasks`
--

INSERT INTO `Tasks` (`task_id`, `project_id`, `title`, `description`, `deadline`, `created_at`, `supervisor_email`, `supervisor_phone`, `supervisor_name`, `supervisor_id`, `isActive`, `required_crane_types`, `preferred_crane_model_id`, `equipment_category_id`, `equipment_brand_id`) VALUES
(12, 3, 'KRAN 1', 'Liebherr 550 ECH', '2025-12-14', '2025-05-14 18:39:24', 'majkemanizer@gmail.com', '', 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(13, 3, 'KRAN 2', 'Crane Operation', '2025-07-17', '2025-05-15 17:39:51', 'majkemanizer@gmail.com', '', 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(14, 4, 'Tower crane operation ', 'Test test ', '2025-08-21', '2025-05-19 16:30:17', 'majkemanizer@gmail.com', '', 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(16, 9, 'Test 9000', 'Jebe D', NULL, '2025-06-01 19:13:33', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(17, 9, 'Crane Test', 'Test', NULL, '2025-06-02 11:38:17', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 0, NULL, NULL, NULL, NULL),
(18, 9, 'Test 6', 'Ok', NULL, '2025-06-02 11:41:28', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(19, 9, 'Test Crane', 'Whooop', NULL, '2025-06-02 16:28:27', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 1, NULL, NULL, NULL, NULL),
(20, 9, 'Test 1500', 'Udbe', NULL, '2025-06-02 17:01:13', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 1, '[2]', 17, 1, 2),
(21, 9, 'Task cream', 'Creamy Juice', '2025-06-28', '2025-06-03 06:55:05', 'majkemanizer@gmail.com', NULL, 'John Kowalski', 3, 1, '[2]', 38, 1, 1);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `TermsConditions`
--

CREATE TABLE `TermsConditions` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` json NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `TermsConditions`
--

INSERT INTO `TermsConditions` (`id`, `title`, `content`, `createdAt`, `updatedAt`) VALUES
('cm8bw3lxb0000v31wgkkfov2n', 'Vilkår og betingelser', '{\"sections\": [{\"title\": \"1. Generelt\", \"content\": \"<p>Denne aftale dækker alle aspekter af de ydelser, vi leverer – herunder både generelle kranydelser og specifikke kranføreropgaver – og gælder for alle aftaler, der indgås med os.</p><hr>\"}, {\"title\": \"2. Formål og Arbejdsopgaver\", \"content\": \"<p>2.1. Aftalens formål er, at kranføreren udfører arbejde – herunder montage-, løfte- og flytteopgaver – ved at betjene den af kunden stillede kran på den eller de af kunden anviste adresser.</p><hr>\"}, {\"title\": \"3. Tjenester\", \"content\": \"<p>Vi leverer kranførere og kranydelser til forskellige projekter baseret på dine specifikke behov. Vi bestræber os på at levere vores tjenester med høj kvalitet og professionalisme.</p><hr>\"}, {\"title\": \"4. Varighed og Ophør\", \"content\": \"<p>4.1. Aftalen regulerer ikke et løbende ansættelsesforhold. Parterne kan løbende aftale specifikke dage eller uger, hvor arbejdet skal udføres.<br>4.2. Aftalen er gældende, indtil de aftalte opgaver er udført – og der skal ikke indgås ny aftale ved eventuelle senere opgaver på samme adresse(r).</p><hr>\"}, {\"title\": \"5. Opsigelse\", \"content\": \"<p>5.1. Aftalen kan opsiges af begge parter med <strong>7 kalenderdages skriftligt varsel</strong>.<br>5.2. Vi forbeholder os desuden retten til straks at ophæve aftalen, hvis du misligholder disse vilkår.</p><hr>\"}, {\"title\": \"6. Priser, Honorar og Betalingsbetingelser\", \"content\": \"<p>6.1. <strong>Priser:</strong> Alle priser er angivet eksklusive moms.<br>6.2. Ved aftale om udførelse af arbejdsopgaver faktureres virksomheden for <strong>minimum 6 timer pr. arbejdsdag</strong>, uanset om arbejdet kan udføres på kortere tid. Kranføreren honoreres således for minimum 6 timer pr. dag – også i tilfælde af kranens stilstand, hvor vedkommende ikke er ansvarlig for eventuelle driftstab.<br><strong>6.3. Satser:</strong><br>Priserne for de enkelte ydelser fastsættes ud fra et konkret tilbud, hvor flere faktorer – såsom projektets omfang, arbejdstidens placering (f.eks. tidlig morgen, sen aften, weekend/helligdage) samt øvrige specifikke forhold – indgår. Det endelige prisniveau fastlægges individuelt for hver opgave og fremgår af det udarbejdede tilbud.<br>6.4. Ved sammenfald af overarbejdstillæg og arbejdstidstilläg sammenlægges disse med den relevante grundtimesats.<br>6.5. Honoraret forfalder til betaling netto kontant ved fakturering hver 14. dag.<br>6.6. Ved betaling efter forfald påløber renter på 1,5 % pr. påbegyndt måned.</p><hr>\"}, {\"title\": \"7. Booking og Aflysning\", \"content\": \"<p>7.1. Booking sker via telefon, e-mail eller gennem vores hjemmeside.<br>7.2. Bekræftelse af booking sendes via e-mail.<br>7.3. <strong>Aflysningsgebyrer:</strong><br>&nbsp;&nbsp;&nbsp;- Aflysning <strong>mere end 48 timer før</strong>: Intet gebyr<br>&nbsp;&nbsp;&nbsp;- Aflysning <strong>mellem 24-48 timer før</strong>: 50% af den aftalte pris<br>&nbsp;&nbsp;&nbsp;- Aflysning <strong>mindre end 24 timer før</strong>: 100% af den aftalte pris</p><hr>\"}, {\"title\": \"8. Ansvar, Forsikring og Ansvarsfraskrivelse\", \"content\": \"<p>8.1. Vi har alle nødvendige forsikringer til at dække vores ansvar.<br>8.2. Virksomheden bekræfter ved aftalens indgåelse, at den har tegnet erhvervsansvarsforsikring og anden relevant forsikring, som dækker kranførerens fejl, forsømmelser samt skader på materiel og personer – herunder indirekte tab (f.eks. driftstab, tidstab, avancetab).<br>8.3. Såfremt forsikringsdækning ikke foreligger for de nævnte forhold, skal virksomheden erstatte og/eller skadesløsholde kranføreren, herunder for krav fra tredjemand.<br>8.4. Vi er ikke ansvarlige for forsinkelser eller manglende opfyldelse som følge af omstændigheder uden for vores rimelige kontrol.</p><hr>\"}, {\"title\": \"9. Misligholdelse og Force Majeure\", \"content\": \"<p>9.1. Ved væsentlig misligholdelse, der ikke afhjælpes inden 7 dage efter skriftligt påkrav, er den ikke-misligholdende part berettiget til straks at ophæve aftalen og kræve erstatning for tab efter dansk rets almindelige regler. (Kranførerens fejl eller forsømmelser betragtes ikke som misligholdelse.)<br>9.2. Ingen af parterne er erstatningsansvarlige for tab, der skyldes omstændigheder af usædvanlig art, som hindrer, besværliggør eller fordyrer opfyldelsen af aftalen – forudsat at disse forhold indtræder efter aftalens indgåelse og ligger uden for parternes kontrol (f.eks. arbejdskonflikter, vejrlig, naturkatastrofer, krig, indre uroligheder, afbrydelse af almindelig samfærdsel).</p><hr>\"}, {\"title\": \"10. Kundens Forpligtelser\", \"content\": \"<p>10.1. Du skal sikre, at arbejdsstedet er sikkert og tilgængeligt for vores personale og udstyr.<br>10.2. Du skal give os alle relevante oplysninger om arbejdet, herunder eventuelle særlige risici eller forhold.<br>10.3. Du skal sikre, at alle nødvendige tilladelser er indhentet, før arbejdet påbegyndes.<br>10.4. Du skal sørge for at stille en parkeringsplads til rådighed for vores medarbejder.</p><hr>\"}, {\"title\": \"11. Fortrolighed\", \"content\": \"<p>11.1. Vi behandler alle oplysninger modtaget fra dig som fortrolige og videregiver dem ikke til tredjepart uden dit samtykke, medmindre det kræves ved lov.<br>11.2. Du forpligter dig til ikke at videregive oplysninger om vores arbejdssteder, priser eller andre forretningsmæssige forhold til konkurrerende virksomheder eller andre uden vores forudgående skriftlige samtykke.</p><hr>\"}, {\"title\": \"12. Immaterielle Rettigheder\", \"content\": \"<p>Alle immaterielle rettigheder tilhørende os forbliver vores ejendom – herunder vores logo, varemærker og andre forretningskendetegn.</p><hr>\"}, {\"title\": \"13. Ændringer af Aftale og Vilkår\", \"content\": \"<p>Enhver ændring af denne aftale skal ske skriftligt og godkendes af begge parter.</p><hr>\"}, {\"title\": \"14. Tvister, Lovvalg og Værneting\", \"content\": \"<p>14.1. Aftalen er underlagt dansk lovgivning.<br>14.2. Enhver tvist, der måtte opstå i forbindelse med aftalen, søges først løst i mindelighed. Såfremt dette ikke lykkes, afgøres tvisten ved de danske domstole.</p><hr>\"}, {\"title\": \"15. Kontakt\", \"content\": \"<p>Hvis du har spørgsmål vedrørende disse vilkår, bedes du kontakte os på:</p><p><strong>KSR CRANES</strong><br>Adresse: Eskebuen 49, 2620 Albertslund, Danmark<br>E-mail: info@ksrcranes.dk<br>Telefon: +45 23 26 20 64</p><hr><p></p>\"}]}', '2025-03-16 17:08:32.799', '2025-03-27 19:56:09.039');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Testimonial`
--

CREATE TABLE `Testimonial` (
  `id` int NOT NULL,
  `quote` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `author` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `approved` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `Testimonial`
--

INSERT INTO `Testimonial` (`id`, `quote`, `author`, `approved`, `createdAt`, `updatedAt`) VALUES
(1, 'Vi har samarbejdet med KSR Cranes på flere byggeprojekter i København gennem de sidste to år, og deres service har været helt i top. Deres kranoperatører er ikke kun yderst professionelle, men også meget fleksible med hensyn til ændringer i tidsplanen. På vores seneste byggeri havde vi brug for en hurtig løsning, da vores oprindelige kranpartner måtte aflyse med kort varsel. KSR Cranes reagerede prompte og havde en kran og operatør på pladsen inden for 24 timer. Deres fokus på sikkerhed og præcision har sparet os for både tid og penge. Vi fortsætter helt sikkert samarbejdet på vores kommende projekter og kan varmt anbefale deres tjenester til andre i branchen.', 'Mikkel Jensen, Projektleder, NordByg A/S', 0, '2025-03-16 10:05:23.842', '2025-05-17 08:50:53.443');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `Timesheet`
--

CREATE TABLE `Timesheet` (
  `id` int NOT NULL,
  `task_id` int NOT NULL,
  `weekNumber` int NOT NULL,
  `year` int NOT NULL,
  `timesheetUrl` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Zrzut danych tabeli `Timesheet`
--

INSERT INTO `Timesheet` (`id`, `task_id`, `weekNumber`, `year`, `timesheetUrl`, `created_at`, `updated_at`) VALUES
(1, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-17 14:41:30', '2025-05-17 14:41:30'),
(2, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-17 14:43:32', '2025-05-17 14:43:32'),
(3, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-17 19:13:15', '2025-05-17 19:13:15'),
(4, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-17 19:17:13', '2025-05-17 19:17:13'),
(5, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-17 19:39:13', '2025-05-17 19:39:13'),
(6, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-17 21:49:05', '2025-05-17 21:49:05'),
(7, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-17 21:54:01', '2025-05-17 21:54:01'),
(8, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 05:43:19', '2025-05-18 05:43:19'),
(9, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 08:26:41', '2025-05-18 08:26:41'),
(10, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 10:28:23', '2025-05-18 10:28:23'),
(11, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 10:45:45', '2025-05-18 10:45:45'),
(12, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 10:50:28', '2025-05-18 10:50:28'),
(13, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-18 14:51:25', '2025-05-18 14:51:25'),
(14, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-18 16:09:38', '2025-05-18 16:09:38'),
(15, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 08:28:59', '2025-05-19 08:28:59'),
(16, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 09:01:25', '2025-05-19 09:01:25'),
(17, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 09:05:22', '2025-05-19 09:05:22'),
(18, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 09:06:46', '2025-05-19 09:06:46'),
(19, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 09:25:28', '2025-05-19 09:25:28'),
(20, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 09:46:35', '2025-05-19 09:46:35'),
(21, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 13:36:37', '2025-05-19 13:36:37'),
(22, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 13:58:23', '2025-05-19 13:58:23'),
(23, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 14:03:22', '2025-05-19 14:03:22'),
(24, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 14:33:36', '2025-05-19 14:33:36'),
(25, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 14:57:20', '2025-05-19 14:57:20'),
(26, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 15:25:16', '2025-05-19 15:25:16'),
(27, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 15:42:06', '2025-05-19 15:42:06'),
(28, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-19 15:48:06', '2025-05-19 15:48:06'),
(29, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-19 16:32:41', '2025-05-19 16:32:41'),
(30, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-24 07:02:21', '2025-05-24 07:02:21'),
(31, 14, 22, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_4/task_14/timesheet2-4-14-week22-2025.pdf', '2025-05-26 15:31:35', '2025-05-26 15:31:35'),
(32, 12, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_12/timesheet2-3-12-week20-2025.pdf', '2025-05-27 10:40:56', '2025-05-27 10:40:56'),
(33, 14, 22, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_4/task_14/timesheet2-4-14-week22-2025.pdf', '2025-05-28 05:55:44', '2025-05-28 05:55:44'),
(34, 13, 20, 2025, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/employee_2/project_3/task_13/timesheet2-3-13-week20-2025.pdf', '2025-05-29 15:13:44', '2025-05-29 15:13:44');

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `v_payroll_batch_details`
-- (See below for the actual view)
--
CREATE TABLE `v_payroll_batch_details` (
`batch_id` int
,`batch_number` varchar(50)
,`period_start` date
,`period_end` date
,`year` int
,`period_number` int
,`status` enum('draft','ready_for_approval','approved','sent_to_zenegy','completed','failed','cancelled')
,`total_employees` int
,`total_hours` decimal(10,2)
,`total_km` decimal(10,2)
,`created_at` datetime
,`approved_at` datetime
,`sent_to_zenegy_at` datetime
,`created_by_name` varchar(255)
,`approved_by_name` varchar(255)
,`entry_count` bigint
,`sent_count` decimal(23,0)
,`failed_count` decimal(23,0)
,`pending_count` decimal(23,0)
);

-- --------------------------------------------------------

--
-- Zastąpiona struktura widoku `v_payroll_ready`
-- (See below for the actual view)
--
CREATE TABLE `v_payroll_ready` (
`entry_id` int unsigned
,`employee_id` int unsigned
,`work_date` date
,`start_time` datetime
,`end_time` datetime
,`pause_minutes` int
,`km` decimal(10,2)
,`hours_worked` decimal(25,2)
,`employee_name` varchar(255)
,`zenegy_employee_number` varchar(50)
,`zenegy_employee_id` varchar(100)
,`sync_enabled` tinyint(1)
);

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
(193, 2, 14, '2025-05-26', '2025-05-26 05:00:00', '2025-05-26 15:00:00', 0, 'rejected', 'rejected', NULL, NULL, '', '2025-05-26 16:06:55', 0, 1, NULL, 33, 0.00, NULL, 0, NULL),
(194, 2, 13, '2025-05-29', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'pending', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, NULL, 80.00, NULL, 0, NULL),
(195, 2, 13, '2025-05-27', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'pending', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, NULL, 80.00, NULL, 0, NULL),
(196, 2, 13, '2025-05-28', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'pending', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, NULL, 80.00, NULL, 0, NULL),
(197, 2, 13, '2025-05-26', '2025-05-26 05:00:00', '2025-05-26 18:00:00', 15, 'submitted', 'pending', NULL, NULL, '', '2025-05-30 17:40:53', 0, 1, NULL, NULL, 80.00, NULL, 0, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `WorkPlanAssignments`
--

CREATE TABLE `WorkPlanAssignments` (
  `assignment_id` int UNSIGNED NOT NULL,
  `work_plan_id` int UNSIGNED NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `work_date` date NOT NULL,
  `start_time` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `end_time` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci COMMENT 'Dodatkowe notatki dla przypisania'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `WorkPlanAssignments`
--

INSERT INTO `WorkPlanAssignments` (`assignment_id`, `work_plan_id`, `employee_id`, `work_date`, `start_time`, `end_time`, `notes`) VALUES
(35, 5, 2, '2025-05-22', '07:00', '15:32', NULL),
(36, 6, 2, '2025-05-22', '06:00', '14:00', NULL),
(37, 6, 2, '2025-05-23', '06:00', '14:00', NULL),
(38, 6, 2, '2025-05-24', '07:00', '23:00', NULL),
(39, 7, 2, '2025-05-22', '07:00', '15:00', NULL),
(40, 7, 2, '2025-05-23', '07:00', '15:00', NULL),
(41, 8, 2, '2025-05-19', '06:00', '14:00', NULL),
(42, 8, 2, '2025-05-20', '06:00', '14:00', NULL),
(43, 8, 2, '2025-05-21', '06:00', '14:00', NULL),
(44, 8, 2, '2025-05-22', '06:00', '14:00', NULL),
(45, 8, 2, '2025-05-23', '06:00', '14:00', NULL),
(46, 8, 2, '2025-05-24', '06:00', '14:00', NULL),
(47, 8, 2, '2025-05-25', '06:00', '14:00', NULL),
(48, 8, 7, '2025-05-22', '07:00', '15:00', NULL),
(49, 8, 7, '2025-05-23', '07:00', '15:00', NULL),
(50, 8, 7, '2025-05-24', '07:00', '15:00', NULL),
(51, 8, 7, '2025-05-25', '07:00', '15:00', NULL),
(52, 9, 2, '2025-05-22', '06:00', '14:00', NULL),
(53, 9, 2, '2025-05-23', '07:00', '15:00', NULL),
(54, 9, 2, '2025-05-24', '06:00', '14:00', NULL),
(56, 4, 2, '2025-05-26', '07:36', '13:36', NULL),
(57, 4, 2, '2025-05-27', '07:36', '13:36', NULL),
(58, 4, 2, '2025-05-28', '07:36', '13:36', NULL),
(59, 4, 2, '2025-05-29', '07:36', '13:00', NULL),
(60, 4, 2, '2025-05-31', '07:36', '13:36', NULL),
(61, 4, 2, '2025-06-01', '07:36', '13:36', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `WorkPlans`
--

CREATE TABLE `WorkPlans` (
  `work_plan_id` int UNSIGNED NOT NULL,
  `task_id` int UNSIGNED NOT NULL,
  `weekNumber` int NOT NULL,
  `year` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by` int UNSIGNED NOT NULL,
  `status` enum('DRAFT','PUBLISHED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `description` text COLLATE utf8mb4_unicode_ci,
  `additional_info` text COLLATE utf8mb4_unicode_ci,
  `attachment_url` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Link do pliku w buckecie (np. S3)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `WorkPlans`
--

INSERT INTO `WorkPlans` (`work_plan_id`, `task_id`, `weekNumber`, `year`, `created_at`, `updated_at`, `created_by`, `status`, `description`, `additional_info`, `attachment_url`) VALUES
(4, 12, 22, 2025, '2025-05-22 11:37:03', '2025-05-22 11:37:03', 3, 'PUBLISHED', NULL, NULL, NULL),
(5, 13, 21, 2025, '2025-05-22 13:33:37', '2025-05-22 13:33:37', 3, 'PUBLISHED', NULL, NULL, 'https://ksr-timesheets.fra1.digitaloceanspaces.com/workplans/task_13/1264d9db-5e3c-4f5c-95a5-a09821b358e6/Certyfikat.pdf'),
(6, 14, 21, 2025, '2025-05-22 16:14:46', '2025-05-22 16:14:46', 3, 'PUBLISHED', NULL, NULL, NULL),
(7, 13, 21, 2025, '2025-05-22 16:17:07', '2025-05-22 16:17:07', 3, 'PUBLISHED', NULL, NULL, NULL),
(8, 14, 21, 2025, '2025-05-22 18:42:01', '2025-05-22 18:42:01', 3, 'PUBLISHED', NULL, NULL, NULL),
(9, 12, 21, 2025, '2025-05-22 18:47:08', '2025-05-22 18:47:08', 3, 'PUBLISHED', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ZenegyApiLog`
--

CREATE TABLE `ZenegyApiLog` (
  `id` int NOT NULL,
  `batch_id` int DEFAULT NULL,
  `batch_entry_id` int DEFAULT NULL,
  `endpoint` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `method` enum('GET','POST','PUT','DELETE','PATCH') COLLATE utf8mb4_unicode_ci NOT NULL,
  `request_headers` json DEFAULT NULL,
  `request_body` json DEFAULT NULL,
  `response_status` int DEFAULT NULL,
  `response_headers` json DEFAULT NULL,
  `response_body` json DEFAULT NULL,
  `response_time_ms` int DEFAULT NULL,
  `is_success` tinyint(1) DEFAULT '0',
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ZenegyConfig`
--

CREATE TABLE `ZenegyConfig` (
  `id` int NOT NULL DEFAULT '1',
  `api_key` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_secret` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `company_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `environment` enum('production','sandbox') COLLATE utf8mb4_unicode_ci DEFAULT 'production',
  `api_base_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT 'https://api.zenegy.com',
  `api_version` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'v1',
  `timeout_seconds` int DEFAULT '30',
  `max_retry_attempts` int DEFAULT '3',
  `webhook_secret` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `last_connection_test` datetime DEFAULT NULL,
  `last_connection_status` enum('success','failed') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` int UNSIGNED DEFAULT NULL
) ;

--
-- Zrzut danych tabeli `ZenegyConfig`
--

INSERT INTO `ZenegyConfig` (`id`, `api_key`, `api_secret`, `tenant_id`, `company_id`, `environment`, `api_base_url`, `api_version`, `timeout_seconds`, `max_retry_attempts`, `webhook_secret`, `is_active`, `last_connection_test`, `last_connection_status`, `updated_at`, `updated_by`) VALUES
(1, 'YOUR_API_KEY_HERE', 'YOUR_API_SECRET_HERE', 'YOUR_TENANT_ID_HERE', 'YOUR_COMPANY_ID_HERE', 'sandbox', 'https://api.zenegy.com', 'v1', 30, 3, NULL, 0, NULL, NULL, '2025-06-04 10:16:14', NULL);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ZenegyEmployeeMapping`
--

CREATE TABLE `ZenegyEmployeeMapping` (
  `id` int NOT NULL,
  `employee_id` int UNSIGNED NOT NULL,
  `zenegy_employee_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zenegy_person_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zenegy_employment_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sync_enabled` tinyint(1) DEFAULT '1',
  `last_synced_at` datetime DEFAULT NULL,
  `sync_errors` int DEFAULT '0',
  `last_error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ZenegyWebhookLog`
--

CREATE TABLE `ZenegyWebhookLog` (
  `id` int NOT NULL,
  `event_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_timestamp` datetime NOT NULL,
  `payload` json NOT NULL,
  `headers` json DEFAULT NULL,
  `processing_status` enum('received','processing','processed','failed','ignored') COLLATE utf8mb4_unicode_ci DEFAULT 'received',
  `processed_at` datetime DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `_prisma_migrations`
--

CREATE TABLE `_prisma_migrations` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  `migration_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logs` text COLLATE utf8mb4_unicode_ci,
  `rolled_back_at` datetime(3) DEFAULT NULL,
  `started_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `applied_steps_count` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Zrzut danych tabeli `_prisma_migrations`
--

INSERT INTO `_prisma_migrations` (`id`, `checksum`, `finished_at`, `migration_name`, `logs`, `rolled_back_at`, `started_at`, `applied_steps_count`) VALUES
('03a6a387-35bb-4f96-aa07-60ff6500992b', '35e339bb9f31319d1daadd5705f910ad735e0cd49ee88cf6501e5a9f12152394', '2025-02-27 12:01:36.143', '20250227120135_embed', NULL, NULL, '2025-02-27 12:01:35.861', 1),
('10572396-16ad-4158-a0e4-2c748ce49f49', 'cf4699bc5bde52562dae0be223c2566d93514b6837545bb9bceba5531881aa44', '2025-03-15 12:28:19.439', '20250315122819_meta_description_to_text5', NULL, NULL, '2025-03-15 12:28:19.271', 1),
('10ca28b4-5fa8-4ebd-ba90-a61f8051fe8a', '796a586cee4c115c152eb8377c3c281c815b4f18cb7474f752d90b0c963c16b6', '2025-03-16 16:27:07.211', '20250316162706_add_privacy_policy', NULL, NULL, '2025-03-16 16:27:07.047', 1),
('1c2ac566-e1ba-4fea-9001-83d64376a7e9', '575d1125bec6059d139a195df2b24b16d65f52309b82a19b9e7ba143fe8381ef', '2025-02-24 15:36:20.164', '20250220072138_mig_one', NULL, NULL, '2025-02-24 15:36:19.574', 1),
('1c5e7dfe-cedc-4e3e-bf7f-450af3ad9fec', '92e4fd518899b6177e34ee30b7e87ce57c2992b612fb6e2a14e77eaaa2dfd8b3', '2025-02-24 15:36:42.715', '20250224153642_update_conversations', NULL, NULL, '2025-02-24 15:36:42.372', 1),
('2b04430e-7a33-4cc1-ba82-0588029d6f87', '0e93fbd71a2891395565c307729a12c4a40a37bc00fa6aba6f0ee46c6da34ec7', '2025-03-20 08:12:41.253', '20250320081240_add_task_assignment_to_hiring_request', NULL, NULL, '2025-03-20 08:12:40.703', 1),
('4b511efc-d4d9-49c1-accc-275219c87f08', '27f0ddb9d253c3677e065222731bc9b7525e4cbd3638ad98422f6a41cf54284b', '2025-02-24 19:40:46.657', '20250224194046_archive_option_added', NULL, NULL, '2025-02-24 19:40:46.378', 1),
('512a32c7-0e74-4b5c-9051-7963d58448c4', 'edddb584e8d6e4d48a5d5b68548862adfc6705d132c3c7cf18b1184f582d4302', '2025-03-25 13:10:44.701', '20250325131044_add_image_dimensions', NULL, NULL, '2025-03-25 13:10:44.293', 1),
('6013d654-7baa-468f-afbd-5b66fc3d34fd', 'c458f4f4aecf199d84a22df88e98fead2dfbf407a18205589cf4be836b90a663', '2025-03-16 09:02:41.205', '20250316090240_add_hotspot_fields_to_crane_operator', NULL, NULL, '2025-03-16 09:02:41.013', 1),
('6256ead3-00ba-4620-a4b4-b5d06f50764c', '2ea3268fcce8eec3003d336467e8e3be467544b791b819e933d385cf80f400d6', '2025-02-24 15:36:20.499', '20250220143613_conversation_messages_added', NULL, NULL, '2025-02-24 15:36:20.353', 1),
('68ebb174-17c1-42d3-ba3a-1fb0355b2b6b', '6677ae8036718bac05fb189b99be03dd08f3f82368d5015f8a4f9cbbca5b625d', '2025-03-14 09:25:00.368', '20250314092459_meta_description_to_text', NULL, NULL, '2025-03-14 09:24:59.745', 1),
('740c5728-2313-446a-b2bc-560a539ad35e', 'c42bbfb3cb9b7c546acf8ea3a6f1861f8ec9e1e413214b30a6d1fd0fcf281692', '2025-02-27 08:43:03.922', '20250227084303_hp_ubuntu_dev', NULL, NULL, '2025-02-27 08:43:03.552', 1),
('745f03d6-06fc-472e-8bbf-10e911e2e9f4', 'be7ce35a6ed99353835a45a60c6f1feb6d452cefcad82f401705d5d73f5b0b8d', '2025-03-14 15:12:39.292', '20250314151238_meta_description_to_text2', NULL, NULL, '2025-03-14 15:12:38.986', 1),
('765a90b8-607d-4780-94da-db966634f4ff', '19a83c6dc9f58c83f45b4eac3b981fa0731ad375623adfe2ae84c1bd493bce5b', '2025-03-12 10:08:19.416', '20250312100818_sanity_import', NULL, NULL, '2025-03-12 10:08:18.962', 1),
('a6d5e263-b95f-498c-8611-048de86b3fe0', '272d85f76a352f6406ebf798581f01bd0fd2626bfe2fc8f69f4be682fdfcf81a', '2025-03-16 09:53:33.998', '20250316095333_add_testimonials', NULL, NULL, '2025-03-16 09:53:33.798', 1),
('b00c9358-4413-4116-bf80-a89aeca33d83', '91c6f822b37555d70d5b89fa96c1d5627050012898bdcc8d91e93458b8ab0c53', '2025-03-26 12:44:34.474', '20250326123645_add_crane_models', NULL, NULL, '2025-03-26 12:44:34.118', 1),
('b1914abe-3963-4429-a58a-8c3591f89d14', 'd95c4b7b0980d1ff0dc6cff2b4b45456f51cf32e4cad457a5f5ba7ab9b19ce12', '2025-03-16 10:50:34.422', '20250316105033_add_hiring_form', NULL, NULL, '2025-03-16 10:50:34.030', 1),
('b762f65d-950d-4762-b132-d437245aea88', '128b414b4381b57996df3c2b415c11f22ab633235b6afe626bd4e9047df617d4', '2025-02-24 15:36:20.328', '20250220075820_migtwo', NULL, NULL, '2025-02-24 15:36:20.215', 1),
('bc0663d3-1596-48fd-b875-d858ba389579', '1109fbf3eb14bbc466fef78803c22fb371ba82b80514bcfe3c71508b87c7474b', '2025-03-14 06:35:15.017', '20250314063514_change_description_to_text', NULL, NULL, '2025-03-14 06:35:14.731', 1),
('c182188c-71ec-4a60-b94f-b7b43e8cbcd2', '94db3f849493b6c41f5c7d6d006d877d27e58e95356adba6825110929c887a7c', '2025-03-16 17:22:36.422', '20250316172236_add_cookie_policy', NULL, NULL, '2025-03-16 17:22:36.237', 1),
('c7e93b78-3897-4d47-9226-f70c1d67d6a1', 'aeecaa7d0396d69aa571b8bb189a1acd7750bf1da0912f2f6fae5d0a1a259949', '2025-03-16 16:51:36.638', '20250316165136_add_terms_conditions', NULL, NULL, '2025-03-16 16:51:36.496', 1);

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `About`
--
ALTER TABLE `About`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `activation_email_logs`
--
ALTER TABLE `activation_email_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_employee_id` (`employee_id`);

--
-- Indeksy dla tabeli `AuditLogs`
--
ALTER TABLE `AuditLogs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `AuditLogs_user_id_idx` (`user_id`);

--
-- Indeksy dla tabeli `BillingSettings`
--
ALTER TABLE `BillingSettings`
  ADD PRIMARY KEY (`setting_id`),
  ADD KEY `BillingSettings_project_id_idx` (`project_id`);

--
-- Indeksy dla tabeli `BlogPost`
--
ALTER TABLE `BlogPost`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `BlogPost_slug_key` (`slug`),
  ADD KEY `idx_content_type` (`contentType`),
  ADD KEY `idx_published_content` (`publishedAt`,`contentType`);

--
-- Indeksy dla tabeli `ClientInteractions`
--
ALTER TABLE `ClientInteractions`
  ADD PRIMARY KEY (`interaction_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_client_interactions_project` (`project_id`),
  ADD KEY `idx_client_interactions_date` (`interaction_date`);

--
-- Indeksy dla tabeli `Conversation`
--
ALTER TABLE `Conversation`
  ADD PRIMARY KEY (`conversation_id`),
  ADD UNIQUE KEY `Conversation_task_id_key` (`task_id`);

--
-- Indeksy dla tabeli `ConversationParticipant`
--
ALTER TABLE `ConversationParticipant`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ConversationParticipant_conversation_id_employee_id_key` (`conversation_id`,`employee_id`),
  ADD KEY `ConversationParticipant_employee_id_fkey` (`employee_id`);

--
-- Indeksy dla tabeli `CookiePolicy`
--
ALTER TABLE `CookiePolicy`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `CraneBrand`
--
ALTER TABLE `CraneBrand`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CraneBrand_code_key` (`code`);

--
-- Indeksy dla tabeli `CraneCategory`
--
ALTER TABLE `CraneCategory`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CraneCategory_code_key` (`code`);

--
-- Indeksy dla tabeli `CraneModel`
--
ALTER TABLE `CraneModel`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CraneModel_code_key` (`code`),
  ADD KEY `CraneModel_brandId_idx` (`brandId`),
  ADD KEY `CraneModel_typeId_idx` (`typeId`);

--
-- Indeksy dla tabeli `CraneOperator`
--
ALTER TABLE `CraneOperator`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `CraneType`
--
ALTER TABLE `CraneType`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `CraneType_code_key` (`code`),
  ADD KEY `CraneType_categoryId_idx` (`categoryId`);

--
-- Indeksy dla tabeli `CraneTypes`
--
ALTER TABLE `CraneTypes`
  ADD PRIMARY KEY (`crane_type_id`);

--
-- Indeksy dla tabeli `Customers`
--
ALTER TABLE `Customers`
  ADD PRIMARY KEY (`customer_id`),
  ADD KEY `idx_customers_logo_uploaded_at` (`logo_uploaded_at`);

--
-- Indeksy dla tabeli `EmployeeCraneTypes`
--
ALTER TABLE `EmployeeCraneTypes`
  ADD PRIMARY KEY (`employee_id`,`crane_type_id`),
  ADD KEY `EmployeeCraneTypes_crane_type_id_fkey` (`crane_type_id`);

--
-- Indeksy dla tabeli `EmployeeLanguage`
--
ALTER TABLE `EmployeeLanguage`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_employee_language` (`employeeId`,`language`),
  ADD KEY `idx_employeeId` (`employeeId`);

--
-- Indeksy dla tabeli `EmployeeOvertimeSettings`
--
ALTER TABLE `EmployeeOvertimeSettings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `EmployeeOvertimeSettings_employee_id_idx` (`employee_id`);

--
-- Indeksy dla tabeli `Employees`
--
ALTER TABLE `Employees`
  ADD PRIMARY KEY (`employee_id`),
  ADD UNIQUE KEY `Employees_email_key` (`email`),
  ADD UNIQUE KEY `uk_zenegy_employee_number` (`zenegy_employee_number`),
  ADD KEY `idx_zenegy_employee_number` (`zenegy_employee_number`);

--
-- Indeksy dla tabeli `ErfaringImage`
--
ALTER TABLE `ErfaringImage`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ErfaringImage_slug_key` (`slug`);

--
-- Indeksy dla tabeli `FAQ`
--
ALTER TABLE `FAQ`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `FooterSettings`
--
ALTER TABLE `FooterSettings`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `FormFieldInteraction`
--
ALTER TABLE `FormFieldInteraction`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_formSessionId_fieldName` (`formSessionId`,`fieldName`),
  ADD KEY `idx_formFieldInteraction_formSessionId` (`formSessionId`),
  ADD KEY `idx_formFieldInteraction_fieldName` (`fieldName`);

--
-- Indeksy dla tabeli `FormSession`
--
ALTER TABLE `FormSession`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_formSession_startedAt` (`startedAt`),
  ADD KEY `idx_formSession_formType` (`formType`),
  ADD KEY `idx_formSession_isSubmitted` (`isSubmitted`),
  ADD KEY `idx_formSession_country` (`country`),
  ADD KEY `idx_formSession_deviceType` (`deviceType`);

--
-- Indeksy dla tabeli `FormSnapshot`
--
ALTER TABLE `FormSnapshot`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_formSnapshot_formSessionId` (`formSessionId`),
  ADD KEY `idx_formSnapshot_createdAt` (`createdAt`);

--
-- Indeksy dla tabeli `FormStepData`
--
ALTER TABLE `FormStepData`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_formSessionId_stepNumber` (`formSessionId`,`stepNumber`),
  ADD KEY `idx_formStepData_formSessionId` (`formSessionId`),
  ADD KEY `idx_formStepData_stepNumber` (`stepNumber`);

--
-- Indeksy dla tabeli `Hero`
--
ALTER TABLE `Hero`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `HiringRequestAttachment`
--
ALTER TABLE `HiringRequestAttachment`
  ADD PRIMARY KEY (`id`),
  ADD KEY `HiringRequestAttachment_requestId_idx` (`requestId`);

--
-- Indeksy dla tabeli `HiringRequestStatusHistory`
--
ALTER TABLE `HiringRequestStatusHistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `HiringRequestStatusHistory_requestId_idx` (`requestId`),
  ADD KEY `HiringRequestStatusHistory_changedById_idx` (`changedById`);

--
-- Indeksy dla tabeli `LeaveAuditLog`
--
ALTER TABLE `LeaveAuditLog`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_audit_leave_request` (`leave_request_id`),
  ADD KEY `idx_audit_employee` (`employee_id`),
  ADD KEY `idx_audit_performed_by` (`performed_by`),
  ADD KEY `idx_audit_action` (`action`),
  ADD KEY `idx_audit_date` (`performed_at`);

--
-- Indeksy dla tabeli `LeaveBalance`
--
ALTER TABLE `LeaveBalance`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_employee_year` (`employee_id`,`year`),
  ADD KEY `idx_balance_employee` (`employee_id`),
  ADD KEY `idx_balance_year` (`year`);

--
-- Indeksy dla tabeli `LeaveRequests`
--
ALTER TABLE `LeaveRequests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_leave_employee_id` (`employee_id`),
  ADD KEY `idx_leave_status` (`status`),
  ADD KEY `idx_leave_dates` (`start_date`,`end_date`),
  ADD KEY `idx_leave_type` (`type`),
  ADD KEY `idx_leave_created` (`created_at`),
  ADD KEY `idx_leave_approver` (`approved_by`);

--
-- Indeksy dla tabeli `linkedin_embeds`
--
ALTER TABLE `linkedin_embeds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `postUrl` (`postUrl`);

--
-- Indeksy dla tabeli `linkedin_posts`
--
ALTER TABLE `linkedin_posts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `linkedInPostId` (`linkedInPostId`),
  ADD KEY `blogPostId` (`blogPostId`);

--
-- Indeksy dla tabeli `linkedin_publish_errors`
--
ALTER TABLE `linkedin_publish_errors`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_blogPostId` (`blogPostId`);

--
-- Indeksy dla tabeli `linkedin_settings`
--
ALTER TABLE `linkedin_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Message`
--
ALTER TABLE `Message`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `Message_conversation_id_idx` (`conversation_id`),
  ADD KEY `Message_sender_id_idx` (`sender_id`);

--
-- Indeksy dla tabeli `MessageStatus`
--
ALTER TABLE `MessageStatus`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `MessageStatus_message_id_employee_id_key` (`message_id`,`employee_id`),
  ADD KEY `MessageStatus_employee_id_fkey` (`employee_id`);

--
-- Indeksy dla tabeli `Navbar`
--
ALTER TABLE `Navbar`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `NotificationPushSettings`
--
ALTER TABLE `NotificationPushSettings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_type_role` (`notification_type`,`target_role`);

--
-- Indeksy dla tabeli `Notifications`
--
ALTER TABLE `Notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `Notifications_employee_id_idx` (`employee_id`),
  ADD KEY `Notifications_project_id_idx` (`project_id`),
  ADD KEY `Notifications_task_id_idx` (`task_id`),
  ADD KEY `Notifications_work_entry_id_idx` (`work_entry_id`),
  ADD KEY `fk_notifications_sender` (`sender_id`),
  ADD KEY `fk_notifications_target` (`target_employee_id`),
  ADD KEY `idx_notifications_role_unread` (`target_role`,`is_read`,`created_at`),
  ADD KEY `idx_notifications_employee_category` (`employee_id`,`category`,`is_read`),
  ADD KEY `idx_notifications_action_required` (`action_required`,`expires_at`);

--
-- Indeksy dla tabeli `OperatorHiringRequest`
--
ALTER TABLE `OperatorHiringRequest`
  ADD PRIMARY KEY (`id`),
  ADD KEY `OperatorHiringRequest_customer_id_idx` (`customer_id`),
  ADD KEY `OperatorHiringRequest_assignedOperatorId_idx` (`assignedOperatorId`),
  ADD KEY `OperatorHiringRequest_assignedProjectId_idx` (`assignedProjectId`),
  ADD KEY `OperatorHiringRequest_status_idx` (`status`),
  ADD KEY `OperatorHiringRequest_startDate_idx` (`startDate`),
  ADD KEY `OperatorHiringRequest_assignedTaskId_idx` (`assignedTaskId`),
  ADD KEY `idx_experienceLevel` (`experienceLevel`);

--
-- Indeksy dla tabeli `OperatorHiringRequestModel`
--
ALTER TABLE `OperatorHiringRequestModel`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_request_model` (`requestId`,`modelId`),
  ADD KEY `fk_opReqModel_model` (`modelId`);

--
-- Indeksy dla tabeli `OperatorLanguageRequirement`
--
ALTER TABLE `OperatorLanguageRequirement`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_requestId` (`requestId`);

--
-- Indeksy dla tabeli `OperatorPerformanceReviews`
--
ALTER TABLE `OperatorPerformanceReviews`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `reviewed_by` (`reviewed_by`),
  ADD KEY `idx_performance_reviews_employee` (`employee_id`),
  ADD KEY `idx_performance_reviews_project` (`project_id`);

--
-- Indeksy dla tabeli `OperatorQuote`
--
ALTER TABLE `OperatorQuote`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_hiringRequestId` (`hiringRequestId`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_quoteNumber` (`quoteNumber`);

--
-- Indeksy dla tabeli `Page`
--
ALTER TABLE `Page`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `Page_slug_key` (`slug`);

--
-- Indeksy dla tabeli `PageVisit`
--
ALTER TABLE `PageVisit`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pagevisit_timestamp` (`timestamp`),
  ADD KEY `idx_pagevisit_path` (`path`),
  ADD KEY `idx_pagevisit_country` (`country`),
  ADD KEY `idx_pagevisit_deviceType` (`deviceType`);

--
-- Indeksy dla tabeli `PayrollAuditLog`
--
ALTER TABLE `PayrollAuditLog`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_batch_id` (`batch_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_performed_at` (`performed_at`),
  ADD KEY `idx_performed_by` (`performed_by`);

--
-- Indeksy dla tabeli `PayrollBatchEntries`
--
ALTER TABLE `PayrollBatchEntries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_batch_employee` (`batch_id`,`employee_id`),
  ADD KEY `idx_sync_status` (`sync_status`),
  ADD KEY `idx_employee_id` (`employee_id`);

--
-- Indeksy dla tabeli `PayrollBatches`
--
ALTER TABLE `PayrollBatches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `batch_number` (`batch_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_period` (`period_start`,`period_end`),
  ADD KEY `idx_year_period` (`year`,`period_number`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indeksy dla tabeli `PayrollDailyEntries`
--
ALTER TABLE `PayrollDailyEntries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_entry_date` (`batch_entry_id`,`work_date`),
  ADD KEY `idx_work_date` (`work_date`),
  ADD KEY `idx_batch_entry` (`batch_entry_id`);

--
-- Indeksy dla tabeli `PrivacyPolicy`
--
ALTER TABLE `PrivacyPolicy`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Projects`
--
ALTER TABLE `Projects`
  ADD PRIMARY KEY (`project_id`),
  ADD KEY `Projects_customer_id_idx` (`customer_id`);

--
-- Indeksy dla tabeli `PublicHolidays`
--
ALTER TABLE `PublicHolidays`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_holiday_date` (`date`),
  ADD KEY `idx_holiday_date` (`date`),
  ADD KEY `idx_holiday_year` (`year`),
  ADD KEY `idx_holiday_national` (`is_national`);

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
-- Indeksy dla tabeli `RevenueTracking`
--
ALTER TABLE `RevenueTracking`
  ADD PRIMARY KEY (`revenue_id`),
  ADD KEY `idx_revenue_tracking_project` (`project_id`),
  ADD KEY `idx_revenue_tracking_period` (`billing_period_start`,`billing_period_end`);

--
-- Indeksy dla tabeli `SectionSettings`
--
ALTER TABLE `SectionSettings`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Service`
--
ALTER TABLE `Service`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Subcategory`
--
ALTER TABLE `Subcategory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `Subcategory_serviceId_fkey` (`serviceId`);

--
-- Indeksy dla tabeli `SupervisorSignatures`
--
ALTER TABLE `SupervisorSignatures`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `signature_id` (`signature_id`),
  ADD KEY `idx_signature_id` (`signature_id`),
  ADD KEY `idx_supervisor_id` (`supervisor_id`);

--
-- Indeksy dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `TaskAssignments_employee_id_idx` (`employee_id`),
  ADD KEY `TaskAssignments_task_id_idx` (`task_id`),
  ADD KEY `idx_crane_model_id` (`crane_model_id`);

--
-- Indeksy dla tabeli `Tasks`
--
ALTER TABLE `Tasks`
  ADD PRIMARY KEY (`task_id`),
  ADD KEY `Tasks_project_id_idx` (`project_id`),
  ADD KEY `Tasks_supervisor_id_idx` (`supervisor_id`),
  ADD KEY `fk_tasks_preferred_crane_model` (`preferred_crane_model_id`),
  ADD KEY `fk_tasks_equipment_category` (`equipment_category_id`),
  ADD KEY `fk_tasks_equipment_brand` (`equipment_brand_id`);

--
-- Indeksy dla tabeli `TermsConditions`
--
ALTER TABLE `TermsConditions`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Testimonial`
--
ALTER TABLE `Testimonial`
  ADD PRIMARY KEY (`id`);

--
-- Indeksy dla tabeli `Timesheet`
--
ALTER TABLE `Timesheet`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_task_id` (`task_id`),
  ADD KEY `idx_week_year` (`weekNumber`,`year`);

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
-- Indeksy dla tabeli `WorkPlanAssignments`
--
ALTER TABLE `WorkPlanAssignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD UNIQUE KEY `uq_workplan_employee_date` (`work_plan_id`,`employee_id`,`work_date`),
  ADD KEY `idx_work_plan_id` (`work_plan_id`),
  ADD KEY `idx_employee_id` (`employee_id`);

--
-- Indeksy dla tabeli `WorkPlans`
--
ALTER TABLE `WorkPlans`
  ADD PRIMARY KEY (`work_plan_id`),
  ADD KEY `idx_task_id` (`task_id`),
  ADD KEY `idx_created_by` (`created_by`),
  ADD KEY `idx_week_year` (`weekNumber`,`year`);

--
-- Indeksy dla tabeli `ZenegyApiLog`
--
ALTER TABLE `ZenegyApiLog`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_batch_id` (`batch_id`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_is_success` (`is_success`),
  ADD KEY `batch_entry_id` (`batch_entry_id`);

--
-- Indeksy dla tabeli `ZenegyConfig`
--
ALTER TABLE `ZenegyConfig`
  ADD PRIMARY KEY (`id`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indeksy dla tabeli `ZenegyEmployeeMapping`
--
ALTER TABLE `ZenegyEmployeeMapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_employee` (`employee_id`),
  ADD UNIQUE KEY `unique_zenegy_employee` (`zenegy_employee_id`),
  ADD KEY `idx_sync_enabled` (`sync_enabled`);

--
-- Indeksy dla tabeli `ZenegyWebhookLog`
--
ALTER TABLE `ZenegyWebhookLog`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `event_id` (`event_id`),
  ADD KEY `idx_event_type` (`event_type`),
  ADD KEY `idx_status` (`processing_status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indeksy dla tabeli `_prisma_migrations`
--
ALTER TABLE `_prisma_migrations`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT dla zrzuconych tabel
--

--
-- AUTO_INCREMENT dla tabeli `About`
--
ALTER TABLE `About`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `activation_email_logs`
--
ALTER TABLE `activation_email_logs`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `AuditLogs`
--
ALTER TABLE `AuditLogs`
  MODIFY `log_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `BillingSettings`
--
ALTER TABLE `BillingSettings`
  MODIFY `setting_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT dla tabeli `BlogPost`
--
ALTER TABLE `BlogPost`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT dla tabeli `ClientInteractions`
--
ALTER TABLE `ClientInteractions`
  MODIFY `interaction_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `Conversation`
--
ALTER TABLE `Conversation`
  MODIFY `conversation_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT dla tabeli `ConversationParticipant`
--
ALTER TABLE `ConversationParticipant`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT dla tabeli `CraneBrand`
--
ALTER TABLE `CraneBrand`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT dla tabeli `CraneCategory`
--
ALTER TABLE `CraneCategory`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT dla tabeli `CraneModel`
--
ALTER TABLE `CraneModel`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT dla tabeli `CraneOperator`
--
ALTER TABLE `CraneOperator`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `CraneType`
--
ALTER TABLE `CraneType`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT dla tabeli `CraneTypes`
--
ALTER TABLE `CraneTypes`
  MODIFY `crane_type_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `Customers`
--
ALTER TABLE `Customers`
  MODIFY `customer_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT dla tabeli `EmployeeLanguage`
--
ALTER TABLE `EmployeeLanguage`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `EmployeeOvertimeSettings`
--
ALTER TABLE `EmployeeOvertimeSettings`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `Employees`
--
ALTER TABLE `Employees`
  MODIFY `employee_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT dla tabeli `ErfaringImage`
--
ALTER TABLE `ErfaringImage`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT dla tabeli `FAQ`
--
ALTER TABLE `FAQ`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT dla tabeli `FooterSettings`
--
ALTER TABLE `FooterSettings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `FormFieldInteraction`
--
ALTER TABLE `FormFieldInteraction`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT dla tabeli `FormStepData`
--
ALTER TABLE `FormStepData`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT dla tabeli `Hero`
--
ALTER TABLE `Hero`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `HiringRequestAttachment`
--
ALTER TABLE `HiringRequestAttachment`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `HiringRequestStatusHistory`
--
ALTER TABLE `HiringRequestStatusHistory`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT dla tabeli `LeaveAuditLog`
--
ALTER TABLE `LeaveAuditLog`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `LeaveBalance`
--
ALTER TABLE `LeaveBalance`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `LeaveRequests`
--
ALTER TABLE `LeaveRequests`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `linkedin_embeds`
--
ALTER TABLE `linkedin_embeds`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `linkedin_posts`
--
ALTER TABLE `linkedin_posts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT dla tabeli `linkedin_publish_errors`
--
ALTER TABLE `linkedin_publish_errors`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `linkedin_settings`
--
ALTER TABLE `linkedin_settings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `Message`
--
ALTER TABLE `Message`
  MODIFY `message_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=223;

--
-- AUTO_INCREMENT dla tabeli `MessageStatus`
--
ALTER TABLE `MessageStatus`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=415;

--
-- AUTO_INCREMENT dla tabeli `Navbar`
--
ALTER TABLE `Navbar`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `NotificationPushSettings`
--
ALTER TABLE `NotificationPushSettings`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT dla tabeli `Notifications`
--
ALTER TABLE `Notifications`
  MODIFY `notification_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=134;

--
-- AUTO_INCREMENT dla tabeli `OperatorHiringRequest`
--
ALTER TABLE `OperatorHiringRequest`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT dla tabeli `OperatorHiringRequestModel`
--
ALTER TABLE `OperatorHiringRequestModel`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `OperatorLanguageRequirement`
--
ALTER TABLE `OperatorLanguageRequirement`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT dla tabeli `OperatorPerformanceReviews`
--
ALTER TABLE `OperatorPerformanceReviews`
  MODIFY `review_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `OperatorQuote`
--
ALTER TABLE `OperatorQuote`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT dla tabeli `Page`
--
ALTER TABLE `Page`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PageVisit`
--
ALTER TABLE `PageVisit`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2097;

--
-- AUTO_INCREMENT dla tabeli `PayrollAuditLog`
--
ALTER TABLE `PayrollAuditLog`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PayrollBatchEntries`
--
ALTER TABLE `PayrollBatchEntries`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PayrollBatches`
--
ALTER TABLE `PayrollBatches`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PayrollDailyEntries`
--
ALTER TABLE `PayrollDailyEntries`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PrivacyPolicy`
--
ALTER TABLE `PrivacyPolicy`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `Projects`
--
ALTER TABLE `Projects`
  MODIFY `project_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT dla tabeli `PublicHolidays`
--
ALTER TABLE `PublicHolidays`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PushNotifications`
--
ALTER TABLE `PushNotifications`
  MODIFY `notification_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `PushTokens`
--
ALTER TABLE `PushTokens`
  MODIFY `token_id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `RevenueTracking`
--
ALTER TABLE `RevenueTracking`
  MODIFY `revenue_id` int UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `SectionSettings`
--
ALTER TABLE `SectionSettings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT dla tabeli `Service`
--
ALTER TABLE `Service`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT dla tabeli `Subcategory`
--
ALTER TABLE `Subcategory`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT dla tabeli `SupervisorSignatures`
--
ALTER TABLE `SupervisorSignatures`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  MODIFY `assignment_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT dla tabeli `Tasks`
--
ALTER TABLE `Tasks`
  MODIFY `task_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT dla tabeli `Testimonial`
--
ALTER TABLE `Testimonial`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT dla tabeli `Timesheet`
--
ALTER TABLE `Timesheet`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT dla tabeli `WorkEntries`
--
ALTER TABLE `WorkEntries`
  MODIFY `entry_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=198;

--
-- AUTO_INCREMENT dla tabeli `WorkPlanAssignments`
--
ALTER TABLE `WorkPlanAssignments`
  MODIFY `assignment_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT dla tabeli `WorkPlans`
--
ALTER TABLE `WorkPlans`
  MODIFY `work_plan_id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT dla tabeli `ZenegyApiLog`
--
ALTER TABLE `ZenegyApiLog`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `ZenegyEmployeeMapping`
--
ALTER TABLE `ZenegyEmployeeMapping`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `ZenegyWebhookLog`
--
ALTER TABLE `ZenegyWebhookLog`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Struktura widoku `CurrentLeaveRequests`
--
DROP TABLE IF EXISTS `CurrentLeaveRequests`;

CREATE ALGORITHM=UNDEFINED DEFINER=`doadmin`@`%` SQL SECURITY DEFINER VIEW `CurrentLeaveRequests`  AS SELECT `lr`.`id` AS `id`, `lr`.`employee_id` AS `employee_id`, `e`.`name` AS `employee_name`, `e`.`email` AS `employee_email`, `lr`.`type` AS `type`, `lr`.`start_date` AS `start_date`, `lr`.`end_date` AS `end_date`, `lr`.`total_days` AS `total_days`, `lr`.`status` AS `status`, `lr`.`reason` AS `reason`, `lr`.`created_at` AS `created_at`, `lr`.`approved_by` AS `approved_by`, `approver`.`name` AS `approver_name`, `lr`.`approved_at` AS `approved_at` FROM ((`LeaveRequests` `lr` join `Employees` `e` on((`lr`.`employee_id` = `e`.`employee_id`))) left join `Employees` `approver` on((`lr`.`approved_by` = `approver`.`employee_id`))) WHERE (`lr`.`status` in ('PENDING','APPROVED')) ORDER BY `lr`.`created_at` DESC ;

-- --------------------------------------------------------

--
-- Struktura widoku `EmployeeLeaveBalances`
--
DROP TABLE IF EXISTS `EmployeeLeaveBalances`;

CREATE ALGORITHM=UNDEFINED DEFINER=`doadmin`@`%` SQL SECURITY DEFINER VIEW `EmployeeLeaveBalances`  AS SELECT `lb`.`employee_id` AS `employee_id`, `e`.`name` AS `employee_name`, `e`.`email` AS `employee_email`, `lb`.`year` AS `year`, `lb`.`vacation_days_total` AS `vacation_days_total`, `lb`.`vacation_days_used` AS `vacation_days_used`, ((`lb`.`vacation_days_total` + `lb`.`carry_over_days`) - `lb`.`vacation_days_used`) AS `vacation_days_remaining`, `lb`.`personal_days_total` AS `personal_days_total`, `lb`.`personal_days_used` AS `personal_days_used`, (`lb`.`personal_days_total` - `lb`.`personal_days_used`) AS `personal_days_remaining`, `lb`.`carry_over_days` AS `carry_over_days`, `lb`.`carry_over_expires` AS `carry_over_expires` FROM (`LeaveBalance` `lb` join `Employees` `e` on((`lb`.`employee_id` = `e`.`employee_id`))) WHERE (`lb`.`year` = year(curdate())) ORDER BY `e`.`name` ASC ;

-- --------------------------------------------------------

--
-- Struktura widoku `v_payroll_batch_details`
--
DROP TABLE IF EXISTS `v_payroll_batch_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`doadmin`@`%` SQL SECURITY DEFINER VIEW `v_payroll_batch_details`  AS SELECT `pb`.`id` AS `batch_id`, `pb`.`batch_number` AS `batch_number`, `pb`.`period_start` AS `period_start`, `pb`.`period_end` AS `period_end`, `pb`.`year` AS `year`, `pb`.`period_number` AS `period_number`, `pb`.`status` AS `status`, `pb`.`total_employees` AS `total_employees`, `pb`.`total_hours` AS `total_hours`, `pb`.`total_km` AS `total_km`, `pb`.`created_at` AS `created_at`, `pb`.`approved_at` AS `approved_at`, `pb`.`sent_to_zenegy_at` AS `sent_to_zenegy_at`, `creator`.`name` AS `created_by_name`, `approver`.`name` AS `approved_by_name`, count(distinct `pbe`.`id`) AS `entry_count`, sum((case when (`pbe`.`sync_status` = 'sent') then 1 else 0 end)) AS `sent_count`, sum((case when (`pbe`.`sync_status` = 'failed') then 1 else 0 end)) AS `failed_count`, sum((case when (`pbe`.`sync_status` = 'pending') then 1 else 0 end)) AS `pending_count` FROM (((`PayrollBatches` `pb` left join `Employees` `creator` on((`pb`.`created_by` = `creator`.`employee_id`))) left join `Employees` `approver` on((`pb`.`approved_by` = `approver`.`employee_id`))) left join `PayrollBatchEntries` `pbe` on((`pb`.`id` = `pbe`.`batch_id`))) GROUP BY `pb`.`id` ;

-- --------------------------------------------------------

--
-- Struktura widoku `v_payroll_ready`
--
DROP TABLE IF EXISTS `v_payroll_ready`;

CREATE ALGORITHM=UNDEFINED DEFINER=`doadmin`@`%` SQL SECURITY DEFINER VIEW `v_payroll_ready`  AS SELECT `we`.`entry_id` AS `entry_id`, `we`.`employee_id` AS `employee_id`, `we`.`work_date` AS `work_date`, `we`.`start_time` AS `start_time`, `we`.`end_time` AS `end_time`, `we`.`pause_minutes` AS `pause_minutes`, `we`.`km` AS `km`, round(((timestampdiff(MINUTE,`we`.`start_time`,`we`.`end_time`) / 60.0) - (coalesce(`we`.`pause_minutes`,0) / 60.0)),2) AS `hours_worked`, `e`.`name` AS `employee_name`, `e`.`zenegy_employee_number` AS `zenegy_employee_number`, `zem`.`zenegy_employee_id` AS `zenegy_employee_id`, `zem`.`sync_enabled` AS `sync_enabled` FROM ((`WorkEntries` `we` join `Employees` `e` on((`we`.`employee_id` = `e`.`employee_id`))) left join `ZenegyEmployeeMapping` `zem` on((`e`.`employee_id` = `zem`.`employee_id`))) WHERE ((`we`.`confirmation_status` = 'confirmed') AND (`we`.`sent_to_payroll` = false) AND (`we`.`isActive` = true) AND (`we`.`start_time` is not null) AND (`we`.`end_time` is not null)) ;

--
-- Ograniczenia dla zrzutów tabel
--

--
-- Ograniczenia dla tabeli `activation_email_logs`
--
ALTER TABLE `activation_email_logs`
  ADD CONSTRAINT `activation_email_logs_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `AuditLogs`
--
ALTER TABLE `AuditLogs`
  ADD CONSTRAINT `AuditLogs_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `BillingSettings`
--
ALTER TABLE `BillingSettings`
  ADD CONSTRAINT `BillingSettings_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`);

--
-- Ograniczenia dla tabeli `ClientInteractions`
--
ALTER TABLE `ClientInteractions`
  ADD CONSTRAINT `ClientInteractions_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ClientInteractions_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `Conversation`
--
ALTER TABLE `Conversation`
  ADD CONSTRAINT `Conversation_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `ConversationParticipant`
--
ALTER TABLE `ConversationParticipant`
  ADD CONSTRAINT `ConversationParticipant_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `Conversation` (`conversation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ConversationParticipant_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `CraneModel`
--
ALTER TABLE `CraneModel`
  ADD CONSTRAINT `CraneModel_brandId_fkey` FOREIGN KEY (`brandId`) REFERENCES `CraneBrand` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `CraneModel_typeId_fkey` FOREIGN KEY (`typeId`) REFERENCES `CraneType` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `CraneType`
--
ALTER TABLE `CraneType`
  ADD CONSTRAINT `CraneType_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `CraneCategory` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `EmployeeCraneTypes`
--
ALTER TABLE `EmployeeCraneTypes`
  ADD CONSTRAINT `EmployeeCraneTypes_crane_type_id_fkey` FOREIGN KEY (`crane_type_id`) REFERENCES `CraneTypes` (`crane_type_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `EmployeeCraneTypes_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `EmployeeLanguage`
--
ALTER TABLE `EmployeeLanguage`
  ADD CONSTRAINT `fk_employeeLanguage_employee` FOREIGN KEY (`employeeId`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `EmployeeOvertimeSettings`
--
ALTER TABLE `EmployeeOvertimeSettings`
  ADD CONSTRAINT `EmployeeOvertimeSettings_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `FormFieldInteraction`
--
ALTER TABLE `FormFieldInteraction`
  ADD CONSTRAINT `fk_fieldInteraction_formSession` FOREIGN KEY (`formSessionId`) REFERENCES `FormSession` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `FormSnapshot`
--
ALTER TABLE `FormSnapshot`
  ADD CONSTRAINT `fk_formSnapshot_formSession` FOREIGN KEY (`formSessionId`) REFERENCES `FormSession` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `FormStepData`
--
ALTER TABLE `FormStepData`
  ADD CONSTRAINT `fk_stepData_formSession` FOREIGN KEY (`formSessionId`) REFERENCES `FormSession` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `HiringRequestAttachment`
--
ALTER TABLE `HiringRequestAttachment`
  ADD CONSTRAINT `HiringRequestAttachment_requestId_fkey` FOREIGN KEY (`requestId`) REFERENCES `OperatorHiringRequest` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `HiringRequestStatusHistory`
--
ALTER TABLE `HiringRequestStatusHistory`
  ADD CONSTRAINT `HiringRequestStatusHistory_changedById_fkey` FOREIGN KEY (`changedById`) REFERENCES `Employees` (`employee_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `HiringRequestStatusHistory_requestId_fkey` FOREIGN KEY (`requestId`) REFERENCES `OperatorHiringRequest` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `LeaveAuditLog`
--
ALTER TABLE `LeaveAuditLog`
  ADD CONSTRAINT `fk_audit_employee` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_audit_leave_request` FOREIGN KEY (`leave_request_id`) REFERENCES `LeaveRequests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_audit_performer` FOREIGN KEY (`performed_by`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `LeaveBalance`
--
ALTER TABLE `LeaveBalance`
  ADD CONSTRAINT `fk_balance_employee` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `LeaveRequests`
--
ALTER TABLE `LeaveRequests`
  ADD CONSTRAINT `fk_leave_approver` FOREIGN KEY (`approved_by`) REFERENCES `Employees` (`employee_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_leave_employee` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `linkedin_posts`
--
ALTER TABLE `linkedin_posts`
  ADD CONSTRAINT `linkedin_posts_ibfk_1` FOREIGN KEY (`blogPostId`) REFERENCES `BlogPost` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `linkedin_publish_errors`
--
ALTER TABLE `linkedin_publish_errors`
  ADD CONSTRAINT `fk_linkedin_publish_errors_blogPost` FOREIGN KEY (`blogPostId`) REFERENCES `BlogPost` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `Message`
--
ALTER TABLE `Message`
  ADD CONSTRAINT `Message_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `Conversation` (`conversation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `Message_sender_id_fkey` FOREIGN KEY (`sender_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `MessageStatus`
--
ALTER TABLE `MessageStatus`
  ADD CONSTRAINT `MessageStatus_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `MessageStatus_message_id_fkey` FOREIGN KEY (`message_id`) REFERENCES `Message` (`message_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `Notifications`
--
ALTER TABLE `Notifications`
  ADD CONSTRAINT `fk_notifications_sender` FOREIGN KEY (`sender_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `fk_notifications_target` FOREIGN KEY (`target_employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `Notifications_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `Notifications_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`);

--
-- Ograniczenia dla tabeli `OperatorHiringRequest`
--
ALTER TABLE `OperatorHiringRequest`
  ADD CONSTRAINT `OperatorHiringRequest_assignedOperatorId_fkey` FOREIGN KEY (`assignedOperatorId`) REFERENCES `Employees` (`employee_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `OperatorHiringRequest_assignedProjectId_fkey` FOREIGN KEY (`assignedProjectId`) REFERENCES `Projects` (`project_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `OperatorHiringRequest_assignedTaskId_fkey` FOREIGN KEY (`assignedTaskId`) REFERENCES `Tasks` (`task_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `OperatorHiringRequest_customer_id_fkey` FOREIGN KEY (`customer_id`) REFERENCES `Customers` (`customer_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `OperatorHiringRequestModel`
--
ALTER TABLE `OperatorHiringRequestModel`
  ADD CONSTRAINT `fk_opReqModel_model` FOREIGN KEY (`modelId`) REFERENCES `CraneModel` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_opReqModel_request` FOREIGN KEY (`requestId`) REFERENCES `OperatorHiringRequest` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `OperatorLanguageRequirement`
--
ALTER TABLE `OperatorLanguageRequirement`
  ADD CONSTRAINT `fk_operatorLanguageRequirement_request` FOREIGN KEY (`requestId`) REFERENCES `OperatorHiringRequest` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `OperatorPerformanceReviews`
--
ALTER TABLE `OperatorPerformanceReviews`
  ADD CONSTRAINT `OperatorPerformanceReviews_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `OperatorPerformanceReviews_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `OperatorPerformanceReviews_ibfk_3` FOREIGN KEY (`reviewed_by`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `OperatorQuote`
--
ALTER TABLE `OperatorQuote`
  ADD CONSTRAINT `fk_OperatorQuote_OperatorHiringRequest` FOREIGN KEY (`hiringRequestId`) REFERENCES `OperatorHiringRequest` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `OperatorQuote_ibfk_1` FOREIGN KEY (`hiringRequestId`) REFERENCES `OperatorHiringRequest` (`id`);

--
-- Ograniczenia dla tabeli `PayrollAuditLog`
--
ALTER TABLE `PayrollAuditLog`
  ADD CONSTRAINT `PayrollAuditLog_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `PayrollBatches` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `PayrollAuditLog_ibfk_2` FOREIGN KEY (`performed_by`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `PayrollBatchEntries`
--
ALTER TABLE `PayrollBatchEntries`
  ADD CONSTRAINT `PayrollBatchEntries_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `PayrollBatches` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `PayrollBatchEntries_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `PayrollBatches`
--
ALTER TABLE `PayrollBatches`
  ADD CONSTRAINT `PayrollBatches_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `PayrollBatches_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `PayrollDailyEntries`
--
ALTER TABLE `PayrollDailyEntries`
  ADD CONSTRAINT `PayrollDailyEntries_ibfk_1` FOREIGN KEY (`batch_entry_id`) REFERENCES `PayrollBatchEntries` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `Projects`
--
ALTER TABLE `Projects`
  ADD CONSTRAINT `Projects_customer_id_fkey` FOREIGN KEY (`customer_id`) REFERENCES `Customers` (`customer_id`);

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
-- Ograniczenia dla tabeli `RevenueTracking`
--
ALTER TABLE `RevenueTracking`
  ADD CONSTRAINT `RevenueTracking_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `Subcategory`
--
ALTER TABLE `Subcategory`
  ADD CONSTRAINT `Subcategory_serviceId_fkey` FOREIGN KEY (`serviceId`) REFERENCES `Service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ograniczenia dla tabeli `SupervisorSignatures`
--
ALTER TABLE `SupervisorSignatures`
  ADD CONSTRAINT `SupervisorSignatures_ibfk_1` FOREIGN KEY (`supervisor_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `TaskAssignments`
--
ALTER TABLE `TaskAssignments`
  ADD CONSTRAINT `fk_taskassignments_cranemodel` FOREIGN KEY (`crane_model_id`) REFERENCES `CraneModel` (`id`),
  ADD CONSTRAINT `TaskAssignments_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `TaskAssignments_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`);

--
-- Ograniczenia dla tabeli `Tasks`
--
ALTER TABLE `Tasks`
  ADD CONSTRAINT `fk_tasks_equipment_brand` FOREIGN KEY (`equipment_brand_id`) REFERENCES `CraneBrand` (`id`),
  ADD CONSTRAINT `fk_tasks_equipment_category` FOREIGN KEY (`equipment_category_id`) REFERENCES `CraneCategory` (`id`),
  ADD CONSTRAINT `fk_tasks_preferred_crane_model` FOREIGN KEY (`preferred_crane_model_id`) REFERENCES `CraneModel` (`id`),
  ADD CONSTRAINT `fk_tasks_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `Tasks_project_id_fkey` FOREIGN KEY (`project_id`) REFERENCES `Projects` (`project_id`);

--
-- Ograniczenia dla tabeli `WorkEntries`
--
ALTER TABLE `WorkEntries`
  ADD CONSTRAINT `fk_workentries_payroll_batch` FOREIGN KEY (`payroll_batch_id`) REFERENCES `PayrollBatches` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_workentries_timesheet` FOREIGN KEY (`timesheetId`) REFERENCES `Timesheet` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `WorkEntries_employee_id_fkey` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `WorkEntries_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`);

--
-- Ograniczenia dla tabeli `WorkPlanAssignments`
--
ALTER TABLE `WorkPlanAssignments`
  ADD CONSTRAINT `fk_workplanassignments_employee` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `fk_workplanassignments_workplan` FOREIGN KEY (`work_plan_id`) REFERENCES `WorkPlans` (`work_plan_id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `WorkPlans`
--
ALTER TABLE `WorkPlans`
  ADD CONSTRAINT `fk_workplans_creator` FOREIGN KEY (`created_by`) REFERENCES `Employees` (`employee_id`),
  ADD CONSTRAINT `fk_workplans_task` FOREIGN KEY (`task_id`) REFERENCES `Tasks` (`task_id`);

--
-- Ograniczenia dla tabeli `ZenegyApiLog`
--
ALTER TABLE `ZenegyApiLog`
  ADD CONSTRAINT `ZenegyApiLog_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `PayrollBatches` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ZenegyApiLog_ibfk_2` FOREIGN KEY (`batch_entry_id`) REFERENCES `PayrollBatchEntries` (`id`) ON DELETE CASCADE;

--
-- Ograniczenia dla tabeli `ZenegyConfig`
--
ALTER TABLE `ZenegyConfig`
  ADD CONSTRAINT `ZenegyConfig_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `Employees` (`employee_id`);

--
-- Ograniczenia dla tabeli `ZenegyEmployeeMapping`
--
ALTER TABLE `ZenegyEmployeeMapping`
  ADD CONSTRAINT `ZenegyEmployeeMapping_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `Employees` (`employee_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
