use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::response::IntoResponse;
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use std::sync::Arc;
use tokio::sync::broadcast;

use crate::auth::jwt::decode_token;
use crate::config::Config;
use crate::error::ApiError;

#[derive(Debug, Deserialize)]
pub struct WsQuery {
    pub token: String,
}

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    Query(query): Query<WsQuery>,
    State(config): State<Arc<Config>>,
    State(sender): State<broadcast::Sender<String>>,
) -> Result<impl IntoResponse, ApiError> {
    // Authenticate via query parameter token
    let claims = decode_token(&query.token, &config.jwt_secret)
        .map_err(|_| ApiError::Unauthorized)?;

    tracing::info!("WebSocket connection authenticated for user: {}", claims.sub);

    Ok(ws.on_upgrade(move |socket| handle_socket(socket, sender, claims.sub)))
}

async fn handle_socket(socket: WebSocket, sender: broadcast::Sender<String>, user_id: String) {
    let (mut ws_sender, mut ws_receiver) = socket.split();
    let mut rx = sender.subscribe();

    // Spawn task to forward broadcast messages to this WebSocket client
    let uid = user_id.clone();
    let send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            // Parse the message to check if it's targeted at this user or broadcast
            if let Ok(event) = serde_json::from_str::<serde_json::Value>(&msg) {
                let target = event.get("user_id").and_then(|v| v.as_str());
                let is_broadcast = event
                    .get("broadcast")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                if is_broadcast || target == Some(&uid) {
                    if ws_sender.send(Message::Text(msg.into())).await.is_err() {
                        break;
                    }
                }
            }
        }
    });

    // Handle incoming messages from client (ping/pong, etc.)
    let recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = ws_receiver.next().await {
            match msg {
                Message::Text(text) => {
                    tracing::debug!("Received WS message from {}: {}", user_id, text);
                }
                Message::Close(_) => {
                    tracing::info!("WebSocket closed for user: {}", user_id);
                    break;
                }
                _ => {}
            }
        }
    });

    // Wait for either task to complete
    tokio::select! {
        _ = send_task => {},
        _ = recv_task => {},
    }
}

/// Helper to broadcast events via the channel
pub fn broadcast_event(
    sender: &broadcast::Sender<String>,
    event_type: &str,
    user_id: &str,
    payload: serde_json::Value,
    broadcast_to_all: bool,
) {
    let event = serde_json::json!({
        "event_type": event_type,
        "user_id": user_id,
        "broadcast": broadcast_to_all,
        "payload": payload,
        "timestamp": chrono::Utc::now().to_rfc3339(),
    });

    if let Err(e) = sender.send(event.to_string()) {
        tracing::debug!("No WebSocket subscribers to receive event: {:?}", e);
    }
}
