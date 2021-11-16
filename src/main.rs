#![feature(proc_macro_hygiene, decl_macro)]
#![feature(fs_read_write)]

#[macro_use]
extern crate rocket;
#[macro_use]
extern crate rocket_contrib;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate lazy_static;
extern crate clap;

use clap::{App, Arg};
use rocket::State;
use rocket_contrib::json::{Json, JsonValue};
use std::collections::HashMap;
use std::fmt;
use std::fs::{self, File, OpenOptions};
use std::io::ErrorKind;
use std::io::{self, Write};
use std::iter::FromIterator;
use std::sync::Mutex;

lazy_static! {
    static ref IMAGES: Mutex<HashMap<String, Image>> = Mutex::new(HashMap::new());
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Image {
    sha: String,
    name: String,
    kernel_cmd_line: String,
}

impl fmt::Display for Image {
    fn fmt(&self, fmt: &mut std::fmt::Formatter) -> std::result::Result<(), std::fmt::Error> {
        write!(
            fmt,
            "name {}, sha {}, kernel cmd line  {}",
            self.name, self.sha, self.kernel_cmd_line
        )
    }
}

fn write_images_to_file(file: &str) -> Result<(), io::Error> {
    let mut hashmap = IMAGES.lock().unwrap();
    println!("Write images {:?} on the file {}", hashmap, file);
    let vec = Vec::from_iter(hashmap.values());
    let image_json = serde_json::to_string(&vec).unwrap();
    // TODO avoid race condition when the program crash and we haven't written entirly the file
    let mut buffer = File::create(file)?;
    buffer.write(image_json.as_bytes())?;
    Ok(())
}

#[post("/register-image", format = "json", data = "<image>")]
fn register_image(file: State<String>, image: Json<Image>) -> JsonValue {
    // TODO check arguments validity
    // - if sha is valid
    // - if the kernel cmdline is valid
    println!("Recieved image {}", &image.0);
    let mut hashmap = IMAGES.lock().unwrap();
    if hashmap.contains_key(&image.sha) {
        json!({
            "status": "error",
            "reason": "ID exists."
        })
    } else {
        hashmap.insert(image.sha.clone(), image.0);
        println!("IMAGES {:?}", hashmap);
        drop(hashmap);
        println!("Inserted image");
        write_images_to_file(file.inner()).unwrap();
        json!({ "status": "ok" })
    }
}

fn load_image_repository_from_file(file: &str) -> Result<(), io::Error> {
    let f = File::open(file).map_err(|error| {
        if error.kind() == ErrorKind::NotFound {
            File::create(file).unwrap_or_else(|error| {
                panic!("Problem creating the file: {:?}", error);
            });
        } else {
            panic!("Problem opening the file: {:?}", error);
        }
    });
    let data = fs::read_to_string(file)?;
    if data == "" {
        return Ok(());
    }
    println!("data {}", data);
    let images: Vec<Image> = serde_json::from_str(&data).expect("Faild in converting data");
    let mut hashmap = IMAGES.lock().unwrap();
    for i in images.into_iter() {
        if !hashmap.contains_key(&i.sha) {
            hashmap.insert(i.sha.clone(), i);
        }
    }
    println!("IMAGES {:?}", hashmap);
    Ok(())
}

fn main() {
    let matches = App::new("attestation-server")
        .arg(
            Arg::with_name("image-repository")
                .short("i")
                .long("image-repository")
                .help("Store registered image")
                .takes_value(true),
        )
        .get_matches();
    let repo = matches
        .value_of("image-repository")
        .unwrap_or("/var/run/registered-images.json")
        .to_string();
    println!("Value for config: {}", repo);
    load_image_repository_from_file(&repo).unwrap();
    rocket::ignite()
        .manage(repo)
        .mount("/confidential", routes![register_image])
        .launch();
}
