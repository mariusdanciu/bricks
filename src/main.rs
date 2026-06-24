use app::App;
use winit::event_loop::EventLoop;

use crate::errors::AppError;

mod app;
mod camera;
mod errors;
mod shaders;

enum Storage {
    SQLLite,
    Postgres
}

fn main() -> Result<(), AppError> {
    let event_loop = EventLoop::new()?;

    let mut app = App::new(&event_loop)?;

    event_loop.run_app(&mut app);
    Ok(())
}
