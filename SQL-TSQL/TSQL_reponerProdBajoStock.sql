USE GD2015C1;

/*
Implementar el/los objetos necesarios para poder registrar cuáles son los productos que requieren reponer su stock. 
Como tarea preventiva, semanalmente se analizará esta información para que la falta de stock no sea una traba al momento 
de realizar una venta.

Esto se calcula teniendo en cuenta el stoc_punto_reposicion, es decir, si éste supera en un 10% al stoc_cantidad 
deberá registrarse el producto y la cantidad a reponer.

Considerar que la cantidad a reponer no debe ser mayor a stoc_stock_maximo (cant_reponer= stoc_stock_maximo - stoc_cantidad)
*/


--Como pide registrar me parecio que lo mejor era hacer una tabla 
CREATE TABLE prodSinStock
(
	prod CHAR(8),
	cant_reponer DECIMAL(12,2),
	depo CHAR(8) --el enunciado no decia nada de esto pero como un mismo producto puede estar en varios depos lo quise poner 
)


GO
ALTER PROCEDURE prodsConBajoStock AS 
BEGIN
	
	DELETE FROM prodSinStock

	INSERT INTO prodSinStock
	SELECT stoc_producto,stoc_stock_maximo-stoc_cantidad,stoc_deposito FROM STOCK
	WHERE (stoc_cantidad/stoc_punto_reposicion) > 1.1 AND stoc_stock_maximo IS NOT NULL --lo del null lo aclare porque hay algunos que tiene null en ese campo

END
GO

--Pruebas
SELECT * FROM prodSinStock WHERE prod ='00001523'
EXEC prodsConBajoStock
SELECT * FROM STOCK WHERE stoc_producto='00001523'