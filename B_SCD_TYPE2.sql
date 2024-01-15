
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* In this code we are going to implement the SCD type 2 for the table Customer. It will support retention of historical values for customer data. First we will load                     -
the new or the updated data from the chinook database to our intermediate staging area. We are going to create a new table in the staging area named StagingDimCustomer. We need this     -
so we can store the new data, and achieve the retention of the historical values we mentioned before. By comparing this table with DimCustomer of our DW, we can load the                 -
new data to our DW. Note that we added 4 new attributes (RowIsCurrent, RowStartDate, RowEndDate, RowChangeReason) that are used for the retention of the history of the data.            */
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--========================================================================--
/* We use the DW here so we can drop the constraint between the fact table
and the DimCustomer, so we can be able to make updates, deletes, etc */

USE ChinookDW
GO

---- Drop Constraints
ALTER TABLE FactInvoiceLine drop  constraint [FactInvoiceLineCustomer]
GO
--========================================================================--


USE ChinookStaging
GO


--------------------------------------------------------------- Loading Customer of ChinookStaging --------------------------------------------------------------
/* First we truncate ( delete data from ) the table Customer from chinookstaging and then we load it with the new data from the OLTP Chinook */
TRUNCATE TABLE [ChinookStaging].[dbo].[Customer];

INSERT INTO Customer(CustomerID,  FirstName,  LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, SupportRepId,
			EmployeeFullName, Title, ReportsTo)
SELECT 
	CustomerID,
	c.FirstName,
	c.LastName, 
	Company, 
	c.Address,
	c.City, 
	c.State, 
	c.Country,
	c.PostalCode, 
	c.Phone, 
	c.Fax,
	c.Email, 
	SupportRepId,
	(e.LastName + ' ' + e.FirstName),
	e.Title, 
	e.ReportsTo
FROM  Chinook.[dbo].Customer AS c
INNER JOIN Chinook.dbo.Employee AS e
	ON e.EmployeeId = c.SupportRepId
 
-----------------------------------------------------------

TRUNCATE TABLE [ChinookStaging].[dbo].InvoiceLine;

INSERT INTO InvoiceLine
(InvoiceLineId,  InvoiceId,  TrackId,  UnitPrice,  Quantity,  CustomerId, InvoiceDate,  BillingAddress,
BillingCity, BillingState, BillingCountry, BillingPostalCode, Total)
SELECT
	InvoiceLineId,
	i.InvoiceId,  
	TrackId,
	UnitPrice,
	Quantity,
	i.CustomerId,
	i.InvoiceDate,
	i.BillingAddress,
	i.BillingCity,
	i.BillingState,
	i.BillingCountry,
	i.BillingPostalCode,
	Total
FROM [Chinook].[dbo].InvoiceLine il
	INNER JOIN Chinook.[dbo].Invoice  i 
		ON il.InvoiceId= i.InvoiceId
WHERE InvoiceDate >= '2013-12-23';
--------------------------------------------------------


--------------------------------------------------------------- StagingDimCustomer Creation --------------------------------------------------------------
 
DROP TABLE IF EXISTS ChinookStaging.[dbo].Staging_DimCustomer;

CREATE TABLE ChinookStaging.[dbo].Staging_DimCustomer (
	CustomerKey INT IDENTITY(1,1) NOT NULL,
	CustomerID INT NOT NULL,
	FirstName NVARCHAR(40) NOT NULL, 
	LastName NVARCHAR(20) NOT NULL,
	Company VARCHAR(80) NULL,
	Address NVARCHAR(70) NULL,
	City NVARCHAR(40) NULL,
	State NVARCHAR(40) NULL,
	Country NVARCHAR(40) NULL,
	PostalCode NVARCHAR(40) NULL,
	Phone NVARCHAR(24) NULL,
	Fax NVARCHAR(24) NULL,
	Email NVARCHAR(60) NOT NULL,
	SupportRepId INT NULL,
	EmployeeFullName NVARCHAR(41) NOT NULL,
	EmployeeTitle NVARCHAR(30) NULL,
	ReportsTo INT NULL,
	RowIsCurrent INT DEFAULT 1 NOT NULL,
	RowStartDate DATE DEFAULT '1899-12-31' NOT NULL,
	RowEndDate DATE DEFAULT '9999-12-31' NOT NULL,
	RowChangeReason VARCHAR(200) NULL
);

--------------------------------------------------------------- Load data in StagingDimCustomer -------------------------------------------------------------------
/* We create this table so we can use it and compare the new data with the previous data stored in the respective table from DW. We can see if the data are updated,
or if we have new data and so then we can do the edits */

INSERT INTO ChinookStaging.[dbo].Staging_DimCustomer(
	CustomerID, FirstName, LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, SupportRepId, EmployeeFullName, EmployeeTitle, ReportsTo)
SELECT [CustomerID]customer_id,
	   FirstName,
	   LastName,
	   Company,
	   Address, 
	   City, 
	   State,
	   Country,
	   PostalCode,
	   Phone,
	   Fax,
	   Email, 
	   SupportRepId,
	   EmployeeFullName,
	   Title, 
	   ReportsTo
