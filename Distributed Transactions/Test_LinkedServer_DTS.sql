DECLARE @NewTransaction		bit;

SET XACT_ABORT ON;

BEGIN TRY

	SET @NewTransaction = 1;
	BEGIN TRANSACTION;

	INSERT INTO [{yourlinkserver}].[{yourdb}].[{yourschema}].[_TEST] (Fld1)
	SELECT	'TEST' AS Fld1;

	COMMIT TRANSACTION;

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	SELECT  ERROR_NUMBER() AS ErrNumber, ERROR_MESSAGE() ErrMessage;

END CATCH;