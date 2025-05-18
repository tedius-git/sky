// IMPORTS ---------------------------------------------------------------------
import gleam/option.{None}
import lustre/effect.{type Effect}
import types.{type Model, type Msg, Model}

// MODEL -----------------------------------------------------------------------

@external(javascript, "./sky.ffi.mjs", "get_window_width")
fn get_window_width() -> Float {
  800.0
  // Default
}

@external(javascript, "./sky.ffi.mjs", "get_window_height")
fn get_window_height() -> Float {
  600.0
  // Default
}

pub fn init(_args) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      debug: False,
      light_on: True,
      paused: True,
      width: get_window_width(),
      height: get_window_height(),
      particles: [],
      time: 0.0,
      timer_id: None,
    )
  #(model, effect.none())
}
