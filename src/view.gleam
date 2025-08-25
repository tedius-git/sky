// IMPORTS ---------------------------------------------------------------------
import app.{
  type Model, type Msg, UserDecreseTime, UserIncreseTime, UserToggleA,
  UserTogglePaused, UserToggleTheme, UserToggleV,
}
import gleam/bool
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute as a
import lustre/element.{type Element}
import lustre/element/html as h
import lustre/element/svg
import lustre/event
import physics
import vectors

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  let bg = case model.light_on {
    True -> a.class("bg-white")
    False -> a.class("bg-black")
  }
  let text = case model.light_on {
    True -> a.class("text-black")
    False -> a.class("text-white")
  }
  // Main div 
  h.main([bg, text, a.class("h-screen static flex h-full z-0")], [
    // Github repo link
    h.a(
      [
        a.class(
          "absolute top-5 md:top-auto md:bottom-5 right-5 size-4 z-40 transition duration-300 ease-in-out hover:scale-125",
        ),
        a.target("_black"),
        a.href("https://github.com/tedius-git/sky"),
      ],
      [
        h.img([
          bool.guard(
            model.light_on,
            a.src("./priv/static/assets/github-mark.svg"),
            fn() { a.src("./priv/static/assets/github-mark-white.svg") },
          ),
        ]),
      ],
    ),
    // Menu bar
    // | Buttons...| Timer | Buttons...|
    h.div([a.class("absolute bottom-0 w-full z-20 flex flex-row items-end")], [
      // Buttons right
      h.div([a.class("flex-grow z-20 flex justify-end")], [
        div_glass(
          [a.class("w-12 transition duration-300 ease-in-out hover:scale-125")],
          [view_switch(UserToggleV, model.show_v, h.text("v"), h.text("v"))],
        ),
        div_glass(
          [a.class("w-12 transition duration-300 ease-in-out hover:scale-125")],
          [view_switch(UserToggleA, model.show_a, h.text("a"), h.text("a"))],
        ),
      ]),
      // Timer
      h.div([a.class("flex-shrink-0")], [
        view_timer(model.paused, model.time, model.light_on),
      ]),
      // Buttons left
      h.div([a.class("flex-grow z-20")], [
        div_glass(
          [a.class("w-12 transition duration-300 ease-in-out hover:scale-125")],
          [view_toggle_theme(model.light_on)],
        ),
      ]),
    ]),
    // Simulation Svg
    view_sim(model),
  ])
}

fn view_switch(
  handle_click: msg,
  on: Bool,
  when_on: Element(msg),
  when_off: Element(msg),
) {
  h.button([event.on_click(handle_click)], [
    case on {
      True -> when_on
      False -> when_off
    },
  ])
}

fn view_button_text(
  on_click handle_click: msg,
  label text: String,
) -> Element(msg) {
  h.button([event.on_click(handle_click)], [h.text(text)])
}

fn div_glass(attributes, elements: List(Element(Msg))) -> Element(Msg) {
  h.div(
    list.append(attributes, [
      a.class(
        "border border-neutral-600/10 rounded-xl bg-neutral-500/10 backdrop-blur-sm shadow-xl shadow-neutral-950/20",
      ),
      a.class("flex flex-col m-4 p-3"),
    ]),
    elements,
  )
}

fn view_toggle_theme(light_on: Bool) {
  let size = a.class("size-6")
  let invert = a.class("invert")
  view_switch(
    UserToggleTheme,
    light_on,
    h.img([a.src("./priv/static/assets/theme.png"), size]),
    h.img([a.src("./priv/static/assets/theme.png"), size, invert]),
  )
}

fn view_toggle_paused(paused: Bool, light_on: Bool) {
  let size = a.class("size-6")
  let invert = case light_on {
    True -> a.class("")
    False -> a.class("invert")
  }
  view_switch(
    UserTogglePaused,
    paused,
    h.img([a.src("./priv/static/assets/pause.png"), size, invert]),
    h.img([a.src("./priv/static/assets/play.png"), size, invert]),
  )
}

