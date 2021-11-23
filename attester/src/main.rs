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
use sev::certs::Chain;
use sev::launch::{Measurement, Policy, PolicyFlags, Start};
use sev::session::{Initialized, Session};
use sev::{Build, Version};
use std::collections::HashMap;
use std::convert::TryFrom;
use std::fs::{self, File, OpenOptions};
use std::io::ErrorKind;
use std::io::{self, Read, Write};
use std::iter::FromIterator;
use std::sync::Mutex;
use std::{fmt, thread};
use uuid::Uuid;
mod vmsa;
use rocket::config;
use vmsa::{VMSA_AP, VMSA_BP};

lazy_static! {
    static ref IMAGES: Mutex<HashMap<String, Image>> = Mutex::new(HashMap::new());
    static ref SESSIONS: Mutex<HashMap<String, SessionData>> = Mutex::new(HashMap::new());
    static ref CONFIG: Mutex<Config> = Mutex::new(Config::default());
    static ref MEASURMENTS: Mutex<LibraryMeasurments> = Mutex::new(LibraryMeasurments::default());
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Image {
    sha: String,
    name: String,
    kernel_cmd_line: String,
}

impl Image {
    pub fn get_kernel_cmdline(&self) -> &str {
        &self.kernel_cmd_line
    }
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

#[post(
    "/register-libkrunfw_measurment",
    format = "json",
    data = "<measurments>"
)]
fn register_libkrunfw_measurment(measurments: Json<LibraryMeasurments>) -> JsonValue {
    json!({
        "status": "error",
        "reason": "not implemented yet"
    })
}

#[post("/register-image", format = "json", data = "<image>")]
fn register_image(file: State<String>, image: Json<Image>) -> JsonValue {
    // TODO check arguments validity
    // - if sha is valid
    // - if the kernel cmdline is valid
    println!("Recieved image {}", &image.0);
    let image_key = image.name.clone() + "@" + &image.sha;
    let mut hashmap = IMAGES.lock().unwrap();
    if hashmap.contains_key(&image_key) {
        json!({
            "status": "error",
            "reason": "ID exists."
        })
    } else {
        hashmap.insert(image_key, image.0);
        println!("IMAGES {:?}", hashmap);
        drop(hashmap);
        write_images_to_file(file.inner()).unwrap();
        json!({ "status": "ok" })
    }
}

#[derive(Default)]
struct Config {
    /// Whether guests be requested to use SEV-ES or plain SEV.
    sev_es: bool,
    /// The expected number of CPUs for the Guest.
    num_cpus: u8,
}

#[derive(Serialize, Deserialize)]
struct SessionRequest {
    build: Build,
    chain: Chain,
    image: String,
}

#[derive(Serialize, Deserialize)]
struct SessionResponse {
    id: String,
    start: Start,
}

struct SessionData {
    build: Build,
    session: Session<Initialized>,
    image: String,
}

#[post("/session", format = "json", data = "<session_req>")]
fn session(session_req: Json<SessionRequest>) -> JsonValue {
    let chain: Chain = serde_json::from_str(&json!(session_req.chain).to_string()).unwrap();

    let sev_es = CONFIG.lock().unwrap().sev_es;

    let policy = if sev_es {
        Policy {
            flags: PolicyFlags::NO_DEBUG
                | PolicyFlags::NO_KEY_SHARING
                | PolicyFlags::NO_SEND
                | PolicyFlags::DOMAIN
                | PolicyFlags::ENCRYPTED_STATE
                | PolicyFlags::SEV,
            minfw: Version::default(),
        }
    } else {
        Policy::default()
    };

    let session = Session::try_from(policy).unwrap();
    let start = session.start(chain).unwrap();

    let uuid = Uuid::new_v4().to_simple();

    println!("/session: new request with id={}", uuid);

    SESSIONS.lock().unwrap().insert(
        uuid.to_string(),
        SessionData {
            build: session_req.build,
            session,
            image: session_req.image.clone(),
        },
    );

    json!(SessionResponse {
        id: uuid.to_string(),
        start,
    })
}

