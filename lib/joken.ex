defmodule Joken do
  alias Joken.Token

  @type algorithm :: :HS256 | :HS384 | :HS512
  @type claim :: :exp | :nbf | :iat | :aud | :iss | :sub | :jti
  @type status :: :ok | :error
  @type payload :: map | Keyword.t

  @moduledoc """
  Encodes and decodes JSON Web Tokens.

  Supports the following algorithms:

  * HS256
  * HS384
  * HS512

  Supports the following claims:

  * Expiration (exp)
  * Not Before (nbf)
  * Audience (aud)
  * Issuer (iss)
  * Subject (sub)
  * Issued At (iat)
  * JSON Token ID (jti)


  Usage:

  First, create a module that implements the `Joken.Config` Behaviour. 
  This Behaviour is responsible for the following:

    * encoding and decoding tokens
    * adding and validating claims
    * secret key used for encoding and decoding
    * the algorithm used

  If a claim function returns `nil` then that claim will not be added to the token. 
  Here is a full example of a module that would add and validate the `exp` claim 
  and not add or validate the others:


      defmodule My.Config.Module do
        @behaviour Joken.Config

        def secret_key() do
          Application.get_env(:app, :secret_key)
        end

        def algorithm() do
          :H256
        end

        def encode(map) do
          Poison.encode!(map)
        end

        def decode(binary) do
          Poison.decode!(binary, keys: :atoms!)
        end

        def claim(:exp, payload) do
          Joken.Config.get_current_time() + 300
        end

        def claim(_, _) do
          nil
        end

        def validate_claim(:exp, payload) do
          Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
        end

        def validate_claim(_, _) do
          :ok
        end
      end


  Joken looks for a `joken` config with `config_module`. `config_module` module being a module that implements the `Joken.Config` Behaviour.

       config :joken,
         config_module: My.Config.Module

  then to encode and decode

      {:ok, token} = Joken.encode(%{username: "johndoe"})

      {:ok, decoded_payload} = Joken.decode(jwt)
  """


  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

      Joken.encode(%{ name: "John Doe" })
  """

  @spec encode(payload) :: { status, String.t }
  def encode(payload) do
    Token.encode(config_module, payload)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload

      Joken.decode(token)

  You can also pass a skip list of atoms in order to skip some validations.
  Be advised that this is NOT intended to customize claim validation. It is
  is only intended to be used when you want to refresh a token and need to
  validate an expired token.
  """

  @spec decode(String.t, Keyword.t) :: { status, map | String.t }
  def decode(jwt, options \\ []) do
    Token.decode(config_module, jwt, options)
  end

  defp config_module() do
    Application.get_env(:joken, :config_module)
  end
end
