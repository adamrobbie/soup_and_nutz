defmodule SoupAndNutzWeb.AuthController do
  use SoupAndNutzWeb, :controller
  alias SoupAndNutz.Accounts
  alias SoupAndNutz.Accounts.User

  def login(conn, _params) do
    render(conn, :login)
  end

  def login_post(conn, %{"user" => user_params}) do
    case authenticate_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.first_name}!")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)
    end
  end

  def register(conn, _params) do
    changeset = Accounts.change_user(%User{}, %{
      first_name: "",
      last_name: "",
      email: "",
      username: "",
      password: "",
      password_confirmation: ""
    })
    render(conn, :register, changeset: changeset)
  end

  def register_post(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Account created successfully! Welcome, #{user.first_name}!")
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        render(conn, :register, changeset: changeset)
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> put_flash(:info, "You have been logged out successfully.")
    |> redirect(to: ~p"/auth/login")
  end

  def profile(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user_profile(user)
    render(conn, :profile, user: user, changeset: changeset)
  end

  def profile_update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Profile updated successfully!")
        |> redirect(to: ~p"/auth/profile")

      {:error, changeset} ->
        render(conn, :profile, user: user, changeset: changeset)
    end
  end

  def change_password(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user_password(user, %{
      password: "",
      password_confirmation: ""
    })
    render(conn, :change_password, user: user, changeset: changeset)
  end

  def change_password_post(conn, %{"user" => password_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Password updated successfully!")
        |> redirect(to: ~p"/auth/profile")

      {:error, changeset} ->
        render(conn, :change_password, user: user, changeset: changeset)
    end
  end

  # Private functions

  defp authenticate_user(%{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email(email) do
      nil ->
        {:error, :not_found}

      user ->
        if Bcrypt.verify_pass(password, user.password_hash) do
          Accounts.update_last_login(user)
          {:ok, user}
        else
          {:error, :invalid_password}
        end
    end
  end

  defp authenticate_user(_), do: {:error, :invalid_params}
end
