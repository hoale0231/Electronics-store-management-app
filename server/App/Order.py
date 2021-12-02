from flask import *
import pyodbc
from .DBS import cursor, conn

Order = Blueprint('Order', __name__)

@Order.route("/api/order/all", methods=["GET"])
def queryAllOrder():

    query = "select * from DonHang order by cast(ID as char(9))"

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    return jsonify(results)


@Order.route("/api/order/remove", methods=["POST"])
def removeOrder():
    id = request.args.get("id")

    if (id == None):
        return Response("Please provide an ID!", status=400)
    try:
        query = "delete from DonHang where ID = ?"
        cursor.execute(query, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Order.route("/api/order/add", methods=["POST"])
def addOrder():
    query = "exec InsertDonHang "
    for k, v in request.json.items():
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
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Order.route("/api/order/update", methods=["POST"])
def updateOrder():
    data = request.get_json()
    ID = data["ID"]
    TimeCreated = data["TimeCreated"]
    SumPrices = data["SumPrices"]
    ID_Customer = data["ID_Customer"]
    ID_Employee = data["ID_Employee"]
    ID_Ad = data["ID_Ad"]
    if (ID == None or ID_Customer == None or ID_Employee == None):
        return Response("Not enough information!", status=400)
    try:
        query = '''update DonHang 
                set TimeCreated = ?, SumPrices = ?, ID_Customer = ?, ID_Employee = ?, ID_Ad = ? 
                where ID = ?'''
        cursor.execute(query, TimeCreated, SumPrices, ID_Customer, ID_Employee, ID_Ad, ID)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

def getProductsOfOrder(id):
    query = "exec InfoOrder @id_order = ?"
    
    try:
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    return results

@Order.route("/api/order/info", methods=["GET"])
def queryInfo():
    id = request.args.get("id")

    if id == None:
        return Response("Must provide ID!", status=400)

    query = "select * from DonHang where ID = ?"

    try:
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))

    results["detail"] = getProductsOfOrder(id)
    
    return jsonify(results)

@Order.route("/api/order/allpio", methods=["GET"])
def queryProductInOrder():

    query = "select * from SanPham_Thuoc_DonHang"

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    return jsonify(results)

@Order.route("/api/order/removepio", methods=["POST"])
def removeProductInOrder():
    id_order = request.args.get("id_order")
    id_prod = request.args.get("id_prod")

    if (id_order == None and id_prod == None):
        return Response("Please provide an ID!", status=400)
    try:
        query = "delete from SanPham_Thuoc_DonHang where ID_Order = ? and ID_Prod = ?"
        cursor.execute(query, id_order, id_prod)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Order.route("/api/order/addpio", methods=["POST"])
def addProductInOrder():
    data = request.get_json()
    id_order = data["ID_Order"]
    id_prod = data["ID_Prod"]
    price = data["Price"]
    qty = data["Quantity"]

    if (id_order == None or id_prod == None or price == None or qty == None):
        return Response("Not enough information", status=400)

    try:
        query = "insert into SanPham_Thuoc_DonHang (ID_Order, ID_Prod, Price, Quantity) values (?, ?, ?, ?)"
        cursor.execute(query, id_order, id_prod, price, qty)
        conn.commit()
    except pyodbc.Error as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Order.route("/api/order/updatepio", methods=["POST"])
def updateProductInOrder():
    data = request.get_json()
    id_order = data["ID_Order"]
    id_prod = data["ID_Prod"]
    price = data["Price"]
    qty = data["Quantity"]
    if (id_order == None or id_prod == None or price == None or qty == None):
        return Response("Not enough information!", status=400)
    try:
        query = '''update SanPham_Thuoc_DonHang 
                set Price = ?, Quantity = ? 
                where ID_Order = ? and ID_Prod = ?'''
        cursor.execute(query, price, qty, id_order, id_prod)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Order.route("/api/order/infopio", methods=["GET"])
def queryPIOInfo():
    id_order = request.args.get("id_order")
    id_prod = request.args.get("id_prod")

    if id_order == None or id_prod == None:
        return Response("Must provide ID!", status=400)

    query = "select * from SanPham_Thuoc_DonHang where ID_Order = ? and ID_Prod = ?"

    try:
        cursor.execute(query, id_order, id_prod)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))
    
    return jsonify(results)

@Order.route("/api/order/hotproduct", methods=["GET"])
def getHotProduct():
    prodType = 'All'
    query = "exec LikedProduct @prodType = ?"
    try:
        cursor.execute(query, prodType)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]
    return jsonify(results)