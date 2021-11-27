import flask
import pyodbc
from .DBS import cursor

Product = flask.Blueprint('Product', __name__)
    
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

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return flask.Response(err.args[1], status=400)
        
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    
    return flask.jsonify(results)

@Product.route("/api/product/info", methods = ["GET"])
def queryInfo():
    id = flask.request.args.get("id")
    
    if id == None:
        return flask.Response("Much provide ID!!", status=400)
    
    query = "exec getInfoProduct @ID = ?"
    
    try:
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return flask.Response(err.args[1], status=400)
    
    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))
    
    return flask.jsonify(results)
    