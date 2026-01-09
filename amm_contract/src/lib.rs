#![no_std]
#![no_main]

extern crate alloc;

use alloc::{string::String, vec};
use casper_contract::contract_api::{runtime, storage};
use casper_contract::unwrap_or_revert::UnwrapOrRevert;
use casper_types::{
    CLType, CLTyped, CLValue, EntityEntryPoint as EntryPoint, 
    EntryPointAccess, EntryPointPayment, EntryPointType, EntryPoints,
    Key, Parameter, RuntimeArgs, URef, U256, runtime_args,
    contracts::ContractHash,
};

const TOKEN_A: &str = "token_a";
const TOKEN_B: &str = "token_b";
const RESERVE_A: &str = "reserve_a";
const RESERVE_B: &str = "reserve_b";

fn get_uref(name: &str) -> URef {
    runtime::get_key(name)
        .unwrap_or_revert()
        .into_uref()
        .unwrap_or_revert()
}

#[no_mangle]
pub extern "C" fn init() {
    let token_a: ContractHash = runtime::get_named_arg("token_a");
    let token_b: ContractHash = runtime::get_named_arg("token_b");
    
    runtime::put_key(TOKEN_A, storage::new_uref(token_a).into());
    runtime::put_key(TOKEN_B, storage::new_uref(token_b).into());
    runtime::put_key(RESERVE_A, storage::new_uref(U256::zero()).into());
    runtime::put_key(RESERVE_B, storage::new_uref(U256::zero()).into());
}

#[no_mangle]
pub extern "C" fn add_liquidity() {
    let amount_a: U256 = runtime::get_named_arg("amount_a");
    let amount_b: U256 = runtime::get_named_arg("amount_b");
    
    let token_a_uref = get_uref(TOKEN_A);
    let token_b_uref = get_uref(TOKEN_B);
    let token_a: ContractHash = storage::read(token_a_uref).unwrap_or_revert().unwrap_or_revert();
    let token_b: ContractHash = storage::read(token_b_uref).unwrap_or_revert().unwrap_or_revert();
    
    let caller = runtime::get_caller();
    
    runtime::call_contract::<()>(
        token_a,
        "transfer_from",
        runtime_args! {
            "owner" => Key::from(caller),
            "recipient" => Key::from(runtime::get_caller()),
            "amount" => amount_a,
        },
    );
    
    runtime::call_contract::<()>(
        token_b,
        "transfer_from",
        runtime_args! {
            "owner" => Key::from(caller),
            "recipient" => Key::from(runtime::get_caller()),
            "amount" => amount_b,
        },
    );
    
    let reserve_a_uref = get_uref(RESERVE_A);
    let reserve_b_uref = get_uref(RESERVE_B);
    
    let current_a: U256 = storage::read(reserve_a_uref).unwrap_or_revert().unwrap_or(U256::zero());
    let current_b: U256 = storage::read(reserve_b_uref).unwrap_or_revert().unwrap_or(U256::zero());
    
    storage::write(reserve_a_uref, current_a + amount_a);
    storage::write(reserve_b_uref, current_b + amount_b);
    
    runtime::ret(CLValue::from_t(true).unwrap_or_revert());
}

#[no_mangle]
pub extern "C" fn swap_a_to_b() {
    let amount_in: U256 = runtime::get_named_arg("amount_in");
    let min_out: U256 = runtime::get_named_arg("min_amount_out");
    
    let reserve_a_uref = get_uref(RESERVE_A);
    let reserve_b_uref = get_uref(RESERVE_B);
    
    let reserve_a: U256 = storage::read(reserve_a_uref).unwrap_or_revert().unwrap_or_revert();
    let reserve_b: U256 = storage::read(reserve_b_uref).unwrap_or_revert().unwrap_or_revert();
    
    let amount_in_with_fee = amount_in * U256::from(997);
    let numerator = amount_in_with_fee * reserve_b;
    let denominator = (reserve_a * U256::from(1000)) + amount_in_with_fee;
    let amount_out = numerator / denominator;
    
    if amount_out < min_out {
        runtime::revert(casper_types::ApiError::User(1));
    }
    
    let token_a_uref = get_uref(TOKEN_A);
    let token_b_uref = get_uref(TOKEN_B);
    let token_a: ContractHash = storage::read(token_a_uref).unwrap_or_revert().unwrap_or_revert();
    let token_b: ContractHash = storage::read(token_b_uref).unwrap_or_revert().unwrap_or_revert();
    
    let caller = runtime::get_caller();
    
    runtime::call_contract::<()>(
        token_a,
        "transfer_from",
        runtime_args! {
            "owner" => Key::from(caller),
            "recipient" => Key::from(runtime::get_caller()),
            "amount" => amount_in,
        },
    );
    
    runtime::call_contract::<()>(
        token_b,
        "transfer",
        runtime_args! {
            "recipient" => Key::from(caller),
            "amount" => amount_out,
        },
    );
    
    storage::write(reserve_a_uref, reserve_a + amount_in);
    storage::write(reserve_b_uref, reserve_b - amount_out);
    
    runtime::ret(CLValue::from_t(amount_out).unwrap_or_revert());
}

