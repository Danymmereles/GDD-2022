/****** Script para el comando SelectTopNRows de SSMS  ******/
SELECT [item_tipo]
      ,[item_sucursal]
      ,[item_numero]
      ,[item_producto]
      ,[item_cantidad]
      ,[item_precio]
  FROM [GD2015C1].[dbo].[Item_Factura]
  Order by item_numero asc


  INSERT INTO [dbo].[Item_Factura]
           ([item_tipo] /*Tipo, sucursal y numero deben existir en Factura, por lo tanto deben existir*/
           ,[item_sucursal]
           ,[item_numero]
           ,[item_producto] /*Depende de la tabla producto*/
           ,[item_cantidad]
           ,[item_precio])
     VALUES
           (
		   'A', 
		   '0003',
		   '00090676', 
		   '00010158',
		   2,
		   2
		   )
GO


UPDATE [dbo].[Item_Factura]
   SET [item_cantidad] = 4
      ,[item_precio] = 4
 WHERE [item_tipo] = 'A' AND
       [item_sucursal] = '0003' AND
       [item_numero] = '00090676' AND
       [item_producto] = '00010158'
GO


DELETE [dbo].[Item_Factura]
 WHERE [item_tipo] = 'A' AND
       [item_sucursal] = '0003' AND
       [item_numero] = '00090676' AND
       [item_producto] = '00010158'
GO