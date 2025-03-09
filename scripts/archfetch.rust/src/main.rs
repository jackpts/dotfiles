use std::process::Command;
use regex::Regex;
use term_size::dimensions;

const SCALE_PERCENT: f32 = 0.3;
const LOGO_PATH: &str = "~/dotfiles/.config/fastfetch/she-logo.jpg";

fn main() {
    if !std::path::Path::new("/etc/arch-release").exists() {
        eprintln!("\x1b[31mError: This script works only on Arch Linux\x1b[0m");
        return;
    }

    let (term_width, _) = dimensions().unwrap_or((80, 24));
    let image_width = (term_width as f32 * SCALE_PERCENT) as usize;

    let image = match generate_image() {
        Ok(img) => img,
        Err(_) => {
            eprintln!("\x1b[31mError: Failed to generate image (chafa installed?)\x1b[0m");
            return;
        }
    };

    let text = generate_system_info();

    let empty_line = String::new();
    for (i, img_line) in image.iter().enumerate() {
        let text_line = text.get(i).unwrap_or(&empty_line);
        let clean_line = strip_ansi(img_line);
        let padding = image_width.saturating_sub(clean_line.chars().count());
        
        println!("{}\x1b[0m{: <width$}  {}", 
                 img_line,
                 "",
                 text_line,
                 width = padding);
    }
}

fn generate_image() -> Result<Vec<String>, std::io::Error> {
    let output = Command::new("chafa")
        .arg("--scale=0.3")
        .arg("--symbols=solid+all")
        .arg("--colors=256")
        .arg("--fill=block")
        .arg("--align=left")
        // .arg(format!("--width={}", width))
        .arg(LOGO_PATH)
        .output()?;
    
    Ok(String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.to_string())
        .collect())
}

fn generate_system_info() -> Vec<String> {
    let mut info = Vec::new();
    let green = "\x1b[32m";
    let nc = "\x1b[0m";

    // OS
    if let Ok(os_release) = std::fs::read_to_string("/etc/os-release") {
        let re = Regex::new(r"(?m)^(NAME|VERSION_ID)=(.*)").unwrap();
        let mut name = String::new();
        let mut version = String::new();
        
        for cap in re.captures_iter(&os_release) {
            match cap.get(1).map(|m| m.as_str()) {
                Some("NAME") => {
                    if let Some(value) = cap.get(2) {
                        name = value.as_str().trim_matches('"').to_string();
                    }
                },
                Some("VERSION_ID") => {
                    if let Some(value) = cap.get(2) {
                        version = value.as_str().trim_matches('"').to_string();
                    }
                },
                _ => {}
            }
        }
        
        info.push(format!("{green}OS:{nc} {name} {version}"));
    }

    // Добавьте остальные системные параметры аналогично...

    info
}

fn strip_ansi(text: &str) -> String {
    let re = Regex::new(r"\x1b\[[0-9;]*[mGKH]").unwrap();
    re.replace_all(text, "").to_string()
}
