USE [GD2015C1]
GO

INSERT INTO [dbo].[STOCK]
           ([stoc_cantidad]
           ,[stoc_punto_reposicion]
           ,[stoc_stock_maximo]
           ,[stoc_detalle]
           ,[stoc_proxima_reposicion]
           ,[stoc_producto]
           ,[stoc_deposito])
     VALUES
           (
		   5,
		   10,
		   10,
		   NULL,
		   GETDATE(),
		   '00000112',
		   00
		   )
GO


SELECT [stoc_cantidad]
      ,[stoc_punto_reposicion]
      ,[stoc_stock_maximo]
      ,[stoc_detalle]
      ,[stoc_proxima_reposicion]
      ,[stoc_producto]
      ,[stoc_deposito]
  FROM [dbo].[STOCK]
GO


UPDATE [dbo].[STOCK]
   SET [stoc_cantidad] = 6
      ,[stoc_punto_reposicion] = 3
      ,[stoc_stock_maximo] = 20
      ,[stoc_detalle] = NULL
      ,[stoc_proxima_reposicion] = GETDATE()
 WHERE [stoc_producto] = '00000112' AND
       [stoc_deposito] = 00
GO

DELETE [dbo].[STOCK]
 WHERE [stoc_producto] = '00000112' AND
       [stoc_deposito] = 00