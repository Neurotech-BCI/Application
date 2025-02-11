import os
import io
from flask import Flask, request, jsonify
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload

app = Flask(__name__)

# --- Configuration ---
# Path to your service account credentials JSON file.
SERVICE_ACCOUNT_FILE = 'path/to/your/credential.json'
# The Drive folder where files will be uploaded.
DRIVE_FOLDER_ID = '19KE2jfHlKZyJSdk4WVf3-k9aOEMXUC6-'
# The scopes required for file access.
SCOPES = ['https://www.googleapis.com/auth/drive.file']


def get_drive_service():
    """
    Creates an authorized Google Drive service using the service account credentials.
    """
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    service = build('drive', 'v3', credentials=credentials)
    return service


@app.route('/upload_csv', methods=['POST'])
def upload_csv():
    """
    Expects a JSON payload with two fields:
      - "csv_content": a string containing the CSV data
      - "file_name": the name for the CSV file (e.g., "stroop_test_2025-02-10T15:30:00.csv")
      
    The endpoint uploads the CSV data to the specified Google Drive folder and returns the file ID.
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    csv_content = data.get('csv_content')
    file_name = data.get('file_name')

    if not csv_content or not file_name:
        return jsonify({'error': 'Missing csv_content or file_name'}), 400

    try:
        # Create the Drive API service.
        drive_service = get_drive_service()

        # Define metadata including the destination folder.
        file_metadata = {
            'name': file_name,
            'parents': [DRIVE_FOLDER_ID]
        }

        # Convert the CSV string into a stream of bytes.
        fh = io.BytesIO(csv_content.encode('utf-8'))
        media = MediaIoBaseUpload(fh, mimetype='text/csv')

        # Create the file on Google Drive.
        created_file = drive_service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id'
        ).execute()

        return jsonify({'status': 'success', 'file_id': created_file.get('id')}), 200

    except Exception as e:
        # Log error details as needed.
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Use the PORT environment variable if deployed on a platform like Heroku.
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
