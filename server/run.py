from flask import Flask
from App.Product import Product
from App.Sales import Sales
from App.Toai import Toai
from App.Tuan import Tuan
from App.Tu import Tu

app = Flask(__name__)

@app.route("/", methods=["GET"])
def index():
    return '''<h1>API for Database Systems</h1>'''

app.register_blueprint(Product)
app.register_blueprint(Sales, url_prefix="/sales")
app.register_blueprint(Toai)
app.register_blueprint(Tuan)
app.register_blueprint(Tu)

app.run() 