// IMPORTS ---------------------------------------------------------------------
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{attribute}
import lustre/element/svg.{circle}
import vectors.{type Vector}

// TYPE ---------------------------------------------------------------------
pub type Particle {
  Particle(m: Int, r: Vector, v: Vector, a: Vector)
}

// FUCTIONS ---------------------------------------------------------------------

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

pub fn get_color(particle: Particle) {
  case particle.m < 5 {
    True -> "url(#RED)"
    False ->
      case particle.m < 8 {
        True -> "url(#BLUE)"
        False -> "url(#GREEN)"
      }
  }
}

pub fn to_svg(particle: Particle) {
  let assert Ok(x) = vectors.x(particle.r)
  let assert Ok(y) = vectors.y(particle.r)
  let m = int.to_string(particle.m)
  let color = get_color(particle)
  circle([
    attribute("r", m),
    attribute("cx", float.to_string(x)),
    attribute("cy", float.to_string(y)),
    attribute("fill", color),
  ])
}
