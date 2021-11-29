import pyodbc

# Connect to MS SqlServer. Change serverName if needed
serverName = "WICII"
databaseName = "db_a2"
connect = 'Driver={SQL Server};'+ 'Server=' + serverName + ';' + 'Database=' + databaseName + ';' + 'Trusted_Connection=yes;' + 'ansi=True'

# conn = pyodbc.connect(connect)
# cursor = conn.cursor()