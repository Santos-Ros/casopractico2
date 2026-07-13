from flask import Flask, request, redirect
import psycopg2
import os

app = Flask(__name__)

def get_db_conn():
    conn = psycopg2.connect(
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        host=os.environ["DB_HOST"]
    )
    conn.autocommit = True
    return conn

@app.route("/", methods=["GET", "POST"])
def index():
    conn = get_db_conn()
    cur = conn.cursor()

    cur.execute("CREATE TABLE IF NOT EXISTS votos (opcion TEXT)")
    if request.method == "POST":
        cur.execute("INSERT INTO votos (opcion) VALUES (%s)", (request.form["voto"],))
        return redirect("/")

    cur.execute("SELECT opcion, COUNT(*) FROM votos GROUP BY opcion")
    votos = dict(cur.fetchall())
    naked = votos.get("naked", 0)
    deportiva = votos.get("deportiva", 0)

    conn.close()

    return f"""
    <html>
    <head>
        <style>
            body {{
                margin: 0;
                font-family: 'Segoe UI', Arial, sans-serif;
                background: #1a1a1a;
                color: white;
                text-align: center;
                padding-top: 60px;
            }}
            h1 {{
                color: #e63946;
                background-color: rgba(0, 0, 0, 0.4);
                display: inline-block;
                padding: 10px 24px;
                border-radius: 10px;
            }}
            .opciones {{
                display: flex;
                justify-content: center;
                gap: 50px;
                margin: 30px 0;
            }}
            .opciones form {{
                display: inline-block;
            }}
            .imagen-btn {{
                border: none;
                background: #262626;
                cursor: pointer;
                width: 180px;
                height: 180px;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.5);
                transition: transform 0.2s;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                gap: 8px;
            }}
            .imagen-btn:hover {{
                transform: scale(1.08);
                background: #333;
            }}
            .imagen-btn .icono {{
                font-size: 64px;
            }}
            .imagen-btn .etiqueta {{
                font-size: 16px;
                color: #ccc;
            }}
            .resultados {{
                margin-top: 30px;
                font-size: 22px;
                background-color: rgba(230, 57, 70, 0.15);
                display: inline-block;
                padding: 10px 30px;
                border-radius: 10px;
                border: 1px solid #e63946;
            }}
            .reset-form {{
                margin-top: 20px;
            }}
            .reset-form button {{
                padding: 8px 20px;
                font-size: 16px;
                border-radius: 8px;
                border: none;
                background-color: #444;
                color: white;
                cursor: pointer;
            }}
        </style>
    </head>
    <body>
        <h1>🏍️ ¿Naked o Deportiva?</h1>
        <div class="opciones">
            <form method="post">
                <button class="imagen-btn" type="submit" name="voto" value="naked">
                    <span class="icono">🏙️</span>
                    <span class="etiqueta">Naked</span>
                </button>
            </form>
            <form method="post">
                <button class="imagen-btn" type="submit" name="voto" value="deportiva">
                    <span class="icono">🏁</span>
                    <span class="etiqueta">Deportiva</span>
                </button>
            </form>
        </div>
        <div class="resultados">
            <p>🏙️ Naked: {naked} votos</p>
            <p>🏁 Deportiva: {deportiva} votos</p>
        </div>
        <form method="post" action="/reset" class="reset-form">
            <button type="submit">🔄 Reset</button>
        </form>
    </body>
    </html>
    """


@app.route("/reset", methods=["POST"])
def reset():
    conn = get_db_conn()
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS votos")
    conn.close()
    return redirect("/")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)