#[no_mangle]
pub extern "C" fn swap_b_to_a() {
    let amount_in: U256 = runtime::get_named_arg("amount_in");
    let min_out: U256 = runtime::get_named_arg("min_amount_out");
    
    let reserve_a_uref = get_uref(RESERVE_A);
    let reserve_b_uref = get_uref(RESERVE_B);
    
    let reserve_a: U256 = storage::read(reserve_a_uref).unwrap_or_revert().unwrap_or_revert();
    let reserve_b: U256 = storage::read(reserve_b_uref).unwrap_or_revert().unwrap_or_revert();
    
    let amount_in_with_fee = amount_in * U256::from(997);
    let numerator = amount_in_with_fee * reserve_a;
    let denominator = (reserve_b * U256::from(1000)) + amount_in_with_fee;
    let amount_out = numerator / denominator;
    
    if amount_out < min_out {
        runtime::revert(casper_types::ApiError::User(1));
    }
    
    let token_a_uref = get_uref(TOKEN_A);
    let token_b_uref = get_uref(TOKEN_B);
    let token_a: ContractHash = storage::read(token_a_uref).unwrap_or_revert().unwrap_or_revert();
    let token_b: ContractHash = storage::read(token_b_uref).unwrap_or_revert().unwrap_or_revert();
    
    let caller = runtime::get_caller();
    
    runtime::call_contract::<()>(
        token_b,
        "transfer_from",
        runtime_args! {
            "owner" => Key::from(caller),
            "recipient" => Key::from(runtime::get_caller()),
            "amount" => amount_in,
        },
    );
    
    runtime::call_contract::<()>(
        token_a,
        "transfer",
        runtime_args! {
            "recipient" => Key::from(caller),
            "amount" => amount_out,
        },
    );
    
    storage::write(reserve_a_uref, reserve_a - amount_out);
    storage::write(reserve_b_uref, reserve_b + amount_in);
    
    runtime::ret(CLValue::from_t(amount_out).unwrap_or_revert());
}

#[no_mangle]
pub extern "C" fn get_reserves() {
    let reserve_a_uref = get_uref(RESERVE_A);
    let reserve_b_uref = get_uref(RESERVE_B);
    
    let reserve_a: U256 = storage::read(reserve_a_uref).unwrap_or_revert().unwrap_or(U256::zero());
    let reserve_b: U256 = storage::read(reserve_b_uref).unwrap_or_revert().unwrap_or(U256::zero());
    
    runtime::ret(CLValue::from_t((reserve_a, reserve_b)).unwrap_or_revert());
}

#[no_mangle]
pub extern "C" fn call() {
    let mut entry_points = EntryPoints::new();
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("init"),
        vec![
            Parameter::new("token_a", Key::cl_type()),
            Parameter::new("token_b", Key::cl_type()),
        ],
        CLType::Unit,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    entry_points.add_entry_point(EntryPoint::new(
        String::from("add_liquidity"),
        vec![
            Parameter::new("amount_a", U256::cl_type()),
            Parameter::new("amount_b", U256::cl_type()),
        ],
        CLType::Bool,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    entry_points.add_entry_point(EntryPoint::new(
        String::from("swap_a_to_b"),
        vec![
            Parameter::new("amount_in", U256::cl_type()),
            Parameter::new("min_amount_out", U256::cl_type()),
        ],
        U256::cl_type(),
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    entry_points.add_entry_point(EntryPoint::new(
        String::from("swap_b_to_a"),
        vec![
            Parameter::new("amount_in", U256::cl_type()),
            Parameter::new("min_amount_out", U256::cl_type()),
        ],
        U256::cl_type(),
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    entry_points.add_entry_point(EntryPoint::new(
        String::from("get_reserves"),
        vec![],
        CLType::Tuple2([
            alloc::boxed::Box::new(U256::cl_type()),
            alloc::boxed::Box::new(U256::cl_type()),
        ]),
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    let (contract_hash, _) = storage::new_contract(entry_points, None, None, None, None);
    runtime::put_key("simple_amm", contract_hash.into());
}
