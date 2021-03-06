/****** Script para el comando SelectTopNRows de SSMS  ******/
SELECT TOP 1000 [depo_codigo]
      ,[depo_detalle]
      ,[depo_domicilio]
      ,[depo_telefono]
      ,[depo_encargado]
      ,[depo_zona]
  FROM [GD2015C1].[dbo].[DEPOSITO]


  INSERT INTO [GD2015C1].[dbo].[DEPOSITO]
           ([depo_codigo]
           ,[depo_detalle]
           ,[depo_domicilio]
           ,[depo_telefono]
           ,[depo_encargado] /*Debe existir en la tabla EMPLEADO, del 1 al 9 esta actualmente*/
           ,[depo_zona]) /*Debe existir en la tabla ZONA, del 000 al 018 estan casi todos, despues hay un par de numeros mas*/
     VALUES
           (
		   '22', /*Del 21 al 50 y del 61 al 99 estan desocupados*/
		   'DEPOSITO MADERO',
		   'SALGUERO',
		   '12345678',
		   6,
		   '017'
		   )
GO


UPDATE [GD2015C1].[dbo].[DEPOSITO]
SET [depo_detalle] = 'DEPOSITOS MADERO',
    [depo_domicilio] = 'NARNIA 123',
    [depo_telefono] = '45671234',
    [depo_encargado] = 6,
    [depo_zona] = '017'
WHERE [depo_codigo] = '22'


DELETE [GD2015C1].[dbo].[DEPOSITO]
WHERE [depo_codigo] = '22'