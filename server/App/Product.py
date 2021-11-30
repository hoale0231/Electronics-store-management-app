from flask import *
import pyodbc
from .DBS import cursor, conn

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
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    
    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))
    
    query = "exec getQuantityProductBranchs @ID = ?"
    
    try:
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    
    for row in cursor:
        results[row[0]] = row[1]
    
    return jsonify(results)

def updateQuantityProductBranch(IDBranch, IDProd, Quantity):
    query = "update ChiNhanh_Ban_SanPham set Quantity = ? where ID_Branch = ? and ID_Prod = ?"
    try:
        cursor.execute(query,  Quantity, IDBranch, IDProd)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return (e.args[1], 400)  #send sql error msg back to client
    return ("Success", 200)
    
@Product.route("/edit/infoproduct", methods=["POST"])
def editProduct():
    query = "exec updateSanPham "
    id = request.json['ID']
    for k, v in request.json.items():
        if k.strip().isnumeric():
            status = updateQuantityProductBranch(k, id, v)
            if status[1] == 200: continue
            else: return Response(status[0], status=status[1])
        if v is None:
            continue
        if type(v) == str:
            query += f"@{k}=N\'{v}\',"
        else: 
            query += f"@{k}={v}," 
    query = query[:-1]
    try:
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
        cursor.execute(query, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

def insertQuantityProductBranch(IDProd, Quantity: dict):
    query = "insert into ChiNhanh_Ban_SanPham (ID_Prod, ID_Branch, Quantity) values (?, ?, ?)"
    for k, v in Quantity.items():
        try:
            cursor.execute(query, IDProd, k, v)
            conn.commit()
        except pyodbc.ProgrammingError as e:
            print("ERROR: " + str(e))
            return (e.args[1], 400)  #send sql error msg back to client
    return ("Success", 200)

@Product.route("/add/product", methods = ["POST"])
def addProduct():
    query = "exec insertSanPham "
    quantity = dict()
    for k, v in request.json.items():
        if k.strip().isnumeric():
            quantity[k] = v
            continue
        if type(v) == str:
            query += f"@{k}=N\'{v}\',"
        else: 
            query += f"@{k}={v}," 
    query = query[:-1]
    try:
        cursor.execute(query)
        insertQuantityProductBranch(cursor.fetchone()[0], quantity)
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
        cursor.execute(query, ProdType)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    
    return jsonify(results)