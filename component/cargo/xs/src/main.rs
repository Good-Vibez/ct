fn main() {
    pretty_env_logger::init();

    process::exit(error::main(|| {
        let args: Vec<String> = env::args().collect();
        log::debug!("Command Line Arguments: {:#?}", args);
        let mut opts = te!(cli::parse_args(&args));

        // reads variables from env file
        // variables from cli (-ah) always have higher priority
        // only insert the ones missing
        if let Some(ctx) = opts.envs.get(opts.env_ctx) {
            for (key, value) in ctx.into_iter() {
                opts.named_args.entry(key).or_insert(match value {
                    cli::EnvValue::Str(str) => str,
                    cli::EnvValue::Map(map) => &map.value,
                });
            }
        }

        let mut inpt = te!(opts.input.open());

        let mut source = String::new();

        let result = (|| {
            if opts.err_server_quit {
                return error::quit();
            }
            if opts.err_server_clear {
                return error::clear_error_server();
            }
            if opts.err_server {
                return error::run_error_server();
            }

            te!(io::Read::read_to_string(&mut inpt, &mut source));

            let script: ast::Script = if opts.json_input_script {
                te!(
                    json::from_str(&source),
                    format!("Source Json Script Error")
                )
            } else {
                te!(ron::from_str(&source), format!("Source Ron Script Error"))
            };
            if opts.export_ast {
                te!(json::to_writer(io::stdout(), &script));
                eprintln!("{:#?}", script);
            }

            let mut ng: engine::Engine = <_>::default();
            for (&name, &val) in &opts.named_args {
                ng.variables.insert(
                    name.to_owned(),
                    engine::Value::from(val.to_owned()),
                );
            }
            if opts.eval {
                te!(eval::eval(script, ng));
            }

            Ok(())
        })();

        Ok(te!(
            result,
            format!("While processing {}", opts.input.to_display())
        ))
    }))
}

mod __user;
mod adaptors;
mod ast;
mod clear;
mod cli;
mod engine;
mod error;
mod eval;
mod input;
mod output;

use {
    clear::clearing,
    engine::Engine,
    error::{
        err,
        te,
        xerr,
        Error,
        Result,
    },
    input::Input,
    serde_json as json,
    serde_yaml as yaml,
    std::{
        borrow::{
            Borrow,
            BorrowMut,
            Cow,
        },
        collections::{
            btree_map::{
                BTreeMap as Map,
                Entry,
            },
            VecDeque as Deq,
        },
        convert::{
            TryFrom,
            TryInto,
        },
        env,
        fmt,
        fs,
        io,
        marker::PhantomData as __,
        mem,
        net,
        //ops::Range,
        process,
    },
};
