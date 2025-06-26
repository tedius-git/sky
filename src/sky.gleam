// IMPORTS ---------------------------------------------------------------------

import lustre
import app.{init,update}
import view.{view}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
