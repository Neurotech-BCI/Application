use actix_web::{post, web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use google_drive3::{DriveHub, api::File};
use yup_oauth2::{ServiceAccountAuthenticator, read_service_account_key};
use hyper::Client;
use hyper_rustls::HttpsConnector;
use std::io::Cursor;
use mime::Mime;

const SERVICE_ACCOUNT_FILE: &str = "./credential.json";
const DRIVE_FOLDER_ID: &str = "19KE2jfHlKZyJSdk4WVf3-k9aOEMXUC6-";

#[derive(Deserialize)]
struct CSVRequest {
    csv_content: String,
    file_name: String,
}

#[derive(Serialize)]
struct UploadSuccess {
    status: String,
    file_id: String,
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

#[post("/upload_csv")]
async fn upload_csv(payload: web::Json<CSVRequest>) -> impl Responder {
    let csv_content = &payload.csv_content;
    let file_name = &payload.file_name;

    // Build an HTTPS connector using hyper-rustls 0.22.1.
    let https_connector = HttpsConnector::with_native_roots();
    let client = Client::builder().build::<_, hyper::Body>(https_connector);

    // Load the service account key.
    let service_account_key = match read_service_account_key(SERVICE_ACCOUNT_FILE).await {
        Ok(key) => key,
        Err(e) => {
            return HttpResponse::InternalServerError().json(ErrorResponse {
                error: format!("Failed to load service account key: {}", e),
            });
        }
    };

    // Create the authenticator.
    let auth = match ServiceAccountAuthenticator::builder(service_account_key)
        .build()
        .await
    {
        Ok(authenticator) => authenticator,
        Err(e) => {
            return HttpResponse::InternalServerError().json(ErrorResponse {
                error: format!("Failed to create authenticator: {}", e),
            });
        }
    };

    // Initialize the Google Drive hub.
    let hub = DriveHub::new(client, auth);

    // Prepare file metadata.
    let mut file_metadata = File::default();
    file_metadata.name = Some(file_name.clone());
    file_metadata.parents = Some(vec![DRIVE_FOLDER_ID.to_string()]);

    // Create a stream from the CSV content.
    let cursor = Cursor::new(csv_content.clone().into_bytes());
    // Parse the MIME type using mime crate version 0.2.6.
    let mime_type: Mime = "text/csv".parse().unwrap();

    // Upload the file to Google Drive.
    let upload_result = hub.files().create(file_metadata)
        .upload(cursor, mime_type)
        .await;

    match upload_result {
        Ok((_, uploaded_file)) => {
            if let Some(file_id) = uploaded_file.id {
                HttpResponse::Ok().json(UploadSuccess {
                    status: "success".to_string(),
                    file_id,
                })
            } else {
                HttpResponse::InternalServerError().json(ErrorResponse {
                    error: "File uploaded but no file ID was returned.".to_string(),
                })
            }
        },
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse {
            error: format!("Failed to upload file: {}", e),
        }),
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Use the PORT environment variable if available; default to 5000.
    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "5000".to_string())
        .parse()
        .unwrap_or(5000);

    println!("Starting server on 0.0.0.0:{}", port);
    
    HttpServer::new(|| {
        App::new().service(upload_csv)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
