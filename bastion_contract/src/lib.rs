//! Bastion Dark Pool - Simplified for MVP
#![no_std]
#![no_main]

extern crate alloc;

use alloc::{string::String, vec::Vec};
use casper_contract::contract_api::{runtime, storage};
use casper_contract::unwrap_or_revert::UnwrapOrRevert;
use casper_types::{
    CLType, CLTyped, CLValue, EntityEntryPoint as EntryPoint, 
    EntryPointAccess, EntryPointPayment, EntryPointType, EntryPoints,
    Key, Parameter, URef, U256,
    ApiError,
};

// Dictionaries
const DICT_BALANCES: &str = "balances";
const DICT_NULLIFIERS: &str = "nullifiers";
const KEY_TOTAL_ORDERS: &str = "total_orders";

// Error codes  
const ERROR_NULLIFIER_USED: u16 = 2;

fn get_dict(name: &str) -> URef {
    runtime::get_key(name)
        .unwrap_or_revert()
        .into_uref()
        .unwrap_or_revert()
}

fn bytes_to_hex(bytes: &[u8]) -> String {
    use alloc::format;
    let mut s = String::new();
    for byte in bytes {
        s.push_str(&format!("{:02x}", byte));
    }
    s
}

// ============================================================================
// Initialization
// ============================================================================

#[no_mangle]
pub extern "C" fn init() {
    storage::new_dictionary(DICT_BALANCES).unwrap_or_revert();
    storage::new_dictionary(DICT_NULLIFIERS).unwrap_or_revert();
    runtime::put_key(KEY_TOTAL_ORDERS, storage::new_uref(0u64).into());
}

// ============================================================================
// Deposits
// ============================================================================

#[no_mangle]
pub extern "C" fn deposit_cspr() {
    let amount: U256 = runtime::get_named_arg("amount");
    let caller = runtime::get_caller();
    let caller_str = alloc::format!("{:?}", caller);
    
    let dict = get_dict(DICT_BALANCES);
    let current: U256 = storage::dictionary_get(dict, &caller_str)
        .unwrap_or_revert()
        .unwrap_or(U256::zero());
    
    storage::dictionary_put(dict, &caller_str, current + amount);
}

// ============================================================================
// Order Submission
// ============================================================================

#[no_mangle]
pub extern "C" fn submit_order() {
    let is_cspr: bool = runtime::get_named_arg("is_cspr");
    let amount: U256 = runtime::get_named_arg("amount");
    let commitment: Vec<u8> = runtime::get_named_arg("commitment");
    let proof: Vec<u8> = runtime::get_named_arg("proof");
    
    // Convert commitment to hex string for dictionary key
    let commitment_key = bytes_to_hex(&commitment);
    
    // Check nullifier not used
    let nullifier_dict = get_dict(DICT_NULLIFIERS);
    let used: bool = storage::dictionary_get(nullifier_dict, &commitment_key)
        .unwrap_or_revert()
        .unwrap_or(false);
    if used {
        runtime::revert(ApiError::User(ERROR_NULLIFIER_USED));
    }
    
    // Mark nullifier as used
    storage::dictionary_put(nullifier_dict, &commitment_key, true);
    
    // Update total orders
    let total_uref = runtime::get_key(KEY_TOTAL_ORDERS)
        .unwrap_or_revert()
        .into_uref()
        .unwrap_or_revert();
    let total: u64 = storage::read(total_uref).unwrap_or_revert().unwrap_or(0);
    storage::write(total_uref, total + 1);
}

// ============================================================================
// View Functions
// ============================================================================

#[no_mangle]
pub extern "C" fn get_balance() {
    let address: Key = runtime::get_named_arg("address");
    let address_str = alloc::format!("{:?}", address);
    
    let dict = get_dict(DICT_BALANCES);
    let balance: U256 = storage::dictionary_get(dict, &address_str)
        .unwrap_or_revert()
        .unwrap_or(U256::zero());
    
    runtime::ret(CLValue::from_t(balance).unwrap_or_revert());
}

#[no_mangle]
pub extern "C" fn get_total_orders() {
    let total_uref = runtime::get_key(KEY_TOTAL_ORDERS)
        .unwrap_or_revert()
        .into_uref()
        .unwrap_or_revert();
    let total: u64 = storage::read(total_uref).unwrap_or_revert().unwrap_or(0);
    
    runtime::ret(CLValue::from_t(total).unwrap_or_revert());
}

// ============================================================================
// Contract Installation
// ============================================================================

#[no_mangle]
pub extern "C" fn call() {
    let mut entry_points = EntryPoints::new();
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("init"),
        alloc::vec![],
        CLType::Unit,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("deposit_cspr"),
        alloc::vec![Parameter::new("amount", U256::cl_type())],
        CLType::Unit,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("submit_order"),
        alloc::vec![
            Parameter::new("is_cspr", CLType::Bool),
            Parameter::new("amount", U256::cl_type()),
            Parameter::new("commitment", CLType::List(alloc::boxed::Box::new(CLType::U8))),
            Parameter::new("proof", CLType::List(alloc::boxed::Box::new(CLType::U8))),
        ],
        CLType::Unit,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("get_balance"),
        alloc::vec![Parameter::new("address", Key::cl_type())],
        U256::cl_type(),
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));
    
    entry_points.add_entry_point(EntryPoint::new(
        String::from("get_total_orders"),
        alloc::vec![],
        CLType::U64,
        EntryPointAccess::Public,
        EntryPointType::Called,
        EntryPointPayment::Caller,
    ));

    let (contract_hash, _) = storage::new_contract(entry_points, None, None, None, None);
    runtime::put_key("bastion_dark_pool", contract_hash.into());
}
