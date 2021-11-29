from flask import *
import pyodbc
from .DBS import connect

Product = Blueprint('Product', __name__)
    
@Product.route("/get/product", methods = ["GET"])
def queryProducts():
    type = request.args.get("type")
    orderBy = request.args.get("orderby")
    desc = request.args.get("desc")
    qty = request.args.get("qty")
    offset = request.args.get("offset")
    
    query = "exec getProductsOfType"
    
    if type != None:        query += f" @type=\'{type}\',"
    if orderBy != None:     query += f" @orderBy=\'{orderBy}\',"
    if desc != None:        query += f" @desc={desc},"
    if qty != None:         query += f" @qty={qty},"
    if offset != None:      query += f" @offset={offset}"
    if query[-1] == ",":    query = query[:-1]

    try:
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
        
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    
    return jsonify(results)

@Product.route("/get/infoproduct", methods = ["GET"])
def queryInfo():
    id = request.args.get("id")
    
    if id == None:
        return Response("Please provide and ID!!", status=400)
    
    query = "exec getInfoProduct @ID = ?"
    
    try:
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    
    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))
    
    return jsonify(results)
    
@Product.route("/edit/infoproduct", methods=["POST"])
def editProduct():
    query = "exec updateSanPham "
    for k, v in request.json.items():
        if v is None:
            continue
        if type(v) == str:
            query += f"@{k}=N\'{v}\',"
        else: 
            query += f"@{k}={v}," 
    query = query[:-1]
    try:
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Product.route("/delete/product", methods = ["POST"])
def deleteProduct():
    id = request.json.get("ID")

    if (id == None):
        return Response("Please provide and ID!!", status=400)
    try:
        query = '''delete from SanPham where ID = ?'''
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Product.route("/add/product", methods = ["POST"])
def addProduct():
    query = "exec insertSanPham "
    for k, v in request.json.items():
        if type(v) == str:
            query += f"@{k}=N\'{v}\',"
        else: 
            query += f"@{k}={v}," 
    query = query[:-1]
    try:
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)
    
@Product.route("/get/SummaryProduct", methods = ["GET"])
def getSummaryProduct():
    ProdType = request.args.get("ProdType")
    
    query = "exec getSummaryProduct @ProdType = ?"
    
    try:
        conn = pyodbc.connect(connect)
        cursor = conn.cursor()
        cursor.execute(query, ProdType)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    
    return jsonify(results)