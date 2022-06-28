/*
Devuelve 1 si el producto esta compuesto por si mismo en algun nivel
*/

CREATE FUNCTION dbo.Ejercicio12Func(@producto CHAR(8),@Componente char(8))
RETURNS int
AS
BEGIN
	IF @producto = @Componente 
		RETURN 1
	ELSE
		BEGIN
		DECLARE @ProdAux char(8)
		DECLARE cursor_componente CURSOR FOR SELECT comp_componente
										FROM Composicion
										WHERE comp_producto = @Componente
		OPEN cursor_componente
		FETCH NEXT from cursor_componente INTO @ProdAux
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF dbo.Ejercicio12Func(@producto,@prodaux) = 1
					RETURN 1 
				FETCH NEXT from cursor_componente INTO @ProdAux
			END
		CLOSE cursor_componente
		DEALLOCATE cursor_componente
		RETURN 0
		END
RETURN 0
END
GO