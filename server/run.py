from flask import Flask
from App.Product import Product
from App.Sales import Sales
from App.Staff import Staff
from App.Order import Order
from App.Customer import Customer

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # Allow utf-8 in jsonify()


@app.route("/", methods=["GET"])
def index():
    return '''<h1>API for Database Systems</h1>'''


app.register_blueprint(Product)
app.register_blueprint(Sales, url_prefix="/api/sales")
app.register_blueprint(Order)
app.register_blueprint(Customer)
app.register_blueprint(Staff)

# Remove debug param after finished testing
# Debug mode detecting change in script and restart server automatically
app.run(debug=1)
