use std::path::PathBuf;
use std::time::Duration;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub redis_url: String,
    pub jwt_secret: String,
    pub jwt_access_expires_in: Duration,
    pub jwt_refresh_expires_in: Duration,
    pub server_host: String,
    pub server_port: u16,
    pub environment: Environment,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Environment {
    Dev,
    Staging,
    Prod,
}

impl std::fmt::Display for Environment {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Environment::Dev => write!(f, "dev"),
            Environment::Staging => write!(f, "staging"),
            Environment::Prod => write!(f, "prod"),
        }
    }
}

impl Config {
    pub fn from_env() -> Self {
        load_dotenv_files();

        let database_url = env_var("DATABASE_URL");
        let redis_url = env_var_or("REDIS_URL", "redis://127.0.0.1:6379");
        let jwt_secret = env_var("JWT_SECRET");
        let jwt_access_expires_in =
            parse_duration(&env_var_or("JWT_ACCESS_EXPIRES_IN", "15m"));
        let jwt_refresh_expires_in =
            parse_duration(&env_var_or("JWT_REFRESH_EXPIRES_IN", "7d"));
        let server_host = env_var_or("SERVER_HOST", "0.0.0.0");
        let server_port = env_var_or("SERVER_PORT", "8080")
            .parse::<u16>()
            .expect("SERVER_PORT must be a valid u16");
        let environment = match env_var_or("APP_ENV", "dev").as_str() {
            "staging" => Environment::Staging,
            "prod" | "production" => Environment::Prod,
            _ => Environment::Dev,
        };

        let config = Config {
            database_url,
            redis_url,
            jwt_secret,
            jwt_access_expires_in,
            jwt_refresh_expires_in,
            server_host,
            server_port,
            environment,
        };

        config.validate();
        config
    }

    fn validate(&self) {
        assert!(
            !self.jwt_secret.is_empty(),
            "JWT_SECRET must not be empty"
        );
        assert!(
            self.jwt_secret.len() >= 32,
            "JWT_SECRET must be at least 32 characters for security"
        );
        assert!(
            !self.database_url.is_empty(),
            "DATABASE_URL must not be empty"
        );
    }
}

fn env_var(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!("Environment variable {} must be set", key))
}

fn env_var_or(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_string())
}

fn parse_duration(s: &str) -> Duration {
    let s = s.trim();
    if s.is_empty() {
        panic!("Duration string must not be empty");
    }

    let (num_str, unit) = s.split_at(s.len() - 1);
    let value: u64 = num_str
        .parse()
        .unwrap_or_else(|_| panic!("Invalid duration number: {}", num_str));

    match unit {
        "s" => Duration::from_secs(value),
        "m" => Duration::from_secs(value * 60),
        "h" => Duration::from_secs(value * 3600),
        "d" => Duration::from_secs(value * 86400),
        _ => panic!(
            "Invalid duration unit '{}'. Use s(seconds), m(minutes), h(hours), d(days)",
            unit
        ),
    }
}


fn load_dotenv_files() {
    // Resolve the backend module directory at compile time.
    // This ensures .env files are ALWAYS loaded from the backend/ folder,
    // regardless of the process's current working directory.
    let module_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));

    // Determine the app mode from process env (before loading any .env files)
    let mode = std::env::var("APP_ENV")
        .unwrap_or_else(|_| "development".to_string());

    // Load in highest-to-lowest priority order.
    // dotenvy::from_path() does NOT override already-set vars,
    // so the first file to set a var "wins".
    let files = vec![
        format!(".env.{}.local", mode),    // Highest priority
        format!(".env.{}", mode),           // Mode-specific
        ".env.local".to_string(),           // Local overrides
        ".env".to_string(),                 // Base defaults (lowest)
    ];

    for file in &files {
        let path = module_dir.join(file);
        match dotenvy::from_path(&path) {
            Ok(_) => tracing::info!("Loaded env file: {}", path.display()),
            Err(_) => tracing::debug!("Env file not found (skipped): {}", path.display()),
        }
    }

    tracing::info!("Environment mode: {} (module dir: {})", mode, module_dir.display());
}
