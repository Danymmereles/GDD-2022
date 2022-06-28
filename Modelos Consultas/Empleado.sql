-- EMPLEADOS
INSERT INTO [dbo].[Empleado]
           ([empl_codigo]
           ,[empl_nombre]
           ,[empl_apellido]
           ,[empl_nacimiento]
           ,[empl_ingreso]
           ,[empl_tareas]
           ,[empl_salario]
           ,[empl_comision]
           ,[empl_jefe]
		   /*Este depende de esta tabla, tiene que existir un empleado con este codigo*/
           ,[empl_departamento]) 
		   /*Este depende de la tabla DEPARTAMENTO, solo tiene 3 valores: 1 - Administracion, 2 - Ventas y 3 - Compras */ 
     VALUES
           (
		   10, /*El ultimo empleado cargado es el 9*/
		   'Daniela',
		   'Mereles',
		   GETDATE(),
		   GETDATE(),
		   'Facturista',
		   11000,
		   0.02,
		   3,
		   2 
		   )


SELECT [empl_codigo]
      ,[empl_nombre]
      ,[empl_apellido]
      ,[empl_nacimiento]
      ,[empl_ingreso]
      ,[empl_tareas]
      ,[empl_salario]
      ,[empl_comision]
      ,[empl_jefe]
      ,[empl_departamento]
  FROM [dbo].[Empleado]
GO


UPDATE [dbo].[Empleado]
   SET [empl_nombre] = 'Daniela',
       [empl_apellido] = 'Mereles',
       [empl_nacimiento] = GETDATE(),
       [empl_ingreso] = GETDATE(),
       [empl_tareas] = 'Sistemas',
       [empl_salario] = 11000,
       [empl_comision] = 0.02,
       [empl_jefe] = 1,
       [empl_departamento] = 1
 WHERE [empl_codigo] = 10
GO


DELETE FROM [dbo].[Empleado]
      WHERE [empl_codigo] = 10
GO

