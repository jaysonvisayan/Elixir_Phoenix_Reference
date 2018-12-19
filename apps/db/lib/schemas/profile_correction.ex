defmodule Innerpeace.Db.Schemas.ProfileCorrection do
  @moduledoc false

  use Innerpeace.Db.Schema
  use Arc.Ecto.Schema

  schema "profile_corrections" do
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :suffix, :string
    field :birth_date, Ecto.Date
    field :gender, :string
    field :id_card, Innerpeace.ImageUploader.Type
    field :status, :string

    belongs_to :user, Innerpeace.Db.Schemas.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :birth_date,
      :gender,
      :status,
      :user_id
    ])
    |> cast_attachments(params, [
      :id_card
    ])
    |> validate_required([
      :id_card,
      :status,
    ],
      message: "This is a required field"
    )
    |> validate_inclusion(:gender, ["Male", "Female"])
    |> validate_format(:first_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The first name you have entered is invalid")
    |> validate_format(:middle_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The middle name you have entered is invalid")
    |> validate_format(:last_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The last name you have entered is invalid")
    |> validate_format(:suffix,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,10}$/,
                       message: "The extension you have entered is invalid")
    |> validate_required_inclusion([
      :first_name,
      :last_name
    ],
    optional: [
      :middle_name,
      :suffix
    ]
    )
  end

  defp validate_required_inclusion(changeset, fields, opts \\ []) do
    merged_fields =
      fields ++ Keyword.get(opts, :optional)

    if Enum.any?(merged_fields, fn(field) -> present?(changeset, field) end) do
      merged_fields
      |> add_error_inclusion(
        changeset,
        Keyword.get(opts, :optional)
      )
    else
      changeset
    end
  end

  defp present?(changeset, field) do
    value =
      changeset
      |> get_field(field)

    value && value != ""
  end

  defp add_error_inclusion([], changeset, opts), do: changeset
  defp add_error_inclusion([field | fields], changeset, opts) do
    if present?(changeset, field) do
      fields
      |> add_error_inclusion(
        changeset,
        opts
      )
    else
      if Enum.member?(opts, field) do
        changeset
      else
        changeset =
          changeset
          |> add_error(
            field,
            "This is a required field",
            additional: :required_inclusion)
      end

      fields
      |> add_error_inclusion(
        changeset,
        opts
      )
    end
  end

  def changeset_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :first_name,
      :middle_name,
      :last_name,
      :suffix,
      :birth_date,
      :gender,
      :status,
      :user_id
    ])
    |> validate_required([
      :status,
    ],
      message: "This is a required field"
    )
    |> validate_inclusion(:gender, ["Male", "Female"])
    |> validate_format(:first_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The first name you have entered is invalid")
    |> validate_format(:middle_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The middle name you have entered is invalid")
    |> validate_format(:last_name,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,150}$/,
                       message: "The last name you have entered is invalid")
    |> validate_format(:suffix,
                       ~r/^[,.\-ña-zÑA-Z\s]{0,10}$/,
                       message: "The extension you have entered is invalid")
    |> validate_required_inclusion([
      :first_name,
      :last_name
    ],
    optional: [
      :middle_name,
      :suffix
    ]
    )
  end

  def changeset_id_card(struct, params \\ %{}) do
    struct
    |> cast_attachments(params, [:id_card])
  end
end
