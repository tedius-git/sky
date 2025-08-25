// IMPORTS ---------------------------------------------------------------------
import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import lustre/effect.{type Effect}
import physics.{type Particle, new_particle, update_particle}
import vectors

// Types -----------------------------------------------------------------------

pub type Model {
  Model(
    show_v: Bool,
    show_a: Bool,
    light_on: Bool,
    width: Float,
    height: Float,
    paused: Bool,
    particles: List(Particle),
    time: Float,
    timer_id: Option(Int),
    mouse: vectors.Vector,
    mouse_down_pos: Option(vectors.Vector),
  )
}

pub type Msg {
  UserTogglePaused
  UserToggleV
  UserToggleA
  UserToggleTheme
  IncreseTime
  TimerStarted(Int)
  UserIncreseTime
  UserDecreseTime
  UpdateParticles(Float)
  MouseMoved(Float, Float)
  MouseDown(Float, Float)
  MouseUp(Float, Float)
}

// Model -----------------------------------------------------------------------

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
      show_v: True,
      show_a: True,
      light_on: True,
      paused: True,
      width: get_window_width(),
      height: get_window_height(),
      particles: [],
      time: 0.0,
      timer_id: None,
      mouse: [0.0, 0.0],
      mouse_down_pos: None,
    )
  #(model, setup_mouse_tracking())
}

//Effects ----------------------------------------------------------------
fn start_timer() -> Effect(Msg) {
  use dispatch <- effect.from
  let timer_id = set_interval(10, fn() { dispatch(IncreseTime) })
  dispatch(TimerStarted(timer_id))
}

fn stop_timer(timer_id: Int) -> Effect(Msg) {
  effect.from(fn(_) {
    clear_interval(timer_id)
    Nil
  })
}

@external(javascript, "./sky.ffi.mjs", "set_interval")
fn set_interval(_delay: Int, _cb: fn() -> a) -> Int {
  0
}

@external(javascript, "./sky.ffi.mjs", "clear_interval")
fn clear_interval(_timer_id: Int) -> Nil {
  Nil
}

fn update_particles_effect(delta: Float) -> Effect(Msg) {
  use dispatch <- effect.from
  dispatch(UpdateParticles(delta))
}

@external(javascript, "./sky.ffi.mjs", "setup_mouse_listener")
fn setup_mouse_listener(dispatch: fn(Float, Float) -> Nil) -> fn() -> Nil

@external(javascript, "./sky.ffi.mjs", "setup_mouse_down_listener")
fn setup_mouse_down_listener(dispatch: fn(Float, Float) -> Nil) -> fn() -> Nil

@external(javascript, "./sky.ffi.mjs", "setup_mouse_up_listener")
fn setup_mouse_up_listener(dispatch: fn(Float, Float) -> Nil) -> fn() -> Nil

fn setup_mouse_tracking() -> Effect(Msg) {
  use dispatch <- effect.from
  let _cleanup_fn =
    setup_mouse_listener(fn(x, y) { dispatch(MouseMoved(x, y)) })
  let _cleanup_down =
    setup_mouse_down_listener(fn(x, y) { dispatch(MouseDown(x, y)) })
  let _cleanup_up =
    setup_mouse_up_listener(fn(x, y) { dispatch(MouseUp(x, y)) })
  Nil
}

// UPDATE ----------------------------------------------------------------------

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let paused = model.paused
  let time = model.time

  case msg {
    UserToggleTheme -> #(
      Model(..model, light_on: bool.negate(model.light_on)),
      effect.none(),
    )
    UserToggleV -> #(
      Model(..model, show_v: bool.negate(model.show_v)),
      effect.none(),
    )
    UserToggleA -> #(
      Model(..model, show_a: bool.negate(model.show_a)),
      effect.none(),
    )
    UserTogglePaused ->
      case paused, model.timer_id {
        True, _ -> #(Model(..model, paused: False), start_timer())
        False, Some(timer_id) -> #(
          Model(..model, paused: True, timer_id: None),
          stop_timer(timer_id),
        )
        False, None -> #(Model(..model, paused: True), effect.none())
      }
    TimerStarted(timer_id) -> #(
      Model(..model, timer_id: Some(timer_id)),
      effect.none(),
    )

    IncreseTime -> #(
      Model(..model, time: time +. 0.1),
      update_particles_effect(0.1),
    )
    UserIncreseTime -> #(
      Model(..model, time: model.time +. 1.0),
      update_particles_effect(1.0),
    )
    UserDecreseTime ->
      case time == 0.0 {
        True -> #(model, effect.none())
        False -> #(
          Model(..model, time: time -. 1.0),
          update_particles_effect(-1.0),
        )
      }
    UpdateParticles(t) -> #(
      Model(..model, particles: {
        let particles =
          list.map(model.particles, update_particle(
            _,
            model.particles,
            t,
            model.width,
            model.height,
          ))
        pair.first(result.partition(particles))
      }),
      effect.none(),
    )
    MouseMoved(x, y) -> {
      #(Model(..model, mouse: [x, y]), effect.none())
    }
    MouseDown(x, y) -> {
      case x >. 30.0, y >. 30.0 {
        True, True -> #(
          Model(..model, mouse_down_pos: Some(model.mouse)),
          effect.none(),
        )
        _, _ -> #(model, effect.none())
      }
    }

    MouseUp(x, y) ->
      case model.mouse_down_pos {
        None -> #(model, effect.none())
        Some(start_pos) -> {
          // TODO - When launching a planet if you move the mouse in the bottom the direcction changes
          let assert [x_0, y_0] = start_pos
          let dx = x_0 -. x
          let dy = y_0 -. y
          let velocity = [dx /. 10.0, dy /. 10.0]
          let new_p = new_particle(start_pos, velocity, 5)
          #(
            Model(
              ..model,
              particles: list.append(model.particles, [new_p]),
              mouse_down_pos: None,
            ),
            effect.none(),
          )
        }
      }
  }
}
