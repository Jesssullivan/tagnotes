from __future__ import print_function
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import datetime
import time
import threading
import pickle
import os
import csv
import subprocess

SCOPES = ['https://www.googleapis.com/auth/calendar']

def run():
    # adapted from https://developers.google.com/calendar/create-events
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    service = build('calendar', 'v3', credentials=creds)
    now = datetime.datetime.utcnow().isoformat() + 'Z'  # 'Z' indicates UTC time

    with open('dates.csv', 'r') as f:
        r = csv.reader(f)
        for row in r:
            try:
                mo = int(row[0][0:2])
            except:
                continue
            try:
                dd = int(row[0][3:5])
            except:
                continue
            try:
                yy = int(str('20' + row[0][6:8]))
            except:
                continue
            try:
                title = str(row[1])
            except:
                continue
            try:
                hh = int(row[2][0:2])
            except:
                continue
            try:
                mm = int(row[2][3:5])
            except:
                continue
            try:
                desc = str(row[3])
            except:
                desc = ' '

    pushdatetime = datetime.datetime(month=mo, day=dd, year=yy, hour=hh, minute=mm)
    pushdateend = datetime.datetime(month=mo, day=dd, year=yy, hour=hh, minute=mm) + datetime.timedelta(hours=1)

    event = {
        'summary': title,
        'description': desc,
        'start': {
            'dateTime': str(pushdatetime.isoformat()),
            'timeZone': 'America/New_York',
        },
        'end': {
            'dateTime': str(pushdateend.isoformat()),
            'timeZone': 'America/New_York',
        },
        'reminders': {
            'useDefault': False,
            'overrides':
                {'method': 'popup', 'minutes': 10},
        },
    }

    event = service.events().insert(calendarId='primary', body=event).execute()
    print('Event created: %s' % (event.get('htmlLink')))


def loop():
    while True:
        time.sleep(2)
        subprocess.Popen('./nScan', shell=True, executable='/bin/bash')
        time.sleep(2)
        try:
            run()
        except:
            time.sleep(2)


init_loop = threading.Thread(target=loop)

if __name__ == '__main__':
    init_loop.start()











