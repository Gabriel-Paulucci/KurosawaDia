use isahc::{HttpClient, http::StatusCode};
use serde_json::to_string;
use serenity::framework::standard::CommandResult;

use crate::config::get_violet_token;

use super::data_error::VioletError;

const BASE_URL: &str = "https://violet.zuraaa.com/api/apps/1/events";

pub struct VioletCLient {
    client: HttpClient
}

impl VioletCLient {
    pub fn default() -> Self {
        let client = HttpClient::builder()
            .default_header("Authorization", get_violet_token())
            .default_header("Content-Type", "application/json")
            .build()
            .expect("Falha ao criar o client da violet");

        Self {
            client
        }
    }

    pub async fn send_error(&self, error: VioletError) -> CommandResult {
        let body = to_string(&error)?;

        let result = self.client.post_async(BASE_URL, body).await?;

        if result.status() != StatusCode::CREATED {
            println!("{}", result.status())
        }

        Ok(())
    }
}