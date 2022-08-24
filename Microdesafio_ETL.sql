-- 1. crear las base de datos BDE y la tabla articulos.titulos
USE master;
-- Borrar la database si existe
IF DB_ID('BDE') IS NOT NULL DROP DATABASE BDE;
-- si no se puede crear porque no se abre la conexion se aborta
IF @@ERROR =3702
   RAISERROR('La base de datos no se puede crear porque no esta abierta',127,127) WITH NOWAIT, LOG;
-- crear database
CREATE DATABASE BDE;
GO

-- Usar la base de datos
USE BDE  
GO
-- Crear un esquema
CREATE SCHEMA articulos AUTHORIZATION dbo;
GO

CREATE TABLE articulos.titulos
(titulo_id char(6) NOT NULL,
titulo varchar(80) NOT NULL,
tipo char(20) NOT NULL);
GO

-- Insertar valores manualmente(OJO esto se puede hacer con COPY o con un asistente)
INSERT INTO articulos.titulos VALUES ('1', 'Consultas SQL','bbdd');
INSERT INTO articulos.titulos VALUES ('3', 'Grupo recursos Azure','administracion');
INSERT INTO articulos.titulos VALUES ('4', '.NET Framework 4.5','programacion');
INSERT INTO articulos.titulos VALUES ('5', 'Programacion C#','dev');
INSERT INTO articulos.titulos VALUES ('7', 'Power BI','BI');
INSERT INTO articulos.titulos VALUES ('8', 'Administracion Sql server','administracion');

-- 2. Uso de alias en columnas para tener nombres de campos normalizados
SELECT TituloId= titulo_id, TituloNombre=titulo, TituloTipo =tipo 
FROM articulos.titulos
GO

-- 3. Transformacion de datos con CASE para hacer limpieza en los valores de un campo
SELECT TituloId= titulo_id, TituloNombre=titulo, 
TituloTipo= CASE tipo
WHEN 'bbdd' THEN 'Base de datos'
WHEN 'BI' THEN 'Base de datos'
WHEN 'administracion' THEN 'Base de datos'
WHEN 'administrador' THEN 'Administración'
WHEN 'dev' THEN 'Desarrollo'
WHEN 'programacion' THEN 'Desarrollo'
END
FROM articulos.titulos
ORDER BY TituloTipo
GO

-- 4. Convertir tipos de datos con CAST (ampliando tamaño de campos y cambio tipo daato)
SELECT TituloId= titulo_id, 
TituloNombre = CAST(titulo as nVarchar(100)),
TituloTipo = CASE CAST(tipo as nVarchar(100))
WHEN 'bbdd' THEN 'Base de datos, Transact-SQL'
WHEN 'BI' THEN 'Base de datos, BI'
WHEN 'administracion' THEN 'Base de datos, Administración'
WHEN 'dev' THEN 'Desarrollo'
WHEN 'programacion' THEN 'Desarrollo'
END
FROM articulos.titulos
ORDER BY TituloTipo
GO

-- 5. crear nueva tabla autores
CREATE TABLE articulos.autores
(TituloId char(6) NOT NULL,
NombreAutor nVarchar(100) NOT NULL,
ApellidosAutor nVarchar(100) NOT NULL,
TelefonoAutor nVarChar(25)
);

-- Insertar en la tabla autores en essquema articulos
INSERT INTO articulos.autores VALUES ('3', 'David', 'Saenz', '99897867');
INSERT INTO articulos.autores VALUES ('8', 'Ana', 'Ruiz', '99897466');
INSERT INTO articulos.autores VALUES ('2', 'Julian', 'Perez', '99897174');
INSERT INTO articulos.autores VALUES ('1', 'Andres', 'Calamaro', '99876869');
INSERT INTO articulos.autores VALUES ('4', 'Cidys', 'Castillo', '998987453');
INSERT INTO articulos.autores VALUES ('5', 'Pedro', 'Molina', '99891768');

