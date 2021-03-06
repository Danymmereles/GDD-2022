-- DEPARTAMENTOS
SELECT [depa_codigo]
      ,[depa_detalle]
      ,[depa_zona]
  FROM [GD2015C1].[dbo].[Departamento]


INSERT INTO [dbo].[Departamento]
           ([depa_codigo]
           ,[depa_detalle]
           ,[depa_zona])
		   /*Este valor depende de la tabla ZONA, debe existir ahi antes de cargarlo aca*/
     VALUES
           (
		   4, /*Solo existen los valores del 1 al 3*/
		   'Sistemas',
		   '017' /*Tiene que ser de 3 caracteres*/
		   )
GO


UPDATE [dbo].[Departamento]
   SET [depa_detalle] = 'Sistemas'
      ,[depa_zona] = '008'
 WHERE [depa_codigo] = 4
GO 


DELETE [dbo].[Departamento]
WHERE [depa_codigo] = 4