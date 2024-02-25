SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null --to get rid of rows where thhe continent is misplaced
order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 1,2

--Looking at the total cases vs total deaths--

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)--we want to see the death percentage but it does not work because the colum total_deaths is not consisted of only number
FROM PortfolioProject..CovidDeaths
order by 1,2

--Try again and validate whether each column has the right data type (INT or FLOAT)
--Option 1: Use Convert(float,data) to transform data type
SELECT location, date, total_cases, new_cases, total_deaths,convert(float,total_deaths)/convert(float,total_cases) as DeathPercentage
FROM PortfolioProject..CovidDeaths
order by 1,2
--Option 2: Use Cast(data as float) to transform data type
SELECT location, date, total_cases, new_cases, total_deaths,cast(total_deaths as float)/cast(total_cases as float) as DeathPercentage
FROM PortfolioProject..CovidDeaths
order by 1,2
--Option 3: Use CASE WHEN and ISNUMERIC
SELECT location, date, total_cases, new_cases, total_deaths,
	CASE 
	WHEN ISNUMERIC(total_cases)=1 AND ISNUMERIC(total_deaths)=1 and cast(total_cases as float) <>0
	THEN cast(total_deaths as float)/cast(total_cases as float)
	ELSE NULL
	END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
order by 1,2

--The int data type is a 4-byte signed integer.
--It can store whole numbers within the range of approximately -2.1 billion to 2.1 billion.
--int values are precise whole numbers; they do not store decimal places.
--Example: 1, -1000, 2147483647.
--float (Floating-Point):

--The float data type is a 8-byte floating-point number.
--It is designed for representing approximate real numbers, including both integers and decimals.
--float can store a wide range of values but may introduce rounding errors due to its nature as a floating-point representation.
--Example: 3.14, -123.456, 1.23456789e10.

--ISNUMERIC(total_deaths) = 1 AND ISNUMERIC(total_cases) = 1:

--ISNUMERIC is a function in SQL Server that checks whether an expression can be evaluated as a numeric type.
--This part of the condition checks if both total_deaths and total_cases can be interpreted as numeric values. The = 1 checks if both conditions are true (both are numeric). If it evaluates to 0, it means that the value in the total_deaths column is not numeric
--CAST(total_cases AS FLOAT) <> 0:

--CAST is used to explicitly CONVERT the total_cases column to the FLOAT data type. CONVERT is similar to CAST with different sytax e.g. CONVERT(float,total_deaths), CAST(total_deaths as float)
--<> 0 checks if the result of the cast is not equal to zero, ensuring that the denominator (total_cases) is not zero to avoid division by zero errors.
--THEN CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT):

--If both conditions from the first part are true (both total_deaths and total_cases are numeric) and total_cases is not zero, then the formula calculates the Death Percentage.
--It casts total_deaths and total_cases to the FLOAT data type and performs the division operation (/), resulting in the Death Percentage.

--Show the likelihood of dying if you contract covid in your country---
SELECT  location,date,total_cases,total_deaths,(convert(float,total_deaths)/convert(float,total_cases))*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
Where location like '%vietnam%' ---included the word states or the name of your country---
ORDER BY 1,2

--Look at total cases vs population, %of population got covid
SELECT  location,date,population,total_cases,(convert(float,total_cases)/convert(float,population))*100 as CasesPercentage
FROM PortfolioProject.dbo.CovidDeaths
Where location like '%vietnam%' ---included the word states or the name of your country---
ORDER BY 1,2

--Look at countries with the highest infection rate compared to population

SELECT  location,MAX(total_cases) as HighestInfestionCount, Max(convert(float,total_cases)/convert(float,population))*100 as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--Where location like '%vietnam%' ---included the word states or the name of your country---
GROUP BY Location, Population
ORDER BY PercentPopulationInfected


--Show the continent with the highest death count--
SELECT  location,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE Continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount desc

--Global numbers--
SELECT  date,sum(new_cases),sum(cast(new_deaths as int)),sum(new_deaths)/sum(cast(new_cases as int))*100 as NewDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
Where continent is not null
Group by date 
Order by 1,2
--The error you're encountering, "Divide by zero error encountered," indicates that you are attempting to perform a division operation where the denominator (sum(cast(new_cases as int))) is zero in some cases.To handle this issue, you can modify your query to check for zero denominators before performing the division