-- 6. crear vista con datos procedentes de las dos tablas
CREATE VIEW vETLDatosparaT
AS
SELECT 
TituloId =t.titulo_id,
TituloNombre =CAST(t.titulo as nVarChar(100)),
TituloTipo =CASE CAST(t.tipo as nVarchar(100))
WHEN 'bbdd' THEN 'Base de datos, Transact-SQL'
WHEN 'BI' THEN 'Base de datos, BI'
WHEN 'administracion' THEN 'Base de datos, Administración'
WHEN 'dev' THEN 'Desarrollo'
WHEN 'programacion' THEN 'Desarrollo'
END,
NombreCompleto =a.NombreAutor + ' ' +a.ApellidosAutor,
a.TelefonoAutor
FROM articulos.titulos as t
JOIN articulos.autores as a ON t.titulo_id =a.TituloId

-- 8. crear BDE_DW (Data Warehouse analogo) y la tabla DimTitulos
USE master;
-- Borrar database
IF DB_ID('BDE_DW') IS NOT NULL DROP DATABASE BDE;
-- si no se puede crear porque no se abre la conexion se aborta
IF @@ERROR =3702
   RAISERROR('La base de datos no se puede crear porque no esta abierta',127,127) WITH NOWAIT, LOG;
-- crear database
CREATE DATABASE BDE_DW;
GO

-- Usar la base de datos
USE BDE_DW  
GO

-- crear la tabla DimTitulo para informes
USE BDE_DW 
GO
CREATE TABLE dbo.DimTitulos
(TituloId char(6) NOT NULL,
TituloNombre nVarChar(100) NOT NULL,
TituloTipo nVarChar(100) NOT NULL,
NombreCompleto nVarChar(200),
TelefonoAutor nVarchar(25));
GO

--8. ahora llenamos con datos de la vista que creamos
USE BDE
GO
INSERT INTO BDE_DW.dbo.DimTitulos
SELECT 
TituloId =t.titulo_id,
TituloNombre =CAST(t.titulo as nVarChar(100)),
TituloTipo =CASE CAST(t.tipo as nVarchar(100))
WHEN 'bbdd' THEN 'Base de datos, Transact-SQL'
WHEN 'BI' THEN 'Base de datos, BI'
WHEN 'administracion' THEN 'Base de datos, Administración'
WHEN 'dev' THEN 'Desarrollo'
WHEN 'programacion' THEN 'Desarrollo'
END,
NombreCompleto =a.NombreAutor + ' ' +a.ApellidosAutor,
a.TelefonoAutor
FROM BDE.articulos.titulos as t
JOIN BDE.articulos.autores as a ON t.titulo_id =a.TituloId

-- 9. Crear un procedimiento almacenado para el ETL
USE BDE
GO
--- es la tecnica mas sencilla (aclarado y rellenado) pero no es la unica tecnica (e.g actualizacion)
CREATE PROCEDURE pETL_Insertar_DimTitulo
AS
DELETE FROM BDE_DW.dbo.DimTitulos;
INSERT INTO BDE_DW.dbo.DimTitulos
SELECT 
TituloId =t.titulo_id,
TituloNombre =CAST(t.titulo as nVarChar(100)),
TituloTipo =CASE CAST(t.tipo as nVarchar(100))
WHEN 'bbdd' THEN 'Base de datos, Transact-SQL'
WHEN 'BI' THEN 'Base de datos, BI'
WHEN 'administracion' THEN 'Base de datos, Administración'
WHEN 'dev' THEN 'Desarrollo'
WHEN 'programacion' THEN 'Desarrollo'
END,
NombreCompleto =a.NombreAutor + ' ' +a.ApellidosAutor,
a.TelefonoAutor
FROM BDE.articulos.titulos as t
JOIN BDE.articulos.autores as a ON t.titulo_id =a.TituloId
GO

-- ir a Programatically>> Stores Procedures y verificar que se creo el procedimeinto

--10. Executar procedimeinto
EXECUTE pETL_Insertar_DimTitulo;
GO

USE BDE_DW

SELECT * FROM dbo.DimTitulos
GO