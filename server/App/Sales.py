import pyodbc
from flask import *

Sales = Blueprint('Sales', __name__)

# Connect to MS SqlServer. Change serverName if needed
serverName = "DESKTOP-7VMMVHB\SQLEXPRESS"
databaseName = "db_a2"
conn = pyodbc.connect('Driver={SQL Server};'
                    'Server=' + serverName + ';'
                    'Database=' + databaseName + ';'
                    'Trusted_Connection=yes;' +
                    'ansi=True')
cursor = conn.cursor()

@Sales.route("/sales-info/all", methods=["GET"])
def getAllSales():
    cursor.execute('select * from CTKM_SanPham')
    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/get/sales-info", methods=["GET"])
def getSalesByID():
    id = request.args.get("id")
    if (id == None):
        return Response("Please provide sales ID", status=400)

    cursor.execute('select * from CTKM_SanPham where id = ?', id)
    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/get/applied-products", methods=["GET"])
def getProductsOfSales():
    id = request.args.get("id")
    if (id == None):
        return Response("Please provide sales ID", status=400)

    query = '''select SanPham.ID, ProdName, Price, manufacture
                from CTKM_SanPham, SanPham, SanPham_ApDung_CTKM
                where CTKM_SanPham.ID = SanPham_ApDung_CTKM.ID_Ad and
                SanPham.ID = SanPham_ApDung_CTKM.ID_Prod and
                CTKM_SanPham.ID = ?'''
    cursor.execute(query, id)
    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/add/sales", methods=["POST"])
def addSales():
    id = request.form.get("id")
    startDate = request.form.get("startDate")
    endDate = request.form.get("endDate")
    rate = request.form.get("rate")

    if (id == None or startDate == None or endDate == None or rate == None):
        return Response("Not enough information", status=400)

    try:
        query = "insert into CTKM_SanPham(ID, TimeStart, TimeEnd, PromoLevel) values (?, ?, ?, ?)"
        cursor.execute(query, id, startDate, endDate, rate)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Sales.route("/apply/product", methods=["POST"])
def applySalesToProduct():
    salesId = request.form.get("salesId")
    productId = request.form.get("productId")
    if (salesId == None):
        return Response("Please provide sales ID", status=400)
    elif (productId == None):
        return Response("Please provide product ID", status=400)
    try:
        query = "insert into SanPham_ApDung_CTKM(ID_Prod, ID_Ad) values (?, ?)"
        cursor.execute(query, productId, salesId)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Sales.route("/apply/brand", methods=["POST"])
def applySalesToBrand():
    salesId = request.form.get("salesId")
    brandName = request.form.get("brandName")
    if (salesId == None):
        return Response("Please provide sales ID", status=400)
    elif (brandName == None):
        return Response("Please provide brand name", status=400)
    try:
        query = "exec applySalesForBrand ?, ?"
        cursor.execute(query, salesId, brandName)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        print("ERROR: " + str(e))
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Sales.route("/update/sales", methods=["POST"])
def updateSales():
    id = request.form.get("id")
    startDate = request.form.get("startDate")
    endDate = request.form.get("endDate")
    rate = request.form.get("rate")

    if (id == None or startDate == None or endDate == None or rate == None):
        return Response("Not enough information", status=400)
    try:
        query = '''update CTKM_SanPham
                set TimeStart = ?, TimeEnd = ?, PromoLevel = ?
                where ID = ?'''
        cursor.execute(query, startDate, endDate, rate, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Sales.route("/remove/sales", methods=["POST"])
def removeSales():
    id = request.form.get("id")

    if (id == None):
        return Response("Please provide and ID", status=400)
    try:
        query = '''delete from CTKM_SanPham where ID = ?'''
        cursor.execute(query, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Sales.route("/remove/applied-product", methods=["POST"])
def removeAppliedProduct():
    salesId = request.form.get("salesId")
    productId = request.form.get("productId")

    if (id == None):
        return Response("Please provide and ID", status=400)
    try:
        query = '''delete from SanPham_ApDung_CTKM where ID_Ad = ? and ID_Prod = ?'''
        cursor.execute(query, salesId, productId)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        return Response(e.args[1], status=400)  #send sql error msg back to client
    return Response("Success", status=200)

@Sales.route("/get/product-sales", methods=["POST"])
def getSalesOfProduct():
    id = request.form.get("id")
    startDate = request.form.get("startDate")
    endDate = request.form.get("endDate")

    if (id == None or startDate == None or endDate == None):
        return Response("Not enough information", status=400)
    query = '''exec getSalesByProduct ?, ?, ?'''
    cursor.execute(query, id, startDate, endDate)

    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/get/best-sales", methods=["POST"])
def getBestSaleOfBrand():
    brandName = request.form.get("brandName")
    startDate = request.form.get("startDate")
    endDate = request.form.get("endDate")

    if (brandName == None or startDate == None or endDate == None):
        return Response("Not enough information", status=400)
    query = '''exec getTopDealsOfBrand ?, ?, ?'''
    cursor.execute(query, brandName, startDate, endDate)

    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

