/*
Implementar el/los objetos necesarios para mantener siempre actualizado 
al instante ante cualquier evento el campo fact_total de la tabla Factura 
considerando que el importe es la suma de los precios por las cantidades de los items.

Nota: Se sabe que actualmente el campo fact_total presenta esta propiedad.
*/

/*
CONSIDERACION: Si se quiere realizar un update sobre un item de la tabla no se podra.
En cambio, se debe realizar un borrado del registro y nueva carga, como en las vistas de los negocios actuales que no permiten
la modificacion de un registro del detalle de una factura
*/

IF OBJECT_ID('TR_TOTAL_FACTURA') IS NOT NULL
	DROP TRIGGER TR_TOTAL_FACTURA
GO

CREATE TRIGGER TR_TOTAL_FACTURA ON Item_Factura
INSTEAD OF INSERT, DELETE
AS BEGIN
	DECLARE @TIPO CHAR(1)
	DECLARE @SUCURSAL CHAR(4)
	DECLARE @FACTURA CHAR(8)
	DECLARE @IMPORTE DECIMAL(12, 2)
	
	DECLARE C_FACTURA CURSOR FOR
		SELECT item_tipo, item_sucursal, item_numero,
		SUM(item_cantidad * item_precio)
		FROM inserted
		GROUP BY item_tipo, item_sucursal, item_numero
		UNION
		SELECT item_tipo, item_sucursal, item_numero,
		SUM(item_cantidad * item_precio)*(-1)
		FROM deleted
		GROUP BY item_tipo, item_sucursal, item_numero
		
	OPEN C_FACTURA
	FETCH NEXT FROM C_FACTURA INTO @TIPO, @SUCURSAL, @FACTURA, @IMPORTE
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE Factura SET fact_total = fact_total + @IMPORTE
		WHERE fact_tipo = @TIPO AND
		fact_sucursal = @SUCURSAL AND
		fact_numero = @FACTURA
		
		FETCH NEXT FROM C_FACTURA INTO @TIPO, @SUCURSAL, @FACTURA, @IMPORTE
	END
	CLOSE C_FACTURA
	DEALLOCATE C_FACTURA
END
GO