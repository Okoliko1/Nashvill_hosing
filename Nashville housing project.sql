

SELECT *
FROM Portfolio_Activity..Nashville_housing


-- Standardize Date Format

Select SaleDateConverted, CONVERT(date, SaleDate)
FROM Portfolio_Activity..Nashville_housing

Update Portfolio_Activity..Nashville_housing
SET SaleDate =  CONVERT(date, SaleDate)

ALTER TABLE Portfolio_Activity..Nashville_housing
ADD SaleDateConverted Date;

UPDATE Portfolio_Activity..Nashville_housing
SET SaleDateConverted =  CONVERT(date, SaleDate)


-- Populate Property Address

Select *
FROM Portfolio_Activity..Nashville_housing
--WHERE PropertyAddress is null
ORDER BY ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Activity..Nashville_housing a
JOIN Portfolio_Activity..Nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Activity..Nashville_housing a
JOIN Portfolio_Activity..Nashville_housing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Breaking Out Address Into Individual Columns ( Address, City, State)

Select PropertyAddress
FROM Portfolio_Activity..Nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address

FROM Portfolio_Activity..Nashville_housing


ALTER TABLE Portfolio_Activity..Nashville_housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE Portfolio_Activity..Nashville_housing
SET PropertySplitAddress =  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE Portfolio_Activity..Nashville_housing
ADD PropertySplitCity Nvarchar(255);

UPDATE Portfolio_Activity..Nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))




SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM Portfolio_Activity..Nashville_housing


ALTER TABLE Portfolio_Activity..Nashville_housing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE Portfolio_Activity..Nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)


ALTER TABLE Portfolio_Activity..Nashville_housing
ADD OwnerSplitCity Nvarchar(255);

UPDATE Portfolio_Activity..Nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE Portfolio_Activity..Nashville_housing
ADD OwnerSplitState Nvarchar(255);

UPDATE Portfolio_Activity..Nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant)
FROM Portfolio_Activity..Nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Portfolio_Activity..Nashville_housing

UPDATE Portfolio_Activity..Nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicate

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

FROM Portfolio_Activity..Nashville_housing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

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

FROM Portfolio_Activity..Nashville_housing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress



-- Delete Unused Columns

SELECT *
FROM Portfolio_Activity..Nashville_housing

ALTER TABLE Portfolio_Activity..Nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Portfolio_Activity..Nashville_housing
DROP COLUMN SaleDate


-- After Cleaning the data i am proceeding to query the data to get more insight

--Calculating the average sale price for each city


SELECT PropertySplitCity,AVG(SalePrice) AS AverageSalePrice
FROM Portfolio_Activity..Nashville_housing
GROUP BY PropertySplitCity
ORDER BY  AverageSalePrice DESC




-- This query calculates the average total value of properties sold in each city in Nashville and sorts them in descending order, providing insights into the demand for higher value properties in different areas.

SELECT PropertySplitCity, AVG(TotalValue) AS AverageTotalValue
FROM Portfolio_Activity..Nashville_housing
GROUP BY PropertySplitCity
ORDER BY AverageTotalValue DESC

-- This query groups the properties sold in the Nashville housing market by the year they were sold and counts the number of properties sold in each year. The results are sorted in ascending order by the sale year.

SELECT DATEPART(YEAR, SaleDateConverted) AS Sale_Year, COUNT(*) AS PropertyCount
FROM Portfolio_Activity..Nashville_housing
GROUP BY  DATEPART(YEAR, SaleDateConverted)
ORDER BY Sale_Year 

--This query calculates the average sale price for properties in Nashville housing market, grouped by year. It also calculates the percentage difference in the average sale price between consecutive years using the LAG function. The results are sorted in ascending order of the sale year.

SELECT DATEPART(YEAR, SaleDateConverted) AS Sale_Year, AVG(SalePrice) AS Average_Sale_Price
, 100 * (AVG(SalePrice) / LAG(AVG(SalePrice)) OVER (ORDER BY YEAR(SaleDateConverted)) - 1) AS Pct_Diff
FROM Portfolio_Activity..Nashville_housing
GROUP BY DATEPART(YEAR, SaleDateConverted)
ORDER BY Sale_Year


