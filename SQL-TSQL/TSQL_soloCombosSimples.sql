USE GD2015C1;

/*
Implementar el/los objetos necesarios para implementar la siguiente restricción en linea:

“Toda Composición (Ej: COMBO 1) debe estar compuesta solamente por productos simples (Ej: COMBO4 compuesto por: 4 Hamburguesas, 2 gaseosas y 2 papas). 
No se permitirá que un combo este compuesto por ningún otro combo.”

Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías.
*/

GO
CREATE TRIGGER soloCombosSimples ON Composicion INSTEAD OF INSERT,UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM deleted) = 0 --se cumple si es un insert
		BEGIN
			DECLARE @producto CHAR(6)
			DECLARE @componente CHAR(6)
			DECLARE C_Comps CURSOR FOR
				SELECT i.comp_producto,i.comp_componente FROM inserted i

			OPEN C_Comps 
			FETCH NEXT FROM C_Comps INTO @producto,@componente
			WHILE @@FETCH_STATUS=0
			BEGIN
				IF EXISTS(SELECT * FROM Composicion WHERE comp_producto=@componente) -- verifica si el componente es un producto compuesto
				PRINT('La composicion solo puede ser simple')
				ELSE
					BEGIN
						INSERT INTO Composicion SELECT * FROM inserted i WHERE i.comp_componente=@componente AND i.comp_producto=@producto
					END
				FETCH NEXT FROM C_Comps INTO @producto,@componente
			END
			CLOSE C_Comps
			DEALLOCATE C_Comps
		END

	ELSE
		BEGIN --En caso de ser un UPDATE //Si agregas arriba un IF UPDATE(comp_componente) deberia saltear los casos que updatearon otras cosas
			DECLARE @prod CHAR(6)
			DECLARE @comp CHAR(6)
			DECLARE @cant INT
			DECLARE @prodDel CHAR(6)
			DECLARE @compDel CHAR(6)
			DECLARE C_CompsUpd CURSOR FOR SELECT d.comp_producto,d.comp_componente FROM deleted d
			DECLARE C_CompsNuevo CURSOR FOR SELECT i.comp_cantidad,i.comp_producto,i.comp_componente FROM inserted i

			OPEN C_CompsUpd 
			OPEN C_CompsNuevo
			FETCH NEXT FROM C_CompsUpd INTO @prodDel,@compDel --Necesito el cursor de deleted para hacer el DELETE en caso de tener que actualizar la info
			FETCH NEXT FROM C_CompsNuevo INTO @cant,@prod,@comp
			WHILE @@FETCH_STATUS =0
			BEGIN
				IF EXISTS (SELECT * FROM Composicion WHERE comp_producto=@comp)
					PRINT ('La composicion solo puede ser simple')

				ELSE
					BEGIN
						DELETE FROM Composicion WHERE comp_producto=@prodDel AND comp_componente=@compDel
						INSERT INTO Composicion VALUES(@cant,@prod,@comp) 
					END

				FETCH NEXT FROM C_CompsUpd INTO @prodDel,@compDel
				FETCH NEXT FROM C_CompsNuevo INTO @cant,@prod,@comp
			END

			CLOSE C_CompsUpd
			DEALLOCATE C_CompsUpd 

		END
END
GO

