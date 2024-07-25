SELECT *
 FROM `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing` LIMIT 1000

 --Standardize Date Format & Update table

 UPDATE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
 SET SaleDate = FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%B %d, %Y', SaleDate))
 WHERE SaleDate IS NOT NULL;

 --Populate Null Property Address Data

UPDATE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
SET PropertyAddress = (
  SELECT MAX(PropertyAddress)
  FROM `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing` AS sub
  WHERE sub.ParcelID = `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`.ParcelID
    AND sub.PropertyAddress IS NOT NULL
)
WHERE PropertyAddress IS NULL;

-- Separate Address and City
--Add New Columns
ALTER TABLE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
ADD COLUMN Address STRING,
ADD COLUMN City STRING;

-- Update New Columns with Extracted Values
UPDATE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
SET 
  Address = REGEXP_EXTRACT(PropertyAddress, r'^[^,]*'),
  City = REGEXP_EXTRACT(PropertyAddress, r',\s*(.*)')
WHERE 
  PropertyAddress IS NOT NULL;



--Populate Null Owner Address Data
-- Add New Columns
ALTER TABLE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
ADD COLUMN OwnerStreetAddress STRING,
ADD COLUMN OwnerCity STRING,
ADD COLUMN OwnerState STRING;

-- Update New Columns with Extracted Values
UPDATE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
SET 
  OwnerStreetAddress = REGEXP_EXTRACT(OwnerAddress, r'^[^,]*'),
  OwnerCity = REGEXP_EXTRACT(OwnerAddress, r',\s*([^,]*)'),
  OwnerState = REGEXP_EXTRACT(OwnerAddress, r',[^,]*,\s*(.*)')
WHERE 
  OwnerAddress IS NOT NULL;

--Change SoldAsVacant True and False to Yes and No

-- Add New Column
ALTER TABLE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
ADD COLUMN SoldAsVacantString STRING;

-- Update New Column with Converted Values
UPDATE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
SET SoldAsVacantString = CASE
  WHEN SoldAsVacant = TRUE THEN 'Yes'
  WHEN SoldAsVacant = FALSE THEN 'No'
  ELSE NULL
END
WHERE SoldAsVacant IS NOT NULL;

-- Remove Duplicates
-- Create a temporary table with only unique rows
CREATE OR REPLACE TABLE `glassy-clock-429511-q6.NashvilleHousing.Nashville_Unique2` AS
WITH Duplicates AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (
      PARTITION BY PropertyAddress, SaleDate, SoldAsVacantString
      ORDER BY `UniqueID `
    ) AS RowNumber
  FROM `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`
)
SELECT *
FROM Duplicates
WHERE RowNumber = 1;

-- Replace the original table with the unique rows
CREATE OR REPLACE TABLE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing` AS
SELECT *
FROM `glassy-clock-429511-q6.NashvilleHousing.Nashville_Unique2`;

--Remove Unused Columns

CREATE OR REPLACE TABLE `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing` AS
SELECT
  `UniqueID `,
  ParcelID,
  Address,
  City,
  SalePrice,
  LegalReference,
  SoldAsVacantString,
  OwnerName,
  OwnerStreetAddress,
  OwnerCity,
  OwnerState,
  Acreage,
  LandValue,
  BuildingValue,
  TotalValue,
  YearBuilt,
  Bedrooms,
  FullBath,
  HalfBath
FROM `glassy-clock-429511-q6.NashvilleHousing.NashvilleHousing`;