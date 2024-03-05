/*

Cleaning Data in SQL Queries

*/


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
Select SaleDate, convert(date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

----Option 1: mission not completed, try a different query
Update NashvilleHousing --when you want to change the format/data type of a column in the data set
Set SaleDate=Convert(Date,SaleDate)

----Option2: If it doesn't Update properly
ALTER TABLE NashvilleHousing --STEP 1: When you want to modify your table, you have to run this first before set the data type for this column
Add SaleDateConverted Date; --Add a column to the new data set

Update NashvilleHousing --STEP 2: set the format/data type of the column you just added to data set
Set SaleDateConverted=Convert(Date,SaleDate)

Select SaleDate, SaleDateConverted --STEP 3: Check data
From PortfolioProject.dbo.NashvilleHousing

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
Select *
From PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null
order by ParcelID
----We found out that rows of the same ParcelID have the same address, so we will condition that any null cells in PropertyAdress will have the address of the other rows with the same ParcelID
----STEP 1: Identify the Null Property Address
Select a.ParcelID,a.PropertyAddress, b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)--SET A CONDITION FOR NULL value, if a.PropertyAddress is NULL, REPLACE WITH b.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
on a.ParcelID=b.ParcelID --We want to self join the table by joining the rows with the same Parcel ID
AND a.[UniqueID ]<>b.[UniqueID] --Differentiate the Unique ID to make sure the rows do not repeat themselves. Syntax [] is used here to delimit values that have space or special characters
WHERE a.PropertyAddress is null

----STEP 2: Update PropertyAddress for the cells that are null
Update a
Set PropertyAddress= ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
on a.ParcelID=b.ParcelID 
AND a.[UniqueID ]<>b.[UniqueID] 
WHERE a.PropertyAddress is null

----STEP 3: Check data again: rerun the code in step 1, it should appear no result now that we have updated the data

-- Breaking out Address into Individual Columns (Address, City, State)
----STEP 1: Seperate the city from the address that is seperated by the deliminer 'comma'
Select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address --Add -1 after charindex to get rid of the comman,Substring extract a portion of the address where as Charindex is trying to find the position of the 1st occurence of the comma (it is actually a number)
,SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,Len(PropertyAddress)) as City --Add+1 so we can start finding the characters BEHIND the comma and remove 1 after PropertyAddress because charindex formula will find the position to replace it
From PortfolioProject.dbo.NashvilleHousing
----CHARINDEX(',', PropertyAddress): This function finds the position of the first occurrence of the comma (,) in the PropertyAddress column. It returns the index or position of the comma within the string.
----SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)): The SUBSTRING function is then used to extract a portion of the PropertyAddress column. It takes three arguments:
----PropertyAddress: The column or expression from which to extract the substring.
----1: The starting position of the substring.
----CHARINDEX(',', PropertyAddress): The length of the substring, determined by the position of the first comma.

----STEP 2: Add 2 NEW columns to the data set
----2.1 Add column PropertySplitAddress to the data set and specify the DATA TYPE
ALTER TABLE NashvilleHousing 
Add PropertySplitAddress nvarchar (255);
----2.2 Set the formula for the new column
Update NashvilleHousing 
Set PropertySplitAddress=SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity nvarchar (255);

Update NashvilleHousing
Set PropertySplitCity=SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,Len(PropertyAddress))

Select *
From PortfolioProject.dbo.NashvilleHousing

----Use PARSENAME
----Step 1: apply parsename(owneraddress,1): did not work because parsename only recognizes '.' as seperator so we have to replace ',' with '.' to prepare the address to be 'parsed' meaning split into different columns
----Step 2: Specify the number of the position: 1,2,3th part of the address but in reverse order
Select OwnerAddress,
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
From PortfolioProject.dbo.NashvilleHousing
----Add new columns to the table with data type
ALTER TABLE NashVilleHousing
Add OwnerSplitAddress nvarchar (255),
OwnerCity nvarchar (255),
OwnerStates nvarchar (255)
----Set value for data
UPDATE NashVilleHousing
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE NashVilleHousing
SET OwnerCity=PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE NashVilleHousing
SET OwnerStates=PARSENAME(REPLACE(OwnerAddress,',','.'),1)


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field
Select Distinct (SoldAsVacant), count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2
----The result shows soem Y and N, which we want to change them all so that we have only 2 groups: Yes and No

Select Soldasvacant,
	CASE when SoldAsVacant='Y' then 'Yes'
		when SoldAsVacant='N' then 'No'
		ELSE SoldAsVacant
		END
From PortfolioProject.dbo.NashvilleHousing
----Update the case when in the tables

Update NashvilleHousing
Set SoldAsVacant=CASE when SoldAsVacant='Y' then 'Yes'
		when SoldAsVacant='N' then 'No'
		ELSE SoldAsVacant
		END



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
----Note: First, We need to partition by sth unique in each row. --ORDER BY ParcelID Give only result '1', so we need to put in CTE so that we can select * from RowNumCTE and set condition when row_num >1
WITH RowNumCTE AS(
Select 
	*,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID, 
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY uniqueID
				) row_num
From PortfolioProject.dbo.NashvilleHousing
)
---- they have to be run together with the se;ect * from RowNumCTE to work

SELECT* --DELETE ---CHANGE FROM SELECT TO DELETE TO REMOVE THESE DUPLICATED ROWS, THE REWRITE SELECT * TO VIEW IF THERE IS STILL SOME DUPLICATES LEFT
FROM RowNumCTE
where row_num >1

SELECT*
FROM RowNumCTE
where row_num >1


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress,TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















