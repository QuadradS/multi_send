use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use ethers::prelude::*;
use ethers::providers::{Provider, Http};
use std::sync::Arc;
use tokio::sync::Mutex;
use serde::{Deserialize, Serialize};
use dotenv::dotenv;
use std::env;
use std::hash::Hash;

abigen!(
    MultiSend,
    r#"[
        event Deposit(address indexed _from, uint _value)
        event Withdraw(address indexed _from, uint _value)
        event Collect(address indexed _from, uint _value)
        event Disperse(address indexed _from, uint _value)

        function withdraw(uint256 amount) public
        function collect(address addr, uint8 percent) public
        function collectMany(address[] memory addresses, uint8 percent) public
        function disperse(address addr, uint8 percent) public
        function disperseAll(address[] memory addresses, uint8 percent) public
        function getBalance(address addr) public view returns (uint256)
    ]"#
);

struct AppState {
    contract: Arc<Mutex<MultiSend<Provider<Http>>>>,
}


#[derive(Serialize, Deserialize)]
struct WithdrawRequest {
    amount: u64,
}

#[derive(Serialize, Deserialize)]
struct CollectRequest {
    addr: String,
    percent: u8,
}

#[derive(Serialize, Deserialize)]
struct DisperseRequest {
    addr: String,
    percent: u8,
}

#[derive(Serialize, Deserialize)]
struct CollectManyRequest {
    addresses: Vec<String>,
    percent: u8,
}

#[derive(Serialize, Deserialize)]
struct DisperseAllRequest {
    addresses: Vec<String>,
    percent: u8,
}

#[post("/withdraw")]
async fn withdraw(
    state: web::Data<AppState>,
    req: web::Json<WithdrawRequest>,
) -> impl Responder {
    let contract = state.contract.clone();
    let amount = req.amount;

    let result = match contract.lock().await.withdraw(amount.into()).send().await {
        Ok(tx) => HttpResponse::Ok().json(format!("Transaction hash: {:?}", tx.tx_hash())),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    };

    result
}

#[post("/collect")]
async fn collect(
    state: web::Data<AppState>,
    req: web::Json<CollectRequest>,
) -> impl Responder {
    let contract = state.contract.clone();
    let addr = req.addr.parse::<Address>().expect("Invalid address");
    let percent = req.percent;

    let result = match  contract.lock().await.collect(addr, percent).send().await {
        Ok(tx) => HttpResponse::Ok().json(format!("Transaction hash: {:?}", tx.tx_hash())),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    };

    result
}

#[post("/disperse")]
async fn disperse(
    state: web::Data<AppState>,
    req: web::Json<DisperseRequest>,
) -> impl Responder {
    let contract = state.contract.clone();
    let addr = req.addr.parse::<Address>().expect("Invalid address");
    let percent = req.percent;

    let result = match contract.lock().await.disperse(addr, percent).send().await {
        Ok(tx) => HttpResponse::Ok().json(format!("Transaction hash: {:?}", tx.tx_hash())),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    };

    result
}

#[post("/collect_many")]
async fn collect_many(
    state: web::Data<AppState>,
    req: web::Json<CollectManyRequest>,
) -> impl Responder {
    let contract = state.contract.clone();
    let addresses: Vec<Address> = req.addresses.iter().map(|s| s.parse().unwrap()).collect();
    let percent = req.percent;


    let result = match contract.lock().await.collect_many(addresses, percent).send().await {
        Ok(tx) => HttpResponse::Ok().json(format!("Transaction hash: {:?}", tx.tx_hash())),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    };

    result
}

#[post("/disperse_all")]
async fn disperse_all(
    state: web::Data<AppState>,
    req: web::Json<DisperseAllRequest>,
) -> impl Responder {
    let contract = state.contract.clone();
    let addresses: Vec<Address> = req.addresses.iter().map(|s| s.parse().unwrap()).collect();
    let percent = req.percent;

    let result = match contract.lock().await.disperse_all(addresses, percent).send().await {
        Ok(tx) => HttpResponse::Ok().json(format!("Transaction hash: {:?}", tx.tx_hash())),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    };

    result
}

#[get("/balance/{addr}")]
async fn get_balance(
    state: web::Data<AppState>,
    addr: web::Path<String>,
) -> impl Responder {
    let contract = state.contract.clone();
    let addr = addr.into_inner().parse::<Address>().expect("Invalid address");

    let balance = contract.lock().await.get_balance(addr).call().await;

    match balance {
        Ok(balance) => HttpResponse::Ok().json(balance),
        Err(e) => HttpResponse::InternalServerError().body(format!("Error: {:?}", e)),
    }
}



#[tokio::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();

    let provider_url = env::var("PROVIDER_URL").expect("PROVIDER_URL must be set");
    let provider = Provider::<Http>::try_from(provider_url).expect("Failed to connect to provider");
    let provider = Arc::new(provider);

    let contract_address: Address = env::var("CONTRACT_ADDRESS")
        .expect("CONTRACT_ADDRESS must be set")
        .parse()
        .expect("Invalid contract address");

    let contract = MultiSend::new(contract_address, provider.clone());

    let app_state = web::Data::new(AppState {
        contract: Arc::new(Mutex::new(contract)),
    });

    HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            .service(withdraw)
            .service(collect)
            .service(disperse)
            .service(collect_many)
            .service(disperse_all)
            .service(get_balance)
    })
        .bind(("127.0.0.1", 8081))?
        .run()
        .await
}
