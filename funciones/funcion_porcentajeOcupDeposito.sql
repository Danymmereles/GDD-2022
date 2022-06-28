
/*
Devuelve el porcentaje de ocupacion del stock de un producto para un deposito 
*/
CREATE FUNCTION fx_ejercicio1 (@cod_articulo char(8), @cod_deposito char(2))
RETURNS VARCHAR(100) AS 
BEGIN
DECLARE @RETORNO VARCHAR(100)
DECLARE @CANTIDAD INT, @MAXIMO INT, @PORCENTAJE INT
 

SELECT @CANTIDAD = stoc_cantidad, @MAXIMO = stoc_stock_maximo
FROM stock s
WHERE stoc_producto = @cod_articulo AND stoc_deposito = @cod_deposito

IF @@ROWCOUNT = 0 
	RETURN 'NO EXISTE EL PRODUCTO O DEPOSITO, O NO HAY ESE PRODUCTO EN ESE DEPOSITO'

IF @CANTIDAD >= @MAXIMO
	RETURN 'DEPOSITO COMPLETO'

SET @PORCENTAJE = ROUND(@CANTIDAD*100/@MAXIMO,0)
SET @RETORNO = CONCAT('OCUPACION DEL DEPOSITO ', @cod_deposito, ' ',@PORCENTAJE,'%')

RETURN @RETORNO

END
