pub fn parse_args<'a, A, S>(args: &'a A) -> Result<Options<'a>>
where
    &'a A: IntoIterator<Item = &'a S>,
    S: AsRef<str> + 'a,
{
    let mut i = args.into_iter().skip(1);
    let mut opts = Options {
        input: Input::Stdin,
        eval: true,
        export_ast: false,
        named_args: <_>::default(),
        envs: <_>::default(),
        env_ctx: &"default",
        err_server: <_>::default(),
        err_server_clear: <_>::default(),
        err_server_quit: <_>::default(),
        json_input_script: <_>::default(),
    };
    loop {
        match i.next().map(<_>::as_ref) {
            None => break,
            Some("--error-server") => {
                opts.err_server = true;
            }
            Some("--error-server-clear") => {
                opts.err_server_clear = true;
            }
            Some("--error-server-quit") => {
                opts.err_server_quit = true;
            }
            Some("--env-file") => {
                let env_file_path = i.next();
                let env_file_path =
                    te!(env_file_path, "Missing argument to --env-file")
                        .as_ref();
                let env_file = fs::File::open(env_file_path)?;
                opts.envs = te!(serde_yaml::from_reader::<_, EnvFile>(&env_file), "Error loading yaml");
            }
            Some("--env-context") => {
                let env_context = i.next();
                let env_context =
                    te!(env_context, "Missing argument to --env-context")
                        .as_ref();
                opts.env_ctx = env_context.as_ref();
            }
            Some("-f") => {
                let filepath = i.next();
                let filepath =
                    te!(filepath, "Missing argument to -f").as_ref();
                opts.input = Input::File(filepath);
            }
            Some("-c") => {
                let script = te!(i.next(), "Missing argument to -c").as_ref();
                opts.input = Input::Str(script);
            }
            Some("-s") => {
                opts.eval = false;
            }
            Some("-a") => {
                opts.export_ast = true;
            }
            Some("-j") => {
                opts.json_input_script = true;
            }
            Some("-ah") => {
                let name = i.next();
                let name = te!(name, "Missing name to -ah");
                let sval = i.next();
                let sval = te!(sval, "Missing argument to -ah");

                opts.named_args.insert(name.as_ref(), sval.as_ref());
            }
            Some(other) => err!(f!("Unknown argument: {:#?}", other)),
        }
    }
    Ok(opts)
}

pub struct Options<'a> {
    pub input: Input<'a>,
    pub eval: bool,
    pub export_ast: bool,
    pub named_args: Map<&'a str, &'a str>,
    pub envs: EnvFile,
    pub env_ctx: &'a str,
    pub err_server: bool,
    pub err_server_clear: bool,
    pub err_server_quit: bool,
    pub json_input_script: bool,
}

use crate::ast::EnvFile;

use super::*;
use std::format as f;
