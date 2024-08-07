from flask import Flask, render_template, request, redirect, url_for, flash, session
from config import Config
import pyodbc

app = Flask(__name__)
app.config.from_object(Config)
app.secret_key = 'your_secret_key'

def get_db_connection():
    conn = pyodbc.connect(app.config['CONNECTION_STRING'])
    return conn

@app.route('/')
def index():
    if 'user_email' in session:
        return render_template('index.html', logged_in=True)
    return render_template('index.html', logged_in=False)

@app.route('/nosotros')
def nosotros():
    return render_template('nosotros.html')

@app.route('/recursos')
def recursos():
    return render_template('recursos.html')

@app.route('/consejos')
def consejos():
    return render_template('consejos.html')

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    session.pop('user_email', None)
    session.pop('specialist_email', None)
    return redirect(url_for('index'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        nombre = request.form['nombre']
        email = request.form['email']
        telefono = request.form['telefono']
        direccion = request.form['direccion']
        contraseña = request.form['contraseña']

        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("{CALL CrearUsuario(?, ?, ?, ?, ?)}", nombre, email, telefono, direccion, contraseña)
            conn.commit()
            return redirect(url_for('index'))
        except pyodbc.Error as e:
            conn.rollback()
            if '23000' in str(e):  # Código de error SQL Server para duplicados
                flash('Este correo ya está siendo utilizado.', 'danger')
            else:
                flash('Ocurrió un error al registrar el usuario. Por favor, inténtalo de nuevo.', 'danger')
        finally:
            cur.close()
            conn.close()

    return render_template('registro_cliente.html')

@app.route('/register_specialist', methods=['GET', 'POST'])
def register_specialist():
    if request.method == 'POST':
        nombre = request.form['nombre']
        email = request.form['email']
        telefono = request.form['telefono']
        especialidad = request.form['especialidad']
        direccion = request.form['direccion']
        sobre_mi = request.form['sobre_mi']
        contraseña = request.form['contraseña']

        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("{CALL CrearEspecialista(?, ?, ?, ?, ?, ?, ?)}", nombre, email, telefono, especialidad, direccion, sobre_mi, contraseña)
            conn.commit()
            return redirect(url_for('index'))
        except pyodbc.Error as e:
            conn.rollback()
            if '23000' in str(e):  # Código de error SQL Server para duplicados
                flash('Este correo ya está siendo utilizado.', 'danger')
            else:
                flash('Ocurrió un error al registrar el especialista. Por favor, inténtalo de nuevo.', 'danger')
        finally:
            cur.close()
            conn.close()

    return render_template('registro_especialista.html')

@app.route('/login_usuario', methods=['GET', 'POST'])
def login_usuario():
    if request.method == 'POST':
        email = request.form['email']
        contraseña = request.form['contraseña']

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, contraseña FROM usuarios WHERE email = ?", (email,))
        user = cur.fetchone()

        if user:
            user_id, hashed_password = user
            if contraseña == hashed_password:
                session['logged_in'] = True
                session['user_email'] = email
                session['user_id'] = user_id
                return redirect(url_for('index'))
            else:
                flash('Contraseña incorrecta', 'danger')
        else:
            flash('Email no registrado', 'danger')

        cur.close()
        conn.close()

    return render_template('login_usuario.html')

@app.route('/login_especialista', methods=['GET', 'POST'])
def login_especialista():
    if request.method == 'POST':
        email = request.form['email']
        contraseña = request.form['contraseña']

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, contraseña FROM especialistas WHERE email = ?", (email,))
        specialist = cur.fetchone()

        if specialist:
            specialist_id, hashed_password = specialist
            if contraseña == hashed_password:
                session['logged_in'] = True
                session['specialist_email'] = email
                session['specialist_id'] = specialist_id
                return redirect(url_for('index'))
            else:
                flash('Contraseña incorrecta', 'danger')
        else:
            flash('Email no registrado', 'danger')

        cur.close()
        conn.close()

    return render_template('login_especialista.html')

@app.route('/crear_cita', methods=['GET', 'POST'])
def crear_cita():
    if 'user_email' not in session:
        flash('Debes iniciar sesión para crear una cita.', 'warning')
        return redirect(url_for('login_usuario'))

    especialista_id = request.args.get('especialista_id')

    if request.method == 'POST':
        fecha_cita = request.form['fecha_cita']
        hora_cita = request.form['hora_cita']
        motivo = request.form['motivo']
        usuario_id = session.get('user_id')

        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("{CALL CrearCita(?, ?, ?, ?, ?)}", usuario_id, especialista_id, fecha_cita, hora_cita, motivo)
            conn.commit()
            return redirect(url_for('index'))
        except Exception as e:
            conn.rollback()
            flash(f'Error: {e}', 'danger')
        finally:
            cur.close()
            conn.close()

    return render_template('crear_cita.html', especialista_id=especialista_id)

@app.route('/mis_citas')
def mis_citas():
    if 'specialist_email' not in session:
        flash('Debes iniciar sesión como especialista para ver tus citas.', 'warning')
        return redirect(url_for('login_especialista'))

    specialist_email = session['specialist_email']

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT citas.id, usuarios.nombre AS usuario_nombre, fecha_cita, hora_cita, motivo, citas.estado
        FROM citas
        JOIN usuarios ON citas.usuario_id = usuarios.id
        WHERE citas.especialista_id = (
            SELECT id FROM especialistas WHERE email = ?
        )
        """, (specialist_email,))

    citas = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('mis_citas.html', citas=citas)

@app.route('/actualizar_estado/<int:cita_id>', methods=['POST'])
def actualizar_estado(cita_id):
    nuevo_estado = request.form['estado']

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("{CALL ActualizarEstadoCita(?, ?)}", cita_id, nuevo_estado)
        conn.commit()
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cur.close()
        conn.close()

    return redirect(url_for('mis_citas'))

@app.route('/mis_citas_paciente')
def mis_citas_paciente():
    if 'user_email' not in session:
        flash('Debes iniciar sesión para ver tus citas.', 'warning')
        return redirect(url_for('login_usuario'))

    user_id = session.get('user_id')

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT citas.id, especialistas.nombre AS especialista_nombre, fecha_cita, hora_cita, motivo, citas.estado
        FROM citas
        JOIN especialistas ON citas.especialista_id = especialistas.id
        WHERE citas.usuario_id = ?
        """, (user_id,))

    citas = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('mis_citas_paciente.html', citas=citas)

@app.route('/cancelar_cita/<int:cita_id>', methods=['POST'])
def cancelar_cita(cita_id):
    if 'user_email' not in session:
        flash('Debes iniciar sesión para cancelar una cita.', 'warning')
        return redirect(url_for('login_usuario'))

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("UPDATE citas SET estado = 'cancelada' WHERE id = ? AND usuario_id = ?", (cita_id, session.get('user_id')))
        conn.commit()
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cur.close()
        conn.close()

    return redirect(url_for('mis_citas_paciente'))

@app.route('/especialistas')
def especialistas():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, nombre, email, especialidad, telefono, direccion, sobre_mi FROM especialistas")
    especialistas = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('especialistas.html', especialistas=especialistas)

if __name__ == '__main__':
    app.run(debug=True)
