from flask import *
import pyodbc

Sales = Blueprint('Sales', __name__)

#Connect to MS SqlServer. Change serverName if needed
serverName = "DESKTOP-7VMMVHB\SQLEXPRESS"
databaseName = "db_a2"
conn = pyodbc.connect('Driver={SQL Server};'
                      'Server='+ serverName + ';'
                      'Database=' + databaseName + ';'
                      'Trusted_Connection=yes;' +
                      'ansi=True')
cursor = conn.cursor()

@Sales.route("/get/all", methods=["GET"])
def getAllSales():
    cursor.execute('select * from CTKM_SanPham')
    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/get/", methods=["GET"])
def getSalesByID():
    id = request.args.get("id")
    cursor.execute('select * from CTKM_SanPham where id = ?', id)
    records = cursor.fetchall()
    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in records]
    return jsonify(results)

@Sales.route("/apply/brand", methods=["POST"])
def applySalesToBrand():
    pass




