defmodule TodosWeb.PageController do
  use TodosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