SELECT sum(new_cases) as TotalNewCases,sum(cast(new_deaths as INT)) as TotalNewDeaths,
	CASE
		WHEN sum(cast(new_cases as int))<>0
		THEN sum(cast(new_deaths as int))/sum(cast(new_cases as int))*100
		ELSE null
		END AS NewDeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
Where continent is not null
GROUP BY date
ORDER BY date

--Lookign at Total Population vs Vaccinations: calulating the cumulative and running sum of NEW_VACCINATIONS defined/divided by partition of dea.location, order by (alphabetically dea.location: from Australia to Zimbabwe and date, from the oldest to newest date)
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location,dea.Date) as RollingPeopleVaccinated --calculate the running sum for each partition of location and order by to present the row of data, if the column 'new_vaccinations' has value, the Cumulative Vaccinations column will be added value, if it is NULL the value stays the same 
--,(RollingPeopleVaccinated/population)*100--you cannot use the column you just created for another column, so you need to use CTE
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2,3
--Note: DON'T use convert (INT,vac.new_vaccinations), use BIGINT instead. The error you're encountering, "Arithmetic overflow error converting expression to data type int," suggests that there is an attempt to convert a value to an int data type, but the value is too large to fit within the range of an int.

--Same formula but order by continent
Select dea.continent,dea.date,dea.population,vac.new_vaccinations,
Sum(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.continent order by dea.continent,dea.Date) as CumulativeVaccinations--calculate the running sum for each partition of location and order by to present the row of data
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
order by 1,2

--USE CTE (common table expressions) so you will be able to temporarirly use the result of the table with new columns that you created (RollingPeopleVaccinated in this case)
--1. Naming the CTE and select the columns
With PopVsVac (continent,location, date,populations,new_vaccinations,RollingPeopleVaccinated) --nr of columns in CTE=nr of columns in the table we created earlier
as
(
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location,dea.Date) as RollingPeopleVaccinated  --calculate the running sum for each partition of location and order by to present the row of data, if the column 'new_vaccinations' has value, the Cumulative Vaccinations column will be added value, if it is NULL the value stays the same 
--,(RollingPeopleVaccinated/population)*100--you cannot use the column you just created for another column, so you need to use CTE
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
--order by 2,3 (Invalid in view)
)
--2. Show data from the CTE you just created, you cannot run it alone, MUST run it with the CTE & Calculate the percentage of new vaccinations on populations
SELECT *,(RollingPeopleVaccinated/populations)*100 as PercentPopulationVaccinated
FROM PopVsVac

-- TEMP TABLE (Alternative for using CTE)
--1. Create the table with all the data type
 DROP TABLE IF EXISTS #PercentPopulationVaccinated --use this when you want to edit your query and re-run your table
	CREATE TABLE #PercentPopulationVaccinated
	(continent nvarchar(255),
	location nvarchar (255),
	date datetime,
	populations numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric)
	--2. Insert data from the selected tables to the new table
	INSERT INTO #PercentPopulationVaccinated
	Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	Sum(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location,dea.Date) as RollingPeopleVaccinated --calculate the running sum for each partition of location and order by to present the row of data, if the column 'new_vaccinations' has value, the Cumulative Vaccinations column will be added value, if it is NULL the value stays the same 
	--,(RollingPeopleVaccinated/population)*100
	From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccinations vac
	on dea.location=vac.location
	and dea.date=vac.date
	where dea.continent is not null
	--order by 2,3
	--3. Select data from the newly created table
	Select *, (RollingPeopleVaccinated/populations)*100--Invalid column name 'RollingPeopleVaccinated'.
	FROM #PercentPopulationVaccinated

	--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS--Go to PortfolioProject>Views>dbo.PercentPeopleVaccinated

	Create View PercentPeopleVaccinated as
	Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	Sum(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location,dea.Date) as RollingPeopleVaccinated --calculate the running sum for each partition of location and order by to present the row of data, if the column 'new_vaccinations' has value, the Cumulative Vaccinations column will be added value, if it is NULL the value stays the same 
	--,(RollingPeopleVaccinated/population)*100
	From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccinations vac
	on dea.location=vac.location
	and dea.date=vac.date
	where dea.continent is not null
	--order by 2,3

	SELECT*
	From PercentPeopleVaccinated