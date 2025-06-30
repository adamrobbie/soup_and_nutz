defmodule SoupAndNutzWeb.Live.AuthHook do
  @moduledoc """
  Authentication hooks for LiveView modules.

  Provides hooks for ensuring authentication and optional authentication
  in LiveView components.
  """

  import Phoenix.Component
  import Phoenix.LiveView
  alias SoupAndNutz.Accounts

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case get_user_from_session(session) do
      nil ->
        {:halt, push_navigate(socket, to: "/auth/login")}

      user ->
        {:cont, assign(socket, current_user: user)}
    end
  end

  def on_mount(:optional_authenticated, _params, session, socket) do
    user = get_user_from_session(session)
    {:cont, assign(socket, current_user: user)}
  end

  defp get_user_from_session(session) do
    case session["user_id"] do
      nil -> nil
      user_id -> Accounts.get_user!(user_id)
    end
  end
end
