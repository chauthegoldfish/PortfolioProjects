----------- covid_deaths table
SELECT *
FROM covid_deaths 

-- Percentage of the Deaths Count per country
SELECT location, date, total_cases, total_deaths,
	(CAST(total_deaths AS numeric)/ (COALESCE (total_cases,0)))* 100 AS deaths_percentage
FROM covid_deaths
-- WHERE location like '%States%'
order by 1,2 desc

-- Countries with Highest Infection Rate compared to Polulation
SELECT location, population, MAX(total_cases) AS highest_infection_count, 
	MAX((COALESCE(total_cases,0)/ CAST(population AS numeric)*100)) AS percent_population_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected desc

--Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc

-- BREAKING THINGS DOWN PER CONTINENT

-- Continent with Highest Death Count per Population
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc

-- GLOBAL NUMBERS (not by continent or location) by date
SELECT date, SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	(SUM(CAST(new_deaths AS numeric))/ SUM(NULLIF(new_cases,0)))* 100 AS global_deaths_percentage
FROM covid_deaths
WHERE continent IS NOT NULL 
	AND new_cases IS NOT NULL
	AND new_deaths IS NOT NULL
	AND global_deaths_percentage IS NOT NULL 
GROUP BY date
order by global_deaths_percentage desc

-- GLOBAL NUMBERS (not by continent or location) overall 
SELECT SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	(SUM(CAST(new_deaths AS numeric))/ SUM(NULLIF(new_cases,0)))* 100 AS global_deaths_percentage
FROM covid_deaths
WHERE continent IS NOT NULL 
order by global_deaths_percentage desc


---------- covid_vaccinations table

-- Population Vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	-- PARTITION BY to make sure it's not counting over again when getting to the next country
	-- ORDER BY to specialize is as a ROLLING COUNT
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- (CAN BE EXCLUDED)
ORDER BY 2,3 


-- How many people in a country have been vaccinated? (using the max # of the rolling count divided by the country's population)
---- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated)
AS 
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	-- PARTITION BY to make sure it's not counting over again when getting to the next country
	-- ORDER BY to specialize is as a ROLLING COUNT
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- (CAN BE EXCLUDED)
-- ORDER BY 2,3 
	)
SELECT *, (rolling_people_vaccinated/population)*100 AS vaccinated_people_per_country
FROM PopvsVac


---TEMP TABLE
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
);

INSERT INTO PercentPopulationVaccinated (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
( 
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	-- PARTITION BY to make sure it's not counting over again when getting to the next country
	-- ORDER BY to specialize is as a ROLLING COUNT
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
-- WHERE dea.continent IS NOT NULL -- (CAN BE EXCLUDED)
-- ORDER BY 2,3 
	)
SELECT *, (rolling_people_vaccinated/population)*100 AS vaccinated_people_per_country
FROM PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
	-- PARTITION BY to make sure it's not counting over again when getting to the next country
	-- ORDER BY to specialize is as a ROLLING COUNT
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL -- (CAN BE EXCLUDED)
-- ORDER BY 2,3 
