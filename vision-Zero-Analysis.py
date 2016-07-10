# -*- coding: utf-8 -*-
"""
Created on Fri Jul  8 19:53:53 2016

@author: matt-666
"""

import sqlite3

conn = sqlite3.connect('''VisionZeroDB.sqlite''')
cur = conn.cursor()

# All non vero injuries and dates
cur.execute('''SELECT Date, PersonsInjured 
                      FROM VZCollision 
                      WHERE PersonsInjured > 0''')
t1 = list(cur.fetchall())

# Sum all injuries and deaths
cur.execute('''SELECT SUM(PersonsInjured), SUM(PersonsKilled),
                      SUM(MotoristsInjured), SUM(MotoristsKilled),
                      SUM(PedestriansInjured), SUM(PedestriansKilled),
                      SUM(CyclistsInjured), SUM(CyclistsKilled)                     
                      FROM VZCollision 
                      WHERE PersonsInjured > 0
                      AND Date = '06/24/2016' ''')
t2 = list(cur.fetchall())
conn.commit()

