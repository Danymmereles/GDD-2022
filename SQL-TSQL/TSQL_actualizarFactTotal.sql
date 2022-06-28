/*
Implementar el/los objetos necesarios para mantener siempre actualizado 
al instante ante cualquier evento el campo fact_total de la tabla Factura 
considerando que el importe es la suma de los precios por las cantidades de los items.

Nota: Se sabe que actualmente el campo fact_total presenta esta propiedad.
*/

IF OBJECT_ID('TR_TOTAL_FACTURA') IS NOT NULL
	DROP TRIGGER TR_TOTAL_FACTURA
GO

CREATE TRIGGER TR_TOTAL_FACTURA ON Item_Factura
AFTER INSERT, UPDATE, DELETE
AS BEGIN
	-- Hasta donde encontre no se pueden hacer updates sobre varias rows al mismo tiempo
	-- Se "podria" pero es medio complicado y CREO que no viene al caso
	IF UPDATE(item_cantidad) OR UPDATE(item_precio) BEGIN
		DECLARE @CANT_VIEJA DECIMAL(12, 2) =
			(SELECT item_cantidad FROM deleted)
		DECLARE @CANT_NUEVA DECIMAL(12, 2) =
			(SELECT item_cantidad FROM inserted)
		DECLARE @PRECIO_VIEJO DECIMAL(12, 2) =
			(SELECT item_precio FROM deleted)
		DECLARE @PRECIO_NUEVO DECIMAL(12, 2) =
			(SELECT item_precio FROM inserted)

		
		UPDATE Factura
		SET fact_total = fact_total - @CANT_VIEJA * @PRECIO_VIEJO + @CANT_NUEVA * @PRECIO_NUEVO
		WHERE fact_tipo = (SELECT item_tipo FROM deleted)
			AND fact_sucursal = (SELECT fact_sucursal FROM deleted)
			AND fact_numero = (SELECT fact_numero FROM deleted)
	END
	ELSE BEGIN
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
		WHILE @@FETCH_STATUS = 0 BEGIN
			UPDATE Factura SET fact_total = fact_total + @IMPORTE
			WHERE fact_tipo = @TIPO AND
			fact_sucursal = @SUCURSAL AND
			fact_numero = @FACTURA
			
			FETCH NEXT FROM C_FACTURA INTO @TIPO, @SUCURSAL, @FACTURA, @IMPORTE
		END
		CLOSE C_FACTURA
		DEALLOCATE C_FACTURA
	END
END
GO
