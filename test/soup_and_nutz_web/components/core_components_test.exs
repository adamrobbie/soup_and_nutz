defmodule SoupAndNutzWeb.CoreComponentsTest do
  use SoupAndNutzWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SoupAndNutzWeb.CoreComponents

  test "renders flash group" do
    flash = %{"info" => "Test message", "error" => "Error message"}
    html = render_component(&flash_group/1, %{flash: flash})
    assert html =~ "Test message"
    assert html =~ "Error message"
    assert html =~ "flash-group"
  end

  test "renders input" do
    html = render_component(&input/1, %{name: "test", label: "Test Input", value: "test value"})
    assert html =~ "input"
    assert html =~ "Test Input"
  end
end
