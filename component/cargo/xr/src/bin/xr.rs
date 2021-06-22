use xr::*;

pub fn main() {
    pretty_env_logger::init();

    match app() {
        Ok(()) => (),
        Err(e) => {
            xerr::v2::show_trace(e, |a| eprintln!("{}", a));
            std::process::exit(1);
        }
    }
}
