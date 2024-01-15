--=====================================================================================================================================================--
/* In this .sql file, we create the Data Warehouse (DW) of Chinook. The tables, date, Track, Customer and Employee, Playlist are the dimensions of our 
DW. The InvoiceLine table is the fact. For every dimension we changed the primary keys, and included them to the fact table to create the connection   
and create a star scheme DW. Note the relationships are not created here.                                                                              */                                                                            
--=====================================================================================================================================================--

CREATE DATABASE ChinookDW
GO

USE ChinookDW
GO

DROP TABLE IF EXISTS Bridge;
DROP TABLE IF EXISTS dimTrack;
DROP TABLE IF EXISTS dimEmployee;
DROP TABLE IF EXISTS dimPlaylist;
DROP TABLE IF EXISTS dimCustomer;
DROP TABLE IF EXISTs dimInvoice;
DROP TABLE IF EXISTS FactInvoiceLine;


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ Dimension Track Creation ----------------------------------------------------------------------
---- dimTrack dimension will need to include:
CREATE TABLE DimTrack (
	Track_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- New PK
    TrackId INT NOT NULL ,
    TrackName NVARCHAR(200) NOT NULL,
	Composer NVARCHAR(220) NULL,
	Milliseconds INT NULL,
	Bytes INT NULL,
	UnitPrice NUMERIC(10,2) NOT NULL,
	AlbumId INT NULL,
	AlbumTitle NVARCHAR(160) NOT NULL,
	Artist_Id INT NOT NULL,
	ArtistName NVARCHAR(120) NULL,
	MediaTypeId INT NULL,
	MediaTypeName NVARCHAR(120) NULL,
	GenreId INT NULL,
	GenreName NVARCHAR(120) NULL

);

----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- Dimension Playlist Creation ----------------------------------------------------------------------
-- We added 4 new attributes (RowIsCurrent, RowStartDate, RowEndDate, RowChangeReason) that we are going need for the SCD type 2 implementation later.
CREATE TABLE DimPlaylist (
	-- Playlist_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- New PK
    PlaylistId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	PlaylistName NVARCHAR(120) NULL
);


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------ Bridge PlaylistTrack Creation -----------------------------------------------------------------
---- dimTrack dimension will need to include:

CREATE TABLE Bridge (
    BridgeId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- ADD PK
    TrackId INT NOT NULL,
    PlaylistId INT NOT NULL
);


----------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- Dimension Customer Creation ----------------------------------------------------------------------
-- We added 4 new attributes (RowIsCurrent, RowStartDate, RowEndDate, RowChangeReason) that we are going need for the SCD type 2 implementation later.

CREATE TABLE DimCustomer(
	Customer_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- New PK
	CustomerId INT NOT NULL,
	LastName NVARCHAR(20) NOT NULL,
	FirstName NVARCHAR(40) NOT NULL,
	Company NVARCHAR(80) NULL,
	CustomerAddress NVARCHAR(70) NULL,
	City NVARCHAR(40) NULL,
	CustomerState NVARCHAR(40) NULL,
	CustomerCountry NVARCHAR(40) NULL,
	CustomerPostalCode NVARCHAR(10) NULL,
	CustomerPhone NVARCHAR(24) NULL,
	CustomerFax NVARCHAR(24) NULL,
	CustomerEmail NVARCHAR(60) NOT NULL,
	SupportedByEmployee INT NULL,
	EmployeeFullName NVARCHAR(41) NOT NULL,
	EmployeeTitle NVARCHAR(30) NULL,
	ReportsTo INT NULL,
	------------------------------------------------
	RowIsCurrent INT DEFAULT 1 NOT NULL,
	RowStartDate DATE DEFAULT '1899-12-31' NOT NULL,
	RowEndDate DATE DEFAULT '9999-12-31' NOT NULL,
	RowChangeReason VARCHAR(200) NULL
);


-------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Dimension Employee Creation --------------------------------------------------------------------
CREATE TABLE DimEmployee(
	Employee_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- New PK
	EmployeeId INT NULL,
	LastName NVARCHAR(20) NOT NULL,
	FirstName NVARCHAR(20) NOT NULL,
	EmployeeTitle NVARCHAR(30) NULL,
	ReportsTo INT NULL,
	BirthDate datetime NULL,
	HireDate datetime NULL,
	EmployeeAddress NVARCHAR(70) NULL,
	EmployeeCity NVARCHAR(40) NULL,
	EmployeeState NVARCHAR(40) NULL,
	EmployeeCountry NVARCHAR(40) NULL,
	Employee_PostalCode NVARCHAR(10) NULL,
	Employee_Phone NVARCHAR(24) NULL,
	Employee_Fax NVARCHAR(24) NULL,
	Employee_Mail NVARCHAR(60) NULL
	);


-------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ FACT InvoiceLine Creation ----------------------------------------------------------------------
CREATE TABLE FactInvoiceLine(
	Date_Key INT NOT NULL,
    Track_Key INT NOT NULL,
	-- Playlist_Key INT NOT NULL,
	Employee_Key INT NOT NULL,
	Customer_Key INT NOT NULL,
	-----------------------------------
    InvoiceLine_Id INT NOT NULL,
    Invoice_Id INT NOT NULL,
	TrackId INT NULL,
    Quantity INT NOT NULL,
	UnitPrice NUMERIC(10,2) NOT NULL,
	-----------------------------------
	CustomerId INT NOT NULL,
	InvoiceDate datetime NOT NULL,
	BillingAddress NVARCHAR(70) NULL,
	BillingCity NVARCHAR(40) NULL,
	BillingState NVARCHAR(40) NULL,
	BillingCountry NVARCHAR(40) NULL,
	BillingPostalCode NVARCHAR(10) NULL,
	Total NUMERIC(10,2) NOT NULL,

);

