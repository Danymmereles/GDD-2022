USE [GD2015C1]
GO

SELECT [zona_codigo]
      ,[zona_detalle]
  FROM [dbo].[Zona]
GO


INSERT INTO [dbo].[Zona]
           ([zona_codigo]
           ,[zona_detalle])
     VALUES
           (
		   '027', /*Del 026 al 066 no estan cargados exceptuando 041 y 062*/
		   'Zona Puerto Madero'
		   )
GO


UPDATE [dbo].[Zona]
   SET [zona_detalle] = 'ZONA PUERTO MADERO'
 WHERE [zona_codigo] = '027'
GO

Delete dbo.Zona
WHERE [zona_codigo] = '027'