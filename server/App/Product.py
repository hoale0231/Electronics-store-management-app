import flask
import pyodbc 

Product = flask.Blueprint('Product', __name__)

# cnxn = pyodbc.connect("Driver={SQL Server Native Client 11.0};"
#                       "Server=WICII;"
#                       "Database=db_a2;"
#                       "Trusted_Connection=yes;")

# cursor = cnxn.cursor()
    
@Product.route("/api/product/all", methods = ["GET"])
def queryAllDishesType():
    pass
    # try:
    #     cursor.execute('select * from SanPham')
    # except pyodbc.Error as err:
    #     print(err)
    
    # return flask.jsonify(list(cursor.fetchall()))