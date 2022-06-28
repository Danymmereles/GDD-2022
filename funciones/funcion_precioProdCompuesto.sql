IF OBJECT_ID('precio_compuesto') IS NOT NULL
	DROP FUNCTION precio_compuesto
GO 

/*
Devuelve el precio de un producto compuesto calculado por componentes
*/

CREATE FUNCTION precio_compuesto(@producto CHAR(8))
RETURNS DECIMAL(12, 2)
AS
BEGIN
	/*
		Si el producto no tiene componentes, su precio es el precio del producto - Condicion base
		Si el producto tiene componentes, su precio es el precio de sus componentes - Condición recursiva
	*/
	DECLARE @precio DECIMAL(12, 2)=0.0
	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto=@producto)
		BEGIN
			SET @precio = (SELECT prod_precio FROM Producto WHERE prod_codigo=@producto)
			RETURN @precio
		END

	-- Si estamos acá al menos hay un componente que compone a mi producto
	DECLARE @componente CHAR(8)
	DECLARE @componente_cant DECIMAL(12, 2)

	DECLARE C2 CURSOR FOR 
	SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto=@producto
	OPEN C2

	FETCH NEXT FROM C2 INTO @componente, @componente_cant 
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @precio = @precio + dbo.precio_compuesto(@componente) * @componente_cant
			FETCH NEXT FROM C2 INTO @componente, @componente_cant
		END

	CLOSE C2
	DEALLOCATE C2
	RETURN @precio
END
GO