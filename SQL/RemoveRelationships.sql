
--------------------------------------------------------------------------------------------------------------------
/* This script drops all the connections of the DW. We need it, in case we want to make changes to the connected   -
tables or even if you want to drop the data warehouse                                                             */
--------------------------------------------------------------------------------------------------------------------

use ChinookDW

ALTER TABLE FactInvoiceLine drop  constraint [FactInvoiceLineTrack] ;

ALTER TABLE FactInvoiceLine drop  constraint [FactInvoiceLineDate]  ;

ALTER TABLE FactInvoiceLine drop  constraint [FactInvoiceLineCustomer]  ;

ALTER TABLE FactInvoiceLine drop  constraint [FactInvoiceLineEmployee] ;


