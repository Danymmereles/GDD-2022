USE GD2015C1;

/*
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock 
suficiente del producto en el deposito ‘00’.

Nota: En caso de que se facture un producto compuesto, por ejemplo, combo1, deberá controlar que exista stock en el deposito ‘00’ 
de cada uno de sus componentes
*/

GO
CREATE FUNCTION hayStock (@prod CHAR(8),@cant INT) RETURNS INT --No me salio con recursividad para los compuestos
AS
BEGIN
	DECLARE @resultado INT

	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto=@prod) --Es decir, no es un producto compuesto
		BEGIN
			IF (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto=@prod AND stoc_deposito='00') > @cant SET @resultado = 1 
			ELSE SET @resultado=0
		END
	ELSE
		BEGIN
			 IF EXISTS (SELECT * FROM STOCK
				JOIN Composicion C ON C.comp_producto=@prod AND stoc_producto=C.comp_componente
				WHERE stoc_cantidad < C.comp_cantidad*@cant AND stoc_deposito = '00') --Si existe al menos uno de los componentes que NO tenga stock 

				SET @resultado = 0

			ELSE SET @resultado = 1

		END

	RETURN @resultado
END
GO

GO
CREATE TRIGGER noVender ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	
	DECLARE @prod CHAR(8)
	DECLARE @cant INT

	DECLARE C_Venta CURSOR FOR
	SELECT i.item_producto,i.item_cantidad FROM inserted i

	OPEN C_Venta
	FETCH NEXT FROM C_Venta INTO @prod,@cant

	WHILE @@FETCH_STATUS=0
		BEGIN
			IF(dbo.hayStock(@prod,@cant)) = 1
				BEGIN
					INSERT INTO Item_Factura
					SELECT * FROM inserted i WHERE i.item_producto=@prod AND i.item_cantidad=@cant
				END
			ELSE PRINT('No hay stock')
	    FETCH NEXT FROM C_Venta INTO @prod,@cant
		END
END
GO




