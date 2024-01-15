
--================================================================================================================================================================--
/* In this .SQL file we create the intermediate staging area of the Chinook database. We will minimize the tables, from 11 to 5. We will include
the track table joined with the Artist, Album, Genre, MediaType, *Playlist* tables. So the user can access to all those tables now through the track table. 
The invoiceLine now is one with the invoice table. The tables customer and employee are joined as well. While you can access to Employee through customer table 
( but only to those that have supported the customers, we thought that your company needs to have access to the infos of all the employees ( even if the didn't 
have some connection with the customers ). So we included an extra Employee table, so you can have access to this too. */
--================================================================================================================================================================--

USE ChinookStaging
GO

-- Delete the tables from our base ( staging )
DROP TABLE IF EXISTS ChinookStaging.dbo.Employee;
DROP TABLE IF EXISTS ChinookStaging.dbo.Customer;
DROP TABLE IF EXISTS ChinookStaging.dbo.InvoiceLine;
DROP TABLE IF EXISTS ChinookStaging.dbo.Playlist;
DROP TABLE IF EXISTS ChinookStaging.dbo.Track;
DROP TABLE IF EXISTS ChinookStaging.dbo.DimDate;
DROP TABLE IF EXISTS ChinookStaging.dbo.PlaylistTrackBridge;

--=======================================================================================================================================--
--                                                             Cloning                                                                   --
--=======================================================================================================================================--

-------------------------------------------------------------- Bridge --------------------------------------------------------------------
/* This is the PlaylistTrack table. We observed that in reality it works as an intermediate (bridge) table in the original data base, to
handle the many-to-many relationship between track and playlist. So we are going to clone it to the staging area as well, to handle the 
problem there too. */

SELECT Chinook.dbo.PlaylistTrack.*
INTO PlaylistTrackBridge
FROM Chinook.dbo.PlaylistTrack

-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- PLAYLIST TABLE -----------------------------------------------------------------
/* We just copy the playlist table from the OLTP to the new table named Playlist as well to the staging intermediate area                */

SELECT Chinook.[dbo].Playlist.*
INTO ChinookStaging.[dbo].Playlist
FROM Chinook.[dbo].Playlist

--------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ TRACK TABLE -------------------------------------------------------------------
/* We want to create one table that has every track related ( genre, album, artist, ...) tables ( except the playlist). So we are going to 
join Album and Artist, and then join those with Track. We also are going to join genre and media type with track. Keep in mind that due to 
the many-to-many relationship between Track and playlist, we are not going to join those tables here.*/

SELECT Chinook.[dbo].Track.*, 
	   Chinook.[dbo].Genre.Name AS GenreName,
	   Chinook.[dbo].MediaType.Name AS MediaTypeName,
	   Chinook.[dbo].Album.Title AS AlbumTitle,
	   Chinook.[dbo].Album.ArtistId,
	   Chinook.[dbo].Artist.Name AS ArtistName
INTO ChinookStaging.[dbo].Track
FROM Chinook.[dbo].Track
INNER JOIN Chinook.[dbo].Genre
	ON Chinook.dbo.Genre.GenreId = Chinook.dbo.Track.GenreId
INNER JOIN Chinook.dbo.MediaType
	ON Chinook.dbo.MediaType.MediaTypeId = Chinook.dbo.Track.MediaTypeId
INNER JOIN Chinook.dbo.Album
	ON Chinook.dbo.Album.AlbumId = Chinook.dbo.Track.AlbumId
INNER JOIN Chinook.[dbo].[Artist]
	ON Chinook.[dbo].[Artist].ArtistId = Chinook.[dbo].[Album].[ArtistId]

--------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Invoice Line TABLE ------------------------------------------------------------------
/* For this table we are going to join Invoice Line with Invoice. The reason is that we want to create at the end a star scheme, and at the same 
time we want to have a table of Employee ( not to put it in one with the customers ). So, We aimto have a table (InvoiceLine-Invoice) as the fact, 
and the dimensions employee, customer, track, date and playlist. */

SELECT il.*,
	   i.CustomerId,
	   i.InvoiceDate,
	   i.BillingAddress,
	   i.BillingCity,
	   i.BillingState,
	   i.BillingCountry,
	   i.BillingPostalCode,
	   i.Total
INTO ChinookStaging.[dbo].InvoiceLine
FROM Chinook.[dbo].InvoiceLine il
INNER JOIN Chinook.[dbo].Invoice i
	ON i.InvoiceId = il.InvoiceId 

-----------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Customer TABLE -------------------------------------------------------------------
/* We will join here the Employee table with the Customer, so you can gain information ( except Customers ) about the Most succesful employee 
through the sales and all his information as well. The reason we added all the information of an Employee, is for your ease. You can gain every 
information of the Employee who helped a specific or more customers by just access Customer Table. */

SELECT Chinook.[dbo].Customer.*,
	   Chinook.[dbo].Employee.LastName + ' ' + Chinook.[dbo].Employee.FirstName AS EmployeeFullName,
	   Chinook.[dbo].Employee.Title,
	   Chinook.[dbo].Employee.ReportsTo
INTO ChinookStaging.[dbo].Customer
FROM Chinook.[dbo].Customer
INNER JOIN Chinook.[dbo].Employee
	ON Chinook.[dbo].Employee.EmployeeId = Chinook.[dbo].[Customer].SupportRepId

-----------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ Employee TABLE -------------------------------------------------------------------
/* As we said previously we included the table Employee, because you need to have access to all your Employees, even if they didn't have 
any connection with your customers. So if you want to, make any update to your Employees ( add, delete, update ) you access this table. Remember
that here are all the Employees of the company ( so not everyone can be found in the customer table ).*/

SELECT Chinook.[dbo].Employee.*
INTO ChinookStaging.[dbo].Employee
FROM Chinook.[dbo].Employee


