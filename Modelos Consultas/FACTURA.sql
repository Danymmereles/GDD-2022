USE [GD2015C1]
GO

INSERT INTO [dbo].[Factura]
           ([fact_tipo]
           ,[fact_sucursal]
           ,[fact_numero]
           ,[fact_fecha]
           ,[fact_vendedor]
           ,[fact_total]
           ,[fact_total_impuestos]
           ,[fact_cliente]) /*Debe existir en la tabla cliente*/
     VALUES
           (
		   'A', /*La idea es escribir A, B o C*/
		   '0003', /*Todos dicen 0003, no depende de otra tabla*/
		   '00070000', /*Todos los numero donde desde de 3 0 viene un 7 estan desocupados*/
           GETDATE(),
		   4,
		   200,
		   20,
		   '03779' /*Del 00000 al 03779 estan la mayoria si es que no todos*/
		   ) 
		   
GO


SELECT TOP 1000 [fact_tipo]
      ,[fact_sucursal]
      ,[fact_numero]
      ,[fact_fecha]
      ,[fact_vendedor]
      ,[fact_total]
      ,[fact_total_impuestos]
      ,[fact_cliente]
  FROM [GD2015C1].[dbo].[Factura]
  Order by fact_numero 


    UPDATE [dbo].[Factura]
   SET [fact_fecha] = GETDATE()
      ,[fact_vendedor] = 7
      ,[fact_total] = 150
      ,[fact_total_impuestos] = 15
      ,[fact_cliente] = '01634'
 WHERE [fact_tipo] = 'A' AND
       [fact_sucursal] = '0003' AND
       [fact_numero] = '00070000'
GO
