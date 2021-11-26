import flask
import pyodbc

Product = flask.Blueprint('Product', __name__)

cnxn = pyodbc.connect("Driver={SQL Server Native Client 11.0};"
                      "Server=WICII;"
                      "Database=db_a2;"
                      "Trusted_Connection=yes;")

cursor = cnxn.cursor()
    
@Product.route("/api/product/all", methods = ["GET"])
def queryProducts():
    type = flask.request.args.get("type")
    orderBy = flask.request.args.get("orderby")
    desc = flask.request.args.get("desc")
    qty = flask.request.args.get("qty")
    offset = flask.request.args.get("offset")
    
    query = "exec getProductsOfType"
    
    if type != None:
        query += f" @type=\'{type}\',"
        
    if orderBy != None:
        query += f" @orderBy=\'{orderBy}\',"
        
    if desc != None:
        query += f" @desc={desc},"
        
    if qty != None:
        query += f" @qty={qty},"
        
    if offset != None:
        query += f" @offset={offset}"

    if query[-1] == ",":
        query = query[:-1]
    print(query)
    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        
    return flask.jsonify([{"ID": row.ID, 
                           "ProdName": row.ProdName, 
                           "PriceIn": row.PriceIn, 
                           "Price": row.Price, 
                           "CurrentPrice": row.CurrentPrice, 
                           "Insurance": row.Insurance, 
                           "TotalQuantity": row.TotalQuantity} 
                          for row in cursor])
