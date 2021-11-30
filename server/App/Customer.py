from flask import *
import pyodbc
from .DBS import cursor, conn

Customer = Blueprint('Customer', __name__)

@Customer.route("/get/customers", methods=["GET"])
def queryCustomers():
    sortby = request.args.get("sortby")
    orderbyAsc = request.args.get("asc")
    minRecommendee = int(request.args.get("minRec"))

    # Not select passwd
    query = "select ID, Username, Phone, Fname, Lname, Email, Bdate, IdNum, FamScore from KhachHang"
    if sortby == "ID":
        query += f" order by cast({sortby} as int)"
    else:
        query += f" order by {sortby}"
    
    if orderbyAsc == "1":
        query += " asc"
    elif orderbyAsc == "0":
        query += " desc"
    else:
        return Response("asc must be 1 or 0", status=400)

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]

    # Select Number of recommendee
    query = f"exec get_list_recommender {minRecommendee}"
    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    # Add Num_ref to results
    for row in cursor:
        id_customer = row[0]
        num_recommendee = row[-1]
        for item in results:
            if item["ID"] == id_customer:
                item["Num_ref"] = num_recommendee
                break;
    # Keep Num_ref = 0 record if minRecommendee=0 else drop it
    if minRecommendee != 0:
        for idx, item in reversed(list(enumerate(results))):
            if "Num_ref" not in item.keys():
                results.pop(idx)
    else:
        for item in results:
            if "Num_ref" not in item.keys():
                item["Num_ref"] = 0


    return jsonify(results)

@Customer.route("/get/customer", methods=["GET"])
def queryCustomer():
    customer_id = request.args.get("id")

    if customer_id == None:
        return Response("Much provide id", status=400)

    # Get infomation of KhachHang with id
    query = f"select * from KhachHang where ID={customer_id}"

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))

    # Get infomation of their recommendees
    query = f"exec get_list_recommendee \'{customer_id}\'"

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames2 = [column[0] for column in cursor.description]
    results2 = [dict(zip(colNames2, row)) for row in cursor]

    results["Recommendee"] = results2
    results["Num_ref"] = len(results2)

    return results

@Customer.route("/edit/customer", methods=["POST"])
def updateCustomer():
    data = request.get_json()

    ID_customer = data["ID"]
    Username = data["Username"]
    Passwd = data["Passwd"]
    Phone = data["Phone"]
    Fname = data["Fname"]
    Lname = data["Lname"]
    Email = data["Email"]
    Bdate = data["Bdate"]
    IdNum = data["IdNum"]
    if data["FamScore"] is not None:
        FamScore = int(data["FamScore"])
    else:
        FamScore = 0

    # Update KhachHang table
    query = '''update KhachHang set 
        Username = ?,
        Passwd = ?,
        Phone = ?,
        Fname = ?,
        Lname = ?,
        Email = ?,
        Bdate = ?,
        IdNum = ?,
        FamScore = ? 
        where ID = ?'''
    try:
        cursor.execute(query, Username, Passwd, Phone, Fname, Lname, Email, Bdate, IdNum, FamScore, ID_customer)
        cursor.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)

@Customer.route("/add/customer", methods=["POST"])
def addCustomer():
    data = request.get_json()

    # Insert table KhachHang
    query = "exec Insert_KhachHang "

    for k, v in request.json.items():
        if type(v) == str:
            query += f"@{k}=N\'{v}\',"
        else:
            query += f"@{k}={v},"
    query = query[:-1]

    try:
        cursor.execute(query)
        cursor.commit()
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    return Response("Success", status=200)