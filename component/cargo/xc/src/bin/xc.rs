use xc::*;
pub fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    app(args, io::stdin(), io::stdout())?;
    Ok(())
}
