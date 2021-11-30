# import flask
# from .DBS import cursor

from flask import *
import pyodbc
from .DBS import cursor, conn

# Staff = Blueprint('zzz', __name__)
Staff = Blueprint('Staff', __name__)


@Staff.route("/api/staff/all", methods=["GET"])
def queryStaffs():

    query = "select * from NhanVien order by cast(ID as int)"

    try:
        cursor.execute(query)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = [dict(zip(colNames, row)) for row in cursor]

    return jsonify(results)


@Staff.route("/api/staff/info", methods=["GET"])
def queryInfo():
    id = request.args.get("id")

    if id == None:
        return Response("Much provide ID!!", status=400)

    query = "select * from NhanVien where ID = ?"

    try:
        cursor.execute(query, id)
    except pyodbc.Error as err:
        print(err)
        return Response(err.args[1], status=400)

    colNames = [column[0] for column in cursor.description]
    results = dict(zip(colNames, cursor.fetchone()))

    return jsonify(results)


@Staff.route("/api/staff/remove", methods=["POST"])
def removeStaff():
    id = request.args.get("id")

    if (id == None):
        return Response("Please provide and ID", status=400)
    try:
        query = "delete from NhanVien where ID = ?"
        cursor.execute(query, id)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)


@Staff.route("/api/staff/update", methods=["POST"])
def updateStaff():
    data = request.get_json()
    ID = data["ID"]
    Passwd = data["Passwd"]
    IdNum = data["IdNum"]
    Phone = data["Phone"]
    Salary = data["Salary"]
    Bdate = data["Bdate"]
    Fname = data["Fname"]
    Lname = data["Lname"]
    Addr = data["Addr"]
    ID_branch = data["ID_branch"]
    if (ID == None):
        return Response("Please provide and ID", status=400)
    try:
        query = '''update NhanVien set
        Passwd = ?, IdNum = ?, Phone = ?, Salary = ?, Bdate = ?,
        Fname = ?, Lname = ?, Addr = ?, ID_branch = ?
        where ID = ?'''
        cursor.execute(query, Passwd, IdNum, Phone, Salary,
                       Bdate, Fname, Lname, Addr, ID_branch, ID)
        conn.commit()
    except pyodbc.ProgrammingError as e:
        # send sql error msg back to client
        return Response(e.args[1], status=400)
    return Response("Success", status=200)


@Staff.route("/api/staff/add", methods=["POST"])
def addStaff():
    query = "exec insertNhanVien "
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