-- This query gets the count of properties sold for each month over all years and displays the results in descending order.The MONTH and DATENAME functions are used to group the data by month and display the name of the month.

SELECT
  DATENAME(MONTH, SaleDateConverted) AS Month,
  COUNT(*) AS Property_Count
FROM Portfolio_Activity..Nashville_housing
GROUP BY MONTH(SaleDateConverted), DATENAME(MONTH, SaleDateConverted)
ORDER BY COUNT(*) DESC;


-- This query calculates the percentage of properties sold as vacant and non-vacant

SELECT SoldAsVacant, 
       COUNT(*) AS Property_Count, 
       CAST(COUNT(*) AS numeric) / (SELECT COUNT(*) FROM Portfolio_Activity..Nashville_housing) AS Percentage_Sold
FROM Portfolio_Activity..Nashville_housing
GROUP BY SoldAsVacant

-- This query retrieves the top 10 land use categories with the highest count of properties

SELECT Top 10 LandUse, COUNT(*) AS LandUse_count
FROM Portfolio_Activity..Nashville_housing
GROUP BY LandUse
ORDER BY LandUse_count DESC

--Average Value of properties by Land use category

SELECT Top 10 LandUse, AVG(TotalValue) AS Total_property_value
FROM Portfolio_Activity..Nashville_housing
GROUP BY LandUse
ORDER BY Total_property_value DESC

-- Average Sale price of by land use category

SELECT Top 10 LandUse, AVG(SalePrice) AS Avg_property_value
FROM Portfolio_Activity..Nashville_housing
GROUP BY LandUse
ORDER BY Avg_property_value DESC




--Create view for visualization

CREATE VIEW Average_sale_price_by_city AS
SELECT PropertySplitCity,AVG(SalePrice) AS AverageSalePrice
FROM Portfolio_Activity..Nashville_housing
GROUP BY PropertySplitCity
--ORDER BY  AverageSalePrice DESC


CREATE VIEW AverageValueByCity AS
SELECT PropertySplitCity, AVG(TotalValue) AS AverageTotalValue
FROM Portfolio_Activity..Nashville_housing
GROUP BY PropertySplitCity
--ORDER BY AverageTotalValue DESC

CREATE VIEW propertySaleByYear AS
SELECT DATEPART(YEAR, SaleDateConverted) AS Sale_Year, COUNT(*) AS PropertyCount
FROM Portfolio_Activity..Nashville_housing
GROUP BY  DATEPART(YEAR, SaleDateConverted)
--ORDER BY Sale_Year 

CREATE VIEW SalesByMonths AS
SELECT
  DATENAME(MONTH, SaleDateConverted) AS Month,
  COUNT(*) AS Property_Count
FROM Portfolio_Activity..Nashville_housing
GROUP BY MONTH(SaleDateConverted), DATENAME(MONTH, SaleDateConverted)
--ORDER BY COUNT(*) DESC;


CREATE VIEW SoldAsVacant AS
SELECT SoldAsVacant, 
       COUNT(*) AS Property_Count, 
       CAST(COUNT(*) AS numeric) / (SELECT COUNT(*) FROM Portfolio_Activity..Nashville_housing) AS Percentage_Sold
FROM Portfolio_Activity..Nashville_housing
GROUP BY SoldAsVacant


CREATE VIEW TopLandUses AS
SELECT Top 10 LandUse, COUNT(*) AS LandUse_count
FROM Portfolio_Activity..Nashville_housing
GROUP BY LandUse
--ORDER BY LandUse_count DESC


CREATE VIEW TopLandUseByAvgPropertyValue AS
SELECT Top 10 LandUse, AVG(SalePrice) AS Avg_property_value
FROM Portfolio_Activity..Nashville_housing
GROUP BY LandUse
ORDER BY Avg_property_value DESC








