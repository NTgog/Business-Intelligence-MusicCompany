
--==================================================================================================--
/* In this .sql file we load tha data from the intermediate staging area to the Data Warehouse.      -
Keep in mind that you will not see to load data to the Date Dimension here. We do this in another    -
script.                                                                                             */
--==================================================================================================--

USE ChinookDW

---- Only for the first load
TRUNCATE TABLE FactInvoiceLine;
TRUNCATE TABLE Bridge ;
TRUNCATE TABLE DimTrack;
TRUNCATE TABLE DimPlaylist;
TRUNCATE TABLE DimCustomer;
TRUNCATE TABLE DimEmployee;


--===================================================
-- Dimension Employee
-----------------------------
INSERT INTO DimEmployee (EmployeeID, LastName, FirstName, EmployeeTitle, ReportsTo, BirthDate, HireDate, EmployeeAddress, EmployeeCity, EmployeeCountry, EmployeeState, 
	Employee_PostalCode, Employee_Phone, Employee_Fax, Employee_Mail)
SELECT EmployeeId,
	   LastName,
	   FirstName,
	   Title,  ----> EmployeeTitle
	   ReportsTo,
	   BirthDate,
	   HireDate,
	   Address,  ----> EmployeeAddress
	   City,  ----> EmployeeCity
	   Country, ----> EmployeeCoutry
	   State, ----> EmployeeState
	   PostalCode, ----> Employee_PostalCode
	   Phone, ----> Employee_Phone
	   Fax, ----> Employee_Fax
	   Email ----> Employee_Mail
FROM ChinookStaging.dbo.Employee


--===================================================
-- Dimension Customer
-----------------------------
INSERT INTO DimCustomer(CustomerID, LastName, FirstName, Company, CustomerAddress, City, CustomerState, CustomerCountry, CustomerPostalCode, CustomerPhone, CustomerFax, 
	CustomerEmail, SupportedByEmployee, EmployeeFullName,  EmployeeTitle, ReportsTo)
SELECT CustomerID,
	   LastName, 
	   FirstName, 
	   Company, 
	   Address, ----> CustomerAddress 
	   City, ----> CustomerCity
	   State, ----> CustomerState
	   Country, ----> CustomerCountry
	   PostalCode, ----> CustomerPostalCode
	   Phone, ----> CustomerPhone
	   Fax, ----> CustomerFax
	   Email, ----> CustomerEmail
	   SupportRepId,  ----> SupportedByEmployee
	   EmployeeFullName, 
	   Title, ----> EmployeeTitle
	   ReportsTo
FROM ChinookStaging.dbo.Customer


--===================================================
-- Dimension Track
-----------------------------
INSERT INTO DimTrack(TrackId, TrackName, Composer, Milliseconds, Bytes, UnitPrice, AlbumId, AlbumTitle, Artist_Id, ArtistName, MediaTypeId, MediaTypeName,
	GenreId, GenreName)
SELECT TrackId,
	   Name, ----> TrackName
	   Composer,
	   Milliseconds,
	   Bytes, 
	   UnitPrice,
	   AlbumId,
	   AlbumTitle,
	   ArtistId, 
	   ArtistName, 
	   MediaTypeId,
	   MediaTypeName,
	   GenreId,
	   GenreName
FROM ChinookStaging.dbo.Track


--===============================================
-- Dimension Playlist
-----------------------------
INSERT INTO DimPlaylist(PlaylistName)
SELECT 
	   Name ----> PlaylistName
FROM ChinookStaging.dbo.Playlist


--===================================================
-- Bridge
-----------------------------
INSERT INTO Bridge(TrackId, PlaylistId)
SELECT TrackId, 
	   PlaylistId
FROM ChinookStaging.dbo.PlaylistTrackBridge


--===================================================
-- Fact Invoice Line
-----------------------------
/* We need to note here the usage of the aggregate function max combined with the group by clause. The resons is that we have a many to many
relationship in our database and when we load data from invoiceLine to the fact, same rows with only one different value in the keys occur. 
For example if a track (in which is connected an invoice) belongs to 3 playlists, we are going to have in the fact 3 same rows with 
different values in the PlaylistKey, which is not good practice. So we minimize this problem by using the aggregate function MAX() ( we 
could also use MIN() ). */

INSERT INTO FactInvoiceLine( Date_Key, Track_Key, Employee_Key, Customer_Key, InvoiceLine_Id, Invoice_Id, TrackId, Quantity, UnitPrice, 
	                         CustomerId, InvoiceDate, BillingAddress, BillingCity, BillingState, BillingCountry, BillingPostalCode, Total )
SELECT d.DateKey,
	   Track_Key,
	   Employee_Key,
	   Customer_Key, 
	   InvoiceLineId, 
	   il.InvoiceId, 
	   il.TrackId, 
	   Quantity, 
	   il.UnitPrice, 
	   il.CustomerId,
	   il.InvoiceDate,
	   il.BillingAddress,
	   il.BillingCity, 
	   il.BillingState,
	   il.BillingCountry, 
	   il.BillingPostalCode,
	   il.Total
FROM ChinookStaging.dbo.InvoiceLine AS il
INNER JOIN ChinookDW.dbo.DimCustomer AS c
	ON c.CustomerId = il.CustomerId
INNER JOIN ChinookDW.dbo.DimEmployee as e
	ON e.EmployeeId = c.SupportedByEmployee
INNER JOIN ChinookDW.dbo.DimDate as d
	ON d.Date = il.InvoiceDate
INNER JOIN ChinookDW.dbo.DimTrack as t
	ON t.TrackId = il.TrackId
--INNER JOIN Bridge b
--	ON b.TrackId = il.TrackId
--INNER JOIN ChinookDW.dbo.DimPlaylist as p
--	ON p.PlaylistId = b.PlaylistId
