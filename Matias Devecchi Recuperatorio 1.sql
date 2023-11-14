-- 1
SELECT 
	c.clie_razon_social 'Razon social', 
	c.clie_domicilio 'Domicilio',
	(
		SELECT SUM(i3.item_cantidad)
		FROM Item_Factura i3
		JOIN Factura f3 ON i3.item_numero = f3.fact_numero AND i3.item_sucursal = f3.fact_sucursal AND i3.item_tipo = f3.fact_tipo
		WHERE c.clie_codigo = f3.fact_cliente AND (YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) OR YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) + 1)
	) 'Cant. unidades compradas'
FROM Cliente c
JOIN Factura f ON c.clie_codigo = f.fact_cliente
GROUP BY c.clie_codigo, c.clie_razon_social, c.clie_domicilio, YEAR(f.fact_fecha)
HAVING c.clie_codigo =  (
	SELECT TOP 1 f2.fact_cliente
	FROM Factura f2
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
	GROUP BY f2.fact_cliente, YEAR(f2.fact_fecha)
	ORDER BY SUM(f2.fact_total) DESC
) AND c.clie_codigo =  (
	SELECT TOP 1 f2.fact_cliente
	FROM Factura f2
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) + 1
	GROUP BY f2.fact_cliente, YEAR(f2.fact_fecha)
	ORDER BY SUM(f2.fact_total) DESC
)

-- 2
CREATE TABLE Compuestos_Menor_Precio (
	codigo INT NOT NULL IDENTITY PRIMARY KEY,
	fecha SMALLDATETIME NOT NULL,
	cliente CHAR(6) NOT NULL FOREIGN KEY REFERENCES Cliente(clie_codigo),
	precio DECIMAL(12,2) NOT NULL
);
CREATE TABLE Componente_Compuestos_Menor_Precio (
	cmp_codigo INT NOT NULL FOREIGN KEY REFERENCES Compuestos_Menor_Precio(codigo),
	componente_codigo CHAR(8) NOT NULL FOREIGN KEY REFERENCES Producto(prod_codigo),
	CONSTRAINT pcmp_pk PRIMARY KEY (cmp_codigo, componente_codigo) 
);

-- DROP TRIGGER evaluarSiCompuestoEsMasBarato
GO
CREATE TRIGGER evaluarSiCompuestoEsMasBarato ON Item_Factura INSTEAD OF INSERT AS
BEGIN

	DECLARE @item_numero CHAR(8)
	DECLARE @item_sucursal CHAR(4)
	DECLARE @item_tipo CHAR(1)
	DECLARE @fact_fecha SMALLDATETIME
	DECLARE @fact_cliente CHAR(6)
	DECLARE @prod_Precio DECIMAL(12,2)
	DECLARE @prod_Comp CHAR(8)
	DECLARE C_Comp CURSOR FOR
		SELECT i.item_producto, i.item_numero, i.item_sucursal, i.item_tipo, i.item_precio FROM inserted i

	OPEN C_Comp
	FETCH NEXT FROM C_Comp INTO @prod_comp, @item_numero, @item_sucursal, @item_tipo, @prod_Precio

	WHILE @@FETCH_STATUS=0
		BEGIN
			IF EXISTS (SELECT * FROM Composicion WHERE comp_producto=@prod_Comp) --Es decir, si es un prod compuesto
				BEGIN
					IF (
						SELECT SUM(p.prod_precio * c.comp_cantidad)
						FROM Composicion c
						JOIN Producto p ON c.comp_componente = p.prod_codigo
						WHERE c.comp_producto = @prod_Comp
					) > @prod_Precio
						BEGIN
							SET @fact_fecha = (SELECT f.fact_fecha
							FROM Factura f
							WHERE f.fact_numero = @item_numero AND f.fact_sucursal = @item_sucursal AND f.fact_tipo = @item_tipo)
							SET @fact_cliente = (SELECT f.fact_cliente
							FROM Factura f
							WHERE f.fact_numero = @item_numero AND f.fact_sucursal = @item_sucursal AND f.fact_tipo = @item_tipo)


							INSERT INTO Compuestos_Menor_Precio
							(
								fecha, cliente, precio
							)
							VALUES (
								@fact_fecha,
								@fact_cliente,
								@prod_precio
							)
							DECLARE @NewId INT;
							SET @NewId = SCOPE_IDENTITY();

							INSERT INTO Componente_Compuestos_Menor_Precio
							SELECT @NewId, c.comp_componente FROM Composicion c WHERE c.comp_producto = @prod_Comp
						END
				END
			
			INSERT INTO Item_Factura
			SELECT * FROM inserted i WHERE i.item_producto=@prod_Comp --Como es un producto simple lo mando asi como venia

			FETCH NEXT FROM C_Comp INTO @prod_comp, @item_numero, @item_sucursal, @item_tipo, @prod_Precio
		END

		CLOSE C_Comp
		DEALLOCATE C_Comp
END

-- Prueba
/*
SELECT i.item_numero, i.item_sucursal, i.item_tipo
FROM Factura f
JOIN Item_Factura i ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
LEFT OUTER JOIN Composicion c ON c.comp_producto = i.item_producto

00068710 0003 A

SELECT c.comp_producto FROM Composicion c
00001104


SELECT SUM(p.prod_precio * c.comp_cantidad)
FROM Composicion c
JOIN Producto p ON c.comp_componente = p.prod_codigo
WHERE c.comp_producto = '00001104'

DELETE FROM Item_Factura WHERE item_tipo = 'A' AND item_sucursal = '0003' AND item_numero = '00068710' AND item_producto = '00001104'

INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio) VALUES (
	'A',
	'0003',
	'00068710',
	'00001104',
	1,
	8
)

SELECT * FROM Compuestos_Menor_Precio
SELECT * FROM Componente_Compuestos_Menor_Precio
*/
