/*
Stock vendido desde una fecha
*/

CREATE FUNCTION FX_STOCK_VENDIDO_DESDE_FECHA(@PRODUCTO CHAR(8), @FECHA SMALLDATETIME)
	RETURNS DECIMAL(12,2)
BEGIN
	DECLARE @STOCK_VENDIDO DECIMAL(12,2)

	SET @STOCK_VENDIDO = 
	(SELECT SUM(item_cantidad) 
	FROM Item_Factura
	JOIN Factura 
	ON item_numero + item_sucursal + item_tipo =
	fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha >= @FECHA
	AND item_producto = @PRODUCTO 
	GROUP BY item_producto)

	RETURN @STOCK_VENDIDO
END
GO