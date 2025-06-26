// IMPORTS ---------------------------------------------------------------------
import gleam/float
import gleam/list
import lustre/attribute.{attribute}
import lustre/element/svg.{line}

// TYPE ---------------------------------------------------------------------
pub type Vector =
  List(Float)

// FUNCTIONS ---------------------------------------------------------------------

pub fn x(v: Vector) {
  list.first(v)
}

pub fn y(v: Vector) {
  list.last(v)
}

/// Returns the additive inverse of the Vector given
pub fn negate(v: Vector) -> Vector {
  let smart_negate = fn(x: Float) {
    case x {
      0.0 -> 0.0
      _ -> float.negate(x)
    }
  }
  list.map(v, smart_negate)
}

/// Add two Vectors
pub fn add(v: Vector, u: Vector) -> Vector {
  list.map2(v, u, float.add)
}

/// Subtract two Vectors
pub fn subtract(v: Vector, u: Vector) -> Vector {
  add(v, negate(u))
}

/// Multiply a Vector and a Float
pub fn scale(a: Float, v: Vector) -> Vector {
  let smart_mult = fn(s: Float, t: Float) -> Float {
    case s, t {
      0.0, _ -> 0.0
      _, 0.0 -> 0.0
      _, _ -> float.multiply(s, t)
    }
  }
  list.map(v, smart_mult(a, _))
}

/// Dot product
pub fn dot(v: Vector, u: Vector) -> Float {
  list.fold(list.map2(v, u, float.multiply), 0.0, float.add)
}

pub fn equals(v: Vector, u: Vector, tol: Float) -> Bool {
  let is_close = list.map2(v, u, fn(x, y) { float.loosely_equals(x, y, tol) })
  list.all(is_close, fn(x) { x })
}

pub fn mod(v: Vector) {
  list.fold(list.map(v, fn(x) { x *. x }), 0.0, float.add)
}

pub fn normalize(v: Vector) {
  scale(1.0 /. mod(v), v)
}

pub fn to_svg(center: Vector, to: Vector, color: String) {
  let assert Ok(x1) = x(center)
  let assert Ok(y1) = y(center)
  let assert Ok(x2) = x(add(center, scale(50.0, to)))
  let assert Ok(y2) = y(add(center, scale(50.0, to)))
  line([
    attribute("x1", float.to_string(x1)),
    attribute("y1", float.to_string(y1)),
    attribute("x2", float.to_string(x2)),
    attribute("y2", float.to_string(y2)),
    attribute("stroke", color),
    attribute("marker-end", "url(#arrow)"),
  ])
}
