-- CLIENTES
INSERT INTO [dbo].[Cliente]
           ([clie_codigo]
           ,[clie_razon_social]
           ,[clie_telefono]
           ,[clie_domicilio]
           ,[clie_limite_credito]
           ,[clie_vendedor])
     VALUES
           (
				'03781', /*Del 03780 al 09900 no hay clientes cargados*/
				'MERELES COMPANY',
				'12345678',
				'NARNIA 123',
				1000000,
				3
		   )
GO

SELECT [clie_codigo]
      ,[clie_razon_social]
      ,[clie_telefono]
      ,[clie_domicilio]
      ,[clie_limite_credito]
      ,[clie_vendedor]
  FROM [GD2015C1].[dbo].[Cliente]
  Order by clie_codigo desc


UPDATE [dbo].[Cliente]
   SET [clie_razon_social] = 'MERELES COMPANY',
       [clie_telefono] = '12345678',
       [clie_domicilio] = 'NARNIA 123',
       [clie_limite_credito] = 1000000,
       [clie_vendedor] = 3
 WHERE [clie_codigo] = '03781'
GO
/*Cuidado que la primary key no se puede actualizar, por eso no esta*/

DELETE FROM [dbo].[Cliente]
      WHERE [clie_codigo] = '03781'
GO