FROM ChinookStaging.[dbo].[Customer] ;

 --------------------------------------------------------------- Load data in DimCustomer of DW -------------------------------------------------------------------
 /* Time to do the hardwork. Here is the stage where we are going to load the data in the Data Warehouse (DW). By loading, we mean that we are going to add new data,
 or update the old ones by keeping at the same time their history. This is the implementation of delta Loading.*/

declare @etldate date = '2013-12-23'; -- The date after last

INSERT INTO ChinookDW.[dbo].DimCustomer (CustomerID, LastName, FirstName, Company, CustomerAddress, City, CustomerState, CustomerCountry, CustomerPostalCode, 
CustomerPhone, CustomerFax, CustomerEmail, SupportedByEmployee, EmployeeFullName, EmployeeTitle, ReportsTo, RowStartDate, RowChangeReason )
SELECT 
	CustomerID, LastName, FirstName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, SupportRepId, 
	EmployeeFullName, EmployeeTitle, ReportsTo, @etldate, ActionName
FROM
(
	MERGE ChinookDW.[dbo].DimCustomer AS target
		USING ChinookStaging.[dbo].Staging_DimCustomer as source
		ON target.[CustomerID] = source.[CustomerID]
	 WHEN MATCHED 	 AND 
	 (source.City <> target.City  
	 OR source.Company <> target.Company
	 OR source.State <> target.CustomerState
	 OR source.Country <> target.CustomerCountry
	 OR source.PostalCode <> target.CustomerPostalCode
	 OR source.Phone <> target.CustomerPhone
	 OR source.Fax <> target.CustomerFax
	 OR source.Email <> target.CustomerEmail
	 OR source.Address <> target.CustomerAddress
	 OR source.Company <> target.Company)
	 AND target.[RowIsCurrent] = 1 
	 THEN UPDATE SET
		 target.RowIsCurrent = 0,
		 target.RowEndDate = dateadd(day, -1, @etldate),
		 target.RowChangeReason = 'UPDATED NOT CURRENT'
	 WHEN NOT MATCHED THEN
	   INSERT  (
			CustomerID, LastName, FirstName, Company, CustomerAddress, City, CustomerState, CustomerCountry, CustomerPostalCode, 
	CustomerPhone, CustomerFax, CustomerEmail, SupportedByEmployee, EmployeeFullName, EmployeeTitle, ReportsTo, RowStartDate,   RowChangeReason
	   )
	   VALUES( 
		   source.CustomerID, source.LastName ,source.FirstName,
			source.Company, source.Address, source.City, source.State, source.Country, source.PostalCode, 
	source.Phone, source.Fax, source.Email, source.SupportRepId,
	 source.EmployeeFullName, source.EmployeeTitle, source.ReportsTo,CAST(GetDate() AS Date), 'NEW RECORD'
	   )
	WHEN NOT MATCHED BY Source THEN
		UPDATE SET 
			Target.RowEndDate= dateadd(day, -1, CAST(GetDate() AS Date))
			,target.RowIsCurrent = 0
			,Target.RowChangeReason  = 'SOFT DELETE'
	OUTPUT 
		 source.CustomerID, source.LastName ,source.FirstName, source.Company, source.Address, source.City, source.State, 
		 source.Country, source.PostalCode, source.Phone, source.Fax, source.Email, source.SupportRepId , source.EmployeeFullName, 
		 source.EmployeeTitle, source.ReportsTo, $Action AS ActionName   
) Mrg
WHERE Mrg.ActionName = 'UPDATE'
AND [CustomerID] IS NOT NULL;



------------------------------------------------
-- insert new facts ...

INSERT INTO [ChinookDW].[dbo].FactInvoiceLine(
    Date_Key, Track_Key, Employee_Key, Customer_Key,
    InvoiceLine_Id, Invoice_Id, TrackId, Quantity, UnitPrice, c.CustomerId, InvoiceDate,
	BillingAddress, BillingCity, BillingState, BillingCountry, BillingPostalCode, Total)
SELECT d.DateKey, 
	   t.Track_Key, 
	   e.Employee_key,
	   c.Customer_Key,
	   il.InvoiceLineId, il.InvoiceId, il.TrackId, il.Quantity, il.UnitPrice, il.CustomerId,
	   il.InvoiceDate, il.BillingAddress, il.BillingCity, il.BillingState, il.BillingCountry, il.BillingPostalCode, il.Total
FROM 
    ChinookStaging.dbo.InvoiceLine AS il
INNER JOIN ChinookDW.dbo.DimCustomer AS c
    ON c.CustomerID=il.CustomerId and c.RowIsCurrent=1
INNER JOIN ChinookDW.dbo.DimEmployee AS e
    ON e.EmployeeID = c.SupportedByEmployee and c.RowIsCurrent=1
INNER JOIN ChinookDW.dbo.DimTrack t
	ON t.TrackId = il.TrackId and c.RowIsCurrent=1
INNER JOIN ChinookDW.dbo.DimDate d
	ON d.Date = il.InvoiceDate and c.RowIsCurrent=1

GO

--===============================================================================================--
/* Again here we use Chinook DW so we can recover the constraint between the fact table Invoice
Line and the Dimension Customer. */

USE ChinookDW
GO

-- Recover Constraints
ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLineCustomer] FOREIGN KEY (Customer_Key)
    REFERENCES DimCustomer (Customer_Key)
GO

--===============================================================================================--