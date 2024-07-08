use std::io::{self, Write};
use std::process::exit;

fn process_line(line: &str) {
    let full_cmd = match u32::from_str_radix(line, 16) {
        Ok(c) => c,
        Err(_) => {
            println!("{line}");
            io::stdout().flush().unwrap();
            return;
        }
    };
    let addr_bits = full_cmd >> 7 & 0x1F;
    let cmd_bits = full_cmd >> 4 & 7;
    let data_bits = full_cmd & 0xF;

    print!("{addr_bits:#X}: ");

    match cmd_bits {
        0b000 => println!("NOP"),
        0b001 => println!("~{data_bits}"),
        0b010 => {
            if data_bits & 0b1000 != 0 {
                println!("ROL")
            } else if data_bits & 1 != 0 {
                println!("SHL w/1")
            } else {
                println!("SHL w/0")
            }
        },
        0b011 => {
            if data_bits & 0b1000 != 0 {
                println!("ROR")
            } else if data_bits & 1 != 0 {
                println!("SHR w/1")
            } else {
                println!("SHR w/0")
            }
        },
        0b100 => println!("OFF {data_bits}"),
        0b101 => println!("ON {data_bits}"),
        0b110 => println!("ALL OFF"),
        0b111 => println!("ALL ON"),
        _ => panic!("Impossible value")
    }
    io::stdout().flush().unwrap();
}

fn main() {
    loop {
        let mut line = String::new();
        match io::stdin().read_line(&mut line) {
            Ok(0) => break,
            Ok(_) => process_line(line.trim_end()),
            Err(error) => {
                println!("Error {error}");
                exit(1);
            }
        }
    }
}
