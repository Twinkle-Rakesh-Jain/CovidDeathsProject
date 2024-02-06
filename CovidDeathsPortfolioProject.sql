 /* Importing Covid Deaths table here */

USE covid_deaths;
SELECT * 
FROM covid_deaths.covid_deaths;
TRUNCATE TABLE covid_deaths.covid_deaths;
set global local_infile=on;    
LOAD DATA LOCAL INFILE '/Users/twinklejain/Desktop/Data Analysis Project/Covid Deaths/covid_deathssublime.csv'
INTO TABLE covid_deaths
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;  
SELECT *
FROM covid_deaths.covid_deaths;
SELECT COUNT(*)
FROM covid_deaths.covid_deaths;   

/* Importing Covid Vaccination table here */
SELECT * 
FROM covid_deaths.covid_vaccinations;
TRUNCATE TABLE covid_vaccinations;

set global local_infile=on; 
LOAD DATA LOCAL INFILE '/Users/twinklejain/Desktop/Data Analysis Project/Covid Vaccinations/covid_vaccinationssublime.csv'
INTO TABLE covid_vaccinations 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT * 
FROM covid_deaths.covid_vaccinations;
SELECT COUNT(*)
FROM covid_deaths.covid_vaccinations;

/* Just sorting the tables by country and date */
SELECT * 
FROM covid_deaths.covid_deaths
ORDER BY 3,4;
SELECT * 
FROM covid_deaths.covid_vaccinations
ORDER BY 3,4;

/*Selecting the data that we'll be looking at */
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths.covid_deaths
ORDER BY 1,2;

/* Looking at total cases vs total deaths. Shows the likelihood of dying if you contract covid in your country */
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM covid_deaths.covid_deaths
WHERE location = 'India';

/* Looking at total cases vs total population. Shows what percentage of population got covid in India */
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS covid_percentage
FROM covid_deaths.covid_deaths
WHERE location = 'India'
ORDER BY 2;

/* Looking at countries with the highest infection rate compared to population*/
SELECT location, population, MAX(total_cases) AS HighestinfectIONcount, MAX(total_cases/population) * 100 AS Percentpopulationinfected
FROM covid_deaths.covid_deaths
GROUP BY location, population
ORDER BY Percentpopulationinfected DESC;

/* Showing countries with total death counts per population */
SELECT location, MAX(total_deaths) AS totaldeathcount
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
GROUP BY location
ORDER BY totaldeathcount DESC;

/* Showing continent with total death counts per population */
SELECT TRIM(REPLACE(continent, '\0', '')) AS continent, MAX(total_deaths) AS totaldeathcount
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
/* WHERE continent IS NOT NULL AND TRIM(REPLACE(continent, '\0', '')) <> '' */
GROUP BY TRIM(REPLACE(continent, '\0', ''))
ORDER BY totaldeathcount DESC;

SELECT REPLACE(TRIM(continent), ' ', '') AS continent, MAX(total_deaths) AS totaldeathcount
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
/* WHERE continent IS NOT NULL AND TRIM(REPLACE(continent, '\0', '')) <> '' */
GROUP BY REPLACE(TRIM(continent), ' ', '')
ORDER BY totaldeathcount DESC;

/* Global Numbers */
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,  SUM(new_deaths)/SUM(new_cases) * 100 AS death_percentage
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
GROUP BY date
ORDER BY 1, 2;

/* Looking at total population vs total vaccinations */
 SELECT REPLACE(TRIM(dea.continent), ' ', '') AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 FROM covid_deaths.covid_deaths dea
 JOIN covid_deaths.covid_vaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE REPLACE(TRIM(dea.continent), ' ', '') != ''
 ORDER BY 2,3;

 SELECT REPLACE(TRIM(dea.continent), ' ', '') AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeople_Vaccinated
 FROM covid_deaths.covid_deaths dea
 JOIN covid_deaths.covid_vaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE REPLACE(TRIM(dea.continent), ' ', '') != ''
 ORDER BY 2,3;

/* Using CTEs */
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeople_Vaccinated)
AS(
SELECT REPLACE(TRIM(dea.continent), ' ', '') AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeople_Vaccinated
 FROM covid_deaths.covid_deaths dea
 JOIN covid_deaths.covid_vaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE REPLACE(TRIM(dea.continent), ' ', '') != ''
)
SELECT *, (RollingPeople_Vaccinated/Population) * 100
FROM PopVsVac;

/* Creating temp table */
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
 continent nvarchar(255),
 location nvarchar(255),
 date date,
 population INT,
 new_vaccinations INT,
 RollingPeople_Vaccinated BIGINT
 );
 INSERT INTO PercentPopulationVaccinated
 SELECT REPLACE(TRIM(dea.continent), ' ', '') AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeople_Vaccinated
 FROM covid_deaths.covid_deaths dea
 JOIN covid_deaths.covid_vaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE REPLACE(TRIM(dea.continent), ' ', '') != '';
 
SELECT *, (RollingPeople_Vaccinated/Population) * 100
FROM PercentPopulationVaccinated;

/* Creating views to store data for later visualisations */
CREATE VIEW PercentagePopulationVaccinated AS
SELECT REPLACE(TRIM(dea.continent), ' ', '') AS continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeople_Vaccinated
 FROM covid_deaths.covid_deaths dea
 JOIN covid_deaths.covid_vaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE REPLACE(TRIM(dea.continent), ' ', '') != '';


/*Tableau 1*/
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/ SUM(new_cases) AS deathpercentage
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
ORDER BY 1, 2;

/*Tableau 2*/
SELECT REPLACE(TRIM(continent), ' ', '') AS continent, SUM(new_deaths) AS totaldeathcount
FROM covid_deaths.covid_deaths
WHERE REPLACE(TRIM(continent), ' ', '') != ''
GROUP BY REPLACE(TRIM(continent), ' ', '')
ORDER BY totaldeathcount desc;

/*Tableau 3*/
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationinfected
FROM covid_deaths.covid_deaths
GROUP BY Location, Population
ORDER BY PercentPopulationinfected desc;

/*Tableau 4*/
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationinfected
FROM covid_deaths.covid_deaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationinfected desc;

