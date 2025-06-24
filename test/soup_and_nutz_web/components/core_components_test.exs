defmodule SoupAndNutzWeb.CoreComponentsTest do
  use SoupAndNutzWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoupAndNutzWeb.CoreComponents

  test "renders flash group" do
    flash = %{"info" => "Test message", "error" => "Error message"}
    html = render_flash_group(flash)

    assert html =~ "Test message"
    assert html =~ "Error message"
    assert html =~ "flash-group"
  end

  test "renders flash group with empty flash" do
    html = render_flash_group(%{})
    assert html =~ "flash-group"
  end

  test "renders button with default attributes" do
    html = render_button("Click me")
    assert html =~ "Click me"
    assert html =~ "button"
    assert html =~ "bg-brand"
  end

  test "renders button with custom attributes" do
    html = render_button("Click me",
      type: "submit",
      class: "custom-class",
      disabled: true
    )
    assert html =~ "Click me"
    assert html =~ "type=\"submit\""
    assert html =~ "custom-class"
    assert html =~ "disabled"
  end

  test "renders button with variant" do
    html = render_button("Click me", variant: :outline)
    assert html =~ "Click me"
    assert html =~ "border-brand"
  end

  test "renders button with size" do
    html = render_button("Click me", size: :lg)
    assert html =~ "Click me"
    assert html =~ "px-4"
    assert html =~ "text-lg"
  end

  test "renders input with default attributes" do
    html = render_input("test", "Test Input")
    assert html =~ "Test Input"
    assert html =~ "input"
    assert html =~ "name=\"test\""
  end

  test "renders input with custom attributes" do
    html = render_input("test", "Test Input",
      type: "email",
      placeholder: "Enter email",
      required: true
    )
    assert html =~ "Test Input"
    assert html =~ "type=\"email\""
    assert html =~ "placeholder=\"Enter email\""
    assert html =~ "required"
  end

  test "renders input with error" do
    html = render_input("test", "Test Input", errors: ["This field is required"])
    assert html =~ "Test Input"
    assert html =~ "This field is required"
    assert html =~ "border-red-500"
  end

  test "renders label" do
    html = render_label("test", "Test Label")
    assert html =~ "Test Label"
    assert html =~ "label"
    assert html =~ "for=\"test\""
  end

  test "renders label with custom attributes" do
    html = render_label("test", "Test Label", class: "custom-class")
    assert html =~ "Test Label"
    assert html =~ "custom-class"
  end

  test "renders table" do
    rows = [
      %{id: 1, name: "John", email: "john@example.com"},
      %{id: 2, name: "Jane", email: "jane@example.com"}
    ]

    html = render_table(rows,
      id: "users-table",
      row_click: fn row -> "click:#{row.id}" end
    )

    assert html =~ "users-table"
    assert html =~ "John"
    assert html =~ "Jane"
    assert html =~ "john@example.com"
    assert html =~ "jane@example.com"
  end

  test "renders table with custom columns" do
    rows = [
      %{id: 1, name: "John", email: "john@example.com"},
      %{id: 2, name: "Jane", email: "jane@example.com"}
    ]

    html = render_table(rows,
      id: "users-table",
      columns: [
        %{key: :name, label: "Full Name"},
        %{key: :email, label: "Email Address"}
      ]
    )

    assert html =~ "Full Name"
    assert html =~ "Email Address"
    assert html =~ "John"
    assert html =~ "jane@example.com"
  end

  test "renders table with actions" do
    rows = [
      %{id: 1, name: "John", email: "john@example.com"}
    ]

    html = render_table(rows,
      id: "users-table",
      actions: fn row -> [
        %{label: "Edit", icon: "pencil", link: "/users/#{row.id}/edit"},
        %{label: "Delete", icon: "trash", link: "/users/#{row.id}", method: :delete}
      ] end
    )

    assert html =~ "Edit"
    assert html =~ "Delete"
    assert html =~ "/users/1/edit"
    assert html =~ "/users/1"
  end

  test "renders modal" do
    html = render_modal("test-modal", "Test Modal",
      show: true,
      max_w: "md"
    )

    assert html =~ "Test Modal"
    assert html =~ "test-modal"
    assert html =~ "max-w-md"
  end

  test "renders modal with custom content" do
    html = render_modal("test-modal", "Test Modal",
      show: true,
      max_w: "lg"
    ) do
      "Custom modal content"
    end

    assert html =~ "Test Modal"
    assert html =~ "Custom modal content"
    assert html =~ "max-w-lg"
  end

  test "renders badge" do
    html = render_badge("Success", color: :green)
    assert html =~ "Success"
    assert html =~ "bg-green-100"
    assert html =~ "text-green-800"
  end

  test "renders badge with different colors" do
    html = render_badge("Error", color: :red)
    assert html =~ "Error"
    assert html =~ "bg-red-100"
    assert html =~ "text-red-800"
  end

  test "renders badge with size" do
    html = render_badge("Info", color: :blue, size: :lg)
    assert html =~ "Info"
    assert html =~ "px-3"
    assert html =~ "text-sm"
  end

  test "renders icon" do
    html = render_icon("hero-heart", class: "w-6 h-6")
    assert html =~ "hero-heart"
    assert html =~ "w-6 h-6"
  end

  test "renders icon with different types" do
    html = render_icon("hero-heart", type: :outline, class: "w-5 h-5")
    assert html =~ "hero-heart"
    assert html =~ "w-5 h-5"
  end

  test "renders link" do
    html = render_link("Test Link", to: "/test", class: "custom-link")
    assert html =~ "Test Link"
    assert html =~ "href=\"/test\""
    assert html =~ "custom-link"
  end

  test "renders link with method" do
    html = render_link("Delete", to: "/delete", method: :delete, class: "text-red-600")
    assert html =~ "Delete"
    assert html =~ "href=\"/delete\""
    assert html =~ "text-red-600"
    assert html =~ "data-method=\"delete\""
  end

  test "renders form" do
    html = render_form("test-form", "/submit", method: :post) do
      "Form content"
    end

    assert html =~ "test-form"
    assert html =~ "action=\"/submit\""
    assert html =~ "method=\"post\""
    assert html =~ "Form content"
  end

  test "renders form with multipart" do
    html = render_form("test-form", "/submit", multipart: true) do
      "Form content"
    end

    assert html =~ "test-form"
    assert html =~ "multipart"
    assert html =~ "Form content"
  end

  test "renders select" do
    options = [
      %{value: "1", label: "Option 1"},
      %{value: "2", label: "Option 2"}
    ]

    html = render_select("test", "Test Select", options)
    assert html =~ "Test Select"
    assert html =~ "Option 1"
    assert html =~ "Option 2"
    assert html =~ "value=\"1\""
    assert html =~ "value=\"2\""
  end

  test "renders select with selected value" do
    options = [
      %{value: "1", label: "Option 1"},
      %{value: "2", label: "Option 2"}
    ]

    html = render_select("test", "Test Select", options, value: "2")
    assert html =~ "Test Select"
    assert html =~ "selected"
  end

  test "renders textarea" do
    html = render_textarea("test", "Test Textarea", placeholder: "Enter text")
    assert html =~ "Test Textarea"
    assert html =~ "textarea"
    assert html =~ "placeholder=\"Enter text\""
  end

  test "renders textarea with rows" do
    html = render_textarea("test", "Test Textarea", rows: 5)
    assert html =~ "Test Textarea"
    assert html =~ "rows=\"5\""
  end
end
