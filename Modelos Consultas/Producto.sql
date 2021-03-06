/****** Script para el comando SelectTopNRows de SSMS  ******/
SELECT [prod_codigo]
      ,[prod_detalle]
      ,[prod_precio]
      ,[prod_familia]
      ,[prod_rubro]
      ,[prod_envase]
  FROM [GD2015C1].[dbo].[Producto]
  Order by prod_codigo desc

  INSERT INTO [dbo].[Producto]
           ([prod_codigo]
           ,[prod_detalle]
           ,[prod_precio]
           ,[prod_familia] /*Debe existir el valor en la tabla FAMILIA, que seria la marca*/
           ,[prod_rubro] /*Debe existir el valor en la tabla RUBRO, que seria el tipo de producto*/
           ,[prod_envase]) /*Tiene solo 3 valores: 1 - Bolsa, 2 - Lata y 3 - Caja*/
     VALUES
           (
		   '00017442', /*A partir del 00017442 y del G0000009 no hay nada cargado*/
		   'Resaltadores Pastel',
		   100,
		   '7 3',
		   '0014',
		   3
           )
GO


UPDATE [dbo].[Producto]
   SET [prod_detalle] = 'RESALTADORES PASTEL',
       [prod_precio] = 50,
       [prod_familia] = '7 3',
       [prod_rubro] = '0014',
       [prod_envase] = 3
 WHERE [prod_codigo] = '00017442'
GO


Delete [dbo].[Producto]
Where [prod_codigo] = '00017442'