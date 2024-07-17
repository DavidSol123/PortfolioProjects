
SELECT *
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Likelihood of deaths by country if you contract Covid

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases) * 100, 2) AS death_percentage
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE location = 'Canada'
ORDER BY location, date

-- Total Cases vs Population

SELECT location, date, total_cases, population, ROUND((total_cases/population) * 100, 2) AS death_percentage_total_pop
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE location = 'Canada'
ORDER BY location, date

-- Countries with highest infection rate compared to population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX(ROUND((total_cases/population) * 100, 2)) AS percent_population_infected
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- By continent

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

--Global numbers

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100, 2) AS death_percentage
FROM glassy-clock-429511-q6.portfolio_project.covid_deaths
WHERE continent IS NOT NULL

-- Total population vs vaccinations

WITH PopvsVac AS 
(
  SELECT dea.continent, 
         dea.location, 
         dea.date, 
         dea.population, 
         SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
  FROM glassy-clock-429511-q6.portfolio_project.covid_deaths AS dea
  JOIN glassy-clock-429511-q6.portfolio_project.covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac

CREATE OR REPLACE VIEW `glassy-clock-429511-q6.portfolio_project.PercentPopulationVaccinated` AS 
WITH PopvsVac AS 
(
  SELECT dea.continent, 
         dea.location, 
         dea.date, 
         dea.population, 
         vac.new_vaccinations,
         SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
  FROM `glassy-clock-429511-q6.portfolio_project.covid_deaths` AS dea
  JOIN `glassy-clock-429511-q6.portfolio_project.covid_vaccinations` AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)
SELECT continent, 
       location, 
       date, 
       population, 
       new_vaccinations,
       rolling_people_vaccinated, 
       (rolling_people_vaccinated / population) * 100 AS vaccination_percentage
FROM PopvsVac
ORDER BY location, date;
