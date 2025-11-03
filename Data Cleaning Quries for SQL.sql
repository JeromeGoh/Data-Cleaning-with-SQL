/*
Cleaning Data in SQL Quries
*/

Select * 
From dbo.NashvilleHousing

-------------------------------------------------------------------------------------------
-- Standardize Date Format

-- View original SaleDate and convert into standard DATE format
Select SaleDate, CONVERT(Date, SaleDate) 
From dbo.NashvilleHousing

-- Upate the SaleDate column with a standerdized DATE format
Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Add a column to store the converted SaleDate 
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Populate the newSaleDateConverted column with cleaned data values
Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Verifying conversion
Select SaleDateConverted, CONVERT(Date, SaleDate) 
From dbo.NashvilleHousing

-------------------------------------------------------------------------------------------
-- Populating Property Address Data

-- Check records ordered by ParcelID to identify duplicates with missing PropertyAddress
Select *
From dbo.NashvilleHousing
-- Where PropertyAddress is NULL (To filter missing PropertyAddress)
order by ParcelID

-- Find matching ParcelIDs where one recording has a missing PropertyAddress
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a 
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

-- Update missing (NULL) PropertyAddress with values from matching ParcelIDs
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-- Check after updating missing (NULL) PropertyAddress with values 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a 
JOIN dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL
-------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns 

-- Check records ordered by ParcelID to identify duplicates with missing PropertyAddress
Select PropertyAddress
From dbo.NashvilleHousing
-- Where PropertyAddress is NULL (To filter missing PropertyAddress)
-- order by ParcelID

-- Preview how to split PropertyAddress using SUBSTRING + CHARINDEX
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address -- Extracts street address (before comma)
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address -- Extracts city (after comma)

From dbo.NashvilleHousing

-- Add new column for split street address
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);
-- DROP COLUMN PropertySplitAddress; -- To drop column for PropertySplitAddress

-- Update new column with street address (before coma)
Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

-- Add new column for split city name
ALTER TABLE NashvilleHousing
ADD PropertySplitACity Nvarchar(255);

-- Update new column with city name (after coma)
Update NashvilleHousing
SET PropertySplitACity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- View final results after splitting
SELECT * 
From dbo.NashvilleHousing

SELECT OwnerAddress
FROM dbo.NashvilleHousing

-- Using PARSENAME to split into Address, City & State
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousing

-- Add new column for owner street address
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

-- Fill new column with split address (before 1st comma)
Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- Add new column for owner city (middle part)
ALTER TABLE NashvilleHousing
ADD OwnerSplitACity Nvarchar(255);

-- Add new column for owner city
Update NashvilleHousing
SET OwnerSplitACity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Fill new column with split address (last part) 
ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

-- Add new column for split address
Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Check on final results after splitting OwnerAddress
SELECT * 
From dbo.NashvilleHousing

-------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Solid as Vacant" field

-- Check unique values and their counts in SoldAsVacantColumn
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM dbo.NashvilleHousing
Group By SoldAsVacant
order by 2

-- Using CASE: to replace 'Y' with 'Yes' and 'N' with 'No' for consistency
SELECT SoldAsVacant 
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM dbo.NashvilleHousing

-- Apply the transformation to the table
UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
	END

-- Verify the results after updating (Only left with 'Yes' and 'No')
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM dbo.NashvilleHousing
Group By SoldAsVacant
order by 2

-------------------------------------------------------------------------------------------
-- Remove Duplicates

-- Create CTE to identify duplicate rows based on key columns
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID -- Keep the first occurrence
					) row_num

	FROM dbo.NashvilleHousing
	-- ORDER BY ParcelID
)

-- View all rows flagged as duplicates (row_num > 1)
SELECT *
FROM RowNUMCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete duplicate rows while keeping the first instance
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

	FROM dbo.NashvilleHousing
	-- ORDER BY ParcelID
)

DELETE
FROM RowNUMCTE
WHERE row_num > 1

-------------------------------------------------------------------------------------------
-- Delete Unused Columns

-- View current table before removing columns (For verification)
SELECT * 
FROM dbo.NashvilleHousing

-- Drop unusd columns that are no longer needed after data cleaning
ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

-- Drop old SaleData Column (Replaced with SaleDateConverted)
ALTER TABLE dbo.NashvilleHousing
DROP COLUMN SaleDate