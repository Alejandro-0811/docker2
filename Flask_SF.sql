-- Crear la base de datos
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Flask_SF')
BEGIN
    CREATE DATABASE Flask_SF;
END
GO

USE Flask_SF;
GO

-- Crear tabla usuarios
CREATE TABLE usuarios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    contraseña VARCHAR(255) NOT NULL,
    fecha_registro DATETIME DEFAULT GETDATE()
);
GO

-- Crear tabla especialistas
CREATE TABLE especialistas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    especialidad VARCHAR(100),
    direccion VARCHAR(255),
    sobre_mi VARCHAR(MAX), -- Cambiado de TEXT a VARCHAR(MAX)
    contraseña VARCHAR(255) NOT NULL,
    fecha_registro DATETIME DEFAULT GETDATE()
);
GO

-- Crear tabla citas
CREATE TABLE citas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    especialista_id INT NOT NULL,
    fecha_cita DATE NOT NULL,
    hora_cita TIME NOT NULL,
    motivo VARCHAR(255),
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (especialista_id) REFERENCES especialistas(id)
);
GO

-- Crear tabla bitacora
CREATE TABLE bitacora (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tabla VARCHAR(50),
    operacion VARCHAR(50),
    registro_id INT,
    datos VARCHAR(MAX), -- Cambiado de TEXT a VARCHAR(MAX)
    fecha DATETIME DEFAULT GETDATE()
);
GO

-- Procedimiento para crear usuario
CREATE PROCEDURE CrearUsuario
    @p_nombre VARCHAR(100),
    @p_email VARCHAR(100),
    @p_telefono VARCHAR(20),
    @p_direccion VARCHAR(255),
    @p_contraseña VARCHAR(255)
AS
BEGIN
    INSERT INTO usuarios (nombre, email, telefono, direccion, contraseña)
    VALUES (@p_nombre, @p_email, @p_telefono, @p_direccion, @p_contraseña);
END
GO

-- Procedimiento para crear especialista
CREATE PROCEDURE CrearEspecialista
    @p_nombre VARCHAR(100),
    @p_email VARCHAR(100),
    @p_telefono VARCHAR(20),
    @p_especialidad VARCHAR(100),
    @p_direccion VARCHAR(255),
    @p_sobre_mi VARCHAR(MAX), -- Cambiado de TEXT a VARCHAR(MAX)
    @p_contraseña VARCHAR(255)
AS
BEGIN
    INSERT INTO especialistas (nombre, email, telefono, especialidad, direccion, sobre_mi, contraseña)
    VALUES (@p_nombre, @p_email, @p_telefono, @p_especialidad, @p_direccion, @p_sobre_mi, @p_contraseña);
END
GO

-- Procedimiento para crear cita
CREATE PROCEDURE CrearCita
    @p_usuario_id INT,
    @p_especialista_id INT,
    @p_fecha_cita DATE,
    @p_hora_cita TIME,
    @p_motivo VARCHAR(255)
AS
BEGIN
    INSERT INTO citas (usuario_id, especialista_id, fecha_cita, hora_cita, motivo)
    VALUES (@p_usuario_id, @p_especialista_id, @p_fecha_cita, @p_hora_cita, @p_motivo);
END
GO

-- Procedimiento para actualizar estado de cita
CREATE PROCEDURE ActualizarEstadoCita
    @p_cita_id INT,
    @p_nuevo_estado VARCHAR(50)
AS
BEGIN
    DECLARE @estado_actual VARCHAR(50);

    SELECT @estado_actual = estado FROM citas WHERE id = @p_cita_id;

    IF @estado_actual = 'cancelada'
    BEGIN
        THROW 50000, 'La cita ya ha sido cancelada y no puede ser modificada.', 1;
    END
    ELSE
    BEGIN
        UPDATE citas SET estado = @p_nuevo_estado WHERE id = @p_cita_id;
    END
END
GO

-- Triggers para la tabla usuarios
CREATE TRIGGER after_insert_usuarios
ON usuarios
AFTER INSERT
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'usuarios',
        'INSERT',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Dirección: ', direccion)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_update_usuarios
ON usuarios
AFTER UPDATE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'usuarios',
        'UPDATE',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Dirección: ', direccion)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_delete_usuarios
ON usuarios
AFTER DELETE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'usuarios',
        'DELETE',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Dirección: ', direccion)
    FROM DELETED;
END
GO

-- Triggers para la tabla especialistas
CREATE TRIGGER after_insert_especialistas
ON especialistas
AFTER INSERT
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'especialistas',
        'INSERT',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Especialidad: ', especialidad, ', Dirección: ', direccion, ', Sobre mí: ', sobre_mi)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_update_especialistas
ON especialistas
AFTER UPDATE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'especialistas',
        'UPDATE',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Especialidad: ', especialidad, ', Dirección: ', direccion, ', Sobre mí: ', sobre_mi)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_delete_especialistas
ON especialistas
AFTER DELETE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'especialistas',
        'DELETE',
        id,
        CONCAT('Nombre: ', nombre, ', Email: ', email, ', Teléfono: ', telefono, ', Especialidad: ', especialidad, ', Dirección: ', direccion, ', Sobre mí: ', sobre_mi)
    FROM DELETED;
END
GO

-- Triggers para la tabla citas
CREATE TRIGGER after_insert_citas
ON citas
AFTER INSERT
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'citas',
        'INSERT',
        id,
        CONCAT('Usuario ID: ', usuario_id, ', Especialista ID: ', especialista_id, ', Fecha Cita: ', fecha_cita, ', Hora Cita: ', hora_cita, ', Motivo: ', motivo, ', Estado: ', estado)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_update_citas
ON citas
AFTER UPDATE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'citas',
        'UPDATE',
        id,
        CONCAT('Usuario ID: ', usuario_id, ', Especialista ID: ', especialista_id, ', Fecha Cita: ', fecha_cita, ', Hora Cita: ', hora_cita, ', Motivo: ', motivo, ', Estado: ', estado)
    FROM INSERTED;
END
GO

CREATE TRIGGER after_delete_citas
ON citas
AFTER DELETE
AS
BEGIN
    INSERT INTO bitacora (tabla, operacion, registro_id, datos)
    SELECT
        'citas',
        'DELETE',
        id,
        CONCAT('Usuario ID: ', usuario_id, ', Especialista ID: ', especialista_id, ', Fecha Cita: ', fecha_cita, ', Hora Cita: ', hora_cita, ', Motivo: ', motivo, ', Estado: ', estado)
    FROM DELETED;
END
GO

-- Consultas para verificar tablas
SELECT * FROM usuarios;
SELECT * FROM especialistas;
SELECT * FROM citas;
SELECT * FROM bitacora;
