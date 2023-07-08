[SQL Project based on the Alex Freberg Data Analyst Bootcamp]
--Utilized Covid Death/Vaccination Data from the following site: https://ourworldindata.org/covid-deaths

--Looking at Total Cases vs. Total Deaths
--Had to change data types to float/int, as they were saved as nvarchar

SELECT Location, Date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2


--Looking at Total Cases vs. Population
SELECT Location, Date, population, total_cases, (CAST(total_cases AS float)/population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE Location LIKE '%states%' 
ORDER BY 1,2


--Looking at Countries with Highest Infection Rate Compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases AS float)/population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC


--Showing Countries with the Highest Death Count Per Population

SELECT Location, population, MAX(CAST(total_deaths AS int)) AS HighestDeathCount, MAX(CAST(total_deaths AS int)/population) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY DeathPercentage DESC


--Looking into Total Deaths by Continent

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Looking into Total Cases/Deaths and Death Percentage Globally by Date
--While in the video, Alex did not require this line of code "HAVING SUM(new_deaths) != 0 AND SUM(new_cases) !=0", I was getting a zero division error, which is what led me to add this line in the query.

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(new_deaths) != 0 AND SUM(new_cases) !=0
ORDER BY 1, 2


--Looking into Total Cases/Deaths and Death Percentage Globally

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 1, 2


--Looking at Total Population vs. Vaccinations
--I had to convert vac.new_vaccinations to bigint given that the numbers exceed 2,147,483,647

WITH vaccinated_population (Continent, Location, Date, Population, NewVaccinations, RollingPeoplevaccinated)
AS 
(SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidVaccinations AS vac
JOIN CovidDeaths AS death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
)

SELECT *, (RollingPeoplevaccinated/Population) * 100 AS PercentVaccinated
FROM vaccinated_population
ORDER BY 2, 3


--Making a TempTable
--Added drop table for temp table in case changes are needed

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent varchar(20),
Location varchar(50),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated 
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidVaccinations AS vac
JOIN CovidDeaths AS death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL


--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM CovidVaccinations AS vac
JOIN CovidDeaths AS death
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
SELECT *, (RollingPeoplevaccinated/Population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated


--Creating a View for Total Cases by Country

CREATE VIEW TotalCasesbyCountry AS
SELECT death.Location, CAST(MAX(death.total_cases) AS bigint) AS total_cases
FROM CovidDeaths AS death
JOIN CovidVaccinations AS vac
	ON death.continent = vac.continent 
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
GROUP BY death.Location
