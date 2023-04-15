import mist
import gleam/list
import gleam/string
import gleam/http/response
import gleam/http/request.{Request}
import gleam/bit_string
import mist/http.{Body, FileBody}
import mist/file
import mist/handler.{Response}
import gleam/io
import gleam/int
import gleam/result
import gleam/erlang/process

pub fn service(req: Request(Body)) {
  case request.path_segments(req) {
    [] | ["index.html"] -> {
      serve_file(["..", "dist", "index.html"])
    }
    ["_astro", ..path] -> {
      serve_file(["..", "dist", "_astro", ..path])
    }
    ["assets", filename] -> {
      serve_file(["..", "assets", filename])
    }
    ["blog", post] -> {
      serve_file(["..", "dist", post, "index.html"])
    }
  }
}

fn serve_file(path: List(String)) {
  let file_path =
    path
    |> string.join("/")
    |> bit_string.from_string
  let size = file.size(file_path)
  let assert Ok(fd) = file.open(file_path)
  let response = response.new(200)

  case
    path
    |> list.last
    |> result.unwrap("")
    |> string.reverse
  {
    "sj." <> _ ->
      response.prepend_header(response, "Content-Type", "text/javascript")
    "lmth." <> _ ->
      response.prepend_header(response, "Content-Type", "text/html;charset=utf-8")
    "pbew." <> _ -> 
      response.prepend_header(response, "Content-Type", "image/webp")
    _ -> response
  } |>
  response.set_body(FileBody(fd, int.to_string(size), 0, size))
  |> Response
}

pub fn main() {
  let port = 3000
  let assert Ok(_) = mist.serve(port, handler.with_func(service))

  io.println("Starting server...")
  process.sleep_forever()
}
