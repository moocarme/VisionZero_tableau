# -*- coding: utf-8 -*-
"""
Created on Fri Jul  8 19:53:53 2016

@author: matt-666
"""

import csv, sqlite3

con = sqlite3.connect('''VisionZeroDB.sqlite''')
cur = con.cursor()
cur.executescript('''DROP TABLE IF EXISTS VZCollision;
    CREATE TABLE VZCollision (Date DATE, Time TEXT, Borough TEXT, ZipCode INTEGER, 
                              Latitude REAL, Longitude REAL, Location TEXT, 
                              Street TEXT, CrossStreet TEXT, OffStreet TEXT, 
                              PersonsInjured INTEGER, PersonsKilled INTEGER, 
                              PedestriansInjured INTEGER, PedestriansKilled INTEGER, 
                              CyclistsInjured INTEGER, CyclistsKilled INTEGER, 
                              MotoristsInjured INTEGER, MotoristsKilled INTEGER, 
                              Vehicle1 TEXT, Vehicle2 TEXT, Vehicle3 TEXT, 
                              Vehicle4 TEXT, Vehicle5 TEXT, UniqueKey INTEGER, 
                              VehicleType1 TEXT, VehicleType2 TEXT, 
                              VehicleType3 TEXT, VehicleType4 TEXT, 
                              VehicleType5 TEXT);''')

with open('data/NYPD_Motor_Vehicle_Collisions.csv','rb') as fin: # `with` statement available in 2.5+
    # csv.DictReader uses first line in file for column headings by default
    dr = csv.DictReader(fin) # comma is default delimiter
    to_db = [(i['DATE'], i['TIME'], i['BOROUGH'], i['ZIP CODE'], i['LATITUDE'], \
        i['LONGITUDE'], i['LOCATION'], i['ON STREET NAME'], i['CROSS STREET NAME'], 
        i['OFF STREET NAME'], i['NUMBER OF PERSONS INJURED'], i['NUMBER OF PERSONS KILLED'], \
        i['NUMBER OF PEDESTRIANS INJURED'], i['NUMBER OF PEDESTRIANS KILLED'], \
        i['NUMBER OF CYCLIST INJURED'], i['NUMBER OF CYCLIST KILLED'], \
        i['NUMBER OF MOTORIST INJURED'], i['NUMBER OF MOTORIST KILLED'], 
        i['CONTRIBUTING FACTOR VEHICLE 1'], i['CONTRIBUTING FACTOR VEHICLE 2'], \
        i['CONTRIBUTING FACTOR VEHICLE 3'], i['CONTRIBUTING FACTOR VEHICLE 4'], \
        i['CONTRIBUTING FACTOR VEHICLE 5'], i['UNIQUE KEY'], i['VEHICLE TYPE CODE 1'], \
        i['VEHICLE TYPE CODE 2'], i['VEHICLE TYPE CODE 3'], i['VEHICLE TYPE CODE 4'], \
        i['VEHICLE TYPE CODE 5']) for i in dr]

cur.executemany('''INSERT INTO VZCollision (Date, Time, Borough, ZipCode, Latitude, 
                                            Longitude, Location, Street, CrossStreet, 
                                            OffStreet, PersonsInjured, PersonsKilled, 
                                            PedestriansInjured, PedestriansKilled, 
                                            CyclistsInjured, CyclistsKilled, 
                                            MotoristsInjured, MotoristsKilled, 
                                            Vehicle1, Vehicle2, Vehicle3, Vehicle4, 
                                            Vehicle5, UniqueKey, VehicleType1, 
                                            VehicleType2, VehicleType3, VehicleType4, 
                                            VehicleType5) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);''', to_db)
con.commit()

