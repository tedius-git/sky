import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option}
import vectors.{type Vector}

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

pub type Particle {
  Particle(m: Int, r: Vector, v: Vector, a: Vector)
}

pub fn forces(
  particle: Particle,
  others: List(Particle),
) -> List(vectors.Vector) {
  let g = 6.6743e3
  list.map(others, fn(p) {
    let dr = vectors.subtract(p.r, particle.r)

    let r_squared = vectors.dot(dr, dr)

    let force_magnitude =
      g *. int.to_float(particle.m) *. int.to_float(p.m) /. r_squared

    let direction = vectors.normalize(dr)

    case force_magnitude >. 10.0 {
      True -> vectors.scale(10.0, direction)

      False -> vectors.scale(force_magnitude, direction)
    }
  })
}

pub fn sum_forces(particle: Particle, all: List(Particle)) -> vectors.Vector {
  let r = particle.r
  let others =
    list.filter(all, fn(p) { bool.negate(vectors.equals(r, p.r, 0.1)) })
  list.fold(forces(particle, others), [0.0, 0.0], vectors.add)
}
