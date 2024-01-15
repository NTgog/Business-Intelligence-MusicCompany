
------------------------------------------------------------------------------------------------------------------
/* Time to connect dimension with the fact. We create the relations for our DW. Note we added ( and named ) the  -
constraints for you convenience ( you can drop a single or more connections now )                               */
------------------------------------------------------------------------------------------------------------------

USE ChinookDW
GO

-----------------------------------------------------------------------------------------------
-- Creating the relationships among the fact table and the Dimensions. We want a STAR schema. 

ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLineDate] FOREIGN KEY (Date_Key)
    REFERENCES DimDate(DateKey);

ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLineTrack] FOREIGN KEY (Track_Key)
    REFERENCES DimTrack (Track_Key);

ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLineEmployee] FOREIGN KEY (Employee_Key)
    REFERENCES DimEmployee (Employee_Key);

ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLineCustomer] FOREIGN KEY (Customer_Key)
    REFERENCES DimCustomer (Customer_Key);

--ALTER TABLE FactInvoiceLine ADD constraint [FactInvoiceLinePlaylist] FOREIGN KEY (Playlist_Key)
--    REFERENCES DimPlaylist (Playlist_Key);


------------------------------------------------------------------------------------------------------------------
-- Creating the relations between DimPlaylist and DimTrack tables by using an intermediate table named Bridge.

-- Add foreign key constraint for DimTrack
ALTER TABLE Bridge
ADD CONSTRAINT FK_Bridge_DimTrack
FOREIGN KEY (TrackId)
REFERENCES DimTrack (Track_Key);

-- Add foreign key constraint for DimPlaylist
ALTER TABLE Bridge
ADD CONSTRAINT FK_Bridge_DimPlaylist
FOREIGN KEY (PlaylistId)
REFERENCES DimPlaylist (PlaylistId);





