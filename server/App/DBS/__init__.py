import pyodbc

# Connect to MS SqlServer. Change serverName if needed
serverName = "LAPTOP-IBRL3521"
databaseName = "db_a2"
conn = pyodbc.connect('Driver={SQL Server};'
                      'Server=' + serverName + ';'
                      'Database=' + databaseName + ';'
                      'Trusted_Connection=yes;' +
                      'ansi=True')

cursor = conn.cursor()
