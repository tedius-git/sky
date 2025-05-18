// IMPORTS ---------------------------------------------------------------------

import lustre
import model.{init}
import update.{update}
import view.{view}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
