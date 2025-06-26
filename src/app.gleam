// IMPORTS ---------------------------------------------------------------------
import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import lustre/effect.{type Effect}
import physics.{type Particle, new_particle, update_particle}

// Types -----------------------------------------------------------------------

pub type Model {
  Model(
    debug: Bool,
    light_on: Bool,
    width: Float,
    height: Float,
    paused: Bool,
    particles: List(Particle),
    time: Float,
    timer_id: Option(Int),
  )
}

pub type Msg {
  UserTogglePaused
  UserToggleDebug
  UserToggleTheme
  IncreseTime
  TimerStarted(Int)
  UserAddedParticle
  UserIncreseTime
  UserDecreseTime
  UpdateParticles(Float)
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

// UPDATE ----------------------------------------------------------------------

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let paused = model.paused
  let particles = model.particles
  let time = model.time

  case msg {
    UserToggleTheme -> #(
      Model(..model, light_on: bool.negate(model.light_on)),
      effect.none(),
    )
    UserToggleDebug -> #(
      Model(..model, debug: bool.negate(model.debug)),
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
    UserAddedParticle -> #(
      Model(
        ..model,
        particles: list.append(particles, [
          new_particle(model.width, model.height),
        ]),
      ),
      effect.none(),
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
  }
}
