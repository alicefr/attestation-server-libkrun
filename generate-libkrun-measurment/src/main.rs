#[macro_use]
extern crate serde_derive;

use clap::{App, Arg};
use libc::{c_char, size_t};
use std::fs::{self, File};
use std::io::Write;
#[link(name = "krunfw")]

extern "C" {
    fn krunfw_get_qboot(size: *mut size_t) -> *mut c_char;
    fn krunfw_get_initrd(size: *mut size_t) -> *mut c_char;
    fn krunfw_get_kernel(load_addr: *mut u64, size: *mut size_t) -> *mut c_char;
}

fn write_libkrunfw_measurment(dir: &str) {
    let mut kernel_guest_addr: u64 = 0;
    let mut kernel_size: usize = 0;
    let kernel_host_addr = unsafe {
        krunfw_get_kernel(
            &mut kernel_guest_addr as *mut u64,
            &mut kernel_size as *mut usize,
        )
    };

    let mut qboot_size: usize = 0;
    let qboot_host_addr = unsafe { krunfw_get_qboot(&mut qboot_size as *mut usize) };

    let mut initrd_size: usize = 0;
    let initrd_host_addr = unsafe { krunfw_get_initrd(&mut initrd_size as *mut usize) };

    let qboot_data =
        unsafe { std::slice::from_raw_parts(qboot_host_addr as *const u8, qboot_size) };
    let kernel_data =
        unsafe { std::slice::from_raw_parts(kernel_host_addr as *const u8, kernel_size) };
    let initrd_data =
        unsafe { std::slice::from_raw_parts(initrd_host_addr as *const u8, initrd_size) };
    File::create(dir.to_owned() + "/qboot_data")
        .unwrap()
        .write_all(&qboot_data)
        .unwrap();
    File::create(dir.to_owned() + "/kernel_data")
        .unwrap()
        .write_all(&kernel_data)
        .unwrap();
    File::create(dir.to_owned() + "/initrd_data")
        .unwrap()
        .write_all(&initrd_data)
        .unwrap();
}

fn main() {
    let matches = App::new("generate-libkrunfw-measurment")
        .arg(
            Arg::with_name("directory")
                .short("d")
                .long("directory")
                .help("Directory where to store the generated ")
                .takes_value(true),
        )
        .get_matches();
    let directory = matches.value_of("directory").unwrap_or("").to_string();
    fs::create_dir_all(&directory).unwrap();
    write_libkrunfw_measurment(&directory);
}
