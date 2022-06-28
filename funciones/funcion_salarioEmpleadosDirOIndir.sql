/*
Devuelve el salario de los empleados/subordinados directos e indirectos
*/

CREATE FUNCTION FX_SALARIO_EMPLEADOS(@EMPLEADO NUMERIC(6,0))
RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @SALARIO_EMPLEADOS DECIMAL(12,2)
	
	SET @SALARIO_EMPLEADOS = 
	ISNULL((SELECT SUM(DBO.FX_SALARIO_EMPLEADOS(empl_codigo) + empl_salario)
	FROM Empleado
	WHERE empl_jefe = @EMPLEADO), 0)
	
	RETURN @SALARIO_EMPLEADOS
END
GO