fn view_timer(paused: Bool, _time: Float, light_on: Bool) -> Element(Msg) {
  h.div(
    [
      a.class(
        "relative border-2 rounded-full m-4 size-32 transition duration-300 ease-in-out hover:scale-105",
      ),
      bool.guard(paused, a.class("border-red-500"), fn() {
        a.class("border-lime-900")
      }),
      a.class(
        "bg-neutral-500/10 backdrop-blur-sm shadow-xl shadow-neutral-950/20",
      ),
    ],
    [
      // h.p([a.class("absolute inset-x-0 top-5 text-center")], [
      //   text(int.to_string(float.truncate(time))),
      // ]),
      h.div([a.class("absolute inset-0 flex justify-center items-center")], [
        view_toggle_paused(paused, light_on),
      ]),
      {
        case paused {
          True ->
            h.div(
              [
                a.class(
                  "absolute inset-x-0 bottom-6 gap-4 flex justify-center items-center",
                ),
              ],
              [
                view_button_text(on_click: UserDecreseTime, label: "-"),
                view_button_text(on_click: UserIncreseTime, label: "+"),
              ],
            )
          False -> h.div([], [])
        }
      },
    ],
  )
}

fn view_sim(model: Model) -> Element(Msg) {
  h.svg([a.class("relative grow z-10 ")], {
    let particles_svg = list.map(model.particles, physics.to_svg)
    let launch_v = case model.mouse_down_pos {
      None -> []
      Some(start_pos) -> {
        let assert [x_0, y_0] = start_pos
        let assert [x, y] = model.mouse
        let dx = x_0 -. x
        let dy = y_0 -. y
        [vectors.to_svg([x_0, y_0], [dx /. 100.0, dy /. 100.0], "gray")]
      }
    }

    {
      let a = case model.show_a {
        True ->
          list.map(model.particles, fn(p) {
            #(
              p.r,
              {
                let forces = physics.sum_forces(p, model.particles)
                vectors.scale(2.0, forces)
                |> vectors.min(vectors.normalize(forces))
              },
              "darkorchid",
            )
          })
        False -> []
      }
      let v = case model.show_v {
        True ->
          list.map(model.particles, fn(p) {
            #(p.r, vectors.scale(0.1, p.v), "gray")
          })
        False -> []
      }
      let arrows = list.append(v, a)
      list.map(arrows, fn(v) {
        let #(from, to, color) = v
        vectors.to_svg(from, to, color)
      })
    }
    |> list.append(particles_svg)
    |> list.append(launch_v)
    |> list.append([
      svg.defs([], list.append(view_colors(), view_arrow_marker())),
    ])
  })
}

fn view_colors() {
  [
    svg.linear_gradient(
      [
        a.id("RED"),
        a.attribute("x1", "0%"),
        a.attribute("y1", "0%"),
        a.attribute("x2", "100%"),
        a.attribute("y2", "100%"),
      ],
      [
        svg.stop([
          a.attribute("offset", "0%"),
          a.attribute("stop-color", "#f36364"),
        ]),
        svg.stop([
          a.attribute("offset", "50%"),
          a.attribute("stop-color", "#f36364"),
        ]),
        svg.stop([
          a.attribute("offset", "100%"),
          a.attribute("stop-color", "#f292ed"),
        ]),
      ],
    ),
    svg.linear_gradient(
      [
        a.id("BLUE"),
        a.attribute("x1", "0%"),
        a.attribute("y1", "0%"),
        a.attribute("x2", "100%"),
        a.attribute("y2", "100%"),
      ],
      [
        svg.stop([
          a.attribute("offset", "0%"),
          a.attribute("stop-color", "#c6f8ff"),
        ]),
        svg.stop([
          a.attribute("offset", "50%"),
          a.attribute("stop-color", "#595cff"),
        ]),
        svg.stop([
          a.attribute("offset", "100%"),
          a.attribute("stop-color", "#595cff"),
        ]),
      ],
    ),
    svg.linear_gradient(
      [
        a.id("GREEN"),
        a.attribute("x1", "0%"),
        a.attribute("y1", "0%"),
        a.attribute("x2", "100%"),
        a.attribute("y2", "100%"),
      ],
      [
        svg.stop([
          a.attribute("offset", "0%"),
          a.attribute("stop-color", "#f3f520"),
        ]),
        svg.stop([
          a.attribute("offset", "50%"),
          a.attribute("stop-color", "#59d102"),
        ]),
        svg.stop([
          a.attribute("offset", "100%"),
          a.attribute("stop-color", "#59d102"),
        ]),
      ],
    ),
  ]
}

fn view_arrow_marker() {
  [
    svg.marker(
      [
        a.attribute("id", "arrow"),
        a.attribute("viewBox", "0 0 10 10"),
        a.attribute("refX", "5"),
        a.attribute("refY", "5"),
        a.attribute("markerWidth", "6"),
        a.attribute("markerHeight", "6"),
        a.attribute("orient", "auto-start-reverse"),
        a.attribute("stroke", "context-stroke"),
        a.attribute("fill", "context-stroke"),
      ],
      [svg.path([a.attribute("d", "M 0 0 L 10 5 L 0 10 z")])],
    ),
  ]
}