#[derive(Default, Serialize, Deserialize)]
struct LibraryMeasurments {
    qboot_data: Vec<u8>,
    kernel_data: Vec<u8>,
    initrd_data: Vec<u8>,
}

#[derive(Serialize, Deserialize)]
struct AttestationRequest {
//    session_id: String,
    measurment: Measurement,
//    image: String,
}

#[post("/attestation/<id>", format = "json", data = "<measurment>")]
fn attestation(id: String, measurment: Json<Measurement,>) -> JsonValue {
    let m = measurment.0;
    print!("attestation with id={}", &id);
    if let Some(session_data) = SESSIONS.lock().unwrap().remove(&id) {
        let measurments = MEASURMENTS.lock().unwrap();
        let mut session = session_data.session.measure().unwrap();
        session
            .update_data(measurments.qboot_data.as_slice())
            .unwrap();
        session
            .update_data(measurments.kernel_data.as_slice())
            .unwrap();
        session
            .update_data(measurments.initrd_data.as_slice())
            .unwrap();

        let (sev_es, num_cpus) = {
            let config = CONFIG.lock().unwrap();
            (config.sev_es, config.num_cpus)
        };

        if sev_es {
            session.update_data(&VMSA_BP).unwrap();

            for _ in 1..num_cpus {
                session.update_data(&VMSA_AP).unwrap();
            }
        }

        match session.verify(session_data.build, m) {
            Err(_) => {
                println!("Verification failed for id={}", &id);
                json!({ "status": "error",
                        "reason": "no session found",
                })
            }
            Ok(session) => {
                println!(
                    "/attestation: verification succeeded for id={}",
                    &id
                );
                if let Some(image) = IMAGES.lock().unwrap().get(&session_data.image) {
                    let cmdline: Vec<u8> = image.get_kernel_cmdline().as_bytes().to_vec();
                    let padding = vec![0; 512 - cmdline.len()];
                    let data = [cmdline, padding].concat();
                    let secret = session
                        .secret(sev::launch::HeaderFlags::default(), &data)
                        .unwrap();
                    json!(secret)
                } else {
                    json!({ "status": "error",
                            "reason": format!("no image {} found", &session_data.image),
                    })
                }
            }
        }
    } else {
        json!({ "status": "error",
                "reason": "no session found",
        })
    }
}

fn load_libkrunfw_measurments(dir: &str) {
    let mut m = MEASURMENTS.lock().unwrap();
    File::open(dir.to_owned() + "/qboot_data")
        .unwrap()
        .read_to_end(&mut m.qboot_data)
        .unwrap();
    File::open(dir.to_owned() + "/kernel_data")
        .unwrap()
        .read_to_end(&mut m.kernel_data)
        .unwrap();
    File::open(dir.to_owned() + "/initrd_data")
        .unwrap()
        .read_to_end(&mut m.initrd_data)
        .unwrap();
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
        .arg(
            Arg::with_name("directory")
                .short("d")
                .long("directory")
                .help("Directory where to locate the library measurments")
                .required(true)
                .takes_value(true),
        )
        .get_matches();
    let repo = matches
        .value_of("image-repository")
        .unwrap_or("/var/run/registered-images.json")
        .to_string();
    let dir = matches.value_of("directory").unwrap().to_string();
    load_image_repository_from_file(&repo).unwrap();
    load_libkrunfw_measurments(&dir);
    let config_confidential = config::Config::build(config::Environment::Production)
        .port(8080)
        .finalize()
        .unwrap();
    let config_attestation = config::Config::build(config::Environment::Production)
        .port(8081)
        .finalize()
        .unwrap();

    thread::spawn(move || {
        rocket::custom(config_confidential)
            .manage(repo)
            .mount(
                "/confidential",
                routes![register_image, register_libkrunfw_measurment],
            )
            .launch();
    });
    rocket::custom(config_attestation)
        .mount("/untrusted", routes![attestation, session])
        .launch();
}
