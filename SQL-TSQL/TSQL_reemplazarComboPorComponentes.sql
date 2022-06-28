USE GD2015C1;

/*
Implementar el/los objetos necesarios para implementar la siguiente restricción en línea:
Cuando se inserta en una venta un COMBO, nunca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes.
Nota: Se sabe que actualmente todos los artículos guardados de ventas están descompuestos en sus componentes.
*/


--Si lo queres hacer recursivo tenes que hacer un AFTER INSERT que hace que el trigger en si sea recursivo :(
GO
ALTER TRIGGER sinCombos ON Item_Factura INSTEAD OF INSERT AS
BEGIN

	DECLARE @prod_Comp CHAR(8)
	DECLARE C_Comp CURSOR FOR
		SELECT i.item_producto FROM inserted i

	OPEN C_Comp
	FETCH NEXT FROM C_Comp INTO @prod_comp

	WHILE @@FETCH_STATUS=0
		BEGIN
			IF EXISTS (SELECT * FROM Composicion WHERE comp_producto=@prod_Comp) --Es decir, si es un prod compuesto
				BEGIN
					INSERT INTO Item_Factura
					SELECT i.item_tipo,i.item_sucursal,i.item_numero,P.prod_codigo,(i.item_cantidad*C.comp_cantidad),(P.prod_precio*C.comp_cantidad) FROM inserted i
						JOIN Composicion C ON C.comp_producto=@prod_Comp
						JOIN Producto P ON P.prod_codigo=C.comp_componente
				END
			ELSE
				BEGIN
					INSERT INTO Item_Factura
					SELECT * FROM inserted i WHERE i.item_producto=@prod_Comp --Como es un producto simple lo mando asi como venia 
				END
			FETCH NEXT FROM C_Comp INTO @prod_comp
		END

		CLOSE C_Comp
		DEALLOCATE C_Comp
END
GO

--Hacemos pruebitas 
INSERT INTO Factura VALUES ('A', '0099', '99999999', GETDATE(), 1, 0, 0, NULL)
INSERT INTO Item_Factura VALUES ('A', '0099', '99999999', '00001104', 2, 10)


SELECT * FROM Item_Factura WHERE item_numero='99999999'

DELETE FROM Item_Factura WHERE item_numero='99999999'
DELETE FROM Factura WHERE fact_numero='99999999'